import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Panel {
    id: root
    title: "Calendar"
    note: Qt.formatDateTime(view, "MMMM yyyy")

    property date view: new Date()

    function step(months) {
        const d = new Date(view);
        // Set the day first: stepping a month from the 31st lands in the month
        // after next, because the target has no 31st.
        d.setDate(1);
        d.setMonth(d.getMonth() + months);
        view = d;
    }

    // Sunday-first grid of 42 cells, the trailing week trimmed if unused.
    readonly property var cells: {
        const first = new Date(view.getFullYear(), view.getMonth(), 1);
        const lead = first.getDay();
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(view.getFullYear(), view.getMonth(), 1 + i - lead);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === view.getMonth(),
                today: d.toDateString() === new Date().toDateString()
            });
        }
        while (out.length > 35 && !out.slice(35).some(c => c.inMonth)) out.length = 35;
        return out;
    }

    ColumnLayout {
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.fgDim
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 2

            Repeater {
                model: root.cells

                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 24

                    Rectangle {
                        anchors.centerIn: parent
                        width: 24; height: 22
                        radius: Config.radius - 2
                        color: modelData.today ? Theme.accent : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: modelData.today ? Theme.bg
                             : modelData.inMonth ? Theme.fg
                             : Qt.alpha(Theme.fgDim, 0.45)
                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 1
                        font.bold: modelData.today
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2

            Repeater {
                model: [{ t: "‹ prev", d: -1 }, { t: "today", d: 0 }, { t: "next ›", d: 1 }]

                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    horizontalAlignment: modelData.d < 0 ? Text.AlignLeft
                                       : modelData.d > 0 ? Text.AlignRight
                                       : Text.AlignHCenter
                    text: modelData.t
                    color: area.containsMouse ? Theme.accent : Theme.fgDim
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: modelData.d === 0 ? root.view = new Date() : root.step(modelData.d)
                    }
                }
            }
        }
    }
}
