pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

DashboardWidgetBlock {
    id: root

    title: "Timers"

    // Default size
    implicitWidth: 220
    implicitHeight: 160

    // ── Timer state structure ───────────────────────────────────────
    // Each timer: { name: string, endTime: number, paused: bool, duration: number }
    // endTime is Unix timestamp when timer should expire (if not paused)
    // duration is total countdown duration in seconds (for reset)

    property var timers: StateService.get("dashboard.widgets.timers.list", [])

    // ── Save helpers ────────────────────────────────────────────────
    function _saveTimers() {
        StateService.set("dashboard.widgets.timers.list", root.timers)
    }

    function _now() {
        return Math.floor(Date.now() / 1000)
    }

    // ── Timer operations ────────────────────────────────────────────

    function _addTimer(name, durationMinutes) {
        const durationSec = Math.max(1, Math.round(durationMinutes * 60))
        const newTimer = {
            name: name || "Timer",
            endTime: _now() + durationSec,
            paused: false,
            duration: durationSec
        }
        root.timers = [...root.timers, newTimer]
        _saveTimers()
    }

    function _removeTimer(index) {
        const list = [...root.timers]
        list.splice(index, 1)
        root.timers = list
        _saveTimers()
    }

    function _togglePause(index) {
        const list = [...root.timers]
        const t = { ...list[index] }
        if (t.paused) {
            // Resume: extend endTime from now
            const remaining = t.endTime - _now()
            t.endTime = _now() + Math.max(0, remaining)
        } else {
            // Pause: store remaining time
            t.paused = true
            t.pausedRemaining = t.endTime - _now()
        }
        list[index] = t
        root.timers = list
        _saveTimers()
    }

    function _resetTimer(index) {
        const list = [...root.timers]
        const t = { ...list[index] }
        t.endTime = _now() + t.duration
        t.paused = false
        delete t.pausedRemaining
        list[index] = t
        root.timers = list
        _saveTimers()
    }

    function _onTimerExpired(timerName) {
        Quickshell.execDetached([
            "notify-send",
            "Timer Complete",
            timerName + " has finished!",
            "-a", "Shell",
            "-u", "normal"
        ])
    }

    // ── Format helpers ──────────────────────────────────────────────

    function _formatRemaining(endTime, paused, pausedRemaining) {
        let remaining
        if (paused) {
            remaining = Math.max(0, pausedRemaining ?? 0)
        } else {
            remaining = Math.max(0, endTime - _now())
        }
        const h = Math.floor(remaining / 3600)
        const m = Math.floor((remaining % 3600) / 60)
        const s = remaining % 60
        if (h > 0) {
            return String(h).padStart(2, "0") + ":" +
                   String(m).padStart(2, "0") + ":" +
                   String(s).padStart(2, "0")
        }
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    // ── Timer list ──────────────────────────────────────────────────

    property bool _addingTimer: false
    property string _newTimerName: ""
    property string _newTimerMinutes: "5"

    // Expired timers to clean up
    property var _expiredIndices: []

    // Check for expired timers every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const toRemove = []
            root.timers.forEach((t, i) => {
                if (!t.paused && t.endTime <= _now()) {
                    _onTimerExpired(t.name)
                    toRemove.push(i)
                }
            })
            if (toRemove.length > 0) {
                const list = root.timers.filter((_, i) => !toRemove.includes(i))
                root.timers = list
                _saveTimers()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 38
        spacing: 6

        // Timer list (scrollable)
        Flickable {
            id: listFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: timerListColumn.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: timerListColumn
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.timers

                    delegate: Rectangle {
                        id: timerItem
                        required property var modelData
                        property int index: model.index

                        width: listFlick.width
                        height: timerRow.implicitHeight + 8
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1Hover

                        ColumnLayout {
                            id: timerRow
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            // Name + time
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: timerItem.modelData.name
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Appearance.colors.colOnSurface
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: _formatRemaining(
                                        timerItem.modelData.endTime,
                                        timerItem.modelData.paused,
                                        timerItem.modelData.pausedRemaining
                                    )
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: Appearance.font.family.numbers
                                    color: timerItem.modelData.paused
                                        ? Appearance.colors.colOnSurfaceVariant
                                        : (timerItem.modelData.endTime - _now() <= 10 && !timerItem.modelData.paused)
                                            ? Appearance.colors.colError
                                            : Appearance.colors.colOnSurface
                                }
                            }

                            // Controls row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                // Play/Pause button
                                MaterialSymbol {
                                    text: timerItem.modelData.paused ? "play_arrow" : "pause"
                                    iconSize: 14
                                    color: Appearance.colors.colOnSurfaceVariant
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root._togglePause(timerItem.index)
                                    }
                                }

                                // Reset button
                                MaterialSymbol {
                                    text: "restart_alt"
                                    iconSize: 14
                                    color: Appearance.colors.colOnSurfaceVariant
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root._resetTimer(timerItem.index)
                                    }
                                }

                                // Delete button
                                MaterialSymbol {
                                    text: "close"
                                    iconSize: 14
                                    color: Appearance.colors.colOnSurfaceVariant
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root._removeTimer(timerItem.index)
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }
        }

        // Empty state hint
        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            text: "No timers yet"
            font.pixelSize: 11
            color: Appearance.colors.colOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: root.timers.length === 0 && !root._addingTimer
        }

        // Add timer form / button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root._addingTimer ? addForm.implicitHeight + 12 : 28
            radius: Appearance.rounding.normal
            color: Appearance.colors.colSurfaceContainerHighest
            clip: true

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 150 }
            }

            Column {
                id: addForm
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6
                visible: root._addingTimer

                // Name input row
                RowLayout {
                    spacing: 4

                    Text {
                        text: "Name:"
                        font.pixelSize: 10
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    TextInput {
                        id: nameInput
                        text: root._newTimerName
                        font.pixelSize: 11
                        color: Appearance.colors.colOnSurface
                        background: Rectangle {
                            anchors.fill: parent
                            color: Appearance.colors.colLayer1Hover
                            radius: 4
                        }
                        padding: 4
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        onTextChanged: root._newTimerName = text
                    }
                }

                // Duration input row
                RowLayout {
                    spacing: 4

                    Text {
                        text: "Min:"
                        font.pixelSize: 10
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    TextInput {
                        id: durationInput
                        text: root._newTimerMinutes
                        font.pixelSize: 11
                        color: Appearance.colors.colOnSurface
                        background: Rectangle {
                            anchors.fill: parent
                            color: Appearance.colors.colLayer1Hover
                            radius: 4
                        }
                        padding: 4
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 24
                        inputMethodHints: Qt.ImhDigitsOnly
                        onTextChanged: root._newTimerMinutes = text
                    }

                    Item { Layout.fillWidth: true }

                    // Cancel
                    MaterialSymbol {
                        text: "close"
                        iconSize: 14
                        color: Appearance.colors.colOnSurfaceVariant
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root._addingTimer = false
                                root._newTimerName = ""
                                root._newTimerMinutes = "5"
                            }
                        }
                    }

                    // Confirm add
                    MaterialSymbol {
                        text: "check"
                        iconSize: 14
                        color: Appearance.colors.colPrimary
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const mins = parseInt(root._newTimerMinutes) || 5
                                root._addTimer(root._newTimerName || "Timer", mins)
                                root._addingTimer = false
                                root._newTimerName = ""
                                root._newTimerMinutes = "5"
                            }
                        }
                    }
                }
            }

            // Add button (when not adding)
            Text {
                anchors.centerIn: parent
                text: "+ Add Timer"
                font.pixelSize: 11
                color: Appearance.colors.colOnSurfaceVariant
                visible: !root._addingTimer
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root._addingTimer) {
                        root._addingTimer = true
                    }
                }
            }
        }
    }
}
