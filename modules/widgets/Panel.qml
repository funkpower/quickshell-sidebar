import QtQuick
import QtQuick.Layouts
import qs
import qs.services

// Shared chrome for a desktop widget. Slightly translucent so the wallpaper
// reads through it on the background layer, and opaque enough to stay legible
// over a busy picture.
Rectangle {
    id: root
    property string title: ""
    property string note: ""
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 28
    radius: Config.radius * 2
    color: Qt.alpha(Theme.bgAlt, 0.82)
    border.width: 1
    border.color: Qt.alpha(Theme.overlay, 0.7)

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            visible: root.title !== ""

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.accent
                font.family: Config.font
                font.pixelSize: Config.fontSize
                font.bold: true
            }
            Text {
                text: root.note
                color: Theme.fgDim
                font.family: Config.font
                font.pixelSize: Config.fontSize - 2
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
            onWidthChanged: if (children.length > 0) children[0].width = width
        }
    }
}
