import QtQuick
import QtQuick.Layouts
import qs
import qs.services

Panel {
    title: "Weather"
    note: Weather.available ? Weather.location : ""

    ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            visible: Weather.available

            Text {
                text: Weather.icon
                color: Theme.accent
                font.family: Config.font
                font.pixelSize: 44
            }
            ColumnLayout {
                spacing: 0
                Text {
                    text: Weather.temp + "°"
                    color: Theme.fg
                    font.family: Config.font
                    font.pixelSize: 30
                }
                Text {
                    text: Weather.label
                    color: Theme.fg
                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                }
                Text {
                    text: "feels " + Weather.feelsLike + "°  ·  wind " + Weather.wind + "  ·  " + Weather.humidity + "%"
                    color: Theme.fgDim
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2
                }
            }
        }

        Text {
            visible: !Weather.available
            text: "unavailable — check mw-weather"
            color: Theme.fgDim
            font.family: Config.font
            font.pixelSize: Config.fontSize - 1
        }

        Repeater {
            model: Weather.available ? Weather.days.slice(1, 6) : []

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.preferredWidth: 38
                    text: Qt.formatDateTime(new Date(modelData.date), "ddd")
                    color: Theme.fgDim
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 1
                }
                Text {
                    text: modelData.icon
                    color: Theme.accentAlt
                    font.family: Config.font
                    font.pixelSize: Config.fontSize + 1
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.label
                    color: Theme.fgDim
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2
                }
                Text {
                    text: modelData.precip + "%"
                    color: modelData.precip > 50 ? Theme.blue : Theme.fgDim
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2
                }
                Text {
                    Layout.preferredWidth: 62
                    horizontalAlignment: Text.AlignRight
                    text: modelData.high + "° / " + modelData.low + "°"
                    color: Theme.fg
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 1
                }
            }
        }
    }
}
