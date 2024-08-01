/*
    SPDX-FileCopyrightText: 2021 Bharadwaj Raju <bharadwaj.raju777@protonmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2 // For StackView
import QtQuick.Layouts 1.1
import org.kde.lingmo.components 3.0 as LingmoComponents3
import org.kde.lingmoui 2.20 as LingmoUI
import org.kde.kquickcontrolsaddons 2.0

ColumnLayout {
    spacing: 0
    property alias text: textArea.text
    property string uuid

    property var header: Item {}

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            stack.pop()
            event.accepted = true;
        }
    }

    function saveAndExit() {
        clipboardSource.edit(uuid, text);
        stack.pop();
        done();
    }

    function done() {
        // The modified item will be pushed to the top, and we would like to highlight the real first item
        Qt.callLater(() => {stack.initialItem.view.currentIndex = 0;});
    }

    QQC2.StackView.onStatusChanged: {
        if (QQC2.StackView.status === QQC2.StackView.Active) {
            textArea.forceActiveFocus(Qt.ActiveWindowFocusReason);
            textArea.cursorPosition = textArea.text.length;
            main.editing = true;
        } else {
            main.editing = false;
        }
    }

    Shortcut {
        sequence: StandardKey.Save
        onActivated: saveAndExit()
    }

    LingmoComponents3.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: LingmoUI.Units.smallSpacing * 2
        Layout.rightMargin: LingmoComponents3.ScrollBar.vertical.visible ? 0 : LingmoUI.Units.smallSpacing * 2
        Layout.topMargin: LingmoUI.Units.smallSpacing * 2

        LingmoComponents3.TextArea {
            id: textArea
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText

            KeyNavigation.up: dialogItem.KeyNavigation.up
            Keys.onPressed: event => {
                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                    saveAndExit();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignRight
        Layout.margins: LingmoUI.Units.smallSpacing * 2
        LingmoComponents3.Button {
            text: i18nc("@action:button", "Save")
            icon.name: "document-save"
            KeyNavigation.up: textArea
            KeyNavigation.right: cancelButton
            onClicked: saveAndExit()
        }
        LingmoComponents3.Button {
            id: cancelButton
            text: i18nc("@action:button", "Cancel")
            icon.name: "dialog-cancel"
            KeyNavigation.up: textArea
            onClicked: stack.pop()
        }
    }
}
