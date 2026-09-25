import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

// No Panel chrome: the clock is the anchor of the layout and reads better as
// bare type over the wallpaper than as another boxed card.
ColumnLayout {
    id: root

    // The desktop gives the clock a whole row to itself and wants it read from
    // across the room; the dashboard sits it in a column beside everything
    // else. Same widget, one knob.
    property bool big: false
    property bool centred: false

    Layout.fillWidth: true
    spacing: root.big ? -14 : -6

    Text {
        Layout.alignment: root.centred ? Qt.AlignHCenter : Qt.AlignLeft
        text: Qt.formatDateTime(clock.date, Config.timeFormat)
        color: Theme.fg
        font.family: Config.font
        font.pixelSize: root.big ? 150 : 78
        font.bold: true
        style: Text.Raised
        styleColor: Qt.alpha(Theme.bg, 0.6)
    }
    Text {
        Layout.alignment: root.centred ? Qt.AlignHCenter : Qt.AlignLeft
        Layout.topMargin: root.big ? 18 : 10
        text: Qt.formatDateTime(clock.date, Config.dateFormat)
        color: Theme.accent
        font.family: Config.font
        font.pixelSize: root.big ? 30 : 19
        style: Text.Raised
        styleColor: Qt.alpha(Theme.bg, 0.6)
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
