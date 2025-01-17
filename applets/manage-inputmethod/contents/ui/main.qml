/*
 *    SPDX-FileCopyrightText: 2021 Aleix Pol Gonzalez <aleixpol@kde.org>
 *
 *    SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.1
import QtQuick.Layouts 1.1

import org.kde.lingmo.plasmoid 2.0
import org.kde.lingmo.core as LingmoCore
import org.kde.lingmo.workspace.keyboardlayout 1.0 as Keyboards
import org.kde.kcmutils // KCMLauncher
import org.kde.lingmoui 2.20 as LingmoUI

PlasmoidItem {
    id: root

    Plasmoid.onActivated: {
        if (!Keyboards.KWinVirtualKeyboard.available) {
            settingsAction.trigger()
        } else if (unsupportedState.when) {
            Keyboards.KWinVirtualKeyboard.forceActivate()
        } else if (Keyboards.KWinVirtualKeyboard.visible) {
            Keyboards.KWinVirtualKeyboard.active = false
        } else {
            Keyboards.KWinVirtualKeyboard.enabled = !Keyboards.KWinVirtualKeyboard.enabled
        }
    }
    preferredRepresentation: fullRepresentation
    fullRepresentation: LingmoUI.Icon {
        activeFocusOnTab: true
        source: Plasmoid.icon
        active: compactMouse.containsMouse

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Space:
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Select:
                Plasmoid.activated();
                break;
            }
        }
        Accessible.name: Plasmoid.title
        Accessible.description: toolTipSubText
        Accessible.role: Accessible.Button

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Plasmoid.activated()
        }
        LingmoUI.Icon {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            width: LingmoUI.Units.iconSizes.small / 2
            height: width
            visible: root.state === "unavailable"
            source: visible ? "emblem-unavailable" : ""
        }
    }

    LingmoCore.Action {
        id: settingsAction
        text: i18ndc("lingmo_applet_org.kde.lingmo.manageinputmethod", "Opens the system settings module", "Configure Virtual Keyboards...")
        icon.name: "settings-configure"
        onTriggered: KCMLauncher.openSystemSettings("kcm_virtualkeyboard")
    }
    Component.onCompleted: {
        Plasmoid.setInternalAction("configure", settingsAction)
    }

    states: [
        State {
            name: "unavailable"
            when: !Keyboards.KWinVirtualKeyboard.available
            PropertyChanges {
                target: Plasmoid
                icon: "input-keyboard-virtual-off"
                status: LingmoCore.Types.HiddenStatus
            }
            PropertyChanges {
                target: root
                toolTipSubText: i18nd("lingmo_applet_org.kde.lingmo.manageinputmethod", "Virtual Keyboard: unavailable")
            }
        },
        State {
            name: "disabled"
            when: Keyboards.KWinVirtualKeyboard.available && !Keyboards.KWinVirtualKeyboard.enabled
            PropertyChanges {
                target: Plasmoid
                icon: "input-keyboard-virtual-off"
                status: LingmoCore.Types.ActiveStatus
            }
            PropertyChanges {
                target: root
                toolTipSubText: i18nd("lingmo_applet_org.kde.lingmo.manageinputmethod", "Virtual Keyboard: disabled")
            }
        },
        State {
            id: unsupportedState
            name: "unsupported"
            when: Keyboards.KWinVirtualKeyboard.available && !Keyboards.KWinVirtualKeyboard.activeClientSupportsTextInput
            // When the current client doesn't support input methods, we can force
            // the display of the virtual keyboard so it emulates a hardware keyboard instead
            PropertyChanges {
                target: Plasmoid
                icon: "arrow-up"
                status: LingmoUI.Settings.tabletMode ? LingmoCore.Types.ActiveStatus : LingmoCore.Types.PassiveStatus
            }
            PropertyChanges {
                target: root
                toolTipSubText: i18nd("lingmo_applet_org.kde.lingmo.manageinputmethod", "Show Virtual Keyboard")
            }
        },
        State {
            name: "visible"
            when: Keyboards.KWinVirtualKeyboard.available && Keyboards.KWinVirtualKeyboard.visible
            PropertyChanges {
                target: Plasmoid
                icon: "arrow-down"
                // Because the keyboard can become visible with a touch input when
                // while not explicitly in Touch Mode
                status: LingmoUI.Settings.hasTransientTouchInput ? LingmoCore.Types.ActiveStatus : LingmoCore.Types.PassiveStatus
            }
            PropertyChanges {
                target: root
                toolTipSubText: i18nd("lingmo_applet_org.kde.lingmo.manageinputmethod", "Virtual Keyboard: visible")
            }
        },
        State {
            name: "idle"
            when: Keyboards.KWinVirtualKeyboard.available && Keyboards.KWinVirtualKeyboard.enabled && !Keyboards.KWinVirtualKeyboard.visible
            PropertyChanges {
                target: Plasmoid
                icon: "input-keyboard-virtual-on"
                // It's only relevant in tablet mode
                status: LingmoUI.Settings.tabletMode ? LingmoCore.Types.ActiveStatus : LingmoCore.Types.PassiveStatus
            }
            PropertyChanges {
                target: root
                toolTipSubText: i18nd("lingmo_applet_org.kde.lingmo.manageinputmethod", "Virtual Keyboard: enabled")
            }
        }
    ]
}
