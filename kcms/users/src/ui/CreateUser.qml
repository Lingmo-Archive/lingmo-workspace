/*
    SPDX-FileCopyrightText: 2020 Carson Black <uhhadd@gmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2

import org.kde.kcmutils as KCM
import org.kde.lingmoui 2.20 as LingmoUI

KCM.SimpleKCM {
    title: i18n("Create User")

    onVisibleChanged: {
        realNameField.text = "";
        userNameField.text = "";
        passwordField.text = "";
        verifyField.text = "";
        usertypeBox.currentIndex = 0;
    }
    Component.onCompleted: realNameField.forceActiveFocus()

    LingmoUI.FormLayout {
        anchors.centerIn: parent
        QQC2.TextField {
            id: realNameField
            LingmoUI.FormData.label: i18n("Name:")
        }
        QQC2.TextField {
            id: userNameField
            LingmoUI.FormData.label: i18n("Username:")
            validator: RegularExpressionValidator {
                regularExpression: /^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$/
            }
        }
        QQC2.ComboBox {
            id: usertypeBox

            textRole: "label"
            model: [
                { type: "standard", label: i18n("Standard") },
                { type: "administrator", label: i18n("Administrator") },
            ]

            LingmoUI.FormData.label: i18n("Account type:")
        }
        LingmoUI.PasswordField {
            id: passwordField
            onTextChanged: debouncer.reset()
            LingmoUI.FormData.label: i18n("Password:")
        }
        LingmoUI.PasswordField {
            id: verifyField
            onTextChanged: debouncer.reset()
            LingmoUI.FormData.label: i18n("Confirm password:")
        }
        LingmoUI.InlineMessage {
            id: passwordWarning

            Layout.fillWidth: true
            type: LingmoUI.MessageType.Error
            text: i18n("Passwords must match")
            visible: passwordField.text !== ""
                && verifyField.text !== ""
                && passwordField.text !== verifyField.text
                && debouncer.isTriggered
        }
        Debouncer {
            id: debouncer
        }
        QQC2.Button {
            text: i18n("Create")
            enabled: !passwordWarning.visible
                && realNameField.text !== ""
                && userNameField.text !== ""
                && passwordField.text !== ""
                && verifyField.text !== ""

            onClicked: {
                if (passwordField.text !== verifyField.text) {
                    debouncer.isTriggered = true;
                    return;
                }
                kcm.mainUi.createUser(userNameField.text, realNameField.text, passwordField.text, (usertypeBox.model[usertypeBox.currentIndex]["type"] === "administrator"));
            }
        }
    }
}
