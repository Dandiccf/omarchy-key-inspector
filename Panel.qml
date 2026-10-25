import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  PluginTranslations { id: strings }
  moduleName: "io.github.dandiccf.key-inspector"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var history: []
  property string latest: ""
  property string detail: ""
  property string shortcut: ""
  property string copyStatus: ""
  property string latestRaw: ""

  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.controller.show()
    Qt.callLater(function() { keyCapture.forceActiveFocus() })
  }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }

  function copyReport() {
    if (!shortcut || clipboardProcess.running) return
    var report = "Omarchy Key Inspector report\n"
      + "Keyboard model (optional): [enter if known]\n"
      + "Printed key label (optional): [describe if useful]\n\n"
      + "Latest capture\n"
      + "Received: " + latest + "\n"
      + "Hyprland key: " + shortcut + "\n"
      + latestRaw + "\n\n"
      + "Recent captures (newest first)\n"
      + history.join("\n") + "\n\n"
      + "Note: Fn may be handled inside the keyboard. Identical captures cannot be bound separately in Omarchy."
    clipboardProcess.report = report
    clipboardProcess.running = true
    copyStatus = "Copying report…"
    keyCapture.forceActiveFocus()
  }

  Process {
    id: clipboardProcess
    command: ["wl-copy"]
    stdinEnabled: true
    property string report: ""

    onStarted: {
      write(report)
      report = ""
      stdinEnabled = false
    }
    onExited: function(exitCode) {
      stdinEnabled = true
      root.copyStatus = exitCode === 0 ? "Full report copied" : "Could not copy report"
    }
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
    names[Qt.Key_Dead_Circumflex] = "Circumflex (dead key)"
    names[Qt.Key_AsciiCircum] = "Circumflex (^)"
    names[Qt.Key_degree] = "Degree (°)"
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
    names[Qt.Key_Enter] = "Enter"
    names[Qt.Key_Space] = "Space"
    names[Qt.Key_CapsLock] = "Caps Lock"
    names[Qt.Key_AltGr] = "AltGr"
    names[Qt.Key_Shift] = "Shift"
    names[Qt.Key_Control] = "Ctrl"
    names[Qt.Key_Alt] = "Alt"
    names[Qt.Key_Meta] = "Super"
    if (names[k]) return names[k]
    if (event.text) return event.text
    var enumName = qtEnumName(k)
    return enumName ? enumName.replace(/^Key_/, "").replace(/_/g, " ")
      .replace(/([a-z0-9])([A-Z])/g, "$1 $2") : "Qt key " + k
  }

  function qtEnumName(key) {
    if (typeof Qt.enumValueToString !== "function") return ""
    try { return Qt.enumValueToString(Qt.Key, key) }
    catch (error) { return "" }
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
      + "\nQt enum: " + (qtEnumName(event.key) || "(not found)")
      + "\nQt modifiers: " + event.modifiers
      + "\nNative scan code: " + event.nativeScanCode
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
      LayoutMirroring.enabled: strings.rightToLeft
      LayoutMirroring.childrenInherit: true
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
        objectName: "keyInspectorContent"
        width: parent.width
        spacing: Style.space(10)

        Row {
          width: parent.width
          spacing: Style.space(10)
          Text { textFormat: Text.PlainText;
            text: "⌨  Key Inspector"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
          Text { textFormat: Text.PlainText;
            text: inhibitor.active ? strings.t("Ready") : strings.t("Click here to focus")
            color: inhibitor.active ? Commons.Color.accent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Text { textFormat: Text.PlainText;
          width: parent.width
          text: strings.t("Press a key to see what Omarchy receives. Shortcuts are paused while this panel has focus.")
          color: root.foreground
          opacity: 0.75
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Rectangle { width: parent.width; height: 1; color: root.foreground; opacity: 0.2 }

        Text { textFormat: Text.PlainText;
          width: parent.width
          text: root.latest || strings.t("Press a key")
          color: Commons.Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
          font.bold: true
          elide: Text.ElideRight
        }
        Text { textFormat: Text.PlainText;
          width: parent.width
          text: root.detail || strings.t("The key and modifiers will appear here.")
          color: root.foreground
          opacity: 0.7
          font.family: "monospace"
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
        Text { textFormat: Text.PlainText;
          width: parent.width
          text: "Hyprland: " + root.shortcut
          color: root.foreground
          font.family: "monospace"
          font.pixelSize: Style.font.subtitle
          visible: root.shortcut !== ""
          elide: Text.ElideRight
        }

        Rectangle { width: parent.width; height: 1; color: root.foreground; opacity: 0.2 }
        Text { textFormat: Text.PlainText;
          text: strings.t("RECENT KEYS")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        Repeater {
          model: root.history
          Text { textFormat: Text.PlainText;
            required property string modelData
            width: content.width
            text: modelData
            color: root.foreground
            font.family: "monospace"
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }

        Text { textFormat: Text.PlainText;
          width: parent.width
          text: strings.t("Fn can stay inside the keyboard. If two presses show the same result here, Omarchy cannot bind them separately.")
          color: root.foreground
          opacity: 0.65
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Row {
          spacing: Style.space(16)
          Text { textFormat: Text.PlainText;
            text: strings.t(root.copyStatus || strings.t("Copy full report"))
            color: Commons.Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea { anchors.fill: parent; onClicked: root.copyReport() }
          }
          Text { textFormat: Text.PlainText;
            text: strings.t("Clear history")
            color: Commons.Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea {
              anchors.fill: parent
              onClicked: {
                root.history = []
                root.latest = ""
                root.detail = ""
                root.shortcut = ""
                root.latestRaw = ""
                root.copyStatus = ""
                keyCapture.forceActiveFocus()
              }
            }
          }
          Text { textFormat: Text.PlainText;
            text: strings.t("Close (Esc)")
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
