/*
    SPDX-FileCopyrightText: 2018 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtCore
import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtQuick.Dialogs 6.3 as QtDialogs
import QtQuick.Controls 2.3 as QtControls
import QtQuick.Templates 2.3 as T
import QtQml 2.15

import org.kde.lingmoui 2.8 as LingmoUI
import org.kde.newstuff 1.91 as NewStuff
import org.kde.kcmutils as KCM
import org.kde.private.kcms.colors 1.0 as Private

KCM.GridViewKCM {
    id: root

    view.model: kcm.filteredModel
    view.currentIndex: kcm.filteredModel.selectedSchemeIndex

    Binding {
        target: kcm.filteredModel
        property: "query"
        value: searchField.text
        restoreMode: Binding.RestoreBinding
    }

    Binding {
        target: kcm.filteredModel
        property: "filter"
        value:  filterCombo.model[filterCombo.currentIndex].filter
        restoreMode: Binding.RestoreBinding
    }

    KCM.SettingStateBinding {
        configObject: kcm.colorsSettings
        settingName: "colorScheme"
        extraEnabledConditions: !kcm.downloadingFile
    }

    KCM.SettingHighlighter {
        target: colourFlow
        highlight: !Qt.colorEqual(kcm.accentColor, "transparent")
    }

    // The thumbnails are a bit more elaborate and need more room, especially when translated
    view.implicitCellWidth: LingmoUI.Units.gridUnit * 15
    view.implicitCellHeight: LingmoUI.Units.gridUnit * 13

    // we have a duplicate property here as "var" instead of "color", so that we
    // can set it to "undefined", which lets us use the "a || b" shorthand for
    // "a if a is defined, otherwise b"
    readonly property var accentColor: Qt.colorEqual(kcm.accentColor, "transparent") ? undefined : kcm.accentColor

    DropArea {
        anchors.fill: parent
        onEntered: {
            if (!drag.hasUrls) {
                drag.accepted = false;
            }
        }
        onDropped: {
            infoLabel.visible = false;
            kcm.installSchemeFromFile(drop.urls[0]);
        }
    }

    headerPaddingEnabled: false // Let the InlineMessage touch the edges
    header: ColumnLayout {
        spacing: LingmoUI.Units.smallSpacing

        LingmoUI.InlineMessage {
            id: notInstalledWarning
            Layout.fillWidth: true

            type: LingmoUI.MessageType.Warning
            position: LingmoUI.InlineMessage.Position.Header
            showCloseButton: true
            visible: false

            Connections {
                target: kcm
                function onShowSchemeNotInstalledWarning(schemeName) {
                    notInstalledWarning.text = i18n("The color scheme '%1' is not installed. Selecting the default theme instead.", schemeName)
                    notInstalledWarning.visible = true;
                }
            }
        }

        ColumnLayout {
            spacing: LingmoUI.Units.smallSpacing

            Layout.fillWidth: true
            // Equal to the margins removed by disabling header padding
            Layout.margins: LingmoUI.Units.mediumSpacing

            AccentColorUI {
                id: colourFlow
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }

            RowLayout {
                Layout.fillWidth: true

                spacing: LingmoUI.Units.smallSpacing

                LingmoUI.SearchField {
                    id: searchField
                    Layout.fillWidth: true
                }

                QtControls.ComboBox {
                    id: filterCombo
                    Layout.rightMargin: parent.spacing * 3
                    textRole: "text"
                    model: [
                        {text: i18n("All Schemes"), filter: Private.KCM.AllSchemes},
                        {text: i18n("Light Schemes"), filter: Private.KCM.LightSchemes},
                        {text: i18n("Dark Schemes"), filter: Private.KCM.DarkSchemes}
                    ]

                    // HACK QQC2 doesn't support icons, so we just tamper with the desktop style ComboBox's background
                    // and inject a nice little filter icon.
                    Component.onCompleted: {
                        if (!background || !background.hasOwnProperty("properties")) {
                            // not a KQuickStyleItem
                            return;
                        }

                        var props = background.properties || {};

                        background.properties = Qt.binding(function() {
                            var newProps = props;
                            newProps.currentIcon = "view-filter";
                            newProps.iconColor = LingmoUI.Theme.textColor;
                            return newProps;
                        });
                    }
                }
            }
        }
    }

    actions: [
        LingmoUI.Action {
            text: i18n("Install from File…")
            icon.name: "document-import"
            onTriggered: fileDialogLoader.active = true
        },
        NewStuff.Action {
            text: i18n("Get New…")
            configFile: "colorschemes.knsrc"
            onEntryEvent: function (entry, event) {
                if (event == NewStuff.Entry.StatusChangedEvent) {
                    kcm.knsEntryChanged(entry)
                } else if (event == NewStuff.Entry.AdoptedEvent) {
                    kcm.loadSelectedColorScheme()
                }
            }
        }
    ]

    view.delegate: KCM.GridDelegate {
        id: delegate

        text: model.display

        thumbnailAvailable: true
        thumbnail: Rectangle {
            anchors.fill: parent

            opacity: model.pendingDeletion ? 0.3 : 1
            Behavior on opacity {
                NumberAnimation { duration: LingmoUI.Units.longDuration }
            }

            color: kcm.tinted(model.palette.window, kcm.accentColor, model.tints, model.tintFactor)

            LingmoUI.Theme.inherit: false
            LingmoUI.Theme.highlightColor: root.accentColor || model.palette.highlight
            LingmoUI.Theme.textColor: kcm.tinted(model.palette.text, kcm.accentColor, model.tints, model.tintFactor)

            Rectangle {
                id: windowTitleBar
                width: parent.width
                height: Math.round(LingmoUI.Units.gridUnit * 1.5)
                color: kcm.tinted((model.accentActiveTitlebar && root.accentColor) ? kcm.accentBackground(root.accentColor, model.palette.window) : model.activeTitleBarBackground, kcm.accentColor, model.tints, model.tintFactor)

                QtControls.Label {
                    anchors {
                        fill: parent
                        leftMargin: LingmoUI.Units.smallSpacing
                        rightMargin: LingmoUI.Units.smallSpacing
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: (model.accentActiveTitlebar && root.accentColor) ? kcm.accentForeground(kcm.accentBackground(root.accentColor, model.palette.window), true) : model.activeTitleBarForeground
                    text: i18n("Window Title")
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: windowTitleBar.bottom
                    bottom: parent.bottom
                    margins: LingmoUI.Units.smallSpacing
                }
                spacing: LingmoUI.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    QtControls.Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter
                        text: i18n("Window text")
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: model.palette.windowText
                    }

                    QtControls.Button {
                        Layout.alignment: Qt.AlignBottom
                        text: i18n("Button")
                        LingmoUI.Theme.inherit: false
                        LingmoUI.Theme.highlightColor: kcm.tinted(root.accentColor ? kcm.accentBackground(root.accentColor, model.palette.base) : model.palette.highlight, kcm.accentColor, model.tints, model.tintFactor)
                        LingmoUI.Theme.backgroundColor: kcm.tinted(model.palette.button, kcm.accentColor, model.tints, model.tintFactor)
                        LingmoUI.Theme.textColor: kcm.tinted(model.palette.buttonText, kcm.accentColor, model.tints, model.tintFactor)
                        activeFocusOnTab: false
                    }
                }

                QtControls.Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 0

                    activeFocusOnTab: false

                    // Frame by default has a transparent background, override it so we can use the view color
                    // instead.
                    background: Rectangle {
                        color: LingmoUI.Theme.backgroundColor
                        border.width: 1
                        border.color: kcm.tinted(Qt.rgba(model.palette.text.r, model.palette.text.g, model.palette.text.b, 0.3), kcm.accentColor, model.tints, model.tintFactor)
                    }

                    // We need to set inherit to false here otherwise the child ItemDelegates will not use the
                    // alternative base color we set here.
                    LingmoUI.Theme.inherit: false
                    LingmoUI.Theme.backgroundColor: kcm.tinted(model.palette.base, kcm.accentColor, model.tints, model.tintFactor)
                    LingmoUI.Theme.disabledTextColor: kcm.tinted(model.disabledText, kcm.accentColor, model.tints, model.tintFactor)
                    LingmoUI.Theme.highlightColor: kcm.tinted(root.accentColor ? kcm.accentBackground(root.accentColor, model.palette.base) : model.palette.highlight, kcm.accentColor, model.tints, model.tintFactor)
                    LingmoUI.Theme.highlightedTextColor: kcm.tinted(root.accentColor ? kcm.accentForeground(kcm.accentBackground(root.accentColor, model.palette.base), true) : model.palette.highlightedText, kcm.accentColor, model.tints, model.tintFactor)
                    LingmoUI.Theme.linkColor: kcm.tinted(root.accentColor || model.palette.link, kcm.accentColor, model.tints, model.tintFactor)
                    LingmoUI.Theme.textColor: kcm.tinted(model.palette.text, kcm.accentColor, model.tints, model.tintFactor)

                    Column {
                        id: listPreviewColumn

                        function demoText(palette) {
                            return " <a href='#'><font color='%1'>%2</font></a> <a href='#'><font color='%3'>%4</font></a>"
                            .arg(palette.link)
                            .arg(i18nc("Hyperlink", "link"))
                            .arg(palette.linkVisited)
                            .arg(i18nc("Visited hyperlink", "visited"));
                        }

                        anchors.fill: parent
                        anchors.margins: 1

                        QtControls.ItemDelegate {
                            width: parent.width
                            text: i18n("Normal text") + listPreviewColumn.demoText(model.palette)
                            activeFocusOnTab: false
                        }

                        QtControls.ItemDelegate {
                            width: parent.width
                            highlighted: true
                            text: i18n("Highlighted text") + listPreviewColumn.demoText(model.selectedPalette)
                            activeFocusOnTab: false
                        }

                        QtControls.ItemDelegate {
                            width: parent.width
                            enabled: false
                            text: i18n("Disabled text") + listPreviewColumn.demoText(model.palette)
                            activeFocusOnTab: false
                        }
                    }
                }
            }

            // Make the preview non-clickable but still reacting to hover
            MouseArea {
                anchors.fill: parent
                onClicked: delegate.clicked()
                onDoubleClicked: delegate.doubleClicked()
            }
        }

        actions: [
            LingmoUI.Action {
                icon.name: "document-edit"
                tooltip: i18n("Edit Color Scheme…")
                enabled: !model.pendingDeletion
                onTriggered: kcm.editScheme(model.schemeName, root)
            },
            LingmoUI.Action {
                icon.name: "edit-delete"
                tooltip: i18n("Remove Color Scheme")
                enabled: model.removable
                visible: !model.pendingDeletion
                onTriggered: model.pendingDeletion = true
            },
            LingmoUI.Action {
                icon.name: "edit-undo"
                tooltip: i18n("Restore Color Scheme")
                visible: model.pendingDeletion
                onTriggered: model.pendingDeletion = false
            }
        ]
        onClicked: {
            kcm.model.selectedScheme = model.schemeName;
            view.forceActiveFocus();
        }
        onDoubleClicked: {
            kcm.save();
        }
    }

    footer: ColumnLayout {
        LingmoUI.InlineMessage {
            id: infoLabel
            Layout.fillWidth: true

            showCloseButton: true

            Connections {
                target: kcm
                function onShowSuccessMessage(message) {
                    infoLabel.type = LingmoUI.MessageType.Positive;
                    infoLabel.text = message;
                    infoLabel.visible = true;
                    // Avoid dual message widgets
                    notInstalledWarning.visible = false;
                }
                function onShowErrorMessage(message) {
                    infoLabel.type = LingmoUI.MessageType.Error;
                    infoLabel.text = message;
                    infoLabel.visible = true;
                    notInstalledWarning.visible = false;
                }
            }
        }
    }

    Loader {
        id: fileDialogLoader
        active: false
        sourceComponent: QtDialogs.FileDialog {
            title: i18n("Open Color Scheme")
            currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
            nameFilters: [ i18n("Color Scheme Files (*.colors)") ]
            Component.onCompleted: open()
            onAccepted: {
                infoLabel.visible = false;
                kcm.installSchemeFromFile(selectedFile)
                fileDialogLoader.active = false
            }
            onRejected: {
                fileDialogLoader.active = false
            }
        }
    }
}
