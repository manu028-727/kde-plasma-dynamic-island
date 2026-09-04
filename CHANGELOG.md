# Changelog

All notable user-facing changes should be documented here.

## 0.2.2

- Test release to validate the CI packaging workflow.

## 0.2.1

- Improved compatibility for newer Plasma versions

## 0.2.0

- Split the control center editor into its own QML component while keeping the tile renderer in the main island file.
- Moved control center tile bodies into dedicated QML components under `contents/ui/controlcenter/`.
- Extracted control center module metadata, default layout, icons, and size limits into a shared registry.
- Improved control center tile states, compact behavior, notification row sizing, slider feedback, and network/Bluetooth/power summaries.
- Added richer control center connectivity data for wired/Wi-Fi details, IP addresses, Bluetooth adapter/devices, and KDE Connect devices. Improved Notifications and KDE Connect tiles with richer rows, app/device details, quick actions, safer empty states, clearer live state, overflow hints, and compact-friendly quick actions.
- Fixed activity popup routing so new notifications and jobs are not masked by an active media player.
- Fixed the KDE Connect tile trying to open the KCM instead of the app.
- Added an optional Plasma Layout Template panel preset for manual/GitHub installs, including a 50 px centered top panel and Panel Colorizer setup when available.
- Removed unintended accent glow from icon-only and launcher-style control center tiles.
- Fixed the Wi-Fi networks tile showing a tiny signal fill bar when no signal value is available.
- Hardened control-center drag handling, notification row closing, and media button actions against stale runtime objects.
- Hardened control-center grid geometry against invalid host items, tiny popup widths, and non-finite placement values.
- Hardened brightness, volume, progress, Wi-Fi parsing, and layout math against malformed or delayed runtime data.
- Improved edit-mode mouse handling to reduce scroll/drag conflicts.
- Updated the fallback control center layout to match the polished release layout.

## 0.1.2

- Control center edit mode now keeps layout changes in a draft until Save is pressed.
- Added Cancel and Reset-to-default-draft actions for safer layout editing.
- Added a reserved-space preview while dragging tiles in the editable grid.

## 0.1.1

- Improved Dynamic Island sizing, popup positioning, media controls, and morph animation behavior.
- Added modular JSON-backed control center editing with draggable and resizable tiles.
- Added control center modules for user/power, media, notifications, volume, brightness, Wi-Fi, Bluetooth, battery, power mode, appearance, Theme, KDE Connect, and Settings.

## 0.1.0

- Initial public KDE Plasma 6 Dynamic Island widget release.
