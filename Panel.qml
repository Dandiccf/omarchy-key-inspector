import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.dandiccf.key-inspector"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var history: []
  property string latest: "Press a key"
  property string detail: "The key and modifiers will appear here."
  property string shortcut: ""
  property string copyStatus: ""
  property string latestRaw: ""

  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.controller.show()
    Qt.callLater(function() { keyCapture.forceActiveFocus() })
  }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }

  function copyReport() {
    if (!shortcut) return
    var report = "Omarchy Key Inspector report\n"
      + "Keyboard model: [enter model if known]\n"
      + "Physical button: [describe the printed key when sending this report]\n\n"
      + "Latest capture\n"
      + "Received: " + latest + "\n"
      + "Hyprland key: " + shortcut + "\n"
      + latestRaw + "\n\n"
      + "Recent captures (newest first)\n"
      + history.join("\n") + "\n\n"
      + "Note: Fn may be handled inside the keyboard. Identical captures cannot be bound separately in Omarchy."
    Quickshell.execDetached(["wl-copy", report])
    copyStatus = "Full report copied"
    keyCapture.forceActiveFocus()
  }

  function keyName(event) {
    var k = event.key
    if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k)
    if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
    if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return "F" + (k - Qt.Key_F1 + 1)
    var names = {}
    names[Qt.Key_Left] = "Left Arrow"
    names[Qt.Key_Right] = "Right Arrow"
    names[Qt.Key_Up] = "Up Arrow"
    names[Qt.Key_Down] = "Down Arrow"
    names[Qt.Key_Print] = "Print Screen"
    names[Qt.Key_Insert] = "Insert"
    names[Qt.Key_Delete] = "Delete"
    names[Qt.Key_Home] = "Home"
    names[Qt.Key_End] = "End"
    names[Qt.Key_PageUp] = "Page Up"
    names[Qt.Key_PageDown] = "Page Down"
    names[Qt.Key_Pause] = "Pause"
    names[Qt.Key_ScrollLock] = "Scroll Lock"
    names[Qt.Key_NumLock] = "Num Lock"
    names[Qt.Key_MonBrightnessDown] = "Screen Brightness Down"
    names[Qt.Key_MonBrightnessUp] = "Screen Brightness Up"
    names[Qt.Key_KeyboardBrightnessDown] = "Keyboard Brightness Down"
    names[Qt.Key_KeyboardBrightnessUp] = "Keyboard Brightness Up"
    names[Qt.Key_Search] = "Search"
    names[Qt.Key_MediaPrevious] = "Previous Track"
    names[Qt.Key_MediaPlay] = "Media Play"
    names[Qt.Key_MediaPause] = "Media Pause"
    names[Qt.Key_MediaTogglePlayPause] = "Play / Pause"
    names[Qt.Key_MediaNext] = "Next Track"
    names[Qt.Key_MediaStop] = "Media Stop"
    names[Qt.Key_VolumeMute] = "Mute"
    names[Qt.Key_VolumeDown] = "Volume Down"
    names[Qt.Key_VolumeUp] = "Volume Up"
    names[Qt.Key_Calculator] = "Calculator"
    names[Qt.Key_Menu] = "Menu"
    names[Qt.Key_Escape] = "Escape"
    names[Qt.Key_Tab] = "Tab"
    names[Qt.Key_Backtab] = "Tab"
    names[Qt.Key_Backspace] = "Backspace"
    names[Qt.Key_Return] = "Return"
    names[Qt.Key_Enter] = "Numpad Enter"
    names[Qt.Key_Space] = "Space"
    names[Qt.Key_CapsLock] = "Caps Lock"
    names[Qt.Key_AltGr] = "AltGr"
    names[Qt.Key_Shift] = "Shift"
    names[Qt.Key_Control] = "Ctrl"
    names[Qt.Key_Alt] = "Alt"
    names[Qt.Key_Meta] = "Super"
    return names[k] || (event.text ? event.text : "Qt key " + k)
  }

  function optionalNative(value) {
    return value === undefined || value === null ? "(not provided)" : String(value)
  }

  function modifierNames(mask) {
    var names = []
    if (mask & Qt.MetaModifier) names.push("SUPER")
    if (mask & Qt.ControlModifier) names.push("CTRL")
    if (mask & Qt.AltModifier) names.push("ALT")
    if (mask & Qt.ShiftModifier) names.push("SHIFT")
    if (mask & Qt.GroupSwitchModifier) names.push("ALTGR")
    return names
  }

  function record(event) {
    if (event.isAutoRepeat) return
    var key = keyName(event)
    if (key === "Super" || key === "Ctrl" || key === "Alt" || key === "Shift" || key === "AltGr") return
    var parts = modifierNames(event.modifiers)
    parts.push(key)
    latest = parts.join(" + ")
    shortcut = modifierNames(event.modifiers).concat(["code:" + event.nativeScanCode]).join(" + ")
    copyStatus = ""
    latestRaw = "Qt key: " + event.key
      + "\nQt modifiers: " + event.modifiers
      + "\nNative scan code: " + event.nativeScanCode
      + "\nNative virtual key: " + optionalNative(event.nativeVirtualKey)
      + "\nNative modifiers: " + optionalNative(event.nativeModifiers)
      + "\nText: " + (event.text ? JSON.stringify(event.text) : "(none)")
    detail = "Qt key " + event.key + "    scan " + event.nativeScanCode
      + "    text " + (event.text ? JSON.stringify(event.text) : "—")
    history = [latest + " | " + shortcut + " | " + detail].concat(history).slice(0, 8)
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCapture
    contentWidth: panel.fittedContentWidth(Style.space(650))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Item {
      id: keyCapture
      width: parent.width
      implicitHeight: content.implicitHeight
      height: implicitHeight
      focus: true

      ShortcutInhibitor {
        id: inhibitor
        window: panel
        enabled: root.opened && keyCapture.activeFocus
      }

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier)
          root.close()
        else
          root.record(event)
        event.accepted = true
      }

      MouseArea {
        anchors.fill: parent
        onClicked: keyCapture.forceActiveFocus()
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        Row {
          width: parent.width
          spacing: Style.space(10)
          Text {
            text: "⌨  Key Inspector"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
          Text {
            text: inhibitor.active ? "Ready" : "Click here to focus"
            color: inhibitor.active ? Color.accent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Text {
          width: parent.width
          text: "Press a key to see what Omarchy receives. Shortcuts are paused while this panel has focus."
          color: root.foreground
          opacity: 0.75
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Rectangle { width: parent.width; height: 1; color: root.foreground; opacity: 0.2 }

        Text {
          width: parent.width
          text: root.latest
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
          font.bold: true
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: root.detail
          color: root.foreground
          opacity: 0.7
          font.family: "monospace"
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: "Hyprland: " + root.shortcut
          color: root.foreground
          font.family: "monospace"
          font.pixelSize: Style.font.subtitle
          visible: root.shortcut !== ""
          elide: Text.ElideRight
        }

        Rectangle { width: parent.width; height: 1; color: root.foreground; opacity: 0.2 }
        Text {
          text: "RECENT KEYS"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        Repeater {
          model: root.history
          Text {
            required property string modelData
            width: content.width
            text: modelData
            color: root.foreground
            font.family: "monospace"
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }

        Text {
          width: parent.width
          text: "Fn can stay inside the keyboard. If two presses show the same result here, Omarchy cannot bind them separately."
          color: root.foreground
          opacity: 0.65
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Row {
          spacing: Style.space(16)
          Text {
            text: root.copyStatus || "Copy full report"
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea { anchors.fill: parent; onClicked: root.copyReport() }
          }
          Text {
            text: "Clear history"
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea {
              anchors.fill: parent
              onClicked: {
                root.history = []
                root.latest = "Press a key"
                root.detail = "The key and modifiers will appear here."
                root.shortcut = ""
                root.latestRaw = ""
                root.copyStatus = ""
                keyCapture.forceActiveFocus()
              }
            }
          }
          Text {
            text: "Close (Esc)"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea { anchors.fill: parent; onClicked: root.close() }
          }
        }
      }
    }
  }
}
