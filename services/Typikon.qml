pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// The liturgical day, from the `typikon` command.
//
// Computed locally, so this needs no network and cannot go stale. It only has
// to be re-read when the date changes, which a clock at minute precision
// notices without polling a subprocess every few seconds.
//
// typikon lives in its own repo:
//   https://git.pumpin.online/funkpower/typikon
//   cargo install --git https://git.pumpin.online/funkpower/typikon
Singleton {
    id: root

    // Today plus the next six, so the week ahead is visible at a glance.
    readonly property int days: 7

    property bool available: false
    property string error: ""

    property var week: []
    property var today: ({})

    readonly property string date:        today.date        ?? ""
    readonly property string weekday:     today.weekday     ?? ""
    readonly property string churchDate:  today.churchDate  ?? ""
    readonly property string season:      today.season      ?? ""
    readonly property string cycle:       today.cycle       ?? ""
    readonly property string feast:       today.feast       ?? ""
    // The rank sign a menaion prints in the margin, which says how the day is
    // kept. Not a restatement of `feast`: most polyeleos days carry a sign and
    // no feast name at all, so without this they read as ordinary.
    readonly property string sign:        today.sign        ?? ""
    readonly property string rank:        today.rank        ?? ""
    readonly property string title:       today.title       ?? ""
    readonly property string fast:        today.fast        ?? "none"
    readonly property string fastLabel:   today.fastLabel   ?? ""
    readonly property string emoji:       today.emoji       ?? ""
    readonly property string reason:      today.reason      ?? ""
    readonly property string obligation:  today.obligation  ?? ""
    readonly property string pascha:      today.pascha      ?? ""
    readonly property int    daysToPascha: today.daysToPascha ?? 0
    readonly property var    commemorations: today.commemorations ?? []

    readonly property bool obligatory: obligation === "obligatory"

    // A request made while a run is in flight is queued, not dropped. Dropping
    // it meant a jurisdiction or date set a moment after startup never took
    // effect at all -- the answer stayed yesterday's until midnight.
    property bool _queued: false

    function refresh() {
        if (proc.running) { root._queued = true; return; }
        proc.command = root._command();
        proc.running = true;
    }

    // The day is named on the command line rather than left to the subprocess.
    // SystemClock does not report the wall clock: it snaps to the tick it is
    // waiting for, and Qt's coarse timers let that tick arrive a fraction of a
    // second early -- measured here at 0.4s on a minute tick. So at midnight the
    // shell believes it is already tomorrow while the kernel still says today,
    // and `typikon` with no date answers from the kernel. It returns in about
    // 2ms, far too fast to lose that race, so the rollover run re-fetched
    // yesterday and nothing asked again until the following midnight.
    function _command() {
        const c = ["typikon", "--json", "--date", root._day, "--days", String(root.days)];
        if (Config.churchJurisdiction !== "")
            c.push("--jurisdiction", Config.churchJurisdiction);
        if (Config.churchTypikonFast)
            c.push("--typikon");
        return c;
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Re-read when the day rolls over, not on a timer. The answer changes at
    // midnight and at no other moment.
    readonly property string _day: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
    on_DayChanged: root.refresh()
    Component.onCompleted: root.refresh()

    Process {
        id: proc
        onExited: if (root._queued) { root._queued = false; root.refresh(); }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text);
                    root.week = parsed.days ?? [parsed];
                    root.today = root.week.length ? root.week[0] : {};
                    root.available = true;
                    root.error = "";
                } catch (e) {
                    root.available = false;
                    root.error = "could not read typikon";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    root.available = false;
                    root.error = this.text.trim();
                }
            }
        }
    }
}
