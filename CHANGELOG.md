# Changelog

All notable user-facing changes should be documented here.

## 0.3.0

### Activity pills

- Added dedicated compact and expanded layouts for music, notifications, and downloads/jobs, with automatic priority-based switching between active providers.
- Expanded the MPRIS presentation with album artwork, animated audio bars, playback progress and elapsed time, plus previous, play/pause, and next controls.
- Added per-job progress, status details, and pause, resume, and cancel controls when supported by the source application.
- Added expanded keyboard-layout announcements with the full layout name, display name, and short layout code.

### Notifications

- Fixed notification images and thumbnails by supporting Plasma image data and image URLs while keeping the application icon separate.
- Added an expanded multi-line notification preview and a compact pill with an animated unread indicator.
- Added configurable notification body length, preview line count, image visibility, and popup duration.
- Kept timed-out and system-popup-dismissed notifications in Dynamic Island's history until they are closed or cleared from the applet.
- Prevented expired notifications from invoking actions that Plasma has already invalidated.

### Configuration and polish

- Added a General configuration page with independent toggles for music, notification, job, and keyboard-layout activity providers.
- Added configurable durations for notification popups and other ongoing announcements.
- Kept floating popups within the nearest screen's bounds, including when the widget is placed near an edge, without changing the morph animation's origin.
- Made applet-owned labels, menus, checkboxes, and spin boxes follow KDE Plasma's configured font family across regular, demi-bold, and bold text.
- Removed the unsupported `shadowEnabled` property for Plasma 6 compatibility.

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
