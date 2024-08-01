/*
  SPDX-FileCopyrightLabel: 2021 Han Young <hanyoung@protonmail.com>
  SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
  SPDX-FileCopyrightText: 2018 Eike Hein <hein@kde.org>
  SPDX-FileCopyrightText: 2021 Harald Sitter <sitter@kde.org>
  SPDX-License-Identifier: LGPL-3.0-or-later
*/
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

import org.kde.lingmoui 2.15 as LingmoUI
import org.kde.kcmutils as KCM
import kcmregionandlang 1.0

KCM.ScrollViewKCM {
    property int replaceLangIndex: -1
    implicitHeight: languageListView.height
    id: languageSelectPage
    title: i18n("Language")
    LanguageListModel {
        id: languageListModel
        Component.onCompleted: {
            languageListModel.setRegionAndLangSettings(kcm.settings, kcm);
        }
    }

    headerPaddingEnabled: false // Let the InlineMessages touch the edges
    header: ColumnLayout {
        spacing: 0

        LingmoUI.InlineMessage {
            text: i18n("Putting any other languages below English will cause undesired behavior in some applications. If you would like to use your system in English, remove all other languages.")
            Layout.fillWidth: true
            type: LingmoUI.MessageType.Error
            position: LingmoUI.InlineMessage.Position.Header
            visible: languageListModel.selectedLanguageModel.shouldWarnMultipleLang
        }

        LingmoUI.InlineMessage {
            id: unsupportedLanguageMsg
            text: i18nc("Error message, %1 is the language name", "The language \"%1\" is unsupported", languageListModel.selectedLanguageModel.unsupportedLanguage)
            Layout.fillWidth: true
            type: LingmoUI.MessageType.Error
            position: LingmoUI.InlineMessage.Position.Header
            visible: languageListModel.selectedLanguageModel.unsupportedLanguage.length > 0
        }

        QQC2.Label {
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            // Equal to the margins removed by disabling header padding
            Layout.margins: LingmoUI.Units.mediumSpacing
            text: i18n("Add languages in the order you want to see them in your applications.")
            textFormat: Text.PlainText
        }
    }

    Component {
        id: languagesListItemComponent
        Item {
            width: ListView.view.width
            height: listItem.implicitHeight

            LingmoUI.SwipeListItem {
                id: listItem

                contentItem: RowLayout {
                    spacing: LingmoUI.Units.smallSpacing

                    LingmoUI.ListItemDragHandle {
                        listItem: listItem
                        listView: languageListView
                        visible: languageListView.count > 1
                        onMoveRequested: (oldIndex, newIndex) => {
                            languageListModel.selectedLanguageModel.move(oldIndex, newIndex);
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                        text: model.display
                        textFormat: Text.PlainText

                        color: listItem.checked || (listItem.pressed && !listItem.checked && !listItem.sectionDelegate) ? listItem.activeTextColor : listItem.textColor;
                    }

                    QQC2.Button {
                        Layout.alignment: Qt.AlignRight
                        visible: languageListView.count <= 1
                        text: i18nc("@info:tooltip", "Change Language")
                        icon.name: "configure"
                        onClicked: {
                            replaceLangIndex = index;
                            addLanguagesSheet.titleText = i18nc("@title:window", "Change Language");
                            addLanguagesSheet.open();
                        }
                    }
                }

                actions: [
                    LingmoUI.Action {
                        enabled: index > 0
                        visible: languageListView.count > 1
                        icon.name: "go-top"
                        tooltip: i18nc("@info:tooltip", "Move to top")
                        onTriggered: languageListModel.selectedLanguageModel.move(index, 0)
                    },
                    LingmoUI.Action {
                        visible: languageListView.count > 1
                        icon.name: "edit-delete"
                        tooltip: i18nc("@info:tooltip", "Remove")
                        onTriggered: languageListModel.selectedLanguageModel.remove(index);
                    }]
            }
        }
    }
    view: ListView {
        id: languageListView
        model: languageListModel.selectedLanguageModel
        delegate: languagesListItemComponent
        LingmoUI.PlaceholderMessage {
            anchors.centerIn: parent
            visible: languageListView.count === 0
            text: i18nc("@info:placeholder", "No Language Configured")
        }
    }

    Component {
        id: addLanguageItemComponent

        QQC2.ItemDelegate {
            id: languageItem

            required property string nativeName
            required property string languageCode

            width: availableLanguagesList.width

            text: nativeName

            onClicked: {
                if (replaceLangIndex >= 0) {
                    languageListModel.selectedLanguageModel.replaceLanguage(replaceLangIndex, languageCode);
                    replaceLangIndex = -1;
                } else {
                    languageListModel.selectedLanguageModel.addLanguage(languageCode);
                }
                addLanguagesSheet.close();
            }
        }
    }

    LingmoUI.OverlaySheet {
        id: addLanguagesSheet
        property string titleText: i18nc("@title:window", "Add Languages")
        parent: languageSelectPage

        topPadding: 0
        leftPadding: 0
        rightPadding: 0
        bottomPadding: 0

        title: titleText

        onClosed: {
            titleText = i18nc("@title:window", "Add Languages");
        }

        ListView {
            id: availableLanguagesList
            implicitWidth: 18 * LingmoUI.Units.gridUnit
            model: languageListModel
            delegate: addLanguageItemComponent
            cacheBuffer: Math.max(0, contentHeight)
            reuseItems: true
        }
    }
    footer: ColumnLayout {
        QQC2.Button {
            Layout.alignment: Qt.AlignRight
            enabled: availableLanguagesList.count

            text: i18nc("@action:button", "Add More…")

            onClicked: {
                addLanguagesSheet.open();
                replaceLangIndex = -1;
            }

            checkable: true
            checked: addLanguagesSheet.visible
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            QQC2.Label {
                text: languageListModel.numberExample
                textFormat: Text.PlainText
            }
            QQC2.Label {
                text: languageListModel.currencyExample
                textFormat: Text.PlainText
            }
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: languageListModel.metric
            textFormat: Text.PlainText
        }

        QQC2.Label {
            Layout.alignment: Qt.AlignHCenter
            text: languageListModel.timeExample
            textFormat: Text.PlainText
        }
    }
}
