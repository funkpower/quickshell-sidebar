import QtQuick
import QtQuick.Layouts
import qs
import qs.services

Panel {
    id: root
    title: "Church calendar"
    // The church date, always: on the old calendar it is the answer people
    // came for, and on the new it is a harmless echo of the title bar.
    note: Typikon.available ? Typikon.churchDate : ""

    // The glyph carries what kind of fast it is, so obligation has to be shown
    // some other way or it disappears with the text: the weekday takes the
    // colour. Under the Typikon nothing binds and every fast day is yellow;
    // under a particular law that does bind — the Byzantine Catholic one —
    // the days that bind go red. A panel that blurs the two states something
    // untrue, so the distinction is kept even where the current jurisdiction
    // never exercises it.
    function tint(d) {
        if (!d) return Theme.fgDim;
        if (d.fast === "none") return Theme.fgDim;
        return d.obligation === "obligatory" ? Theme.red : Theme.yellow;
    }

    // Built from the week in view rather than hardcoded, because the levels a
    // tradition uses are its own — six under the Typikon, three under
    // Ruthenian law — and the words for them differ too.
    readonly property var legend: {
        const seen = [], out = [];
        for (const d of Typikon.week) {
            if (!d.emoji || seen.indexOf(d.fast) !== -1) continue;
            seen.push(d.fast);
            out.push({ emoji: d.emoji, label: d.fastLabel });
        }
        return out;
    }

    // The rank signs the week actually contains, named. Same reasoning as the
    // fast legend: the glyph carries the whole of the meaning, so something has
    // to say what it is. Ordinary days have no sign and contribute nothing.
    readonly property var signs: {
        const seen = [], out = [];
        for (const d of Typikon.week) {
            if (!d.sign || seen.indexOf(d.sign) !== -1) continue;
            seen.push(d.sign);
            out.push({ sign: d.sign, label: d.rank ?? "" });
        }
        return out;
    }

    ColumnLayout {
        spacing: 7

        Text {
            visible: !Typikon.available
            Layout.fillWidth: true
            text: Typikon.error !== "" ? Typikon.error : "unavailable — check typikon"
            color: Theme.fgDim
            wrapMode: Text.WordWrap
            font.family: Config.font
            font.pixelSize: Config.fontSize - 1
        }

        // Today, given room because it is the day being asked about.
        RowLayout {
            Layout.fillWidth: true
            visible: Typikon.available
            spacing: 11

            Text {
                text: Typikon.emoji
                font.family: Config.font
                font.pixelSize: 28
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignTop
                        visible: Typikon.sign !== ""
                        text: Typikon.sign
                        color: Theme.accent
                        // JetBrains Mono carries only the circled cross; the
                        // other two come from fontconfig's fallback, which is
                        // why the week below gives the sign a fixed slot rather
                        // than trusting its advance width.
                        font.family: Config.font
                        font.pixelSize: Config.fontSize + 2
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Typikon.title
                        color: Typikon.feast !== "" ? Theme.accent : Theme.fg
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.family: Config.font
                        font.pixelSize: Config.fontSize
                        font.bold: true
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: {
                        const bits = [Typikon.weekday];
                        if (Typikon.season !== "") bits.push(Typikon.season);
                        if (Typikon.obligatory) bits.push("obligatory");
                        return bits.join("  ·  ");
                    }
                    color: root.tint(Typikon.today)
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                    font.bold: Typikon.obligatory
                }

                // Forefeast, afterfeast and leave-taking repeat for days at a
                // time, so they get their own quiet line rather than crowding
                // out the commemoration that makes the day itself.
                Text {
                    Layout.fillWidth: true
                    visible: Typikon.cycle !== ""
                    text: Typikon.cycle
                    color: Qt.alpha(Theme.fgDim, 0.8)
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                    font.italic: true
                }
            }
        }

        // The rest of today's commemorations, under it.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 39
            visible: Typikon.available
            spacing: 0

            Repeater {
                model: Typikon.commemorations.filter(c => c !== Typikon.title).slice(0, 3)

                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    text: "· " + modelData
                    color: Theme.fgDim
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Typikon.week.length > 1
            implicitHeight: 1
            color: Qt.alpha(Theme.overlay, 0.6)
        }

        // The next six: glyph, weekday, and what is kept that day.
        Repeater {
            model: Typikon.week.length > 1 ? Typikon.week.slice(1) : []

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 9

                Text {
                    text: modelData.emoji
                    font.family: Config.font
                    font.pixelSize: Config.fontSize + 3
                }
                Text {
                    Layout.preferredWidth: 32
                    text: modelData.weekday.substring(0, 3)
                    color: root.tint(modelData)
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 2
                    font.bold: modelData.obligation === "obligatory"
                }
                Text {
                    // A slot rather than a spacing, so the titles line up
                    // whether or not the day is marked.
                    Layout.preferredWidth: 12
                    text: modelData.sign ?? ""
                    color: Theme.accent
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 1
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: modelData.feast ? Theme.accent : Theme.fgDim
                    elide: Text.ElideRight
                    font.family: Config.font
                    font.pixelSize: Config.fontSize - 3
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Typikon.available
            implicitHeight: 1
            color: Qt.alpha(Theme.overlay, 0.6)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Typikon.available
            spacing: 10

            // A legend, because the glyphs now carry the whole meaning.
            Flow {
                Layout.fillWidth: true
                spacing: 9

                Repeater {
                    model: root.legend
                    delegate: Text {
                        required property var modelData
                        text: modelData.emoji + " " + modelData.label
                        color: Qt.alpha(Theme.fgDim, 0.75)
                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 3
                    }
                }

                Repeater {
                    model: root.signs
                    delegate: Text {
                        required property var modelData
                        text: modelData.sign + " " + modelData.label
                        color: Qt.alpha(Theme.accent, 0.85)
                        font.family: Config.font
                        font.pixelSize: Config.fontSize - 3
                    }
                }
            }

            Text {
                // Labelled, because a bare ISO date in a corner is a riddle.
                text: Typikon.pascha !== "" ? "Pascha " + Typikon.pascha : ""
                color: Theme.fgDim
                font.family: Config.font
                font.pixelSize: Config.fontSize - 3
            }
        }
    }
}
