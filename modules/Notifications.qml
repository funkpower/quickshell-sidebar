pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs
import qs.services

// The notification daemon. Replaces mako, actions included.
Singleton {
    id: root
    // State lives in services/Notifs so the sidebar cards can read it without
    // modules/ and modules/sidebar/ importing each other.
    readonly property var active: Notifs.active

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: n => {
            n.tracked = true;
            Notifs.record(n);
        }
    }

    // Deferred, every one of them. These are called from inside a delegate's
    // own signal handler — a click on the card, or the expiry Timer the card
    // carries — and dropping the notification reassigns the list the Repeater
    // is built from. Mutating a Repeater's model from within its own delegate
    // re-enters the incubator while it is still creating or destroying that
    // delegate, and it dies there. Twice today, both times on a notification
    // arriving while another was on screen.
    //
    // Qt.callLater pushes the change to the end of the event loop, so the
    // regeneration that follows starts from a settled stack.
    // Closing is best-effort by the time this runs. Deferring to the end of the
    // event loop means the sender may have closed the notification itself in
    // between, and a destroyed QObject throws on property access rather than
    // reading as null — which is why this cannot be an `if (n)` guard, and was
    // the TypeError this logged on every expiry.
    function close(n) {
        try { n.dismiss(); } catch (e) {}
    }

    function dismiss(n) {
        Qt.callLater(() => {
            Notifs.drop(n);
            root.close(n);
        });
    }

    function dismissAll() {
        Qt.callLater(() => {
            const all = Notifs.active;
            Notifs.clearActive();
            for (const n of all) root.close(n);
        });
    }

    PanelWindow {
        visible: root.active.length > 0
        WlrLayershell.namespace: "mw-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        anchors { top: true; right: true }
        implicitWidth: 400
        implicitHeight: Math.max(1, column.implicitHeight + 20)
        color: "transparent"
        exclusiveZone: 0

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // A ScriptModel, not the array directly. Assigning a JS array to a
            // Repeater replaces the whole model, so every arrival tears down
            // and rebuilds every card — and the crash lives in that rebuild,
            // inside QQmlDelegateModel's incubator, reached through
            // QQuickRepeater::regenerate. Three crashes today all had that
            // same stack and all fired on a notification arriving.
            //
            // ScriptModel diffs the array and emits inserts and removes, so
            // existing cards are left alone and there is no regeneration to
            // re-enter.
            Repeater {
                model: ScriptModel { values: root.active }

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: body.implicitHeight + 20
                    radius: Config.radius
                    color: Theme.bg
                    border.width: 2
                    border.color: modelData?.urgency === NotificationUrgency.Critical ? Theme.red
                                : modelData?.urgency === NotificationUrgency.Low ? Theme.surface
                                : Theme.accent

                    RowLayout {
                        id: body
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // The sender's own image — an avatar from a chat app,
                        // album art from a player. Distinct from appIcon, which
                        // identifies the application rather than the event, so
                        // both can be present and they mean different things.
                        Rectangle {
                            visible: image.status === Image.Ready
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: Config.radius - 2
                            color: Theme.surface
                            clip: true

                            Image {
                                id: image
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                source: card.modelData?.image ?? ""
                            }
                        }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // The application's icon, resolved through the icon
                            // theme — appIcon is a name, not a path.
                            Image {
                                visible: status === Image.Ready
                                Layout.alignment: Qt.AlignVCenter
                                // Image derives its implicit size from the
                                // source, so those are read-only; the layout
                                // has to be told directly.
                                sourceSize.width: 15
                                sourceSize.height: 15
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                                asynchronous: true
                                source: (card.modelData?.appIcon ?? "") === ""
                                        ? "" : Quickshell.iconPath(card.modelData.appIcon, true)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData?.summary ?? ""
                                color: Theme.fg
                                elide: Text.ElideRight
                                font.family: Config.font
                                font.pixelSize: Config.fontSize
                                font.bold: true
                            }
                            Text {
                                text: modelData?.appName ?? ""
                                color: Theme.fgDim
                                font.family: Config.font
                                font.pixelSize: Config.fontSize - 2
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: (modelData?.body ?? "") !== ""
                            text: modelData?.body ?? ""
                            color: Theme.fgDim
                            wrapMode: Text.WordWrap
                            textFormat: Text.StyledText
                            font.family: Config.font
                            font.pixelSize: Config.fontSize - 1
                        }

                        RowLayout {
                            // Guarded: Notifs.active is reassigned wholesale on
                            // every arriving and dismissed notification, so the
                            // outer Repeater regenerates and card.modelData is
                            // briefly undefined while it does. Reaching through
                            // it unguarded crashed the delegate incubator — and
                            // because the shell also holds the session lock,
                            // that crash locked the session out.
                            visible: (card.modelData?.actions?.length ?? 0) > 0
                            spacing: 6

                            Repeater {
                                model: card.modelData?.actions ?? []

                                delegate: Rectangle {
                                    id: button
                                    required property var modelData
                                    implicitWidth: label.implicitWidth + 16
                                    implicitHeight: 24
                                    radius: Config.radius
                                    color: area.containsMouse ? Theme.accent : Theme.surface

                                    Text {
                                        id: label
                                        anchors.centerIn: parent
                                        text: button.modelData?.text ?? ""
                                        color: area.containsMouse ? Theme.bg : Theme.fg
                                        font.family: Config.font
                                        font.pixelSize: Config.fontSize - 1
                                    }

                                    MouseArea {
                                        id: area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: button.modelData?.invoke()
                                    }
                                }
                            }
                        }
                    }

                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: root.dismiss(modelData)
                    }

                    Timer {
                        running: card.modelData !== undefined
                                 && (modelData?.urgency ?? 0) !== NotificationUrgency.Critical
                        interval: (modelData?.expireTimeout ?? 0) > 0 ? modelData.expireTimeout * 1000 : 6000
                        onTriggered: root.dismiss(modelData)
                    }
                }
            }
        }
    }
}
