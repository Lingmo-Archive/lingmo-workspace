/*
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.9
import QtQuick.Layouts 1.1
import org.kde.lingmoui 2.7 as LingmoUI

LingmoUI.Page {
    id: positionPage

    title: i18n("Popup Position")

    ScreenPositionSelector {
        anchors.horizontalCenter: parent.horizontalCenter
        selectedPosition: kcm.notificationSettings.popupPosition
        onSelectedPositionChanged: kcm.notificationSettings.popupPosition = selectedPosition
    }
}
