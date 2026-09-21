# Key Inspector for Omarchy

See what a key press actually sends to Omarchy. Key Inspector adds a keyboard icon to the bar and opens a focused panel that shows the latest key, modifiers, raw codes, and a short history. **Copy full report** produces a ready-to-paste description for a person or coding agent helping you create a binding.

## Install

Requires an Omarchy release with shell plugins, a Wayland compositor that supports shortcut inhibition, and `wl-copy` from `wl-clipboard` for the report button. These are available in a standard Omarchy installation.

```bash
omarchy plugin add https://github.com/Dandiccf/omarchy-key-inspector.git --enable
```

The bar widget defaults to the right section. If it is not visible, inspect the bar layout with `omarchy plugin list` and enable it with:

```bash
omarchy plugin enable io.github.dandiccf.key-inspector right
```

## Use

1. Click the keyboard icon in the Omarchy bar. The panel says **Ready** when it has focus.
2. Press a key or shortcut. The panel shows the received combination, Qt key value, native scan code, event text, and a candidate Hyprland `code:` key.
3. Press more keys to compare them. The latest eight captures remain visible.
4. Click **Copy full report** and paste the result to the person or agent helping you. Fill in the keyboard model and the label printed on the physical button; software cannot infer those from the event.

Click **Clear history** to erase the captures in the panel. Press **Esc** or click **Close** to dismiss it. The panel requests shortcut inhibition while focused, so desktop shortcuts can be inspected without running their usual actions. If the status does not say **Ready**, click inside the panel first.

### What the report contains

- The received key name and modifiers
- A candidate Hyprland binding such as `SUPER + SHIFT + code:12`
- Qt key and modifier values, native scan code, native virtual key, native modifiers, and text
- Up to eight recent captures, newest first
- Placeholders for the keyboard model and physical button label

The `code:` value is useful when a keyboard sends an unexpected key, but confirm the binding on your system before replacing an existing shortcut. A keyboard's **Fn** key can be handled entirely by its firmware. If `Fn + key` and `key` produce identical captures, Omarchy cannot assign them separate actions without a different keyboard mode or firmware mapping.

## Privacy and behavior

Key Inspector receives keys only while its panel has focus. It keeps up to eight captures in shell memory and does not write them to disk or send them over the network. Copying a report places those captures on the system clipboard, where your clipboard manager may retain them. Clear the history after inspecting sensitive keys.

The plugin changes no keyboard bindings or system configuration. Its only external command is `wl-copy` when you click **Copy full report**.

## Remove

```bash
omarchy plugin remove io.github.dandiccf.key-inspector
```

## Develop

`manifest.json` is the Omarchy plugin contract. `BarWidget.qml` provides the bar icon and loads `Panel.qml`, which captures events through Quickshell's `ShortcutInhibitor`. The plugin has no build step or install hook.

Validate a checkout before publishing or installing it:

```bash
omarchy plugin validate .
```

Key Inspector is licensed under the [MIT License](LICENSE).
