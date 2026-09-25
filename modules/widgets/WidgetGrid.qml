import QtQuick
import QtQuick.Layouts
import qs

// The columns of widgets on the lock screen. Which widgets appear where is a
// list of names in Config; this only knows how to arrange them.
//
// Named Components rather than Loaders pointing at files. A Loader handed a
// sibling's URL gets no access to the types beside it, so Panel stops
// resolving inside the widget and the column comes up empty with nothing in the
// log to say why. Going through a Component declared here keeps them in scope
// and still builds each widget exactly once.
Item {
    id: root

    required property var columns

    // False on the lock screen: a widget that acts on a click would still act
    // on it there, and a locked session that still does things is not locked. `enabled`
    // covers the whole subtree in one place and changes nothing about how any
    // of it draws, which a click-eating MouseArea on top could not promise.
    property bool interactive: true

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    enabled: root.interactive

    Component { id: c_clock;    ClockWidget {} }
    Component { id: c_weather;  WeatherWidget {} }
    Component { id: c_calendar; CalendarWidget {} }

    readonly property var widgets: ({
        "ClockWidget": c_clock, "WeatherWidget": c_weather, "CalendarWidget": c_calendar
    })

    RowLayout {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        Repeater {
            model: root.columns

            delegate: ColumnLayout {
                required property var modelData

                // Pinned, not merely fillWidth. Layouts hand out spare space on
                // top of each item's implicit width, and the clock's 78px type
                // makes its column far wider than the others on implicit width
                // alone.
                Layout.preferredWidth: Config.widgetWidth
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 14

                Repeater {
                    model: modelData

                    delegate: Loader {
                        required property var modelData
                        Layout.fillWidth: true
                        sourceComponent: root.widgets[modelData] ?? null
                    }
                }
            }
        }
    }
}
