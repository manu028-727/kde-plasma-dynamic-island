<p align="center">
  <img src="assets/readme-banner.svg" alt="Dynamic Island for KDE Plasma 6">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/KDE%20Plasma-6-1d99f3?style=for-the-badge&logo=kde&logoColor=white" alt="KDE Plasma 6">
  <img src="https://img.shields.io/badge/Status-Alpha-f59e0b?style=for-the-badge" alt="Alpha status">
  <img src="https://img.shields.io/badge/License-GPL--3.0--or--later-22c55e?style=for-the-badge" alt="GPL-3.0-or-later license">
</p>

A KDE Plasma 6 widget inspired by the iOS/macOS Dynamic Island: a compact black pill for live activity plus a dark floating control-center popup.

## Alpha Warning

This applet is currently in an alpha state. It is usable, but bugs, visual glitches, missing edge cases, or Plasma-version-specific issues may happen while the widget is still evolving.

## Features

- Real MPRIS media controls: previous, play/pause, next, album art, track/artist, progress, and player volume when exposed.
- Plasma notification integration using `org.kde.notificationmanager`.
- Job/download activity progress with pause/resume/cancel when the source job supports it.
- Compact textless panel pill with black glass styling, masked album art, and quick pulse feedback for new activity.
- New activity opens a temporary floating activity popup for about 3 seconds.
- Single-click idle opens the control center popup; single-click during activity reopens the activity popup; double-click opens control center.
- Middle-click toggles media playback.
- Scroll over the island to adjust the active player's volume.
- Control center includes an adaptive activity summary, media controls, volume, brightness, keyboard brightness, passive wired-network status, battery state, KDE Connect, Bluetooth, display/settings shortcuts, and power actions where supported by KDE.

## Install

From this folder:

```bash
kpackagetool6 --type Plasma/Applet --install .
```

If you reinstall after edits:

```bash
kpackagetool6 --type Plasma/Applet --upgrade .
```

Then add **Dynamic Island** from Plasma's widget picker.

## Intended Panel Setup

Dynamic Island is designed to sit by itself on a fully transparent, always on top, floating Plasma panel whose width is set to fit its contents. For the intended look and behavior, make the panel content-wide, enable floating mode, remove any panel background/opacity, and keep Dynamic Island as the only widget on that panel.

## Notes

This targets Plasma 6 and uses the modules available on this machine:

- `org.kde.plasma.private.mpris`
- `org.kde.notificationmanager`
- `org.kde.plasma.plasmoid`
- `org.kde.plasma.private.brightnesscontrolplugin`
- `org.kde.plasma.private.batterymonitor`
- `org.kde.plasma.private.battery`
- `org.kde.plasma.private.volume`
- `org.kde.plasma.networkmanagement`

Downloads appear when the app reports them as Plasma jobs, such as file copies or browser/download integrations that use KDE notifications.

## License

This project is licensed under the **GNU General Public License v3.0 or later** (GPL-3.0-or-later). The complete license text is available in [LICENSE](LICENSE) and on the [GNU website](https://www.gnu.org/licenses/gpl-3.0.html).

In practical terms, the GPL allows you to:

- Use the widget for any purpose, including personal or commercial use.
- Study how it works and modify the QML or other project files.
- Make and share copies of the original project.
- Share modified versions, including as part of another project.

If you distribute the original or a modified version, you must keep the GPL license and copyright notices, provide recipients with the corresponding source code (or a valid written offer for it), and license the distributed work under the GPL. You should also state clearly what you changed. The license does not require you to publish private modifications that you never distribute.

The software is provided **without warranty**, as described in the GPL. The license covers this project; KDE Plasma and any other software, services, media, or artwork that you use with the widget may have their own licenses and terms.
