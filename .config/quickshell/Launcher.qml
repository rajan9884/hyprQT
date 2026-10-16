pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// App launcher with fuzzy matching + inline calc (=expr).
// Replaces: rofi -show drun + rofi -show calc
// IPC: qs ipc call launcher toggle|show|hide
Scope {
    id: root
    property bool showing: false
    property bool mounted: false
    property var targetScreen: Quickshell.screens[0]
    property string query: ""
    property int selected: 0
    property string calcResult: ""

    onShowingChanged: {
        if (showing) { unmountTimer.stop(); mounted = true; root.query = ""; root.selected = 0; root.calcResult = "" }
        else unmountTimer.restart()
    }
    Timer { id: unmountTimer; interval: 200; onTriggered: root.mounted = false }

    function openMenu() {
        var mon = Hyprland.focusedMonitor
        if (mon) { var scr = Quickshell.screens.find(function(s) { return s.name === mon.name }); if (scr) root.targetScreen = scr }
        root.showing = true
    }
    function closeMenu() { root.showing = false }
    function toggleMenu() { root.showing ? root.closeMenu() : root.openMenu() }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleMenu() }
        function show(): void { root.openMenu() }
        function hide(): void { root.closeMenu() }
    }

    // Fuzzy score: subsequence match, bonuses for prefix / consecutive / word-boundary
    function fuzzyScore(name, q) {
        name = name.toLowerCase(); q = q.toLowerCase()
        if (q.length === 0) return 1
        if (name.indexOf(q) === 0) return 1000 - name.length
        var si = 0, score = 0, consec = 0
        for (var i = 0; i < name.length && si < q.length; i++) {
            if (name[i] === q[si]) { score += 10 + consec * 5; if (i === 0 || name[i-1] === " " || name[i-1] === "-" || name[i-1] === "_") score += 8; consec++; si++ }
            else consec = 0
        }
        if (si < q.length) return -1
        return score - name.length * 0.1
    }

    property var filtered: {
        var q = root.query
        if (q.length > 0 && q[0] === "=") return []
        var apps = DesktopEntries.applications.values.filter(function(a) { return !a.noDisplay && !a.hidden })
        var scored = []
        for (var i = 0; i < apps.length; i++) {
            var s = root.fuzzyScore(apps[i].name + " " + (apps[i].genericName || "") + " " + (apps[i].execString || ""), q)
            if (s >= 0) scored.push({ app: apps[i], score: s })
        }
        scored.sort(function(a, b) { return b.score - a.score })
        return scored.slice(0, 12).map(function(x) { return x.app })
    }

    Process { id: calcProc }
    function runCalc(expr) {
        calcProc.command = ["sh", "-c", "qalc '" + expr.replace(/'/g, "'\\''") + "' 2>/dev/null | head -n 1 || python3 -c \"print(" + expr.replace(/"/g, '\\"') + ")\" 2>/dev/null || echo error"]
        calcProc.running = true
    }

    function launchCurrent() {
        if (root.query.length > 0 && root.query[0] === "=") { Quickshell.execDetached(["sh", "-c", "echo -n '" + root.calcResult.replace(/'/g, "'\\''") + "' | wl-copy"]); root.closeMenu(); return }
        if (root.filtered.length === 0) return
        var app = root.filtered[Math.min(root.selected, root.filtered.length - 1)]
        root.closeMenu()
        app.execute()
    }

    LazyLoader {
        id: menuLoader
        active: root.mounted
        PanelWindow {
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "launcher"
            WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: Region { item: root.showing ? card : null }
            Component.onCompleted: card.forceActiveFocus()
            MouseArea { anchors.fill: parent; onClicked: root.closeMenu() }
            Rectangle {
                id: card
                width: Math.min(560, parent.width - 80)
                height: Math.min(480, parent.height - 80)
                anchors.top: parent.top
                anchors.topMargin: Math.max(80, parent.height * 0.18)
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Theme.radius
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                focus: true
                Component.onCompleted: searchField.forceActiveFocus()
                Keys.onEscapePressed: root.closeMenu()
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Down) { if (root.filtered.length > 0) root.selected = (root.selected + 1) % root.filtered.length; event.accepted = true }
                    else if (event.key === Qt.Key_Up) { if (root.filtered.length > 0) root.selected = (root.selected - 1 + root.filtered.length) % root.filtered.length; event.accepted = true }
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.launchCurrent(); event.accepted = true }
                }
                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10
                    Item {
                        width: parent.width
                        height: 24
                        TextInput {
                            id: searchField
                            anchors.fill: parent
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            focus: true
                            // no `text: root.query` binding — it breaks typing/cursor
                            // (Loader remounts on open, so field starts empty anyway)
                            onTextChanged: { root.query = text; root.selected = 0; if (text.length > 1 && text[0] === "=") root.runCalc(text.slice(1)) }
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Down) { if (root.filtered.length > 0) root.selected = (root.selected + 1) % root.filtered.length; event.accepted = true }
                                else if (event.key === Qt.Key_Up) { if (root.filtered.length > 0) root.selected = (root.selected - 1 + root.filtered.length) % root.filtered.length; event.accepted = true }
                                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.launchCurrent(); event.accepted = true }
                                else if (event.key === Qt.Key_Escape) { root.closeMenu(); event.accepted = true }
                            }
                        }
                        Text {
                            anchors.fill: parent
                            visible: searchField.text === ""
                            text: "Type to search apps...  (=2+2 calc)"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: Theme.border }
                    Text {
                        visible: root.query.length > 0 && root.query[0] === "="
                        text: root.calcResult !== "" ? "= " + root.calcResult : "type expression, Enter copies"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                    ListView {
                        width: parent.width
                        height: parent.height - searchField.height - 40
                        clip: true
                        model: root.filtered
                        currentIndex: root.selected
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 52
                            radius: Theme.radius
                            color: index === root.selected ? Theme.alpha(Theme.accent, 0.12) : "transparent"
                            border.width: 1
                            border.color: index === root.selected ? Theme.accent : "transparent"
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 12
                                spacing: 10
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 28
                                    height: 28
                                    sourceSize: Qt.size(28, 28)
                                    source: (modelData.icon && modelData.icon !== "") ? Quickshell.iconPath(modelData.icon, true) : ""
                                    visible: status === Image.Ready
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: Theme.alpha(Theme.accent, 0.12)
                                    visible: !parent.children[0].visible
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name ? modelData.name[0].toUpperCase() : "?"
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                Column {
                                    width: parent.width - 58
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        width: parent.width
                                        text: modelData.name
                                        color: index === root.selected ? Theme.accent : Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        visible: (modelData.genericName || modelData.comment || "") !== ""
                                        text: (modelData.genericName || modelData.comment || "")
                                        color: Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { root.selected = index; root.launchCurrent() } }
                        }
                    }
                    Text { text: "fuzzy find · ↑↓ navigate · enter launch · =expr calc · esc close"; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 10 }
                }
            }
        }
    }
}
