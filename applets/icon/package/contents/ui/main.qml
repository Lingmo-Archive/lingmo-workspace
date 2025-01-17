/*
    SPDX-FileCopyrightText: 2013 Bhushan Shah <bhush94@gmail.com>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>
    SPDX-FileCopyrightText: 2023 Mike Noe <noeerover@gmail.com>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick

import org.kde.draganddrop 2.0 as DragDrop
import org.kde.lingmo.core as LingmoCore
import org.kde.lingmo.extras as LingmoExtras
import org.kde.lingmo.plasmoid 2.0
import org.kde.lingmoui 2.20 as LingmoUI

PlasmoidItem {
    id: root

    readonly property bool constrained: [LingmoCore.Types.Vertical, LingmoCore.Types.Horizontal]
        .includes(Plasmoid.formFactor)
    property bool containsAcceptableDrag: false

    preferredRepresentation: fullRepresentation

    enabled: Plasmoid.valid

    Plasmoid.icon: Plasmoid.iconName
    Plasmoid.title: Plasmoid.name

    Plasmoid.backgroundHints: LingmoCore.Types.NoBackground

    Plasmoid.onActivated: Plasmoid.run()

    Plasmoid.contextualActions: Plasmoid.extraActions

    LingmoCore.Action {
        id: configureAction
        text: i18n("Properties")
        icon.name: "document-properties"
        visible: Plasmoid.valid && Plasmoid.immutability !== LingmoCore.Types.SystemImmutable
        onTriggered: Plasmoid.configure()
    }
    
    Component.onCompleted: {
        Plasmoid.setInternalAction("configure", configureAction);
    }

    onExternalData: (mimetype, data) => {
        root.Plasmoid.url = data;
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        activeFocusOnTab: true
        
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Space:
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Select:
                Plasmoid.run()
                break;
            }
        }
        
        Accessible.name: Plasmoid.title
        Accessible.description: toolTip.subText
        Accessible.role: Accessible.Button

        hoverEnabled: true
        enabled: Plasmoid.valid

        onClicked: Plasmoid.run()

        DragDrop.DropArea {
            anchors.fill: parent
            preventStealing: true
            
            onDragEnter: event => {
                const acceptable = Plasmoid.isAcceptableDrag(event);
                containsAcceptableDrag = acceptable;

                if (!acceptable) {
                    event.ignore();
                }
            }
            
            onDragLeave: containsAcceptableDrag = false
            
            onDrop: event => {
                if (containsAcceptableDrag) {
                    Plasmoid.processDrop(event);
                } else {
                    event.ignore();
                }

                containsAcceptableDrag = false;
            }
        }

        LingmoUI.Icon {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: constrained ? parent.bottom : iconLabel.top
            }
            source: Plasmoid.icon
            enabled: mouseArea.enabled
            active: mouseArea.containsMouse || containsAcceptableDrag
            opacity: Plasmoid.busy ? 0.6 : 1
            
            Behavior on opacity {
                OpacityAnimator {
                    duration: LingmoUI.Units.shortDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        LingmoExtras.ShadowedLabel {
            id: iconLabel

            anchors {
                left: parent.left
                bottom: parent.bottom
                right: parent.right
            }

            text: Plasmoid.title
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2

            visible: !root.constrained
        }

        LingmoCore.ToolTipArea {
            id: toolTip
            anchors.fill: parent
            mainText: Plasmoid.title
            subText: Plasmoid.genericName !== mainText ? Plasmoid.genericName : ""
            textFormat: Text.PlainText
        }
    }
}
