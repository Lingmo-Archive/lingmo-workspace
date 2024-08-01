/*
    SPDX-FileCopyrightText: 2020 Devin Lin <espidev@gmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/
pragma ComponentBehavior: Bound

import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtQuick.Shapes 1.12
import QtQuick.Controls 2.5 as QQC2

import org.kde.lingmoui as LingmoUI

LingmoUI.Dialog {
    id: root

    property var fingerprintModel: kcm.fingerprintModel
    property string currentFinger

    enum DialogState {
        FingerprintList,
        PickFinger,
        Enrolling,
        EnrollComplete
    }

    title: i18n("Configure Fingerprints")

    visible: true

    implicitWidth: LingmoUI.Units.gridUnit * 20
    implicitHeight: LingmoUI.Units.gridUnit * 18

    standardButtons: QQC2.Dialog.NoButton

    customFooterActions: [
        // FingerprintList State
        LingmoUI.Action {
            text: i18n("Add")
            visible: root.fingerprintModel.dialogState === FingerprintDialog.DialogState.FingerprintList
            enabled: root.fingerprintModel.availableFingersToEnroll.length !== 0
            icon.name: "list-add"
            onTriggered: {
                root.fingerprintModel.dialogState = FingerprintDialog.DialogState.PickFinger;
                stack.push(pickFinger);
            }
        },

        // Enrolling State
        LingmoUI.Action {
            text: i18n("Cancel")
            visible: root.fingerprintModel.dialogState === FingerprintDialog.DialogState.Enrolling
            icon.name: "dialog-cancel"
            onTriggered: root.fingerprintModel.stopEnrolling()
        },

        // EnrollComplete State
        LingmoUI.Action {
            text: i18n("Done")
            visible: root.fingerprintModel.dialogState === FingerprintDialog.DialogState.EnrollComplete
            icon.name: "dialog-ok"
            onTriggered: root.fingerprintModel.stopEnrolling()
        }
    ]

    ColumnLayout {
        anchors.fill: parent

        LingmoUI.InlineMessage {
            type: LingmoUI.MessageType.Error
            visible: root.fingerprintModel.currentError !== ""
            text: root.fingerprintModel.currentError
            Layout.fillWidth: true
            actions: [
                LingmoUI.Action {
                    icon.name: "dialog-close"
                    onTriggered: root.fingerprintModel.currentError = ""
                }
            ]
        }

        QQC2.StackView {
            id: stack

            Layout.fillWidth: true
            Layout.fillHeight: true

            initialItem: fingerPrints
        }
    }

    Connections {
        target: root.fingerprintModel

        function onDialogStateChanged() {
            if (root.fingerprintModel.dialogState == FingerprintDialog.FingerprintList) {
                stack.clear();
                stack.push(fingerPrints);
            }
            if (root.fingerprintModel.dialogState == FingerprintDialog.Enrolling) {
                stack.push(enrolling);
            }
        }
    }

    Component {
        id: enrolling

        EnrollFeedback {
            done: root.fingerprintModel.dialogState === FingerprintDialog.DialogState.EnrollComplete
            enrollFeedback: root.fingerprintModel.enrollFeedback
            scanType: root.fingerprintModel.scanType
            finger: root.currentFinger
        }
    }

    Component {
        id: pickFinger

        PickFinger {
            availableFingers: root.fingerprintModel.availableFingersToEnroll
            unavailableFingers: root.fingerprintModel.unavailableFingersToEnroll

            onFingerPicked: finger => {
                root.currentFinger = finger;
                root.fingerprintModel.startEnrolling(finger);
            }
        }
    }

    Component {
        id: fingerPrints

        FingerprintList {
            model: root.fingerprintModel.enrolledFingerprints

            onReenrollFinger: finger => {
                root.currentFinger = finger;
                root.fingerprintModel.startEnrolling(finger);
            }

            onDeleteFinger: finger => {
                root.fingerprintModel.deleteFingerprint(finger);
            }
        }
    }
}
