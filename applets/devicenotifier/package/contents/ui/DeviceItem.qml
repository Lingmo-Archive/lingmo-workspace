/*
    SPDX-FileCopyrightText: 2011 Viranch Mehta <viranch.mehta@gmail.com>
    SPDX-FileCopyrightText: 2012 Jacopo De Simoi <wilderkde@gmail.com>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>
    SPDX-FileCopyrightText: 2022 Harald Sitter <sitter@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQml.Models

import org.kde.lingmo.plasmoid
import org.kde.lingmo.extras as LingmoExtras
import org.kde.lingmo.components as LingmoComponents3
import org.kde.lingmoui as LingmoUI

import org.kde.kquickcontrolsaddons

import org.kde.lingmo.private.devicenotifier as DN

LingmoExtras.ExpandableListItem {
    id: deviceItem

    required property int index

    required property string deviceDescription
    required property string deviceIcon
    required property double deviceFreeSpace
    required property double deviceSize
    required property string deviceFreeSpaceText
    required property string deviceSizeText
    required property bool deviceMounted
    required property int deviceOperationResult
    required property int deviceError
    required property string deviceErrorMessage
    required property var deviceActions
    required property var deviceEmblems

    property bool hasMessage: deviceErrorMessage !== ""

    onDeviceOperationResultChanged: {
        if (!popupIconTimer.running) {
            if (deviceItem.deviceOperationResult === DN.DevicesStateMonitor.Working) {
                if(deviceMounted){
                    unmountTimer.restart();
                }
            } else if (deviceItem.deviceOperationResult === DN.DevicesStateMonitor.Successful) {
                devicenotifier.popupIcon = "dialog-ok"
                popupIconTimer.restart()
            } else if (deviceItem.deviceOperationResult === DN.DevicesStateMonitor.Unsuccessful) {
                devicenotifier.popupIcon = "dialog-error"
                popupIconTimer.restart()
            }
        }
    }

    onHasMessageChanged: {
        if (deviceItem.hasMessage) {
            messageHighlight.highlight(this)
        }
    }

    // this keeps the delegate around for 5 seconds after the device has been
    // removed in case there was a message, such as "you can now safely remove this"
    ListView.onRemove: removeAnimation.start()


    SequentialAnimation {
        id: removeAnimation
        running: false
        PropertyAction { target: deviceItem; property: "ListView.delayRemove"; value: deviceItem.hasMessage }
        PropertyAction { target: deviceItem; property: "enabled"; value: false }
        // Reset action model to hide the arrow
        PropertyAction { target: deviceItem; property: "customExpandedViewContent"; value: []}
        PropertyAction { target: deviceItem; property: "defaultActionButtonAction"; value: null}
        PropertyAction { target: deviceItem; property: "icon"; value: deviceItem.deviceIcon || "device-notifier" }
        PropertyAction { target: deviceItem; property: "subtitle"; value: deviceItem.deviceErrorMessage }
        PauseAnimation { duration: messageHighlightAnimator.duration }
        // Otherwise there are briefly multiple highlight effects
        PropertyAction { target: devicenotifier; property: "currentIndex"; value: -1 }
        PropertyAction { target: deviceItem; property: "ListView.delayRemove"; value: false }
    }


    Timer {
        id: unmountTimer
        interval: 1000
        repeat: false
    }

    icon: deviceItem.deviceIcon

    iconEmblem: {
        if (deviceItem.hasMessage) {
            if (filterModel.deviceError === 0) {
                return "emblem-information"
            } else {
                return "emblem-error"
            }
        } else if (deviceItem.deviceOperationResult !== DN.DevicesStateMonitor.Working && deviceItem.deviceEmblems[0]) {
            return deviceItem.deviceEmblems[0]
        } else {
            return ""
        }
    }

    title: deviceItem.deviceDescription

    subtitle: {
        if (deviceItem.hasMessage) {
            return filterModel.lastErrorMessage
        }
        if (deviceItem.deviceOperationResult !== DN.DevicesStateMonitor.Working) {
            if (deviceItem.deviceFreeSpace > 0 && deviceItem.deviceSize > 0) {
                return i18nc("@info:status Free disk space", "%1 free of %2", deviceItem.deviceFreeSpaceText, deviceItem.deviceSizeText)
            }
            return ""
        } else if (!deviceItem.deviceMounted && deviceItem.deviceOperationResult === DN.DevicesStateMonitor.Working) {
            return i18nc("Accessing is a less technical word for Mounting; translation should be short and mean \'Currently mounting this device\'", "Accessing…")
        } else if (unmountTimer.running) {
            // Unmounting; shown if unmount takes less than 1 second
            return i18nc("Removing is a less technical word for Unmounting; translation should be short and mean \'Currently unmounting this device\'", "Removing…")
        } else {
            // Unmounting; shown if unmount takes longer than 1 second
            return i18n("Don't unplug yet! Files are still being transferred…")
        }
    }

    subtitleCanWrap: true

    // Color the subtitle red for disks with less than 5% free space
    subtitleColor: {
        if (deviceItem.deviceFreeSpace > 0 && deviceItem.deviceSize > 0) {
            if (deviceItem.deviceFreeSpace / deviceItem.deviceSize <= 0.05) {
                return LingmoUI.Theme.negativeTextColor
            }
        }
        return LingmoUI.Theme.textColor
    }

    defaultActionButtonAction: QQC2.Action {
        id: defaultAction
        icon.name: deviceActions.defaultActionIcon
        text: deviceActions.defaultActionText
        onTriggered: {
            if(deviceItem.deviceMounted){
                unmountTimer.restart();
            }
            deviceActions.actionTriggered(deviceActions.defaultActionName)
        }
    }

    isBusy: deviceItem.deviceOperationResult === DN.DevicesStateMonitor.Working

    customExpandedViewContent: deviceActions.rowCount() === 0 || deviceOperationResult === DN.DevicesStateMonitor.Working ? null : actionComponent

    Component {
        id: actionComponent

        ListView {
            id: actionRepeater

            contentWidth: parent.width
            contentHeight: contentItem.height
            width: contentWidth
            height: contentHeight

            model: deviceItem.deviceActions

            delegate: LingmoComponents3.ToolButton
            {
                width: parent.width
                text: model.Text
                icon.name: model.Icon

                KeyNavigation.up: currentIndex > 0 ? actionRepeater.itemAtIndex(currentIndex - 1) : deviceItem
                KeyNavigation.down: {
                    if (currentIndex <= actionRepeater.count - 1) {
                        return actionRepeater.itemAtIndex(currentIndex + 1);
                    } else {
                        return actionRepeater.itemAtIndex(0);
                    }
                }

                onClicked: {
                    deviceActions.actionTriggered(model.Name)
                }

            }
        }

    }
}
