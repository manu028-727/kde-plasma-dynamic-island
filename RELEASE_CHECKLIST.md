# Release Checklist

Use this before publishing a new GitHub release or KDE Store update.

1. Bump `KPlugin.Version` in `metadata.json`.
2. Add the matching section to `CHANGELOG.md`.
3. Run the automated checks:

   ```bash
   node tests/network-state.test.cjs
   node tests/text-utils.test.cjs
   for file in contents/ui/*.qml \
               contents/ui/activities/*.qml \
               contents/ui/controlcenter/*.qml; do
     qmlformat "$file" > /dev/null
   done
   for file in contents/ui/*.js contents/ui/controlcenter/*.js; do
     qmllint "$file"
   done
   scripts/package.sh
   unzip -t dynamic-island-*.plasmoid
   ```

   On a Plasma 6 system, also run the QML test:

   ```bash
   qmltestrunner -input tests
   ```

4. Validate appstream metadata:

   ```bash
   kpackagetool6 --type Plasma/Applet --appstream-metainfo .
   ```

5. Reinstall locally:

   ```bash
   kpackagetool6 --type Plasma/Applet --upgrade .
   ```

6. Clear the QML cache and restart Plasma:

   ```bash
   rm -rf ~/.cache/plasmashell/qmlcache
   systemctl --user restart plasma-plasmashell.service
   ```

7. Test:

   - compact idle pill
   - media playback start, pause, previous, next
   - notification popup and rounded notification image
   - control center open/close, click-to-focus, and outside-click dismissal
   - power menu opens without closing the control center
   - edit mode save/cancel/reset
   - drag, drop-to-hide, palette add, resize
   - brightness and volume sliders, including a missing audio sink/backlight
   - network tile: connected/disconnected Ethernet and Wi-Fi, networking disabled, multiple adapters, IPv6, refresh/settings buttons, and compact sizes
   - Bluetooth and KDE Connect lists with more than three devices

8. Create a tag matching the metadata version, optionally with a prerelease suffix:

   ```bash
   git tag v0.3.2-alpha
   git push origin v0.3.2-alpha
   ```

   CI builds the `.plasmoid`, validates the version, and publishes the GitHub release. Tags with a suffix are marked as prereleases.

9. Copy the GitHub release notes/changelog into KDE Store.
