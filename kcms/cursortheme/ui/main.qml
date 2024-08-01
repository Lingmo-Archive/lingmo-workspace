/*
    SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-only
*/

import QtCore
import QtQuick 2.7
import QtQuick.Window 2.2 // for Screen
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2 as QtControls
import QtQuick.Dialogs 6.3 as QtDialogs
import org.kde.lingmoui 2.5 as LingmoUI
import org.kde.kwindowsystem 1.0 // for isPlatformWayland
import org.kde.newstuff 1.91 as NewStuff
import org.kde.kcmutils as KCM

import org.kde.private.kcm_cursortheme 1.0

KCM.GridViewKCM {
    id: root

    property LaunchFeedbackDialog launchFeedbackDialog: null as LaunchFeedbackDialog

    view.model: kcm.cursorsModel
    view.delegate: Delegate {}
    view.currentIndex: kcm.cursorThemeIndex(kcm.cursorThemeSettings.cursorTheme);

    view.onCurrentIndexChanged: {
        kcm.cursorThemeSettings.cursorTheme = kcm.cursorThemeFromIndex(view.currentIndex)
        view.positionViewAtIndex(view.currentIndex, view.GridView.Beginning);
    }

    Component.onCompleted: {
        view.positionViewAtIndex(view.currentIndex, GridView.Beginning);
    }

    KCM.SettingStateBinding {
        configObject: kcm.cursorThemeSettings
        settingName: "cursorTheme"
        extraEnabledConditions: !kcm.downloadingFile
    }

    headerPaddingEnabled: false // Let the InlineMessage touch the edges
    header: LingmoUI.InlineMessage {
        id: infoLabel

        position: LingmoUI.InlineMessage.Position.Header
        showCloseButton: true

        Connections {
            target: kcm
            function onShowSuccessMessage(message) {
                infoLabel.type = LingmoUI.MessageType.Positive;
                infoLabel.text = message;
                infoLabel.visible = true;
            }
            function onShowInfoMessage(message) {
                infoLabel.type = LingmoUI.MessageType.Information;
                infoLabel.text = message;
                infoLabel.visible = true;
            }
            function onShowErrorMessage(message) {
                infoLabel.type = LingmoUI.MessageType.Error;
                infoLabel.text = message;
                infoLabel.visible = true;
            }
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: {
            if (!drag.hasUrls) {
                drag.accepted = false;
            }
        }
        onDropped: kcm.installThemeFromFile(drop.urls[0])
    }

    actions: [
        LingmoUI.Action {
            displayComponent: QtControls.ComboBox {
                id: sizeCombo

                property int maxContentWidth: implicitContentWidth
                popup.width: Math.max(availableWidth, maxContentWidth)

                model: kcm.sizesModel
                textRole: "display"
                displayText: i18n("Size: %1", currentText)
                currentIndex: kcm.cursorSizeIndex(kcm.cursorThemeSettings.cursorSize);
                onActivated: {
                    kcm.cursorThemeSettings.cursorSize = kcm.cursorSizeFromIndex(sizeCombo.currentIndex);
                    kcm.preferredSize = kcm.cursorSizeFromIndex(sizeCombo.currentIndex);
                }
                flat: true

                KCM.SettingStateBinding {
                configObject: kcm.cursorThemeSettings
                    settingName: "cursorSize"
                    extraEnabledConditions: kcm.canResize
                }

                delegate: QtControls.ItemDelegate {
                    id: sizeComboDelegate

                    readonly property int size: parseInt(model.display)

                    width: parent.width
                    highlighted: ListView.isCurrentItem

                    contentItem: RowLayout {
                        LingmoUI.Icon {
                            source: model.decoration
                            smooth: true
                            // On wayland the cursor size is logical pixels, and on X11 it's physical pixels.
                            property real devicePixelRatio: KWindowSystem.isPlatformWayland ? 1 : Screen.devicePixelRatio
                            property size iconSize: kcm.iconSizeFromIndex(index)
                            Layout.preferredWidth: iconSize.width / devicePixelRatio
                            Layout.preferredHeight: iconSize.height / devicePixelRatio
                            visible: valid && sizeComboDelegate.size > 0
                            roundToIconSize: false
                        }

                        QtControls.Label {
                            Layout.alignment: Qt.AlignRight
                            color: sizeComboDelegate.highlighted ? LingmoUI.Theme.highlightedTextColor : LingmoUI.Theme.textColor
                            text: i18n("Size: %1", model[sizeCombo.textRole])
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                        }
                    }
                    Binding {
                        target: sizeCombo
                        property: "maxContentWidth"
                        value: implicitWidth
                        when: index == sizeCombo.count - 1
                    }
                }
            }
        },
        LingmoUI.Action {
            text: i18nc("@action:button", "&Configure Launch Feedback…")
            icon.name: "preferences-desktop-launch-feedback"
            onTriggered: {
                if (root.launchFeedbackDialog === null) {
                    const component = Qt.createComponent("LaunchFeedbackDialog.qml");
                    root.launchFeedbackDialog = component.createObject(root, {
                        "parent": root,
                    });
                    component.destroy();
                }
                root.launchFeedbackDialog.open();
            }
        },
        LingmoUI.Action {
            text: i18n("&Install from File…")
            icon.name: "document-import"
            onTriggered: fileDialogLoader.active = true
            enabled: kcm.canInstall
        },
        NewStuff.Action {
            text: i18n("&Get New…")
            configFile: "xcursor.knsrc"
            onEntryEvent: function (entry, event) {
                if (event == NewStuff.Entry.StatusChangedEvent) {
                    kcm.ghnsEntryChanged(entry);
                }
            }
        }
    ]

    Loader {
        id: fileDialogLoader
        active: false
        sourceComponent: QtDialogs.FileDialog {
            title: i18n("Open Theme")
            currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
            nameFilters: [ i18n("Cursor Theme Files (*.tar.gz *.tar.bz2)") ]
            Component.onCompleted: open()
            onAccepted: {
                kcm.installThemeFromFile(selectedFile)
                fileDialogLoader.active = false
            }
            onRejected: {
                fileDialogLoader.active = false
            }
        }
    }
}

