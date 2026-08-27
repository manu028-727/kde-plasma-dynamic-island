# Dynamic Island Plasmoid

A KDE Plasma 6 widget inspired by the iOS/macOS Dynamic Island: a compact black pill for live activity plus a dark floating control-center popup.

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

GPL-3.0-or-later.
