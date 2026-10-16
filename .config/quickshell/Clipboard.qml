pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Clipboard history via cliphist. Replaces rofi clipboard.sh + menu-clipboard.
// IPC: qs ipc call clipboard toggle|show|hide
Scope {
    id: root
    property bool showing: false
    property bool mounted: false
    property var targetScreen: Quickshell.screens[0]
    property string query: ""
    property int selected: 0
    property var entries: []

    onShowingChanged: { if (showing) { unmountTimer.stop(); mounted = true; root.query = ""; root.selected = 0; pList.running = true } else unmountTimer.restart() }
    Timer { id: unmountTimer; interval: 200; onTriggered: root.mounted = false }

    function openMenu() {
        var mon = Hyprland.focusedMonitor
        if (mon) { var scr = Quickshell.screens.find(function(s) { return s.name === mon.name }); if (scr) root.targetScreen = scr }
        root.showing = true
    }
    function closeMenu() { root.showing = false }
    function toggleMenu() { root.showing ? root.closeMenu() : root.openMenu() }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggleMenu() }
        function show(): void { root.openMenu() }
        function hide(): void { root.closeMenu() }
    }

    Process {
        id: pList
        command: ["sh", "-c", "cliphist list | head -n 50"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue
                    var tab = lines[i].indexOf("\t")
                    if (tab < 0) continue
                    out.push({ id: lines[i].slice(0, tab).trim(), preview: lines[i].slice(tab + 1).slice(0, 160) })
                }
                root.entries = out
            }
        }
    }
    Process { id: pCopy }
    function pasteEntry(e, copyOnly) {
        var cmd = "cliphist decode '" + e.id.replace(/'/g, "'\\''") + "' | wl-copy" + (copyOnly ? "" : " && wtype -M shift -k Insert -m shift 2>/dev/null || true")
        pCopy.command = ["sh", "-c", cmd]
        pCopy.running = true
        root.closeMenu()
    }
    function wipe() { pCopy.command = ["sh", "-c", "cliphist wipe"]; pCopy.running = true; root.entries = []; root.closeMenu() }

    property var filtered: root.entries.filter(function(e) { return root.query === "" || e.preview.toLowerCase().indexOf(root.query.toLowerCase()) >= 0 }).slice(0, 20)

    LazyLoader {
        active: root.mounted
        PanelWindow {
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "clipboard"
            WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: Region { item: root.showing ? card : null }
            MouseArea { anchors.fill: parent; onClicked: root.closeMenu() }
            Rectangle {
                id: card
                width: Math.min(850, parent.width - 80)
                height: Math.min(500, parent.height - 80)
                anchors.centerIn: parent
                radius: Theme.radius
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                focus: true
                Keys.onEscapePressed: root.closeMenu()
                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10
                    Text { text: "CLIPBOARD"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true; font.letterSpacing: 3 }
                    Rectangle { width: parent.width; height: 1; color: Theme.border }
                    TextInput {
                        width: parent.width
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        focus: true
                        text: root.query
                        onTextChanged: { root.query = text; root.selected = 0 }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Down) { if (root.filtered.length > 0) root.selected = (root.selected + 1) % root.filtered.length; event.accepted = true }
                            else if (event.key === Qt.Key_Up) { if (root.filtered.length > 0) root.selected = (root.selected - 1 + root.filtered.length) % root.filtered.length; event.accepted = true }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { if (root.filtered.length > 0) root.pasteEntry(root.filtered[Math.min(root.selected, root.filtered.length - 1)], (event.modifiers & Qt.ControlModifier)); event.accepted = true }
                            else if (event.key === Qt.Key_Escape) { root.closeMenu(); event.accepted = true }
                        }
                    }
                    ListView {
                        width: parent.width
                        height: parent.height - 140
                        clip: true
                        model: root.filtered
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 36
                            radius: 6
                            color: index === root.selected ? Theme.alpha(Theme.accent, 0.12) : "transparent"
                            border.width: 1
                            border.color: index === root.selected ? Theme.accent : "transparent"
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.preview
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.pasteEntry(modelData, false) }
                        }
                    }
                    Row {
                        width: parent.width
                        spacing: 16
                        Text { text: "enter paste · ctrl+enter copy · esc close"; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        Text {
                            text: "WIPE ALL"
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.wipe() }
                        }
                    }
                }
            }
        }
    }
}
