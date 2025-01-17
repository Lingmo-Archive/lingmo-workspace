/*
    SPDX-FileCopyrightText: 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

    SPDX-License-Identifier: LGPL-2.0-only
*/

#include "themesmodel.h"

#include <Lingmo/Theme>

#include <KLocalizedString>

#include <QApplication>
#include <QCommandLineParser>
#include <QDebug>
#include <QTimer>

using namespace Qt::StringLiterals;

int main(int argc, char **argv)
{
    // This is a CLI application, but we require at least a QGuiApplication for things
    // in Lingmo::Theme, so let's just roll with one of these
    QApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("lingmo-apply-desktoptheme"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("kde.org"));
    KLocalizedString::setApplicationDomain(QByteArrayLiteral("lingmo-apply-desktoptheme"));

    QCommandLineParser *parser = new QCommandLineParser;
    parser->addHelpOption();
    parser->setApplicationDescription(
        i18n("This tool allows you to set the theme of the current Lingmo session, without accidentally setting it to one that is either not available, or "
             "which is already set."));
    parser->addPositionalArgument(
        QStringLiteral("themename"),
        i18n("The name of the theme you wish to set for your current Lingmo session (passing a full path will only use the last part of the path)"));
    parser->addOption(QCommandLineOption(QStringLiteral("list-themes"), i18n("Show all the themes available on the system (and which is the current theme)")));
    parser->process(app);

    int errorCode{0};
    QTextStream ts(stdout);
    ThemesModel *model{new ThemesModel(&app)};
    if (!parser->positionalArguments().isEmpty()) {
        QString requestedTheme{parser->positionalArguments().first()};
        constexpr QLatin1Char dirSplit{'/'};
        if (requestedTheme.contains(dirSplit)) {
            requestedTheme = requestedTheme.split(dirSplit, Qt::SkipEmptyParts).last();
        }
        if (Lingmo::Theme().themeName() == requestedTheme) {
            ts << i18n("The requested theme \"%1\" is already set as the theme for the current Lingmo session.", requestedTheme) << Qt::endl;
            // Not an error condition really, let's just ignore that
        } else {
            bool found{false};
            QStringList availableThemes;
            model->load();
            for (int i = 0; i < model->rowCount(); ++i) {
                QString currentTheme{model->data(model->index(i), ThemesModel::PluginNameRole).toString()};
                if (currentTheme == requestedTheme) {
                    Lingmo::Theme().setThemeName(requestedTheme);
                    found = true;
                    break;
                }
                availableThemes << currentTheme;
            }
            if (found) {
                ts << i18n("The current Lingmo session's theme has been set to %1", requestedTheme) << Qt::endl;
            } else {
                ts << i18n("Could not find theme \"%1\". The theme should be one of the following options: %2",
                           requestedTheme,
                           availableThemes.join(QLatin1String{", "}))
                   << Qt::endl;
                errorCode = -1;
            }
        }
    } else if (parser->isSet(QStringLiteral("list-themes"))) {
        ts << i18n("You have the following Lingmo themes on your system:") << Qt::endl;
        model->load();
        for (int i = 0; i < model->rowCount(); ++i) {
            QString themeName{model->data(model->index(i), ThemesModel::PluginNameRole).toString()};
            if (Lingmo::Theme().themeName() == themeName) {
                ts << u" * %1 (current theme for this Lingmo session)"_s.arg(themeName) << Qt::endl;
            } else {
                ts << u" * %1"_s.arg(themeName) << Qt::endl;
            }
        }
    } else {
        parser->showHelp();
    }
    QTimer::singleShot(0, &app, [&app, &errorCode]() {
        app.exit(errorCode);
    });

    return app.exec();
}
