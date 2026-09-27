pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs
import qs.services
import qs.modules
import qs.modules.widgets

// Lock screen. WlSessionLock means the compositor itself holds the session
// closed, so a crash here leaves the screen locked rather than exposed.
Singleton {
    id: root

    property bool locked: false
    property string error: ""
    property string pw: ""

    function lock() {
        error = ""; pw = ""; locked = true;
    }

    // Config.lockHooks and unlockHooks. Run on the change itself rather than in
    // lock() and the PAM callback, so every way in and out is covered.
    onLockedChanged: {
        for (const argv of (locked ? Config.lockHooks : Config.unlockHooks))
            Hypr.exec(argv);
    }

    WlSessionLock {
        id: session
        locked: root.locked

        WlSessionLockSurface {
            color: Theme.bgAlt

            // The desktop's own wallpaper, read from the same singleton the
            // background layer uses, so the two cannot drift apart. Nothing
            // else had to change to survive a photo behind it: Panel is
            // already translucent and ClockWidget already draws raised type,
            // because both were written for the background layer.
            //
            // Cached, unlike the background layer's copy: every output gets its
            // own lock surface, and they are built and thrown away on each
            // lock, so sharing one decode is cheaper here rather than dearer.
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: Background.wallpaper !== ""
                source: Background.wallpaper === "" ? ""
                      : "file://" + Background.wallpaper
            }

            // Dimmed. A locked screen that looks exactly like the working one
            // reads as unlocked from across the room, and the two bare labels
            // here -- the date under the clock and the PAM error -- are dim and
            // red on purpose and lose to a bright picture. Config.lockDim is
            // the single knob; 0 gives the wallpaper untouched.
            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: Config.lockDim
                visible: Background.wallpaper !== ""
            }

            ColumnLayout {
                id: col
                anchors.centerIn: parent
                spacing: 26
                // Through the parent rather than the surface. centerIn already
                // depends on the content item having geometry, so this cannot be
                // undefined in a way that centerIn survives — and a NaN width
                // here is a lock screen with no password box in it.
                width: Math.min(col.parent.width - 80,
                                Config.widgetWidth * Config.lockLayout.length
                                + 16 * (Config.lockLayout.length - 1))

                // The clock is not one of the widgets in the list. It sits
                // above them, the same shape the desktop uses, so the thing you
                // read from across the room is not stuck in a column.
                ClockWidget {
                    // fillWidth off explicitly: the widget sets it for the
                    // desktop, and while it is on, Layout ignores the horizontal
                    // alignment and the clock sits against the left edge of the
                    // grid instead of over its middle.
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignHCenter
                    big: true
                    centred: true
                }

                // Read-only on purpose: a widget that acts on a click would let
                // anyone at a locked machine drive it. `interactive` means adding
                // one to Config.lockLayout cannot quietly make the lock screen
                // clickable.
                WidgetGrid {
                    id: grid
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    columns: Config.lockLayout
                    interactive: false
                    // A short display would otherwise push the password field
                    // off the bottom, and a lock screen you cannot type into is
                    // not recoverable without a tty.
                    visible: col.parent.height > implicitHeight + 320
                }

                // Only when the grid is not carrying it, so the date is not on
                // screen twice.
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !grid.visible
                    text: Qt.formatDateTime(clock.date, Config.dateFormat)
                    color: Theme.fgDim
                    font.family: Config.font
                    font.pixelSize: Config.fontSize + 2
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 360
                    implicitHeight: 40
                    radius: Config.radius
                    color: Theme.surface
                    border.width: 2
                    border.color: root.error !== "" ? Theme.red
                                : pam.active ? Theme.yellow
                                : Theme.accent

                    TextInput {
                        id: field
                        anchors.fill: parent
                        anchors.margins: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.fg
                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 2
                        enabled: !pam.active
                        focus: true
                        text: root.pw
                        onTextChanged: root.pw = text
                        onAccepted: if (!pam.active && text.length > 0) pam.start()

                        Connections {
                            target: root
                            function onLockedChanged() { if (root.locked) field.forceActiveFocus(); }
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.error !== "" || pam.active
                    text: pam.active ? "checking…" : root.error
                    color: pam.active ? Theme.yellow : Theme.red
                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                }
            }

            SystemClock { id: clock; precision: SystemClock.Seconds }
        }
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            if (responseRequired) respond(root.pw);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.pw = "";
                root.error = "";
                root.locked = false;
            } else {
                root.pw = "";
                root.error = result === PamResult.Failed ? "Wrong password" : "Authentication error";
            }
        }
    }
}
