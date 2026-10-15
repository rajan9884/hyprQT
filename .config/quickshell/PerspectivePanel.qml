// PerspectivePanel.qml — static panel (no tilt / pop / fade animations).
// Kept as a thin wrapper so existing callers (SettingsWindow) keep working:
// all animation-related properties are accepted but ignored.
import QtQuick
Item {
    id: root

    default property alias content: contentContainer.data
    property bool open: false
    property real tiltStrength: 0
    property real parallaxX: 0
    property real parallaxY: 0

    // ---- optional knobs; kept for API compatibility, all ignored ------
    property int fadeDuration: 0
    property int popDuration: 0
    property int tiltDuration: 0
    property int popEasing: Easing.Linear
    property real closedScale: 1.0

    property bool cacheContent: false
    property bool prewarm: false

    opacity: open ? 1 : 0
    visible: open

    // No Behavior on opacity, no transform scale/rotation, no HoverHandler:
    // the panel is fully static — it just appears / disappears.

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}