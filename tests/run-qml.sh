#!/usr/bin/env bash
# Simulated input only: does not read keys or change real fingerprint enrollment.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture_dir=$(mktemp -d /tmp/plugin-i18n-qml.XXXXXX)
trap 'rm -rf -- "$fixture_dir"' EXIT
shell_source=${PLUGIN_TEST_SHELL:-/usr/share/omarchy/shell}
ln -s "$root" "$fixture_dir/Plugin"
ln -s "$shell_source/Commons" "$fixture_dir/Commons"
ln -s "$shell_source/Ui" "$fixture_dir/Ui"
cp "$root/tests/qml-ui.qml" "$fixture_dir/test.qml"
mkdir -p "$fixture_dir/config/omarchy"
LC_ALL=de_AT.UTF-8 LC_MESSAGES=fr_FR.UTF-8 LANG=es_ES.UTF-8 XDG_CONFIG_HOME="$fixture_dir/config" XDG_STATE_HOME="$fixture_dir/state" QT_QPA_PLATFORM=wayland timeout 15 qs -p "$fixture_dir/test.qml" --no-color >"$fixture_dir/test.log" 2>&1 || {
  cat "$fixture_dir/test.log"; exit 1;
}
if rg -q 'FAIL:|TypeError|ReferenceError|Failed to load configuration' "$fixture_dir/test.log" || ! rg -q 'PASS:' "$fixture_dir/test.log"; then
  cat "$fixture_dir/test.log"; exit 1
fi
rg 'PASS:' "$fixture_dir/test.log"
