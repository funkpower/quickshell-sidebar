pragma Singleton

import Quickshell

// The notification STORE. The view that draws them lives in
// modules/Notifications.qml.
//
// Split because modules/sidebar imports this, and if the store lived in
// modules/ then qs.modules and qs.modules.sidebar would import each other.
// QML resolves that circle by silently failing to load, which is a miserable
// thing to debug. Data in services/, views in modules/.
Singleton {
    id: root
    property var active: []
    property var history: []
    readonly property int historyLimit: 60

    // An id we can still read. A notification the sender has already closed is
    // a destroyed QObject, and touching one throws rather than returning
    // undefined, so every comparison below goes through here.
    function idOf(n) {
        try { return n ? n.id : undefined; } catch (e) { return undefined; }
    }

    function record(n) {
        // Applications update a notification by re-sending it under the same
        // id — a download counting up, a player changing track. The server
        // hands that back as another arrival, so without dropping the previous
        // one first an update becomes a second identical card on screen rather
        // than a change to the one already there.
        const id = root.idOf(n);
        root.active = [n, ...root.active.filter(x => {
            const other = root.idOf(x);
            return other !== undefined && other !== id;
        })].slice(0, 6);

        const entry = {
            id: id, summary: n.summary, body: n.body, appName: n.appName,
            urgency: n.urgency, time: new Date()
        };
        // Same reasoning for history: an update should revise its line, not add
        // one, or a single download fills the list on its own.
        const rest = root.history.length > 0 && id !== undefined
                     && root.history[0].id === id
                     ? root.history.slice(1) : root.history;
        root.history = [entry, ...rest].slice(0, root.historyLimit);
    }

    function drop(n) {
        const id = root.idOf(n);
        root.active = root.active.filter(x => {
            if (x === n) return false;
            const other = root.idOf(x);
            // A destroyed entry can never be dismissed again, so it goes too.
            if (other === undefined) return false;
            return id === undefined || other !== id;
        });
    }
    function clearActive() { root.active = []; }
    function clearHistory() { root.history = []; }
}
