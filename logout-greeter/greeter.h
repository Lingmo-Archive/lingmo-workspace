/*
    ksmserver - the KDE session management server

    SPDX-FileCopyrightText: 2016 Martin Graesslin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2018 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: MIT
*/

#pragma once

#include <QList>
#include <QObject>

#include <kworkspace.h>

#include <KPackage/Package>

class KSMShutdownDlg;

class QScreen;
class QEventLoopLocker;

class Greeter : public QObject
{
    Q_OBJECT
public:
    Greeter(const KPackage::Package &package);
    ~Greeter() override;

    void init();
    void enableWindowed();

    bool eventFilter(QObject *watched, QEvent *event) override;

public Q_SLOTS:
    void promptLogout();
    void promptShutDown();
    void promptReboot();
    void promptAll();

private:
    void quit();
    void adoptScreen(QScreen *screen);
    void setupWaylandIntegration();

    bool m_running = false;

    KWorkSpace::ShutdownType m_shutdownType = KWorkSpace::ShutdownTypeHalt;
    QList<KSMShutdownDlg *> m_dialogs;
    bool m_windowed = false;
    KPackage::Package m_package;
};
