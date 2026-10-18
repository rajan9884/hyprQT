pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Global opacity menu (SUPER+O). Port of scripts/opacity.sh's rofi dmenu
// (whose later qmlscene rework could never return a selection — it is gone).
// Picking a value runs quickshell/scripts/opacity-apply.sh, which applies
// everywhere at once:
//   - first `opacity = ".* override"` window rule in hypr/rules.lua
//   - saved state files of surfaces with their own stored opacity:
//       bar-state.json bgOpacity, powermenu-state.json panelOpacity/itemOpacity,
//       mediaosd-state.json bgOpacity
//   - quickshell Theme.qml bgAlpha (persisted for the next cold start)
// Applying also assigns Theme.bgAlpha in the running shell directly: the live
// config files are symlinks into the repo, so a write to Theme.qml does NOT
// trigger quickshell's hot-reload. Without the in-process assignment the new
// value would only appear after a manual shell restart and the menu tick would
// stay frozen at the startup value.
// then reloads Hyprland for the rules change.
// IPC: qs ipc call opacity toggle|show|hide
//      qs ipc call opacity apply 0|40|50|60|70|80|90|100
Scope {
    id: root
    property bool showing: false
    property bool mounted: false
    property var targetScreen: Quickshell.screens[0]

    readonly property var choices: [100, 90, 80, 70, 60, 50, 40]
    // Live quickshell-side value (compiled into Theme.qml at qs start)
    readonly property int currentPct: Math.round(Theme.bgAlpha * 100)

    onShowingChanged: {
        if (showing) { unmountTimer.stop(); mounted = true; root.selected = root.choices.indexOf(root.currentPct) }
        else unmountTimer.restart()
    }
    Timer { id: unmountTimer; interval: 200; onTriggered: root.mounted = false }
    property int selected: -1

    function openMenu() {
        var mon = Hyprland.focusedMonitor
        if (mon) {
            var scr = Quickshell.screens.find(function (s) { return s.name === mon.name })
            if (scr) root.targetScreen = scr
        }
        root.selected = root.choices.indexOf(root.currentPct)
        root.showing = true
    }
    function closeMenu() { root.showing = false }
    function toggleMenu() { root.showing ? root.closeMenu() : root.openMenu() }
    function confirmCurrent() {
        if (root.selected >= 0) root.apply(root.choices[root.selected])
        else root.closeMenu()
    }

    IpcHandler {
        target: "opacity"
        function toggle(): void { root.toggleMenu() }
        function open(): void { root.openMenu() }
        function show(): void { root.openMenu() } // NOTE: unreachable via the qs CLI (subcommand clash); use `open`
        function hide(): void { root.closeMenu() }
        function apply(pct: int): void {
            if (root.choices.indexOf(pct) < 0 && pct !== 0) return
            if (pct === 0) pct = 100
            root.run(pct)
        }
    }

    // ── apply chain (scripts/opacity-apply.sh) ──────────────────────
    // The script persists everything (window rules, Theme.qml, the surfaces'
    // own state files) for the next cold start. The live shell is updated
    // in-process here, since the symlinked Theme.qml write does not hot-reload.
    function apply(pct) { root.run(pct) }

    function run(pct) {
        // Live update: every surface bound to Theme.bg follows immediately and
        // currentPct (the tick) stays correct without a shell restart.
        Theme.bgAlpha = pct / 100
        Quickshell.execDetached({
            command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/opacity-apply.sh", String(pct)]
        })
        root.closeMenu()
    }

    LazyLoader {
        active: root.mounted
        PanelWindow {
            id: win
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "opacity"

            WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: Region { item: root.showing ? card : null }

            Component.onCompleted: card.forceActiveFocus()
            MouseArea { anchors.fill: parent; onClicked: root.closeMenu() }

            Rectangle {
                id: card
                width: Math.min(320, parent.width - 80)
                height: Math.min(root.choices.length * 44 + 92, parent.height - 80)
                anchors.centerIn: parent
                radius: Theme.radius
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                focus: true
                Keys.onEscapePressed: root.closeMenu()
                Keys.onPressed: function (event) {
                    var n = root.choices.length
                    if (event.key === Qt.Key_Q) { root.closeMenu(); event.accepted = true }
                    else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        root.selected = root.selected < 0 ? 0 : (root.selected + 1) % n; event.accepted = true
                    }
                    else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        root.selected = root.selected < 0 ? n - 1 : (root.selected - 1 + n) % n; event.accepted = true
                    }
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.confirmCurrent(); event.accepted = true
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        width: parent.width
                        text: "OPACITY"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        font.letterSpacing: 3
                    }
                    Rectangle { width: parent.width; height: 1; color: Theme.border }

                    Repeater {
                        model: root.choices

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool active: root.currentPct === modelData
                            readonly property bool focused: root.selected === index
                            width: parent.width
                            height: 36
                            radius: Theme.radius
                            color: focused ? Theme.alpha(Theme.accent, 0.12) : "transparent"
                            border.width: 1
                            border.color: focused ? Theme.accent : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.active ? "\udb80\udd2c" : " "
                                    color: Theme.accent
                                    font.family: Theme.iconFont
                                    font.pixelSize: 13
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 20
                                    text: row.modelData + "%"
                                    color: row.active ? Theme.accent : Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: row.focused
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: root.selected = row.index
                                onClicked: root.apply(row.modelData)
                            }
                        }
                    }

                    Text {
                        text: "↑↓ select · enter apply · esc close"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
