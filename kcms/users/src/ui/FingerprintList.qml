/*
    SPDX-FileCopyrightText: 2020 Devin Lin <espidev@gmail.com>
    SPDX-FileCopyrightText: 2024 Nicolas Fella <nicolas.fella@gmx.de>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

pragma ComponentBehavior: Bound

import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2

import org.kde.lingmoui 2.12 as LingmoUI

ListView {
    id: root

    signal deleteFinger(string name)
    signal reenrollFinger(string name)

    delegate: QQC2.ItemDelegate {
        id: delegate

        required property string internalName
        required property string friendlyName

        text: friendlyName
        width: ListView.view.width
        hoverEnabled: false
        down: false
        highlighted: false

        contentItem: RowLayout {

            spacing: LingmoUI.Units.mediumSpacing

            QQC2.Label {
                text: delegate.text

                Layout.fillWidth: true
            }

            QQC2.ToolButton {
                icon.name: "edit-entry"
                text: i18n("Re-enroll finger")
                display: QQC2.Button.IconOnly

                QQC2.ToolTip.delay: LingmoUI.Units.toolTipDelay
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered || activeFocus

                onClicked: root.reenrollFinger(delegate.internalName)
            }

            QQC2.ToolButton {
                icon.name: "edit-delete"
                text: i18n("Delete fingerprint")
                display: QQC2.Button.IconOnly

                QQC2.ToolTip.delay: LingmoUI.Units.toolTipDelay
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered || activeFocus

                onClicked: root.deleteFinger(delegate.internalName)
            }
        }
    }

    LingmoUI.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (LingmoUI.Units.largeSpacing * 4)
        visible: root.count === 0
        text: i18n("No fingerprints added")
        icon.name: "fingerprint"
    }
}
