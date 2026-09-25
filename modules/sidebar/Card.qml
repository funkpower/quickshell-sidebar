import QtQuick
import QtQuick.Layouts
import qs
import qs.services

// Shared chrome for the sidebar sections, so spacing and headings are defined
// once rather than in each card.
Rectangle {
    id: root
    property string title: ""
    property string action: ""
    signal actionClicked()
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 24
    radius: Config.radius * 1.5
    color: Theme.bgAlt

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            visible: root.title !== ""

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.accent
                font.family: Config.font
                font.pixelSize: Config.fontSize - 1
                font.bold: true
            }

            Text {
                visible: root.action !== ""
                text: root.action
                color: area.containsMouse ? Theme.accent : Theme.fgDim
                font.family: Config.font
                font.pixelSize: Config.fontSize - 2

                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    onClicked: root.actionClicked()
                }
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
