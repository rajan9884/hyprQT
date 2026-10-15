pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Theme carousel — replaces SettingsPages/ThemesPage.
// Shortcut: Super+Ctrl+Shift+Space -> qs ipc call themes toggle
// Keys: H/Left + L/Right navigate, Enter/Space apply, 1-9/0 quick-apply,
//       C colorgen toggle, M dark/light toggle, Esc/Q close.
Scope {
    id: root
    property bool showing: false
    property bool mounted: false
    property var targetScreen: Quickshell.screens[0]
    property int selected: 0
    property bool colorGen: true
    property bool darkMode: true

    readonly property var themes: [
        { label: "DEFAULT", command: "default" },
        { label: "WHITE", command: "preset white" },
        { label: "METAL", command: "preset metal" },
        { label: "SLATE", command: "preset slate" },
        { label: "LIGHT GRAY", command: "preset light-gray" },
        { label: "BEIGE", command: "preset beige" },
        { label: "SILVER", command: "preset silver" },
        { label: "GOLD", command: "preset gold" },
        { label: "NORD", command: "preset nord" },
        { label: "TOKYO NIGHT", command: "preset tokyo-night" },
        { label: "CATPPUCCIN MOCHA", command: "preset catppuccin-mocha" },
        { label: "EVERFOREST DARK", command: "preset everforest-dark" },
        { label: "DRACULA", command: "preset dracula" },
        { label: "ONE DARK", command: "preset one-dark" },
        { label: "KANAGAWA", command: "preset kanagawa" },
        { label: "ROSE PINE", command: "preset rose-pine" },
        { label: "RED", command: "preset red" },
        { label: "MATRIX", command: "preset matrix" }
    ]

    function runTheme(cmd) {
        Quickshell.execDetached(["/bin/sh", "-c",
            "python3 \"$HOME/.config/43pr/bin/theme.py\" " + cmd])
        reloadTimer.restart()
    }
    function setColorGen(on) {
        root.colorGen = on
        runTheme("colorgen " + (on ? "on" : "off"))
    }
    function toggleMode() {
        root.darkMode = !root.darkMode
        runTheme("toggle")
    }
    function apply(i) {
        if (i < 0 || i >= themes.length) return
        runTheme(themes[i].command)
    }
    function move(d) {
        var n = themes.length
        root.selected = (root.selected + d + n) % n
    }

    FileView {
        id: stateView
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/43pr/state.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.colorGen = stateAdapter.colorgen
                root.darkMode = stateAdapter.mode_appearance !== "light"
            } catch (e) {}
        }
        adapter: JsonAdapter {
            id: stateAdapter
            property bool colorgen: true
            property string mode_appearance: "dark"
        }
    }
    Timer { id: reloadTimer; interval: 700; onTriggered: stateView.reload() }

    onShowingChanged: {
        if (showing) { unmountTimer.stop(); mounted = true }
        else unmountTimer.restart()
    }
    Timer { id: unmountTimer; interval: 200; onTriggered: root.mounted = false }

    function openMenu() {
        var mon = Hyprland.focusedMonitor
        if (mon) {
            var scr = Quickshell.screens.find(function (s) { return s.name === mon.name })
            if (scr) root.targetScreen = scr
        }
        root.selected = 0
        root.showing = true
    }
    function closeMenu() { root.showing = false }
    function toggleMenu() { root.showing ? root.closeMenu() : root.openMenu() }

    IpcHandler {
        target: "themes"
        function toggle(): void { root.toggleMenu() }
        function show(): void { root.openMenu() }
        function hide(): void { root.closeMenu() }
        function next(): void { root.move(1) }
        function prev(): void { root.move(-1) }
        function applyIndex(i: int): void { root.apply(i) }
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
            WlrLayershell.namespace: "themes"
            WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: Region { item: root.showing ? bar : null }
            Component.onCompleted: bar.forceActiveFocus()

            MouseArea { anchors.fill: parent; onClicked: root.closeMenu() }

            Rectangle {
                id: bar
                width: Math.min(900, parent.width - 60)
                height: 190
                anchors.centerIn: parent
                radius: Theme.radius
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                focus: true
                Keys.onPressed: function (event) {
                    var k = event.key
                    if (k === Qt.Key_Escape || k === Qt.Key_Q) { root.closeMenu(); event.accepted = true }
                    else if (k === Qt.Key_Left || k === Qt.Key_H) { root.move(-1); event.accepted = true }
                    else if (k === Qt.Key_Right || k === Qt.Key_L) { root.move(1); event.accepted = true }
                    else if (k === Qt.Key_Return || k === Qt.Key_Space) { root.apply(root.selected); event.accepted = true }
                    else if (k === Qt.Key_C) { root.setColorGen(!root.colorGen); event.accepted = true }
                    else if (k === Qt.Key_M) { root.toggleMode(); event.accepted = true }
                    else if (k >= Qt.Key_1 && k <= Qt.Key_9) { root.apply(k - Qt.Key_1); event.accepted = true }
                    else if (k === Qt.Key_0) { root.apply(9); event.accepted = true }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - 40
                            text: "THEMES  ·  " + (root.colorGen ? "COLORGEN ON" : "COLORGEN OFF") + "  ·  " + (root.darkMode ? "DARK" : "LIGHT")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "×"
                            color: Theme.textDim
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.closeMenu() }
                        }
                    }
                    ListView {
                        id: strip
                        width: parent.width
                        height: 84
                        orientation: ListView.Horizontal
                        model: root.themes
                        spacing: 8
                        clip: true
                        currentIndex: root.selected
                        highlightMoveDuration: 120
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Center)
                        Component.onCompleted: positionViewAtBeginning()
                        Connections { target: root; function onSelectedChanged() { strip.currentIndex = root.selected; strip.positionViewAtIndex(root.selected, ListView.Center) } }
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 150
                            height: 84
                            radius: Theme.radius
                            color: index === root.selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "transparent"
                            border.width: 1
                            border.color: index === root.selected ? Theme.accent : Theme.border
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (index + 1 > 10) ? "·" : (index + 1) + ""
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                                Text {
                                    width: 134
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    text: modelData.label
                                    color: index === root.selected ? Theme.text : Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: index === root.selected
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selected = index
                                onClicked: root.apply(index)
                            }
                        }
                    }
                    Text {
                        text: "h/l ←/→ move · enter apply · 1-9/0 quick · c colorgen · m mode · esc/q close"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
