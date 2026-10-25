# Validation — 1.1.0

Catalog checks cover all 13 languages, missing keys, and placeholder parity. Eighteen JavaScript checks cover POSIX locale normalization, precedence, regional codes, C/POSIX fallback, and rejection of path-shaped values.

Production-QML flows run against installed Omarchy 4.5 and official 4.0.0/4.0.4 component fixtures. They check native German/Arabic live switching, RTL state, English fallback, older-shell system-locale fallback, stable CTRL + A and scan-code reporting, autorepeat suppression, bounded eight-entry history, markup-shaped captured text, and a wl-copy command containing no report in argv. A German production-panel preview was inspected. No real keys were collected and no clipboard writes were made during testing.

Older fixtures receive only a documented Commons.Color namespace qualification to run on the current Qt version. These tests are not full older OS/Qt installations. Captured key labels and reports deliberately remain in English for troubleshooting. Native-speaker translation review and exhaustive layout review in every language remain welcome.
