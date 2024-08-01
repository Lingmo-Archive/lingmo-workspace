/*
    SPDX-FileCopyrightText: 2022 Dominic Hayes <ferenosdev@outlook.com>
    SPDX-FileCopyrightText: 2023 Ismael Asensio <isma.af@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-only
*/

import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtQuick.Controls 2.3 as QtControls
import org.kde.lingmoui as LingmoUI
import org.kde.private.kcms.lookandfeel 1.0 as Private

ColumnLayout {
    LingmoUI.FormLayout {
        id: layoutForm
        twinFormLayouts: root.hasAppearance ? appearanceForm : null
        visible: root.hasLayout
        Layout.leftMargin: LingmoUI.Units.largeSpacing
        Layout.rightMargin: LingmoUI.Units.largeSpacing

        ColumnLayout {
            LingmoUI.FormData.label: i18n("Layout settings:")
            Repeater {
                model: [
                    { text: i18n("Desktop layout"),
                      flag: Private.LookandFeelManager.DesktopLayout
                            | Private.LookandFeelManager.WindowPlacement
                            | Private.LookandFeelManager.ShellPackage
                    },
                    { text: i18n("Titlebar Buttons layout"), flag: Private.LookandFeelManager.TitlebarLayout },
                ]
                delegate: QtControls.CheckBox {
                    required property var modelData
                    text: modelData.text
                    visible: kcm.themeContents & modelData.flag
                    checked: kcm.selectedContents & modelData.flag
                    onToggled: {
                        kcm.selectedContents ^= modelData.flag
                        if (modelData.flag | Private.LookandFeelManager.DesktopLayout) {
                            resetLayoutWarning.visible = checked;
                        }
                    }
                }
            }
        }
    }

    LingmoUI.InlineMessage {
        id: resetLayoutWarning
        Layout.fillWidth: true
        visible: false
        type: LingmoUI.MessageType.Warning
        text: i18n("Applying a Desktop layout will delete the current set of desktops, panels, docks, and widgets, replacing them with what the theme specifies.")
    }

    LingmoUI.FormLayout {
        id: appearanceForm
        twinFormLayouts: root.hasLayout ? layoutForm : null
        visible: root.hasAppearance
        Layout.leftMargin: LingmoUI.Units.largeSpacing
        Layout.rightMargin: LingmoUI.Units.largeSpacing

        ColumnLayout {
            LingmoUI.FormData.label: i18n("Appearance settings:")
            Repeater {
                model: [
                    { text: i18n("Colors"), flag: Private.LookandFeelManager.Colors },
                    { text: i18n("Application Style"), flag: Private.LookandFeelManager.WidgetStyle },
                    { text: i18n("Window Decoration Style"), flag: Private.LookandFeelManager.WindowDecoration },
                    { text: i18n("Window Decoration Size"), flag: Private.LookandFeelManager.BorderSize },
                    { text: i18n("Icons"), flag: Private.LookandFeelManager.Icons },
                    { text: i18n("Lingmo Style"), flag: Private.LookandFeelManager.LingmoTheme },
                    { text: i18n("Cursors"), flag: Private.LookandFeelManager.Cursors },
                    { text: i18n("Fonts"), flag: Private.LookandFeelManager.Fonts },
                    { text: i18n("Task Switcher"), flag: Private.LookandFeelManager.WindowSwitcher },
                    { text: i18n("Splash Screen"), flag: Private.LookandFeelManager.SplashScreen },
                ]
                delegate: QtControls.CheckBox {
                    required property var modelData
                    text: modelData.text
                    visible: kcm.themeContents & modelData.flag
                    checked: kcm.selectedContents & modelData.flag
                    onToggled: kcm.selectedContents ^= modelData.flag
                }
            }
        }
    }
}
