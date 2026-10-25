import QtQuick
import Quickshell
import "Plugin" as Plugin
ShellRoot {
  id: testRoot
  Plugin.PluginTranslations { id: strings }
  property var languageControl: null
  Timer {
    property int phase: 0
    property int attempts: 0
    interval: 100; running: true; repeat: true
    onTriggered: {
      function check(value, message) { if (!value) throw new Error(message) }
      try {
        if (++attempts > 60) throw new Error("QML flow timed out")
        if (phase === 0) {
          if (strings.nativeAvailable) {
            languageControl = Qt.createQmlObject('import QtQuick; import qs.Commons as C; QtObject { function setLanguage(code) { C.I18n.setLanguage(code) } }', testRoot)
            languageControl.setLanguage("de")
          }
          phase++; return
        }
        if (phase === 1) {
          if (strings.t("Press a key") !== "Taste drücken") return
          if (Quickshell.env("PLUGIN_TEST_PREVIEW")) {
            panel.open()
            phase=10; return
          }
          check(panel.latest === "" && panel.history.length === 0, "initial state")
          panel.record({key: Qt.Key_A, modifiers: Qt.ControlModifier, nativeScanCode: 38, text: "a", isAutoRepeat:false})
          check(panel.latest === "CTRL + A" && panel.shortcut === "CTRL + code:38", "capture labels remain stable")
          check(panel.history.length === 1, "capture history")
          panel.record({key: Qt.Key_A, modifiers:0, nativeScanCode:38, text:"a", isAutoRepeat:true})
          check(panel.history.length === 1, "autorepeat excluded")
          panel.record({key:Qt.Key_unknown, modifiers:0, nativeScanCode:0, text:'<img src="https://example.invalid/test">', isAutoRepeat:false})
          check(panel.latest.indexOf("<img") === 0, "captured text preserved")
          function assertPlain(item) {
            if (item.textFormat !== undefined) check(item.textFormat === Text.PlainText, "captured text sink must be plain text")
            var children=item.children || []
            for(var t=0;t<children.length;++t) assertPlain(children[t])
          }
          var panelWindow=panel.data.find(function(child) { return child.contentItem !== undefined })
          check(panelWindow !== undefined,"production popup present")
          for(var t=0;t<panelWindow.contentItem.length;++t) assertPlain(panelWindow.contentItem[t])
          for (var n=0; n<12; ++n) panel.record({key:Qt.Key_B, modifiers:0, nativeScanCode:56, text:"b", isAutoRepeat:false})
          check(panel.history.length === 8, "history remains bounded")
          var clipboard = panel.data.find(function(child) { return child.command && child.command[0] === "wl-copy" })
          check(clipboard && clipboard.command.length === 1, "clipboard has no captured text in argv")
          if (!strings.nativeAvailable) {
            check(strings.language === "de-AT", "legacy system locale")
            console.log("PASS: legacy locale fallback, German UI and plugin regression checks")
            Qt.quit(); return
          }
          languageControl.setLanguage("ar"); phase++; return
        }
        if (phase === 10) {
          function findContent(obj) {
            if (obj.length !== undefined) {
              for(var j=0;j<obj.length;++j) { var f=findContent(obj[j]);if(f)return f }
              return null
            }
            if (obj.objectName === "keyInspectorContent") return obj
            var children=obj.children || []
            for(var i=0;i<children.length;++i) { var found=findContent(children[i]);if(found)return found }
            return null
          }
          var win=panel.data.find(function(child) { return child.contentItem !== undefined })
          var content=win?findContent(win.contentItem):null
          check(content !== null,"preview content")
          content.grabToImage(function(result) {
            result.saveToFile(Quickshell.env("PLUGIN_TEST_PREVIEW"))
            console.log("PASS: translated production panel preview")
            Qt.quit()
          })
          running=false; return
        }
        if (phase === 2) {
          if (!strings.rightToLeft) return
          check(strings.t("Press a key") !== "Press a key", "Arabic catalog")
          languageControl.setLanguage("is"); phase++; return
        }
        if (phase === 3) {
          if (strings.language !== "is" || strings.rightToLeft) return
          check(strings.t("Press a key") === "Press a key", "English fallback")
          console.log("PASS: native German/Arabic live switch, RTL, English fallback and plugin regression checks")
          Qt.quit()
        }
      } catch (error) { console.log("FAIL: " + error); Qt.quit() }
    }
  }
  Item {
    id: mockBar
    property color foreground: "white"
    property color urgent: "red"
    property bool foregroundAnimationEnabled: false
    property color barForeground: "white"
    property color popupForeground: "white"
    property color popupBackground: "black"
    property bool tooltipsEnabled: false
    function hideTooltip() {}
    function showTooltip() {}
    property color background: "black"
    property string fontFamily: "monospace"
    property string position: "top"
    property int barSize: 30
    property var activePopout: false
    function requestPopout(owner) { activePopout=owner }
    function releasePopout(owner) { activePopout=false }
    property var shell: null
    property bool vertical: false
    property int iconSize: 18
  }
  Plugin.Panel { id: panel; bar: mockBar; anchorItem: mockBar }
  Plugin.BarWidget { bar: mockBar }
}
