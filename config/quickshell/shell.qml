import Quickshell
import "plugins/clipboard" as ClipboardPlugin
import "plugins/webapps" as WebappsPlugin

ShellRoot {
    VolumeOsd {}
    SysOsd {}
    NetworkPanel {}
    BluetoothPanel {}
    AudioPanel {}
    DisplayPanel {}
    ThemeCarousel {}
    Notifications {}
    PowerMenu {}
    Launcher {}
    ClipboardPlugin.Clipboard {}
    WebappsPlugin.Webapps {}
    Emoji {}
    Cheatsheet {}
    Bar {}
    Todo {}
    Wheel {}
}