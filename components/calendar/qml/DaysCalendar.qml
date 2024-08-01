/*
    SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015, 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.lingmoui as LingmoUI
import org.kde.lingmo.components as LingmoComponents
import org.kde.lingmo.workspace.calendar as LingmoCalendar

Item {
    id: daysCalendar

    signal activated(int index, var date, var item)

    property int rows
    property int columns

    property bool showWeekNumbers

    // Only relevand for days in a MonthView
    property LingmoCalendar.Calendar backend

    required property /*LingmoCalendar.Calendar.DateMatchingPrecision*/int dateMatchingPrecision

    required property int borderWidth

    readonly property alias repeater: gridRepeater

    // 7 for days view, null for other views
    property alias /*int?*/ dayOfWeekHeaderModel: dayOfWeekHeaderRepeater.model

    // type: either LingmoCalendar.DaysModel or an equivalent ListModel
    property alias gridModel: gridRepeater.model

    // Take the calendar width, subtract the inner and outer spacings and divide by number of columns (==days in week)
    readonly property int cellWidth: Math.floor((swipeView.width - (columns + 1) * borderWidth) / (columns + (showWeekNumbers ? 1 : 0)))
    // Take the calendar height, subtract the inner spacings and divide by number of rows (root.weeks + one row for day names)
    readonly property int cellHeight: Math.floor((swipeView.height - viewHeader.heading.height - calendarGrid.rows * borderWidth) / calendarGrid.rows)

    Column {
        visible: daysCalendar.showWeekNumbers
        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
            // The borderWidth needs to be counted twice here because it goes
            // in fact through two lines - the topmost one (the outer edge)
            // and then the one below weekday strings
            topMargin: daysCalendar.cellHeight + daysCalendar.borderWidth + daysCalendar.borderWidth
        }
        spacing: daysCalendar.borderWidth

        Repeater {
            model: {
                if (daysCalendar.showWeekNumbers) {
                    if (daysCalendar.backend) {
                        return daysCalendar.backend.weeksModel;
                    }
                }
                return null;
            }

            LingmoComponents.Label {
                required property int modelData

                height: daysCalendar.cellHeight
                width: daysCalendar.cellWidth
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.4
                text: modelData
                textFormat: Text.PlainText
                font.pixelSize: Math.max(LingmoUI.Theme.smallFont.pixelSize, daysCalendar.cellHeight / 3)
            }
        }
    }

    Grid {
        id: calendarGrid

        anchors {
            top: parent.top
            right: parent.right
            rightMargin: daysCalendar.borderWidth
            bottom: parent.bottom
            bottomMargin: daysCalendar.borderWidth
        }

        columns: daysCalendar.columns
        rows: daysCalendar.rows + (daysCalendar.dayOfWeekHeaderModel !== undefined ? 1 : 0)

        spacing: daysCalendar.borderWidth
        columnSpacing: daysCalendar.borderWidth

        Repeater {
            id: dayOfWeekHeaderRepeater

            LingmoComponents.Label {
                required property int index

                width: daysCalendar.cellWidth
                height: daysCalendar.cellHeight
                text: Qt.locale(Qt.locale().uiLanguages[0]).dayName(((daysCalendar.backend.firstDayOfWeek + index) % dayOfWeekHeaderRepeater.count), Locale.ShortFormat)
                textFormat: Text.PlainText
                font.pixelSize: Math.max(LingmoUI.Theme.smallFont.pixelSize, daysCalendar.cellHeight / 3)
                opacity: 0.4
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
            }
        }

        Repeater {
            id: gridRepeater

            DayDelegate {
                // required properties are declared in the base component

                width: daysCalendar.cellWidth
                height: daysCalendar.cellHeight
                dayModel: gridRepeater.model
                dateMatchingPrecision: daysCalendar.dateMatchingPrecision

                Keys.onPressed: event => {
                    if (!daysCalendar.LingmoComponents.SwipeView.isCurrentItem) {
                        event.accepted = false;
                        return;
                    }
                    switch (event.key) {
                    case Qt.Key_Space:
                    case Qt.Key_Enter:
                    case Qt.Key_Return:
                    case Qt.Key_Select:
                        daysCalendar.activated(index, model, this);
                        break;
                    }
                }

                KeyNavigation.left: if (index !== 0) {
                    return gridRepeater.itemAt(index - 1);
                } else {
                    return daysCalendar.KeyNavigation.left;
                }
                KeyNavigation.tab: daysCalendar.KeyNavigation.tab

                Keys.onUpPressed: event => {
                    if (index >= daysCalendar.columns) {
                        gridRepeater.itemAt(index - daysCalendar.columns).forceActiveFocus(Qt.TabFocusReason);
                    } else {
                        event.accepted = false;
                    }
                }
                Keys.onDownPressed: event => {
                    if (index < (daysCalendar.rows - 1) * daysCalendar.columns) {
                        gridRepeater.itemAt(index + daysCalendar.columns).forceActiveFocus(Qt.TabFocusReason);
                    }
                }

                onClicked: {
                    daysCalendar.activated(index, model, this)
                }
            }
        }
    }
}
