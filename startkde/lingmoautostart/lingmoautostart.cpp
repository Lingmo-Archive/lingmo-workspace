/*
    This file is part of the KDE libraries
    SPDX-FileCopyrightText: 2006 Aaron Seigo <aseigo@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "lingmoautostart.h"

#include <KConfigGroup>
#include <KDesktopFile>

#include <QCoreApplication>
#include <QDir>
#include <QFile>

void LingmoAutostart::copyIfNeeded()
{
    if (copyIfNeededChecked) {
        return;
    }

    const QString local = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QLatin1String("/autostart/") + name;

    if (!QFile::exists(local)) {
        const QString global = QStandardPaths::locate(QStandardPaths::GenericConfigLocation, QLatin1String("autostart/") + name);
        if (!global.isEmpty()) {
            KDesktopFile *newDf = df->copyTo(local);
            delete df;
            delete newDf; // Force sync-to-disk
            df = new KDesktopFile(QStandardPaths::GenericConfigLocation, u"autostart/" + name); // Recreate from disk
        }
    }

    copyIfNeededChecked = true;
}

LingmoAutostart::LingmoAutostart(const QString &entryName, QObject *parent)
    : QObject(parent)
{
    const bool isAbsolute = QDir::isAbsolutePath(entryName);
    if (isAbsolute) {
        name = entryName.mid(entryName.lastIndexOf(QLatin1Char('/')) + 1);
    } else {
        if (entryName.isEmpty()) {
            name = QCoreApplication::applicationName();
        } else {
            name = entryName;
        }

        if (!name.endsWith(QLatin1String(".desktop"))) {
            name.append(QLatin1String(".desktop"));
        }
    }

    const QString path = isAbsolute ? entryName : QStandardPaths::locate(QStandardPaths::GenericConfigLocation, QLatin1String("autostart/") + name);
    if (path.isEmpty()) {
        // just a new KDesktopFile, since we have nothing to use
        df = new KDesktopFile(QStandardPaths::GenericConfigLocation, QLatin1String("autostart/") + name);
        copyIfNeededChecked = true;
    } else {
        df = new KDesktopFile(path);
    }
}

LingmoAutostart::~LingmoAutostart() = default;

void LingmoAutostart::setAutostarts(bool autostart)
{
    bool currentAutostartState = !df->desktopGroup().readEntry("Hidden", false);
    if (currentAutostartState == autostart) {
        return;
    }

    copyIfNeeded();
    df->desktopGroup().writeEntry("Hidden", !autostart);
}

bool LingmoAutostart::autostarts(const QString &environment, Conditions check) const
{
    // check if this is actually a .desktop file
    bool starts = df->desktopGroup().exists();

    // check the hidden field
    starts = starts && !df->desktopGroup().readEntry("Hidden", false);

    if (!environment.isEmpty()) {
        starts = starts && checkAllowedEnvironment(environment);
    }

    if (check & CheckCommand) {
        starts = starts && df->tryExec();
    }

    if (check & CheckCondition) {
        starts = starts && checkStartCondition();
    }

    return starts;
}

bool LingmoAutostart::checkStartCondition() const
{
    return LingmoAutostart::isStartConditionMet(df->desktopGroup().readEntry("X-KDE-autostart-condition"));
}

bool LingmoAutostart::isStartConditionMet(QStringView condition)
{
    if (condition.isEmpty()) {
        return true;
    }

    const auto list = condition.split(QLatin1Char(':'));
    if (list.count() < 4) {
        return true;
    }

    if (list[0].isEmpty() || list[2].isEmpty()) {
        return true;
    }

    KConfig config(list[0].toString(), KConfig::NoGlobals);
    KConfigGroup cg(&config, list[1].toString());

    const bool defaultValue = (list[3].toString().compare(QLatin1String("true"), Qt::CaseInsensitive) == 0);
    return cg.readEntry(list[2].toString(), defaultValue);
}

bool LingmoAutostart::checkAllowedEnvironment(const QString &environment) const
{
    const QStringList allowed = allowedEnvironments();
    if (!allowed.isEmpty()) {
        return allowed.contains(environment);
    }

    const QStringList excluded = excludedEnvironments();
    if (!excluded.isEmpty()) {
        return !excluded.contains(environment);
    }

    return true;
}

QString LingmoAutostart::command() const
{
    return df->desktopGroup().readEntry("Exec", QString());
}

void LingmoAutostart::setCommand(const QString &command)
{
    if (df->desktopGroup().readEntry("Exec", QString()) == command) {
        return;
    }

    copyIfNeeded();
    df->desktopGroup().writeEntry("Exec", command);
}

bool LingmoAutostart::isServiceRegistered(const QString &entryName)
{
    const QString localDir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QLatin1String("/autostart/");
    return QFile::exists(localDir + entryName + QLatin1String(".desktop"));
}

// do not specialize the readEntry template -
// http://connect.microsoft.com/VisualStudio/feedback/ViewFeedback.aspx?FeedbackID=100911
static LingmoAutostart::StartPhase readEntry(const KConfigGroup &group, const char *key, LingmoAutostart::StartPhase aDefault)
{
    const QByteArray data = group.readEntry(key, QByteArray());

    if (data.isNull()) {
        return aDefault;
    }

    if (data == "0" || data == "BaseDesktop") {
        return LingmoAutostart::BaseDesktop;
    } else if (data == "1" || data == "DesktopServices") {
        return LingmoAutostart::DesktopServices;
    } else if (data == "2" || data == "Applications") {
        return LingmoAutostart::Applications;
    }

    return aDefault;
}

LingmoAutostart::StartPhase LingmoAutostart::startPhase() const
{
    return readEntry(df->desktopGroup(), "X-KDE-autostart-phase", Applications);
}

QStringList LingmoAutostart::allowedEnvironments() const
{
    return df->desktopGroup().readXdgListEntry("OnlyShowIn");
}

QStringList LingmoAutostart::excludedEnvironments() const
{
    return df->desktopGroup().readXdgListEntry("NotShowIn");
}

QString LingmoAutostart::startAfter() const
{
    return df->desktopGroup().readEntry("X-KDE-autostart-after");
}
