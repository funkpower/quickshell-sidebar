import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Card {
    title: "Notifications"
    action: Notifs.history.length > 0 ? "clear" : ""
    onActionClicked: Notifs.clearHistory()

    ColumnLayout {
        spacing: 6

        Text {
            visible: Notifs.history.length === 0
            text: "nothing yet"
            color: Theme.fgDim
            font.family: Config.font
            font.pixelSize: Config.fontSize - 1
        }

        Repeater {
            // ScriptModel for the same reason as the toast list: history is
            // reassigned on every notification, and handing a Repeater a fresh
            // array rebuilds every row through the incubator that crashed.
            model: ScriptModel { values: Notifs.history.slice(0, 12) }

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitWidth: 3
                    Layout.fillHeight: true
                    radius: 2
                    color: modelData.urgency === 2 ? Theme.red : Theme.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            color: Theme.fg
                            elide: Text.ElideRight
                            font.family: Config.font
                            font.pixelSize: Config.fontSize - 1
                        }
                        Text {
                            text: Qt.formatDateTime(modelData.time, Config.timeFormat)
                            color: Theme.fgDim
                            font.family: Config.font
                            font.pixelSize: Config.fontSize - 3
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: modelData.body !== ""
                        text: modelData.body
                        color: Theme.fgDim
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        textFormat: Text.PlainText
                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 2
                    }
                }
            }
        }
    }
}
