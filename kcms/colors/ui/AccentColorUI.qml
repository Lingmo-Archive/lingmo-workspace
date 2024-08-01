/*
    SPDX-FileCopyrightText: 2023 Tanbir Jishan <tantalising007@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Dialogs as QtDialogs
import QtQuick.Controls 2.3 as QQC2
import QtQuick.Templates 2.3 as T

import org.kde.lingmoui as LingmoUI

RowLayout {
    id: accentColorUI

    readonly property int colorButtonSize: Math.round(LingmoUI.Units.gridUnit * 1.25)

    spacing: LingmoUI.Units.smallSpacing

    QQC2.ComboBox {
        id: colorModeBox
        Layout.alignment: Qt.AlignTop | Qt.AlignRight

        model: [
            i18nc("@item:inlistbox Accent color from color scheme", "Accent Color From Color Scheme"),
            i18nc("@item:inlistbox Accent color from wallpaper", "Accent Color From Wallpaper"),
            i18nc("@item:inlistbox User-chosen custom accent color", "Custom Accent Color")
        ]

        currentIndex: {
            if (kcm.accentColorFromWallpaper) return 1;
            return Qt.colorEqual(kcm.accentColor, "transparent") ? 0 : 2;
        }

        onCurrentIndexChanged: {
            switch (currentIndex) {
                case 0: // colorScheme
                    kcm.accentColor = "transparent";
                    kcm.accentColorFromWallpaper = false;
                    break;

                case 1: // wallpaper
                    kcm.accentColorFromWallpaper = true;
                    break;

                case 2: // custom
                    if(!colorRepeater.model.some(color => Qt.colorEqual(color, kcm.accentColor))) { // if not accent is from the provided list, assign the last used color, if any, or a sensible value
                        kcm.accentColor = Qt.colorEqual(kcm.lastUsedCustomAccentColor, "transparent") ? colorRepeater.model[0] : kcm.lastUsedCustomAccentColor;
                        kcm.accentColorFromWallpaper = false;
                    }
                    break;
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        Layout.maximumWidth: (colorRepeater.count * (accentColorUI.colorButtonSize + spacing)) + customColorIndicator.width

        spacing: LingmoUI.Units.largeSpacing
        opacity: colorModeBox.currentIndex === 2 ? 1.0 : 0.5

        component ColorRadioButton : T.RadioButton {
            id: control
            autoExclusive: false

            property color color: "transparent"
            property bool highlight: true

            implicitWidth: accentColorUI.colorButtonSize
            implicitHeight: accentColorUI.colorButtonSize

            background: Rectangle {
                readonly property bool showHighlight: parent.hovered && !control.checked && control.highlight
                radius:  showHighlight ? LingmoUI.Units.cornerRadius : Math.round(height / 2)
                color: control.color
                border {
                    color: showHighlight ? LingmoUI.Theme.highlightColor : Qt.rgba(0, 0, 0, 0.15)
                }
                Behavior on radius {
                    PropertyAnimation {
                        duration: LingmoUI.Units.veryShortDuration
                        from: Math.round(height / 2)
                    }
                }
                Rectangle {
                    id: tabHighlight
                    anchors.fill: parent
                    radius: Math.round(height / 2)
                    scale: 1.3
                    color: "transparent"
                    visible: control.visualFocus
                    border {
                        color: LingmoUI.Theme.highlightColor
                        width: 1
                    }
                }
            }

            indicator: Rectangle {
                radius: height / 2
                visible: control.checked
                anchors {
                    fill: parent
                    margins: Math.round(LingmoUI.Units.smallSpacing * 1.25)
                }
                border {
                    color: Qt.rgba(0, 0, 0, 0.15)
                    width: 1
                }
            }
        }

        Repeater {
            id: colorRepeater

            model: [
                "#e93a9a",
                "#e93d58",
                "#e9643a",
                "#e8cb2d",
                "#3dd425",
                "#00d3b8",
                "#3daee9",
                "#b875dc",
                "#926ee4",
                "#686b6f",
            ]

            delegate: ColorRadioButton {
                color: modelData
                checked: Qt.colorEqual(kcm.accentColor, modelData) && !kcm.accentColorFromWallpaper

                onToggled: {
                    kcm.accentColorFromWallpaper = false;
                    kcm.accentColor = modelData;
                    kcm.lastUsedCustomAccentColor = modelData;
                    checked = Qt.binding(() => Qt.colorEqual(kcm.accentColor, modelData) && !kcm.accentColorFromWallpaper);
                }
            }
        }

        QtDialogs.ColorDialog {
            id: colorDialog
            title: i18n("Choose custom accent color")
            // User must either choose a colour or cancel the operation before doing something else
            modality: Qt.ApplicationModal
            parentWindow: accentColorUI.Window.window
            selectedColor: Qt.colorEqual(kcm.lastUsedCustomAccentColor, "transparent") ? kcm.accentColor : kcm.lastUsedCustomAccentColor
            onAccepted: {
                kcm.accentColor = colorDialog.selectedColor;
                kcm.lastUsedCustomAccentColor = colorDialog.selectedColor;
                kcm.accentColorFromWallpaper = false;
            }
        }

        Rectangle {
            id: customColorIndicator

            height: customColorButton.height
            width: customColorButton.visibleWidth + colorPicker.width
            radius: customColorButton.background.radius
            color: complementary(kcm.accentColor)

            function complementary(color) {
                return Qt.hsla((((color.hslHue + 0.5) % 1) + 1) % 1, color.hslSaturation, color.hslLightness, color.a);
            }


            ColorRadioButton {
                id: customColorButton

                readonly property bool isCustomColor: !kcm.accentColorFromWallpaper
                    && !Qt.colorEqual(kcm.accentColor, "transparent")
                    && !colorRepeater.model.some(color => Qt.colorEqual(color, root.accentColor))

                readonly property real visibleWidth: visible ? width + LingmoUI.Units.smallSpacing : 0

                color:  kcm.accentColor
                highlight: false
                checked: isCustomColor
                visible: isCustomColor
                anchors.left: parent.left

                MouseArea { // To prevent the button being toggled when clicked. The toggle state should only be controlled through isCustomColor
                    anchors.fill: parent
                    onClicked: colorDialog.open()
                }
                onFocusChanged: colorPicker.focus = true;
            }
            QQC2.RoundButton {
                id: colorPicker
                anchors.right: parent.right
                height: customColorButton.height
                width: customColorButton.width
                padding: 0  // Round button adds some padding by default which we don't need. Setting this to 0 centers the icon
                icon.name: "color-picker"
                icon.width : Math.round(LingmoUI.Units.iconSizes.small * 0.9) // This provides a nice padding.
                onClicked: colorDialog.open()
            }
        }
    }
}
