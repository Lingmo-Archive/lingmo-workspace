/*
    SPDX-FileCopyrightText: 2017 Roman Gilg <subdiff@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.lingmoui as LingmoUI
import org.kde.kcmutils as KCM

import org.kde.colorcorrect as CC

import org.kde.private.kcms.nightlight as Private

KCM.SimpleKCM {
    id: root

    readonly property int error: compositorAdaptor.error
    property bool defaultRequested: false
    property QtObject locator

    readonly property bool doneLocating: locator !== null && !(locator.latitude === 0 && locator.longitude === 0)

    implicitHeight: LingmoUI.Units.gridUnit * 29
    implicitWidth: LingmoUI.Units.gridUnit * 35

    CC.CompositorAdaptor {
        id: compositorAdaptor
    }

    CC.SunCalc {
        id: sunCalc
    }

    // the Geolocator object is created dynamically so we can have control over when geolocation is attempted
    // because the object attempts geolocation immediately when created, which is unnecessary (and bad for privacy)

    function startLocator() {
        locator = Qt.createQmlObject('import org.kde.colorcorrect as CC; CC.Geolocator {}', root, "geoLocatorObj");
    }

    function endLocator() {
        locator?.destroy();
    }

    Connections {
        target: kcm.nightLightSettings
        function onActiveChanged() {
            if (kcm.nightLightSettings.active && kcm.nightLightSettings.mode === Private.NightLightMode.Automatic) {
                root.startLocator();
            } else {
                root.endLocator();
            }
        }
    }

    Component.onCompleted: {
        if (kcm.nightLightSettings.mode === Private.NightLightMode.Automatic && kcm.nightLightSettings.active) {
            startLocator();
        }
    }

    // Update backend when locator is changed
    Connections {
        target: root.locator
        function onLatitudeChanged() {
            kcm.nightLightSettings.latitudeAuto = Math.round(root.locator.latitude * 100) / 100
        }
        function onLongitudeChanged() {
            kcm.nightLightSettings.longitudeAuto = Math.round(root.locator.longitude * 100) / 100
        }
    }

    headerPaddingEnabled: false // Let the InlineMessage touch the edges
    header: LingmoUI.InlineMessage {
        id: errorMessage
        visible: compositorAdaptor.error !== CC.CompositorAdaptor.ErrorCodeSuccess
        position: LingmoUI.InlineMessage.Position.Header
        type: LingmoUI.MessageType.Error
        text: compositorAdaptor.errorText
    }

    Timer {
        id: previewTimer
        interval: LingmoUI.Units.humanMoment
        onTriggered: compositorAdaptor.stopPreview()
    }

    ColumnLayout {
        spacing: 0

        QQC2.Label {
            Layout.margins: LingmoUI.Units.gridUnit
            Layout.alignment: Qt.AlignHCenter

            Layout.maximumWidth: Math.round(root.width - (LingmoUI.Units.gridUnit * 2))
            text: i18n("The blue light filter makes the colors on the screen warmer.")
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
        }

        DayNightView {
            Layout.margins: LingmoUI.Units.smallSpacing
            Layout.bottomMargin: LingmoUI.Units.gridUnit
            Layout.maximumWidth: LingmoUI.Units.gridUnit * 30
            Layout.alignment: Qt.AlignCenter

            readonly property real latitude: kcm.nightLightSettings.mode === Private.NightLightMode.Location
                ? kcm.nightLightSettings.latitudeFixed
                : (root.locator?.locatingDone) ? root.locator.latitude : kcm.nightLightSettings.latitudeAuto
            readonly property real longitude: kcm.nightLightSettings.mode === Private.NightLightMode.Location
                ? kcm.nightLightSettings.longitudeFixed
                : (root.locator?.locatingDone) ? root.locator.longitude : kcm.nightLightSettings.longitudeAuto

            readonly property var morningTimings: sunCalc.getMorningTimings(latitude, longitude)
            readonly property var eveningTimings: sunCalc.getEveningTimings(latitude, longitude)

            enabled: kcm.nightLightSettings.active

            dayTemperature: kcm.nightLightSettings.dayTemperature
            nightTemperature: kcm.nightLightSettings.nightTemperature

            alwaysOn: kcm.nightLightSettings.mode === Private.NightLightMode.Constant
            dayTransitionOn: kcm.nightLightSettings.mode === Private.NightLightMode.Timings
                ? minutesForFixed(kcm.nightLightSettings.morningBeginFixed)
                : minutesForDate(morningTimings.begin)
            dayTransitionOff: kcm.nightLightSettings.mode === Private.NightLightMode.Timings
                ? (minutesForFixed(kcm.nightLightSettings.morningBeginFixed) + kcm.nightLightSettings.transitionTime) % 1440
                : minutesForDate(morningTimings.end)
            nightTransitionOn: kcm.nightLightSettings.mode === Private.NightLightMode.Timings
                ? minutesForFixed(kcm.nightLightSettings.eveningBeginFixed)
                : minutesForDate(eveningTimings.begin)
            nightTransitionOff: kcm.nightLightSettings.mode === Private.NightLightMode.Timings
                ? (minutesForFixed(kcm.nightLightSettings.eveningBeginFixed) + kcm.nightLightSettings.transitionTime) % 1440
                : minutesForDate(eveningTimings.end)

            function minutesForFixed(dateString: string): int {
                // The fixed timings format is "hhmm"
                const hours = parseInt(dateString.substring(0, 2), 10)
                const mins = parseInt(dateString.substring(2, 4), 10)
                return hours * 60 + mins
            }
        }

        QQC2.Label {
            id: sliderValueLabelMetrics
            visible: false
            // One digit more than the theoretical maximum, because who knows
            // which digit is the widest in the current font anyway.
            text: i18nc("Color temperature in Kelvin", "%1K", 99999)
            textFormat: Text.PlainText
        }

        LingmoUI.FormLayout {
            id: parentLayout

            GridLayout {
                LingmoUI.FormData.label: i18n("Day light temperature:")
                LingmoUI.FormData.buddyFor: tempSliderDay
                enabled: kcm.nightLightSettings.active && kcm.nightLightSettings.mode !== Private.NightLightMode.Constant

                columns: 4

                QQC2.Slider {
                    id: tempSliderDay
                    // Match combobox width
                    Layout.minimumWidth: modeSwitcher.width
                    Layout.columnSpan: 3
                    from: kcm.maxDayTemp
                    to: kcm.minDayTemp
                    stepSize: -100
                    live: true

                    value: kcm.nightLightSettings.dayTemperature

                    onMoved: {
                        kcm.nightLightSettings.dayTemperature = value
                        compositorAdaptor.preview(value)

                        // This can fire for scroll events; in this case we need
                        // to use a timer to make the preview message disappear, since
                        // we can't make it disappear in the onPressedChanged handler
                        // since there is no press
                        if (!pressed) {
                            previewTimer.restart()
                        }
                    }
                    onPressedChanged: {
                        if (!pressed) {
                            compositorAdaptor.stopPreview()
                        }
                    }

                    KCM.SettingStateBinding {
                        configObject: kcm.nightLightSettings
                        settingName: "DayTemperature"
                        extraEnabledConditions: kcm.nightLightSettings.active
                    }
                }
                QQC2.Label {
                    text: i18nc("Color temperature in Kelvin", "%1K", tempSliderDay.value)
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignRight
                    Layout.minimumWidth: sliderValueLabelMetrics.implicitWidth
                }
                //row 2
                QQC2.Label {
                    text: i18nc("Night colour blue-ish; no blue light filter activated", "Cool (no filter)")
                    textFormat: Text.PlainText
                }
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Label {
                    text: i18nc("Night colour red-ish", "Warm")
                    textFormat: Text.PlainText
                }
                Item {}
            }

            GridLayout {
                LingmoUI.FormData.label: i18n("Night light temperature:")
                LingmoUI.FormData.buddyFor: tempSliderNight
                enabled: kcm.nightLightSettings.active

                columns: 4

                QQC2.Slider {
                    id: tempSliderNight
                    // Match combobox width
                    Layout.minimumWidth: modeSwitcher.width
                    Layout.columnSpan: 3
                    from: kcm.maxNightTemp
                    to: kcm.minNightTemp
                    stepSize: -100
                    live: true

                    value: kcm.nightLightSettings.nightTemperature

                    onMoved: {
                        kcm.nightLightSettings.nightTemperature = value
                        compositorAdaptor.preview(value)

                        // This can fire for scroll events; in this case we need
                        // to use a timer to make the preview disappear, since
                        // we can't make it disappear in the onPressedChanged handler
                        // since there is no press
                        if (!pressed) {
                            previewTimer.restart()
                        }
                    }
                    onPressedChanged: {
                        if (!pressed) {
                            compositorAdaptor.stopPreview()
                        }
                    }

                    KCM.SettingStateBinding {
                        configObject: kcm.nightLightSettings
                        settingName: "NightTemperature"
                        extraEnabledConditions: kcm.nightLightSettings.active
                    }
                }
                QQC2.Label {
                    text: i18nc("Color temperature in Kelvin", "%1K", tempSliderNight.value)
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignRight
                    Layout.minimumWidth: sliderValueLabelMetrics.implicitWidth
                }
                //row 2
                QQC2.Label {
                    text: i18nc("Night colour blue-ish; no blue light filter activated", "Cool (no filter)")
                    textFormat: Text.PlainText
                }
                Item {
                    Layout.fillWidth: true
                }
                QQC2.Label {
                    text: i18nc("Night colour red-ish", "Warm")
                    textFormat: Text.PlainText
                }
                Item {}
            }

            Item { implicitHeight: LingmoUI.Units.largeSpacing }

            QQC2.ComboBox {
                id: modeSwitcher
                // Work around https://bugs.kde.org/show_bug.cgi?id=403153
                Layout.minimumWidth: LingmoUI.Units.gridUnit * 17
                LingmoUI.FormData.label: i18n("Switching times:")
                currentIndex: kcm.nightLightSettings.active ? kcm.nightLightSettings.mode + 1 : 0
                model: [
                    i18n("Always off"),  // This is not actually a Mode, but represents Night Light being disabled
                    i18n("Sunset and sunrise at current location"),
                    i18n("Sunset and sunrise at manual location"),
                    i18n("Custom times"),
                    i18n("Always on night light")
                ]
                onCurrentIndexChanged: {
                    if (currentIndex !== 0) {
                        kcm.nightLightSettings.mode = currentIndex - 1;
                    }
                    kcm.nightLightSettings.active = (currentIndex !== 0);
                    if (currentIndex - 1 === Private.NightLightMode.Automatic && kcm.nightLightSettings.active) {
                        root.startLocator();
                    } else {
                        root.endLocator();
                    }
                }
            }

            // Show current location in auto mode
            QQC2.Label {
                LingmoUI.FormData.label: i18nc("@label The coordinates for the current location", "Current location:")

                visible: kcm.nightLightSettings.mode === Private.NightLightMode.Automatic && kcm.nightLightSettings.active
                    && root.doneLocating
                enabled: kcm.nightLightSettings.active
                wrapMode: Text.Wrap
                text: i18n("Latitude: %1°   Longitude: %2°",
                    Math.round((root.locator?.latitude ?? 0) * 100) / 100,
                    Math.round((root.locator?.longitude ?? 0) * 100) / 100)
                textFormat: Text.PlainText
            }

            // Inform about geolocation access in auto mode
            // The system settings window likes to take over the cursor with a plain label.
            // The TextEdit 'takes priority' over the system settings window trying to eat the mouse,
            // allowing us to use the HoverHandler boilerplate for proper link handling
            TextEdit {
                Layout.maximumWidth: modeSwitcher.width

                visible: modeSwitcher.currentIndex - 1 === Private.NightLightMode.Automatic && kcm.nightLightSettings.active
                enabled: kcm.nightLightSettings.active

                textFormat: TextEdit.RichText
                wrapMode: Text.Wrap
                readOnly: true

                color: LingmoUI.Theme.textColor
                selectedTextColor: LingmoUI.Theme.highlightedTextColor
                selectionColor: LingmoUI.Theme.highlightColor

                text: xi18nc("@info", "The device's location will be periodically updated using GPS (if available), or by sending network information to <link url='https://location.services.mozilla.com'>Mozilla Location Service</link>.")
                font: LingmoUI.Theme.smallFont

                onLinkActivated: (url) => Qt.openUrlExternally(url)

                HoverHandler {
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            // Show time entry fields in manual timings mode
            TimeField {
                id: eveningBeginFixedField
                visible: kcm.nightLightSettings.mode === Private.NightLightMode.Timings && kcm.nightLightSettings.active
                LingmoUI.FormData.label: i18n("Begin night light at:")

                backend: kcm.nightLightSettings.eveningBeginFixed
                onBackendChanged: {
                    kcm.nightLightSettings.eveningBeginFixed = backend;
                }
                KCM.SettingStateBinding {
                    configObject: kcm.nightLightSettings
                    settingName: "EveningBeginFixed"
                    extraEnabledConditions: kcm.nightLightSettings.active && kcm.nightLightSettings.mode === Private.NightLightMode.Timings
                }
            }

            TimeField {
                id: morningBeginFixedField
                visible: kcm.nightLightSettings.mode === Private.NightLightMode.Timings && kcm.nightLightSettings.active
                LingmoUI.FormData.label: i18n("Begin day light at:")
                backend: kcm.nightLightSettings.morningBeginFixed
                onBackendChanged: {
                    kcm.nightLightSettings.morningBeginFixed = backend;
                }
                KCM.SettingStateBinding {
                    configObject: kcm.nightLightSettings
                    settingName: "MorningBeginFixed"
                    extraEnabledConditions: kcm.nightLightSettings.active && kcm.nightLightSettings.mode === Private.NightLightMode.Timings
                }
            }

            QQC2.SpinBox {
                id: transitionDurationField
                visible: kcm.nightLightSettings.mode === Private.NightLightMode.Timings && kcm.nightLightSettings.active
                LingmoUI.FormData.label: i18n("Transition duration:")
                from: 1
                to: 600 // less than 12 hours (in minutes: 720)
                value: kcm.nightLightSettings.transitionTime
                editable: true
                onValueModified: {
                    kcm.nightLightSettings.transitionTime = value;
                }
                textFromValue: function(value, locale) {
                    return i18np("%1 minute", "%1 minutes", value);
                }
                valueFromText: function(text, locale) {
                    return parseInt(text);
                }

                KCM.SettingStateBinding {
                    configObject: kcm.nightLightSettings
                    settingName: "TransitionTime"
                    extraEnabledConditions: kcm.nightLightSettings.active
                }

                QQC2.ToolTip {
                    text: i18n("Input minutes - min. 1, max. 600")
                }
            }

            QQC2.Label {
                id: manualTimingsError
                visible: {
                    const day = 86400000; // 24h * 60m * 60s * 1000ms
                    const duration = transitionDurationField.value * 60 * 1000;
                    const morning = morningBeginFixedField.getNormedDate();
                    const evening = eveningBeginFixedField.getNormedDate();

                    const diff = Math.abs(evening - morning);
                    const diffMin = Math.min(diff, day - diff);

                    return diffMin <= duration && kcm.nightLightSettings.active
                        && kcm.nightLightSettings.mode === Private.NightLightMode.Timings;
                }
                font.italic: true
                text: i18n("Error: Transition time overlaps.")
                textFormat: Text.PlainText
            }
        }

        // Show location chooser in manual location mode
        LocationsFixedView {
            visible: kcm.nightLightSettings.mode === Private.NightLightMode.Location && kcm.nightLightSettings.active
            Layout.alignment: Qt.AlignHCenter
            enabled: kcm.nightLightSettings.active
        }

        Item {
            visible: kcm.nightLightSettings.active
                && kcm.nightLightSettings.mode === Private.NightLightMode.Automatic
                && (!root.locator || !root.doneLocating)
            Layout.topMargin: LingmoUI.Units.largeSpacing * 4
            Layout.fillWidth: true
            implicitHeight: loadingPlaceholder.implicitHeight

            LingmoUI.LoadingPlaceholder {
                id: loadingPlaceholder

                text: i18nc("@info:placeholder", "Locating…")
                anchors.centerIn: parent
            }
        }
    }
}
