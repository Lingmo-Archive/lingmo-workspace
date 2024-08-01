/*
 *  SPDX-FileCopyrightText: 2021 Devin Lin <espidev@gmail.com>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.lingmoui as LingmoUI
import org.kde.lingmouiaddons.components as LingmoUIComponents
import org.kde.lingmo.workspace.dialogs as PWD

LingmoUI.AbstractApplicationWindow {
    id: root

    width: 600
    height: 600

    PWD.SystemDialog {
        id: simple
        mainText: "Reset Data"
        subtitle: "This will reset all of your data."
        iconName: "documentinfo"

        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
    }

    PWD.SystemDialog {
        id: simpleList
        mainText: "Reset Data"
        subtitle: "This will reset all of your data."
        iconName: "documentinfo"

        ListView {
            Layout.fillWidth: true
            implicitHeight: 100

            model: ListModel {
                ListElement {
                    display: "banana"
                }
                ListElement {
                    display: "banana1"
                }
                ListElement {
                    display: "banana2"
                }
                ListElement {
                    display: "banana3"
                }
            }
            delegate: QQC2.ItemDelegate {
                icon.name: "kate"
                text: display
                checkable: true
                width: ListView.view.width
            }
        }

        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
    }

    PWD.SystemDialog {
        id: desktopPolkit
        mainText: "Authentication Required"
        subtitle: "Authentication is needed to run `/usr/bin/ls` as the super user."
        iconName: "im-user-online"

        LingmoUI.PasswordField {}

        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
        actions: [
            QQC2.Action {
                text: "Details"
                icon.name: "documentinfo"
                onTriggered: desktopPolkit.close()
            }
        ]
    }

    PWD.SystemDialog {
        id: xdgDialog
        mainText: "Wallet access"
        subtitle: "Share your wallet with 'Somebody'."
        iconName: "kwallet"
        acceptable: false

        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
        Component.onCompleted: {
            dialogButtonBox.standardButton(QQC2.DialogButtonBox.Ok).text = "Share"
        }
        actions: [
            QQC2.Action {
                text: "Something Happens"
                icon.name: "documentinfo"
                onTriggered: xdgDialog.acceptable = true
            }
        ]
    }

    PWD.SystemDialog {
        id: appchooser
        title: "Open with..."
        iconName: "applications-all"
        ColumnLayout {
            Text {
                text: "height: " + parent.height + " / " + xdgDialog.height
            }

            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 3

                text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris at viverra mi. Maecenas volutpat et nisi ac scelerisque. Mauris pulvinar blandit dapibus. Nulla facilisi. Donec congue imperdiet maximus. Aliquam gravida velit sed mattis convallis. Nam id nisi egestas nibh ultrices varius quis at sapien."
                wrapMode: Text.WordWrap

                onLinkActivated: {
                    AppChooserData.openDiscover()
                }
            }

            QQC2.Frame {
                id: viewBackground
                Layout.fillWidth: true
                Layout.fillHeight: true
                LingmoUI.Theme.inherit: false
                LingmoUI.Theme.colorSet: LingmoUI.Theme.View
                background: Rectangle {
                    color: LingmoUI.Theme.backgroundColor
                    border.color: Qt.alpha(LingmoUI.Theme.textColor, 0.3)
                }

                QQC2.ScrollView {
                    anchors.fill: parent
                    implicitHeight: grid.cellHeight * 3

                    GridView {
                        id: grid

                        cellHeight: LingmoUI.Units.iconSizes.huge + 50
                        cellWidth: LingmoUI.Units.iconSizes.huge + 80

                        model: ListModel {
                            ListElement {
                                display: "banana"
                            }
                            ListElement {
                                display: "banana1"
                            }
                            ListElement {
                                display: "banana2"
                            }
                            ListElement {
                                display: "banana3"
                            }
                        }
                        delegate: Rectangle {
                            color: "blue"
                            height: grid.cellHeight
                            width: grid.cellWidth

                            LingmoUI.Icon {
                                source: "kalgebra"
                            }
                        }
                    }
                }
            }

            QQC2.Button {
                id: showAllAppsButton
                Layout.alignment: Qt.AlignHCenter
                icon.name: "view-more-symbolic"
                text: "Show More"

                onClicked: {
                    visible = false
                }
            }

            LingmoUI.SearchField {
                id: searchField
                Layout.fillWidth: true
                visible: !showAllAppsButton.visible
                opacity: visible
            }
        }
    }

    PWD.SystemDialog {
        id: mobilePolkit
        mainText: "Authentication Required"
        subtitle: "Authentication is needed to run `/usr/bin/ls` as the super user."

        ColumnLayout {
            width: LingmoUI.Units.gridUnit * 20

            LingmoUIComponents.Avatar {
                implicitHeight: LingmoUI.Units.iconSizes.medium
                implicitWidth: LingmoUI.Units.iconSizes.medium
                Layout.alignment: Qt.AlignHCenter
            }
            LingmoUI.PasswordField {
                Layout.fillWidth: true
            }
        }

        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
        actions: [
            QQC2.Action {
                text: "Details"
                icon.name: "documentinfo"
                onTriggered: mobilePolkit.close()
            }
        ]
    }

    PWD.SystemDialog {
        id: sim
        mainText: "SIM Locked"
        subtitle: "Please enter your SIM PIN in order to unlock it."

        width: LingmoUI.Units.gridUnit * 20
        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel

        LingmoUI.PasswordField {
            Layout.fillWidth: true
        }
    }

    PWD.SystemDialog {
        id: device
        mainText: "Device Request"
        subtitle: "Allow <b>PureMaps</b> to access your location?"

        layout: Qt.Vertical

        actions: [
            QQC2.Action {
                text: "Allow all the time"
                onTriggered: device.accept()
            },
            QQC2.Action {
                text: "Allow only while the app is in use"
                onTriggered: device.accept()
            },
            QQC2.Action {
                text: "Deny"
                onTriggered: device.accept()
            }
        ]
    }

    PWD.SystemDialog {
        id: wifi
        mainText: "eduroam"

        LingmoUI.FormLayout {
            QQC2.ComboBox {
                model: ["PEAP"]
                Layout.fillWidth: true
                LingmoUI.FormData.label: "EAP method:"
                currentIndex: 0
            }
            QQC2.ComboBox {
                model: ["MSCHAPV2"]
                Layout.fillWidth: true
                LingmoUI.FormData.label: "Phase 2 authentication:"
                currentIndex: 0
            }
            QQC2.TextField {
                LingmoUI.FormData.label: "Domain:"
                Layout.fillWidth: true
                text: ""
            }
            QQC2.TextField {
                LingmoUI.FormData.label: "Identity:"
                Layout.fillWidth: true
            }
            QQC2.TextField {
                LingmoUI.FormData.label: "Username:"
                Layout.fillWidth: true
            }
            LingmoUI.PasswordField {
                LingmoUI.FormData.label: "Password:"
                Layout.fillWidth: true
            }
        }

        standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
        Component.onCompleted: {
            dialogButtonBox.standardButton(QQC2.DialogButtonBox.Ok).text = "Save"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        QQC2.Button {
            text: "Simple dialog (Desktop)"
            onClicked: {
                simple.present()
            }
        }
        QQC2.Button {
            text: "Simple List"
            onClicked: {
                simpleList.present()
            }
        }
        QQC2.Button {
            text: "Polkit dialog (Desktop)"
            onClicked: {
                desktopPolkit.present()
            }
        }
        QQC2.Button {
            text: "App Chooser(-ish)"
            onClicked: {
                appchooser.present()
            }
        }
        QQC2.Button {
            text: "XDG dialog (Desktop)"
            onClicked: {
                xdgDialog.present()
            }
        }
        QQC2.Button {
            text: "Polkit dialog (Mobile)"
            onClicked: {
                mobilePolkit.present()
            }
        }
        QQC2.Button {
            text: "SIM PIN dialog (Mobile)"
            onClicked: {
                sim.present()
            }
        }
        QQC2.Button {
            text: "Device request dialog (Mobile)"
            onClicked: {
                device.present()
            }
        }
        QQC2.Button {
            text: "Wifi Dialog (Mobile)"
            onClicked: {
                wifi.present()
            }
        }
    }
}
