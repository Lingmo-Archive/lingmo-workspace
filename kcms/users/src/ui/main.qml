/*
    SPDX-FileCopyrightText: 2019 Nicolas Fella <nicolas.fella@gmx.de>
    SPDX-FileCopyrightText: 2020 Carson Black <uhhadd@gmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.6
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2

import org.kde.kcmutils as KCM
import org.kde.lingmoui as LingmoUI
import org.kde.lingmouiaddons.components as LingmoUIComponents
import org.kde.lingmo.kcm.users 1.0 as UsersKCM

KCM.ScrollViewKCM {
    id: root

    title: i18n("Users")

    sidebarMode: true
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: LingmoUI.Units.gridUnit * 15
    implicitHeight: LingmoUI.Units.gridUnit * 27

    actions: LingmoUI.Action {
            icon.name: "list-add-symbolic"
            text: i18nc("@action:button As in, 'add new user'", "Add New…")
            Accessible.name: i18nc("@action:button", "Add New User…")

            onTriggered: {
                kcm.pop();
                kcm.push("CreateUser.qml");
                userList.currentIndex = -1;
            }
        }

    // QML cannot update avatar image when override. By increasing this number and
    // appending it to image source with '?', we force avatar to reload
    property int avatarVersion: 0

    function createUser(userName, realName, password, isAdministrator) {
        if (kcm.createUser(userName, realName, password, isAdministrator)) {
            userList.indexToActivate = userList.count;
        }
    }
    function deleteUser(uid, deleteData) {
        if (kcm.deleteUser(uid, deleteData)) {
            userList.indexToActivate = userList.count - 1;
        }
    }

    Connections {
        target: kcm
        function onApply() {
            avatarVersion += 1
        }
    }

    Component.onCompleted: {
        kcm.columnWidth = LingmoUI.Units.gridUnit * 15
        kcm.push("UserDetailsPage.qml", { user: kcm.userModel.getLoggedInUser() })
    }

    view: ListView {
        id: userList

        property int indexToActivate: -1

        model: kcm.userModel

        onCountChanged: {
            if (indexToActivate >= 0) {
                kcm.pop();
                currentIndex = Math.min(indexToActivate, count - 1);
                const modelIndex = kcm.userModel.index(currentIndex, 0);
                const user = kcm.userModel.data(modelIndex, UsersKCM.UserModel.UserRole);
                kcm.push("UserDetailsPage.qml", { user });
                indexToActivate = -1;
            }
        }
        section {
            property: "sectionHeader"
            delegate: LingmoUI.ListSectionHeader {
                width: userList.width
                label: section
            }
        }

        delegate: LingmoUI.SubtitleDelegate {
            id: delegate

            required property var model
            required property int index

            property UsersKCM.User user: model.userObject

            width: ListView.view.width

            text: model.displayPrimaryName
            subtitle: model.displaySecondaryName

            highlighted: index === userList.currentIndex

            Accessible.description: `${delegate.ListView.section}, ${i18nc("@info:usagetip", "Press Space to edit the user profile")}`

            onClicked: {
                userList.currentIndex = index;
                kcm.pop();
                kcm.push("UserDetailsPage.qml", { user });
            }

            contentItem: RowLayout {
                spacing: LingmoUI.Units.smallSpacing

                LingmoUIComponents.Avatar {
                    source: model.decoration + '?' + avatarVersion // force reload after saving
                    cache: false // avoid caching
                    name: model.displayPrimaryName
                }

                LingmoUI.TitleSubtitle {
                    Layout.fillWidth: true
                    title: delegate.text
                    subtitle: delegate.subtitle
                    reserveSpaceForSubtitle: true
                    selected: delegate.highlighted
                }
            }
        }
    }
}
