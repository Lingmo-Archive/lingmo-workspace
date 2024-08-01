/*
    SPDX-FileCopyrightText: 2021 Dan Leinir Turthra Jensen <admin@leinir.dk>

    SPDX-License-Identifier: LGPL-2.0-only
*/

#include "config-X11.h"

#include <KLocalizedString>

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDebug>
#include <QFileInfo>

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("lingmo-apply-wallpaperimage"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("kde.org"));
    KLocalizedString::setApplicationDomain(QByteArrayLiteral("lingmo-apply-wallpaperimage"));

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.setApplicationDescription(i18n("This tool allows you to set an image as the wallpaper for the Lingmo session."));
    parser.addPositionalArgument(QStringLiteral("imagefile"),
                                 i18n("An image file or an installed wallpaper kpackage that you wish to set as the wallpaper for your Lingmo session"));
    parser.process(app);

    int errorCode{EXIT_SUCCESS};
    QTextStream ts(stdout);
    if (!parser.positionalArguments().isEmpty()) {
        QString wallpaperFile{parser.positionalArguments().first()};
        QFileInfo wallpaperInfo{wallpaperFile};
        bool isWallpaper{false};
        bool isKPackage{false};
        if (wallpaperFile.contains(u"\'")) {
            // If this happens, we might very well assume that there is some kind of funny business going on
            // even if technically it could just be a possessive. But, security first, so...
            ts << i18n(
                "There is a stray single quote in the filename of this wallpaper (') - please contact the author of the wallpaper to fix this, or rename the "
                "file yourself: %1",
                wallpaperFile)
               << Qt::endl;
            errorCode = EXIT_FAILURE;
        } else {
            if (wallpaperInfo.exists()) {
                if (wallpaperInfo.isFile()) {
                    // then we assume it's an image file... we could check with QImage, but
                    // that makes the operation much heavier than it needs to be
                    isWallpaper = true;
                } else {
                    if (QFileInfo::exists(QStringLiteral("%1/metadata.desktop").arg(wallpaperFile))
                        || QFileInfo::exists(QStringLiteral("%1/metadata.json").arg(wallpaperFile))) {
                        isWallpaper = true;
                        isKPackage = true;
                        // Similarly to above, we could read all the information out of the kpackage, but
                        // that also is not hugely important, so we just deduce that this reasonably should
                        // be an installed kpackage
                    }
                }
            }
        }
        if (isWallpaper) {
            QString script;
            QTextStream out(&script);
            out << "for (var key in desktops()) {" //
                << "var d = desktops()[key];" //
                << "d.wallpaperPlugin = 'org.kde.image';" //
                << "d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];" //
                << u"d.writeConfig('Image', 'file://" + wallpaperFile + u"');" //
                << "}";
            auto message = QDBusMessage::createMethodCall(QStringLiteral("org.kde.lingmoshell"),
                                                          QStringLiteral("/LingmoShell"),
                                                          QStringLiteral("org.kde.LingmoShell"),
                                                          QStringLiteral("evaluateScript"));
            message.setArguments(QVariantList() << QVariant(script));
            auto reply = QDBusConnection::sessionBus().call(message);

            if (reply.type() == QDBusMessage::ErrorMessage) {
                ts << i18n("An error occurred while attempting to set the Lingmo wallpaper:\n") << reply.errorMessage() << Qt::endl;
                errorCode = EXIT_FAILURE;
            } else {
                if (isKPackage) {
                    ts << i18n("Successfully set the wallpaper for all desktops to the KPackage based %1", wallpaperFile) << Qt::endl;
                } else {
                    ts << i18n("Successfully set the wallpaper for all desktops to the image %1", wallpaperFile) << Qt::endl;
                }
            }

        } else if (errorCode == EXIT_SUCCESS) {
            // Just to avoid spitting out multiple errors
            ts << i18n("The file passed to be set as wallpaper does not exist, or we cannot identify it as a wallpaper: %1", wallpaperFile) << Qt::endl;
            errorCode = EXIT_FAILURE;
        }
    } else {
        parser.showHelp();
    }

    return errorCode;
}
