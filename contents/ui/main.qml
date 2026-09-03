import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid
import org.kde.plasma.private.battery
import org.kde.plasma.private.batterymonitor
import org.kde.plasma.private.brightnesscontrolplugin as Brightness
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.volume

PlasmoidItem {
    id: root

    readonly property bool inPanel: [PlasmaCore.Types.TopEdge, PlasmaCore.Types.RightEdge, PlasmaCore.Types.BottomEdge, PlasmaCore.Types.LeftEdge].includes(Plasmoid.location)
    readonly property bool verticalPanel: [PlasmaCore.Types.LeftEdge, PlasmaCore.Types.RightEdge].includes(Plasmoid.location)
    readonly property var rawPlayer: mprisModel.currentPlayer
    readonly property var player: {
        mediaPlayerRevision;
        return bestMediaPlayer();
    }
    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property bool isPlaying: hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool hasJobs: notifications.activeJobsCount > 0
    readonly property bool hasNotifications: notifications.unreadNotificationsCount > 0 || notifications.activeNotificationsCount > 0
    readonly property bool hasActivity: hasJobs || hasPlayer || hasNotifications
    readonly property int panelSlot: inPanel && parent ? Math.max(24, Math.min(36, (verticalPanel ? parent.width : parent.height) - 6)) : 30
    readonly property int islandHeight: Math.max(24, Math.min(36, panelSlot))
    readonly property int idleIslandWidth: Math.round(islandHeight * 2.7)
    readonly property int liveIslandWidth: Math.round(islandHeight * 4.7)
    readonly property int islandWidth: liveIslandWidth
    readonly property real compactArtworkSize: Math.max(18, islandHeight - 8)
    readonly property real realIslandWidth: compactRepresentationItem && compactRepresentationItem.width > 0 ? compactRepresentationItem.width : islandWidth
    readonly property real realIslandHeight: compactRepresentationItem && compactRepresentationItem.height > 0 ? compactRepresentationItem.height : islandHeight
    readonly property int popupWidth: popupMode === "control" ? (controlEditMode ? 620 : 430) : 294
    readonly property int popupHeight: popupMode === "control" ? (controlEditMode ? 570 : 540) : 104
    readonly property int popupRadius: popupMode === "control" ? 34 : 26
    readonly property bool islandExpandsUp: Plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property bool islandExpandsDown: Plasmoid.location === PlasmaCore.Types.TopEdge
    property bool dialogVisible: false
    property bool islandOpen: false
    property bool panelHidden: false
    property bool popupAcceptsFocus: false
    property bool controlEditMode: false
    property int controlLayoutRevision: 0
    property var controlLayoutDraft: []
    property string systemUsername: ""
    property string systemHostname: ""
    property string profileImageUrl: ""
    property bool bluetoothPowered: false
    property string bluetoothDevicesText: ""
    property string wifiNetworksText: ""
    property string popupMode: "control"
    property int clickButton: Qt.NoButton
    property int mediaPlayerRevision: 0
    property string screenBrightnessDisplayName: ""
    property int screenBrightnessValue: 0
    property int screenBrightnessMax: 100
    property int screenBrightnessVisualPercent: 0
    property bool screenBrightnessVisualPinned: false
    property bool controlDragActive: false
    property var controlDragSource: null
    property string controlDragIcon: ""
    property real controlDragX: 0
    property real controlDragY: 0
    property int controlDragSize: 54
    property int controlDragOffsetCol: 0
    property int controlDragOffsetRow: 0
    property var activeControlPage: null
    property int controlDropCol: -1
    property int controlDropRow: -1
    property bool controlDropOnPalette: false
    property bool controlResizeActive: false
    property var controlResizeSource: null
    property int controlResizeIndex: -1
    property int controlResizeWidthUnits: 1
    property int controlResizeHeightUnits: 1
    readonly property string accountIconCommand: "sh -c 'user=$(id -un); path=$(qdbus6 org.freedesktop.Accounts /org/freedesktop/Accounts org.freedesktop.Accounts.FindUserByName \"$user\" 2>/dev/null); test -n \"$path\" && qdbus6 org.freedesktop.Accounts \"$path\" org.freedesktop.Accounts.User.IconFile 2>/dev/null'"

    onControlEditModeChanged: {
        if (!controlEditMode)
            resetControlInteractionState();

    }

    readonly property var controlModules: [
        { "id": "userPower", "name": "User + Power" },
        { "id": "volume", "name": "Volume" },
        { "id": "brightness", "name": "Brightness" },
        { "id": "wifi", "name": "Wi-Fi" },
        { "id": "wifiDevices", "name": "Wi-Fi Networks" },
        { "id": "bluetooth", "name": "Bluetooth" },
        { "id": "bluetoothDiscovery", "name": "Bluetooth Discovery" },
        { "id": "notifications", "name": "Notifications" },
        { "id": "batteryStatus", "name": "Battery Status" },
        { "id": "batteryPercent", "name": "Battery %" },
        { "id": "powerMode", "name": "Power Mode" },
        { "id": "appearanceMode", "name": "Light / Dark" },
        { "id": "theme", "name": "Theme" },
        { "id": "media", "name": "Media" },
        { "id": "kdeConnect", "name": "KDE Connect" },
        { "id": "settings", "name": "Settings" }
    ]

    function positionIslandDialog() {
        const item = root.compactRepresentationItem || root;
        if (!item || !item.mapToGlobal)
            return ;

        const pos = item.mapToGlobal(0, 0);
        islandDialog.x = Math.round(pos.x + item.width / 2 - popupWidth / 2);
        if (Plasmoid.location === PlasmaCore.Types.BottomEdge)
            islandDialog.y = Math.round(pos.y + item.height / 2 + realIslandHeight / 2 - popupHeight);
        else if (Plasmoid.location === PlasmaCore.Types.TopEdge)
            islandDialog.y = Math.round(pos.y + item.height / 2 - realIslandHeight / 2);
        else
            islandDialog.y = Math.round(pos.y + item.height / 2 - popupHeight / 2);
    }

    function openIsland(mode, autoClose) {
        const wasOpen = dialogVisible && islandOpen;
        closeDialogTimer.stop();
        openHandoffTimer.stop();
        activityPopupTimer.stop();
        popupMode = mode;
        popupAcceptsFocus = false;
        expanded = false;
        dialogVisible = true;
        Qt.callLater(positionIslandDialog);
        if (wasOpen) {
            panelHidden = true;
            islandOpen = true;
        } else {
            islandOpen = false;
            openHandoffTimer.restart();
        }
        if (autoClose)
            activityPopupTimer.restart();

    }

    function closeIsland() {
        if (!dialogVisible)
            return ;

        activityPopupTimer.stop();
        openHandoffTimer.stop();
        popupAcceptsFocus = false;
        resetControlInteractionState();
        if (!panelHidden && !islandOpen) {
            dialogVisible = false;
            return ;
        }
        islandOpen = false;
        closeDialogTimer.restart();
    }

    function bump() {
        if (!hasActivity)
            return ;

        showActivityPopup(true);
    }

    function showActivityPopup(autoClose) {
        openIsland("activity", autoClose);
    }

    function showControlCenter() {
        root.refreshSystemState();
        root.ensureControlLayout();
        openIsland("control", false);
    }

    function toggleActivityPopup(autoClose) {
        if (islandOpen && popupMode === "activity") {
            closeIsland();
            return ;
        }
        showActivityPopup(autoClose);
    }

    function toggleControlCenter() {
        if (islandOpen && popupMode === "control") {
            closeIsland();
            return ;
        }
        showControlCenter();
    }

    function rowValue(row, role, fallbackValue) {
        if (row < 0 || notifications.count <= row)
            return fallbackValue;

        const value = notifications.data(notifications.index(row, 0), role);
        return value === undefined || value === null ? fallbackValue : value;
    }

    function firstRowOfType(type) {
        for (let i = 0; i < notifications.count; ++i) {
            if (rowValue(i, NotificationManager.Notifications.TypeRole, NotificationManager.Notifications.NoType) === type)
                return i;

        }
        return -1;
    }

    function notificationRows(limit) {
        const out = [];
        const maxRows = Math.max(0, Math.round(limit || 0));
        for (let i = 0; i < notifications.count; ++i) {
            if (rowValue(i, NotificationManager.Notifications.TypeRole, NotificationManager.Notifications.NoType) !== NotificationManager.Notifications.NotificationType)
                continue;

            out.push(i);
            if (maxRows > 0 && out.length >= maxRows)
                break;

        }
        return out;
    }

    function notificationCount() {
        return notificationRows(0).length;
    }

    function activeRow() {
        const job = firstRowOfType(NotificationManager.Notifications.JobType);
        if (job >= 0)
            return job;

        const notice = firstRowOfType(NotificationManager.Notifications.NotificationType);
        return notice >= 0 ? notice : 0;
    }

    function cleanText(text) {
        return String(text || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }

    function finiteNumber(value, fallbackValue) {
        const number = Number(value);
        return isFinite(number) ? number : fallbackValue;
    }

    function clampNumber(value, minimumValue, maximumValue) {
        const minimum = finiteNumber(minimumValue, 0);
        const maximum = Math.max(minimum, finiteNumber(maximumValue, minimum));
        return Math.max(minimum, Math.min(maximum, finiteNumber(value, minimum)));
    }

    function percentFromRatio(value, maximumValue) {
        const maximum = Math.max(1, finiteNumber(maximumValue, 1));
        return Math.round(clampNumber(value, 0, maximum) / maximum * 100);
    }

    function firstValidNumber(values, fallbackValue) {
        for (let i = 0; i < values.length; ++i) {
            const number = Number(values[i]);
            if (isFinite(number))
                return number;

        }
        return fallbackValue;
    }

    function commandStdout(data) {
        if (!data)
            return "";

        if (data.stdout !== undefined && data.stdout !== null)
            return data.stdout;

        return data["stdout"] || "";
    }

    function resetControlInteractionState() {
        controlDragActive = false;
        controlResizeActive = false;
        controlDropCol = -1;
        controlDropRow = -1;
        controlDropOnPalette = false;
        controlDragSource = null;
        controlDragOffsetCol = 0;
        controlDragOffsetRow = 0;
        controlResizeSource = null;
        controlResizeIndex = -1;
        controlResizeWidthUnits = 1;
        controlResizeHeightUnits = 1;
    }

    function mediaText(value) {
        return String(value || "").replace(/\s+/g, " ").trim();
    }

    function mediaHasMetadata(playerLike) {
        if (!playerLike)
            return false;

        return mediaText(playerLike.track).length > 0 || mediaText(playerLike.artist).length > 0 || mediaText(playerLike.album).length > 0 || mediaText(playerLike.artUrl).length > 0 || finiteNumber(playerLike.length, 0) > 0;
    }

    function mediaIsBrowserish(playerLike) {
        if (!playerLike)
            return false;

        const name = (mediaText(playerLike.identity) + " " + mediaText(playerLike.desktopEntry)).toLowerCase();
        return name.indexOf("vivaldi") !== -1 || name.indexOf("chromium") !== -1 || name.indexOf("chrome") !== -1 || name.indexOf("firefox") !== -1 || name.indexOf("browser") !== -1;
    }

    function mediaPlayerScore(playerLike) {
        if (!playerLike)
            return -1;

        const status = playerLike.playbackStatus;
        const hasMetadata = mediaHasMetadata(playerLike);
        if (status === Mpris.PlaybackStatus.Stopped)
            return -1;

        if (status !== Mpris.PlaybackStatus.Playing && !hasMetadata)
            return -1;

        let score = 0;
        if (status === Mpris.PlaybackStatus.Playing)
            score += 1000;
        else if (status === Mpris.PlaybackStatus.Paused)
            score += 500;
        else
            score += 100;

        if (mediaText(playerLike.track).length > 0)
            score += 80;
        if (mediaText(playerLike.artist).length > 0)
            score += 45;
        if (mediaText(playerLike.album).length > 0)
            score += 20;
        if (mediaText(playerLike.artUrl).length > 0)
            score += 20;
        if (finiteNumber(playerLike.length, 0) > 0)
            score += 25;
        if (playerLike.canControl)
            score += 10;
        if (playerLike.canPlay || playerLike.canPause)
            score += 10;
        if (mediaIsBrowserish(playerLike) && !hasMetadata)
            score -= 400;

        return score;
    }

    function bestMediaPlayer() {
        mediaPlayerRevision;
        let best = null;
        let bestScore = -1;
        if (mediaPlayerInstantiator) {
            for (let i = 0; i < mediaPlayerInstantiator.count; ++i) {
                const candidate = mediaPlayerInstantiator.objectAt(i);
                const score = mediaPlayerScore(candidate);
                if (score > bestScore) {
                    best = candidate ? candidate.playerContainer : null;
                    bestScore = score;
                }
            }
        }

        const fallbackScore = mediaPlayerScore(rawPlayer);
        if (fallbackScore > bestScore) {
            best = rawPlayer;
            bestScore = fallbackScore;
        }

        return bestScore >= 0 ? best : null;
    }

    function primaryText() {
        const row = activeRow();
        if (hasJobs)
            return cleanText(rowValue(row, NotificationManager.Notifications.SummaryRole, "Working"));

        if (hasPlayer)
            return player.track || player.identity || "Media";

        if (hasNotifications)
            return cleanText(rowValue(row, NotificationManager.Notifications.SummaryRole, "Notification"));

        return "Control Center";
    }

    function secondaryText() {
        const row = activeRow();
        if (hasJobs)
            return notifications.jobsPercentage >= 0 ? notifications.jobsPercentage + "%" : cleanText(rowValue(row, NotificationManager.Notifications.BodyRole, ""));

        if (hasPlayer)
            return player.artist || player.album || player.identity || "";

        if (hasNotifications)
            return cleanText(rowValue(row, NotificationManager.Notifications.BodyRole, ""));

        return "Brightness, audio, network, power";
    }

    function activityMode() {
        if (hasJobs)
            return "job";

        if (hasPlayer)
            return "media";

        if (hasNotifications)
            return "notice";

        return "idle";
    }

    function screenBrightnessPercent() {
        if (screenBrightnessDisplayName.length > 0 && screenBrightnessMax > 0)
            return percentFromRatio(screenBrightnessValue, screenBrightnessMax);

        const displays = screenBrightness.displays;
        if (!screenBrightness.isBrightnessAvailable || !displays || displays.count <= 0)
            return 0;

        const idx = displays.index(0, 0);
        const value = firstValidNumber([displays.data(idx, 258), displays.data(idx, 257)], 0);
        const max = firstValidNumber([displays.data(idx, 259), displays.data(idx, 260)], 100);
        return percentFromRatio(value, max);
    }

    function displayedScreenBrightnessPercent() {
        if (!screenBrightness.isBrightnessAvailable)
            return 0;

        return screenBrightnessVisualPinned ? screenBrightnessVisualPercent : screenBrightnessPercent();
    }

    function syncScreenBrightnessDisplay(displayName, value, max) {
        const safeMax = Math.max(1, Math.round(finiteNumber(max, 100)));
        const safeValue = Math.round(clampNumber(value, 0, safeMax));
        const percent = percentFromRatio(safeValue, safeMax);

        screenBrightnessDisplayName = displayName || "";
        screenBrightnessValue = safeValue;
        screenBrightnessMax = safeMax;

        if (!screenBrightnessVisualPinned || Math.abs(percent - screenBrightnessVisualPercent) <= 1) {
            screenBrightnessVisualPercent = percent;
            screenBrightnessVisualPinned = false;
        }
    }

    function setScreenBrightnessPercent(value) {
        if (!screenBrightness.isBrightnessAvailable)
            return ;

        const percent = Math.round(clampNumber(value, 0, 100));
        screenBrightnessVisualPercent = percent;
        screenBrightnessVisualPinned = true;
        screenBrightnessSettleTimer.restart();

        if (screenBrightnessDisplayName.length > 0 && screenBrightnessMax > 0) {
            screenBrightness.setBrightness(screenBrightnessDisplayName, Math.round(screenBrightnessMax * percent / 100));
        } else {
            screenBrightness.adjustBrightnessRatio((percent - screenBrightnessPercent()) / 100);
        }
    }

    function keyboardBrightnessPercent() {
        if (!keyboardBrightness.isBrightnessAvailable || keyboardBrightness.brightnessMax <= 0)
            return 0;

        const value = finiteNumber(keyboardBrightness.brightness, 0);
        const max = finiteNumber(keyboardBrightness.brightnessMax, 0);
        return max > 0 ? percentFromRatio(value, max) : 0;
    }

    function setKeyboardBrightnessPercent(value) {
        if (!keyboardBrightness.isBrightnessAvailable || keyboardBrightness.brightnessMax <= 0)
            return ;

        const percent = clampNumber(value, 0, 100);
        keyboardBrightness.brightness = Math.round(keyboardBrightness.brightnessMax * percent / 100);
    }

    function adjustSystemVolume(up) {
        if (up)
            GlobalService.volumeUp();
        else
            GlobalService.volumeDown();
    }

    function defaultSink() {
        return PreferredDevice.sink || null;
    }

    function systemVolumePercent() {
        const sink = defaultSink();
        if (!sink)
            return 0;

        const volume = finiteNumber(sink.volume, 0);
        return Math.max(0, Math.min(150, percentFromRatio(volume, PulseAudio.NormalVolume)));
    }

    function setSystemVolumePercent(value) {
        const sink = defaultSink();
        if (!sink)
            return ;

        const percent = clampNumber(value, 0, 100);
        sink.muted = false;
        sink.volume = Math.round(PulseAudio.NormalVolume * percent / 100);
    }

    function toggleSystemMute() {
        const sink = defaultSink();
        if (sink)
            sink.muted = !sink.muted;
        else
            GlobalService.globalMute();
    }

    function launchPavucontrol() {
        executable.exec("pavucontrol");
    }

    function launchNetworkSettings() {
        executable.exec("kcmshell6 kcm_networkmanagement");
    }

    function launchBluetoothSettings() {
        executable.exec("kcmshell6 kcm_bluetooth");
    }

    function launchDisplaySettings() {
        executable.exec("kcmshell6 kcm_kscreen");
    }

    function launchNotificationSettings() {
        executable.exec("kcmshell6 kcm_notifications");
    }

    function lockScreen() {
        executable.exec("loginctl lock-session");
        closeIsland();
    }

    function runPowerAction(action) {
        if (action === "lock")
            executable.exec("loginctl lock-session");
        else if (action === "logout")
            executable.exec("qdbus6 org.kde.Shutdown /Shutdown logout");
        else if (action === "sleep")
            executable.exec("systemctl suspend");
        else if (action === "hibernate")
            executable.exec("systemctl hibernate");
        else if (action === "reboot")
            executable.exec("systemctl reboot");
        else if (action === "shutdown")
            executable.exec("systemctl poweroff");
        closeIsland();
    }

    function launchKdeConnectSettings() {
        executable.exec("kcmshell6 kcm_kdeconnect");
    }

    function launchAppearanceSettings() {
        executable.exec("kcmshell6 kcm_lookandfeel");
    }

    function launchSystemSettings() {
        executable.exec("systemsettings");
    }

    function launchPowerSettings() {
        executable.exec("kcmshell6 kcm_powerdevilprofilesconfig");
    }

    function toggleBluetoothPower() {
        executable.exec(bluetoothPowered ? "bluetoothctl power off" : "bluetoothctl power on");
        bluetoothRefreshTimer.restart();
    }

    function launchBluetoothDiscovery() {
        executable.exec("kcmshell6 kcm_bluetooth");
    }

    function toggleAppearanceMode() {
        Brightness.DarkModeControl.darkMode = !Brightness.DarkModeControl.darkMode;
    }

    function profileFaceUrl() {
        if (profileImageUrl.length > 0)
            return profileImageUrl;

        const user = systemUsername || "";
        return user.length > 0 ? "file:///var/lib/AccountsService/icons/" + user : "";
    }

    function refreshSystemState() {
        executable.exec("whoami");
        executable.exec("hostname");
        executable.exec(accountIconCommand);
        executable.exec("bluetoothctl show");
        executable.exec("bluetoothctl devices Connected");
        executable.exec("nmcli -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no");
    }

    function defaultControlLayout() {
        return [
            { "id": "userPower", "w": 6, "h": 2, "v": 2 },
            { "id": "batteryPercent", "w": 2, "h": 2, "v": 2 },
            { "id": "media", "w": 8, "h": 4, "v": 2 },
            { "id": "volume", "w": 8, "h": 2, "v": 2 },
            { "id": "brightness", "w": 8, "h": 2, "v": 2 },
            { "id": "wifi", "w": 2, "h": 2, "v": 2 },
            { "id": "wifiDevices", "w": 4, "h": 2, "v": 2 },
            { "id": "bluetooth", "w": 2, "h": 2, "v": 2 },
            { "id": "bluetoothDiscovery", "w": 4, "h": 2, "v": 2 },
            { "id": "notifications", "w": 4, "h": 4, "v": 2 },
            { "id": "batteryStatus", "w": 2, "h": 2, "v": 2 },
            { "id": "powerMode", "w": 2, "h": 2, "v": 2 },
            { "id": "appearanceMode", "w": 2, "h": 2, "v": 2 },
            { "id": "theme", "w": 2, "h": 2, "v": 2 },
            { "id": "kdeConnect", "w": 2, "h": 2, "v": 2 },
            { "id": "settings", "w": 2, "h": 2, "v": 2 }
        ];
    }

    function controlModuleMinSize(id) {
        if (id === "media" || id === "notifications")
            return { "w": 2, "h": 2 };
        return { "w": 1, "h": 1 };
    }

    function controlModuleMaxSize(id) {
        return { "w": 8, "h": id === "userPower" ? 3 : 6 };
    }

    function controlModuleDefaultSize(id) {
        return {
            "id": id,
            "w": id === "media" || id === "volume" || id === "brightness" ? 8 : id === "notifications" || id === "wifiDevices" || id === "bluetoothDiscovery" ? 4 : 2,
            "h": id === "media" || id === "notifications" ? 4 : 2,
            "v": 2
        };
    }

    function clampedControlModule(id, widthUnits, heightUnits) {
        const minSize = controlModuleMinSize(id);
        const maxSize = controlModuleMaxSize(id);
        return {
            "w": Math.round(clampNumber(widthUnits, minSize.w, maxSize.w)),
            "h": Math.round(clampNumber(heightUnits, minSize.h, maxSize.h))
        };
    }

    function committedControlLayout() {
        const raw = Plasmoid.configuration.controlCenterLayoutJson || "";
        if (raw.length > 0) {
            try {
                const parsed = JSON.parse(raw);
                if (Array.isArray(parsed) && parsed.length > 0)
                    return sanitizeControlLayout(parsed);

            } catch (e) {
                console.warn("Dynamic Island: invalid control center layout JSON", e);
            }
        }
        return defaultControlLayout();
    }

    function controlLayout() {
        controlLayoutRevision;
        if (controlEditMode && Array.isArray(controlLayoutDraft))
            return sanitizeControlLayout(controlLayoutDraft);

        return committedControlLayout();
    }

    function sanitizeControlLayout(layout) {
        const known = {};
        for (let i = 0; i < controlModules.length; ++i)
            known[controlModules[i].id] = true;

        const out = [];
        const seen = {};
        for (let j = 0; j < layout.length; ++j) {
            const item = layout[j] || {};
            if (!known[item.id] || seen[item.id])
                continue;

            const migrated = item.v === 2;
            const size = clampedControlModule(item.id, (item.w || 1) * (migrated ? 1 : 2), (item.h || 1) * (migrated ? 1 : 2));
            const col = isFinite(Number(item.col)) ? Math.round(clampNumber(item.col, 0, 7)) : -1;
            const row = isFinite(Number(item.row)) ? Math.max(0, Math.round(finiteNumber(item.row, 0))) : -1;
            const saved = {
                "id": item.id,
                "w": size.w,
                "h": size.h,
                "v": 2
            };
            if (col >= 0 && row >= 0) {
                saved.col = Math.min(8 - size.w, col);
                saved.row = row;
            }
            seen[item.id] = true;
            out.push(saved);
        }
        return out.length > 0 ? out : defaultControlLayout();
    }

    function saveControlLayout(layout) {
        Plasmoid.configuration.controlCenterLayoutJson = JSON.stringify(sanitizeControlLayout(layout));
        controlLayoutRevision++;
    }

    function updateControlLayout(layout) {
        if (controlEditMode) {
            controlLayoutDraft = sanitizeControlLayout(layout);
            controlLayoutRevision++;
        } else {
            saveControlLayout(layout);
        }
    }

    function ensureControlLayout() {
        if (!Plasmoid.configuration.controlCenterLayoutJson || Plasmoid.configuration.controlCenterLayoutJson.length === 0)
            saveControlLayout(defaultControlLayout());

    }

    function beginControlEdit() {
        controlLayoutDraft = committedControlLayout();
        controlEditMode = true;
        controlLayoutRevision++;
    }

    function saveControlEdit() {
        if (!controlEditMode)
            return ;

        saveControlLayout(controlLayoutDraft);
        controlLayoutDraft = [];
        controlEditMode = false;
    }

    function cancelControlEdit() {
        if (!controlEditMode)
            return ;

        controlLayoutDraft = [];
        controlEditMode = false;
        controlLayoutRevision++;
    }

    function resetControlLayout() {
        updateControlLayout(defaultControlLayout());
    }

    function removeControlModule(index) {
        const layout = controlLayout();
        if (index < 0 || index >= layout.length)
            return ;

        layout.splice(index, 1);
        updateControlLayout(layout);
    }

    function addControlModule(id) {
        insertControlModule(id, -1);
    }

    function insertControlModule(id, target) {
        const layout = controlLayout();
        for (let i = 0; i < layout.length; ++i) {
            if (layout[i].id === id)
                return ;

        }
        const item = controlModuleDefaultSize(id);
        if (target >= 0 && target <= layout.length)
            layout.splice(target, 0, item);
        else
            layout.push(item);

        updateControlLayout(layout);
    }

    function moduleInfo(id) {
        for (let i = 0; i < controlModules.length; ++i) {
            if (controlModules[i].id === id)
                return controlModules[i];

        }
        return { "id": id, "name": id };
    }

    function moduleIcon(id) {
        if (id === "userPower")
            return "user-identity";
        if (id === "volume")
            return "audio-volume-high";
        if (id === "brightness")
            return "brightness-high";
        if (id === "wifi")
            return enabledConnections.wirelessEnabled ? "network-wireless-on" : "network-wireless-off";
        if (id === "wifiDevices")
            return "network-wireless-acquiring";
        if (id === "bluetooth" || id === "bluetoothDiscovery")
            return "preferences-system-bluetooth";
        if (id === "notifications")
            return "notifications";
        if (id === "batteryStatus" || id === "batteryPercent")
            return batteryControl.pluggedIn ? "battery-charging" : "battery";
        if (id === "powerMode")
            return powerProfileIcon();
        if (id === "appearanceMode")
            return "preferences-desktop-theme";
        if (id === "theme")
            return "preferences-desktop-theme-global";
        if (id === "media")
            return "multimedia-player";
        if (id === "kdeConnect")
            return "kdeconnect";
        if (id === "settings")
            return "systemsettings";
        return "unknown";
    }

    function toggleWifi() {
        networkHandler.enableWireless(!enabledConnections.wirelessEnabled);
        wifiRefreshTimer.restart();
    }

    function wifiTitle() {
        if (!enabledConnections.wirelessHwEnabled)
            return "Unavailable";
        return enabledConnections.wirelessEnabled ? "On" : "Off";
    }

    function wifiRows(limit) {
        const rows = [];
        const lines = root.wifiNetworksText.length > 0 ? root.wifiNetworksText.split("\n") : [];
        const maxRows = Math.max(0, Math.round(limit || 0));
        for (let i = 0; i < lines.length; ++i) {
            const line = String(lines[i] || "").trim();
            if (line.length <= 0)
                continue;

            rows.push(line);
            if (maxRows > 0 && rows.length >= maxRows)
                break;

        }
        return rows;
    }

    function wifiPrimaryNetwork() {
        const rows = wifiRows(1);
        return rows.length > 0 ? rows[0].replace(/^• /, "") : enabledConnections.wirelessEnabled ? "No scan results" : "Disabled";
    }

    function wifiSignalPercent() {
        const rows = wifiRows(1);
        if (rows.length <= 0)
            return 0;

        const match = rows[0].match(/(\d+)%$/);
        return match ? clampNumber(match[1], 0, 100) : 0;
    }

    function networkSummary() {
        if (!enabledConnections.networkingEnabled)
            return "Offline";
        if (enabledConnections.wirelessEnabled && wifiSignalPercent() > 0)
            return wifiSignalPercent() + "% signal";
        return "Wired connected";
    }

    function parseWifiNetworks(text) {
        const lines = String(text || "").split("\n");
        const out = [];
        for (let i = 0; i < lines.length; ++i) {
            const parts = splitNmcliFields(lines[i]);
            if (parts.length < 3)
                continue;

            const active = parts[0] === "*";
            const ssid = parts[1] || "Hidden network";
            const signal = clampNumber(parts[2], 0, 100);
            out.push((active ? "• " : "") + ssid + (isFinite(Number(parts[2])) ? " " + signal + "%" : ""));
            if (out.length >= 3)
                break;

        }
        return out.join("\n");
    }

    function splitNmcliFields(line) {
        const fields = [];
        let current = "";
        let escaped = false;
        const text = String(line || "");
        for (let i = 0; i < text.length; ++i) {
            const ch = text.charAt(i);
            if (escaped) {
                current += ch;
                escaped = false;
            } else if (ch === "\\") {
                escaped = true;
            } else if (ch === ":") {
                fields.push(current);
                current = "";
            } else {
                current += ch;
            }
        }
        fields.push(current);
        return fields;
    }

    function parseBluetoothDevices(text) {
        const lines = String(text || "").split("\n");
        const out = [];
        for (let i = 0; i < lines.length; ++i) {
            const line = String(lines[i] || "").trim();
            if (line.length <= 0)
                continue;

            const parts = line.split(" ");
            out.push(parts.length > 2 ? parts.slice(2).join(" ") : line);
            if (out.length >= 3)
                break;

        }
        return out.join("\n");
    }

    function beginControlDrag(source, item, mouse, size) {
        if (!root.controlEditMode || !dialogHost)
            return ;

        const pos = item.mapToItem(dialogHost, mouse.x, mouse.y);
        controlDragSource = source;
        controlDragIcon = moduleIcon(source.moduleId);
        controlDragSize = size;
        controlDragX = pos.x - size / 2;
        controlDragY = pos.y - size / 2;
        controlDragActive = true;
    }

    function updateControlDrag(item, mouse) {
        if (!controlDragActive || !dialogHost)
            return ;

        const pos = item.mapToItem(dialogHost, mouse.x, mouse.y);
        controlDragX = pos.x - controlDragSize / 2;
        controlDragY = pos.y - controlDragSize / 2;
        if (activeControlPage)
            activeControlPage.previewControlDrop(pos.x, pos.y);
    }

    function endControlDrag(item, mouse, commit) {
        if (commit && controlDragActive && activeControlPage && dialogHost && item && mouse) {
            const pos = item.mapToItem(dialogHost, mouse.x, mouse.y);
            activeControlPage.finishControlDrop(controlDragSource, pos.x, pos.y);
        }

        controlDragActive = false;
        controlDropCol = -1;
        controlDropRow = -1;
        controlDropOnPalette = false;
        controlDragOffsetCol = 0;
        controlDragOffsetRow = 0;
        Qt.callLater(function() {
            if (!controlDragActive)
                controlDragSource = null;

        });
    }

    function beginControlResize(source) {
        if (!root.controlEditMode || !source || !activeControlPage)
            return ;

        if (source.moduleIndex < 0)
            return ;

        controlResizeSource = source;
        controlResizeIndex = source.moduleIndex;
        controlResizeWidthUnits = source.moduleWidthUnits;
        controlResizeHeightUnits = source.moduleHeightUnits;
        controlResizeActive = true;
    }

    function updateControlResize(source, widthUnits, heightUnits) {
        if (!controlResizeActive || !source || source !== controlResizeSource)
            return ;

        const size = clampedControlModule(source.moduleId, widthUnits, heightUnits);
        controlResizeWidthUnits = size.w;
        controlResizeHeightUnits = size.h;
    }

    function endControlResize(source, commit) {
        if (commit && controlResizeActive && activeControlPage && source && source === controlResizeSource)
            activeControlPage.commitControlResize(source, controlResizeWidthUnits, controlResizeHeightUnits);

        controlResizeActive = false;
        controlResizeSource = null;
        controlResizeIndex = -1;
        controlResizeWidthUnits = 1;
        controlResizeHeightUnits = 1;
    }

    function clearNotifications() {
        for (let i = notifications.count - 1; i >= 0; --i) {
            if (rowValue(i, NotificationManager.Notifications.TypeRole, NotificationManager.Notifications.NoType) !== NotificationManager.Notifications.NotificationType)
                continue;

            if (rowValue(i, NotificationManager.Notifications.ClosableRole, true))
                notifications.close(notifications.index(i, 0));
        }

    }

    function cyclePowerProfile() {
        const profiles = powerProfiles.profiles;
        if (!profiles || profiles.length <= 0)
            return ;

        const current = profiles.indexOf(powerProfiles.activeProfile);
        const next = profiles[(Math.max(0, current) + 1) % profiles.length];
        powerProfiles.setProfile(next);
    }

    function powerProfileIcon() {
        if (powerProfiles.activeProfile === "performance")
            return "battery-profile-performance";

        if (powerProfiles.activeProfile === "power-saver")
            return "battery-profile-powersave";

        return "battery-profile-balanced";
    }

    function powerProfileTitle() {
        if (powerProfiles.activeProfile === "performance")
            return "Performance";
        if (powerProfiles.activeProfile === "power-saver")
            return "Saver";
        return "Balanced";
    }

    function batteryText() {
        if (!batteryControl.hasInternalBatteries)
            return batteryControl.pluggedIn ? "AC" : "Power";

        return batteryControl.percent + "%";
    }

    Layout.minimumWidth: islandWidth
    Layout.maximumWidth: islandWidth
    Layout.preferredWidth: islandWidth
    Layout.minimumHeight: islandHeight
    Layout.maximumHeight: islandHeight
    Layout.preferredHeight: islandHeight
    switchWidth: islandWidth
    switchHeight: islandHeight
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.status: hasActivity ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.title: ""
    toolTipMainText: primaryText()
    toolTipSubText: secondaryText()
    compactRepresentation: islandComponent
    fullRepresentation: emptyFullRepresentation
    preferredRepresentation: compactRepresentation
    hideOnWindowDeactivate: true
    onExpandedChanged: function() {
        if (expanded)
            expanded = false;

    }

    NotificationManager.Notifications {
        id: notifications

        limit: 8
        showNotifications: true
        showJobs: true
        showExpired: false
        showDismissed: false
        sortMode: NotificationManager.Notifications.SortByTypeAndUrgency
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
    }

    Mpris.Mpris2Model {
        id: mprisModel

        onCurrentPlayerChanged: {
            root.mediaPlayerRevision++;
            root.bump();
        }
    }

    Instantiator {
        id: mediaPlayerInstantiator

        model: Mpris.MultiplexerModel {}
        onObjectAdded: root.mediaPlayerRevision++
        onObjectRemoved: root.mediaPlayerRevision++

        delegate: QtObject {
            readonly property var playerContainer: model.container
            readonly property int playbackStatus: model.playbackStatus
            readonly property string track: model.track || ""
            readonly property string artist: model.artist || ""
            readonly property string album: model.album || ""
            readonly property string artUrl: model.artUrl || ""
            readonly property real length: root.finiteNumber(model.length, 0)
            readonly property string identity: model.identity || ""
            readonly property string desktopEntry: model.desktopEntry || ""
            readonly property bool canControl: model.canControl || false
            readonly property bool canPlay: model.canPlay || false
            readonly property bool canPause: model.canPause || false

            onPlaybackStatusChanged: {
                root.mediaPlayerRevision++;
                root.bump();
            }
            onTrackChanged: root.mediaPlayerRevision++
            onArtistChanged: root.mediaPlayerRevision++
            onAlbumChanged: root.mediaPlayerRevision++
            onArtUrlChanged: root.mediaPlayerRevision++
            onLengthChanged: root.mediaPlayerRevision++
            onIdentityChanged: root.mediaPlayerRevision++
        }
    }

    Brightness.ScreenBrightnessControl {
        id: screenBrightness

        isSilent: true
    }

    Instantiator {
        model: screenBrightness.displays

        delegate: QtObject {
            required property int index
            required property string displayName
            required property int brightness
            required property int maxBrightness

            function syncIfPrimary() {
                if (index === 0)
                    root.syncScreenBrightnessDisplay(displayName, brightness, maxBrightness);
            }

            Component.onCompleted: syncIfPrimary()
            onBrightnessChanged: syncIfPrimary()
            onMaxBrightnessChanged: syncIfPrimary()
            onDisplayNameChanged: syncIfPrimary()
        }
    }

    Timer {
        id: screenBrightnessSettleTimer

        interval: 900
        repeat: false
        onTriggered: {
            root.screenBrightnessVisualPinned = false;
            root.screenBrightnessVisualPercent = root.screenBrightnessPercent();
        }
    }

    Brightness.KeyboardBrightnessControl {
        id: keyboardBrightness

        isSilent: true
    }

    PowerProfilesControl {
        id: powerProfiles

        isSilent: true
    }

    BatteryControlModel {
        id: batteryControl
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaNM.WirelessStatus {
        id: wirelessStatus
    }

    PlasmaNM.Handler {
        id: networkHandler
    }

    Plasma5Support.DataSource {
        id: executable

        function exec(cmd) {
            if (cmd)
                connectSource(cmd);

        }

        engine: "executable"
        onNewData: (sourceName, data) => {
            const stdout = root.commandStdout(data);
            const out = root.cleanText(stdout);
            if (sourceName === "whoami")
                root.systemUsername = out;
            else if (sourceName === "hostname")
                root.systemHostname = out;
            else if (sourceName === root.accountIconCommand)
                root.profileImageUrl = out.length > 0 ? (out.indexOf("file:") === 0 ? out : "file://" + out) : "";
            else if (sourceName === "bluetoothctl show")
                root.bluetoothPowered = out.indexOf("Powered: yes") !== -1;
            else if (sourceName === "bluetoothctl devices Connected")
                root.bluetoothDevicesText = root.parseBluetoothDevices(stdout);
            else if (sourceName === "nmcli -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no")
                root.wifiNetworksText = root.parseWifiNetworks(stdout);

            disconnectSource(sourceName);
        }
    }

    Component.onCompleted: {
        root.ensureControlLayout();
        root.refreshSystemState();
    }

    Connections {
        function onPlaybackStatusChanged() {
            root.bump();
        }

        function onTrackChanged() {
            root.bump();
        }

        target: root.player
    }

    Connections {
        function onRowsInserted(parent, first, last) {
            root.bump();
        }

        function onActiveJobsCountChanged() {
            root.bump();
        }

        function onUnreadNotificationsCountChanged() {
            root.bump();
        }

        target: notifications
    }

    Timer {
        id: activityPopupTimer

        interval: 3000
        repeat: false
        onTriggered: {
            if (root.popupMode === "activity")
                root.closeIsland();

        }
    }

    Timer {
        id: closeDialogTimer

        interval: 360
        repeat: false
        onTriggered: {
            if (!root.islandOpen) {
                root.dialogVisible = false;
                root.panelHidden = false;
            }
        }
    }

    Timer {
        id: openHandoffTimer

        interval: 18
        repeat: false
        onTriggered: {
            root.panelHidden = true;
            root.islandOpen = true;
        }
    }

    Timer {
        id: clickTimer

        interval: 210
        repeat: false
        onTriggered: {
            if (root.clickButton === Qt.MiddleButton && root.player)
                root.player.PlayPause();
            else if (root.islandOpen)
                root.closeIsland();
            else if (root.dialogVisible)
                root.closeIsland();
            else if (root.hasActivity)
                root.showActivityPopup(false);
            else
                root.showControlCenter();
        }
    }

    Timer {
        id: bluetoothRefreshTimer

        interval: 900
        repeat: false
        onTriggered: {
            executable.exec("bluetoothctl show");
            executable.exec("bluetoothctl devices Connected");
        }
    }

    Timer {
        id: wifiRefreshTimer

        interval: 900
        repeat: false
        onTriggered: executable.exec("nmcli -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no")
    }

    PlasmaCore.Dialog {
        id: islandDialog

        appletInterface: root
        location: PlasmaCore.Types.Floating
        type: PlasmaCore.Dialog.Dock
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | (root.popupAcceptsFocus ? 0 : Qt.WindowDoesNotAcceptFocus)
        backgroundHints: PlasmaCore.Dialog.NoBackground
        marginsEnabled: false
        shadowEnabled: false
        hideOnWindowDeactivate: false
        visible: root.dialogVisible
        onVisibleChanged: {
            if (visible)
                Qt.callLater(root.positionIslandDialog);
            else
                root.popupAcceptsFocus = false;

        }
        onWidthChanged: root.positionIslandDialog()
        onHeightChanged: root.positionIslandDialog()

        mainItem: Item {
            id: dialogHost

            width: root.popupWidth
            height: root.popupHeight

            Loader {
                id: dialogLoader

                anchors.fill: parent
                active: root.dialogVisible
                sourceComponent: popupComponent
            }

            Rectangle {
                id: controlDragPreview

                width: root.controlDragSize
                height: root.controlDragSize
                x: root.controlDragX
                y: root.controlDragY
                radius: 17
                visible: root.controlEditMode && (root.controlDragActive || opacity > 0)
                opacity: root.controlDragActive ? 0.92 : 0
                color: "#20212a"
                border.color: "#8e8eff"
                border.width: 1
                z: 1000

                Drag.active: root.controlDragActive
                Drag.source: root.controlDragSource
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                Behavior on opacity {
                    NumberAnimation { duration: 90 }
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Math.min(30, parent.width - 18)
                    height: width
                    source: root.controlDragIcon
                    color: "#f8f8fb"
                }
            }
        }

    }

    Timer {
        id: positionTimer

        interval: 1000
        running: root.hasPlayer && root.isPlaying
        repeat: true
        onTriggered: {
            if (root.player && root.player.updatePosition)
                root.player.updatePosition();

        }
    }

    Component {
        id: islandComponent

        Item {
            id: island

            width: root.islandWidth
            height: root.islandHeight
            scale: 1
            opacity: root.panelHidden ? 0 : 1

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    root.clickButton = mouse.button;
                    clickTimer.restart();
                }
                onDoubleClicked: (mouse) => {
                    clickTimer.stop();
                    root.toggleControlCenter();
                }
                onWheel: (wheel) => {
                    if (root.player && root.player.changeVolume)
                        root.player.changeVolume(wheel.angleDelta.y > 0 ? 0.04 : -0.04, true);
                    else
                        root.adjustSystemVolume(wheel.angleDelta.y > 0);
                }
            }

            Rectangle {
                id: capsule

                anchors.fill: parent
                radius: height / 2
                color: "#030304"
                border.color: "#16161b"
                border.width: 1

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 1
                    height: Math.max(1, parent.height * 0.38)
                    radius: capsule.radius
                    color: "#22222a"
                    opacity: 0.12
                }

            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 5

                Rectangle {
                    Layout.preferredWidth: root.compactArtworkSize
                    Layout.preferredHeight: root.compactArtworkSize
                    color: "transparent"

                    MaskedArtwork {
                        anchors.fill: parent
                        artworkSource: root.hasPlayer ? root.player.artUrl : ""
                        cornerRadius: height / 2
                        mode: root.activityMode()
                        progress: Math.max(0, notifications.jobsPercentage) / 100
                        playing: root.isPlaying
                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Loader {
                        anchors.fill: parent
                        active: root.hasActivity
                        sourceComponent: root.hasJobs ? compactJobIndicator : root.hasPlayer ? compactMediaIndicator : compactNoticeIndicator
                    }

                }

                Rectangle {
                    visible: !root.hasActivity
                    Layout.preferredWidth: 5
                    Layout.preferredHeight: 5
                    radius: 3
                    color: root.hasJobs ? "#42d77d" : root.isPlaying ? "#5ac8fa" : root.hasNotifications ? "#ff9f0a" : "#27272d"
                    opacity: 0.95
                }

            }

        }

    }

    Component {
        id: emptyFullRepresentation

        Item {
            implicitWidth: root.islandWidth
            implicitHeight: root.islandHeight
            width: implicitWidth
            height: implicitHeight
            visible: false
        }

    }

    Component {
        id: compactMediaIndicator

        Item {
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 1
                spacing: 4

                ProgressBar {
                    Layout.preferredWidth: Math.max(48, Math.min(76, root.islandWidth * 0.42))
                    Layout.maximumWidth: Math.max(48, Math.min(76, root.islandWidth * 0.42))
                    Layout.preferredHeight: 4
                    visible: root.hasPlayer && root.player.length > 0
                    from: 0
                    to: Math.max(1, root.player ? root.player.length : 1)
                    value: root.player ? root.player.position : 0
                    accent: "#5ac8fa"
                }

                Row {
                    Layout.preferredWidth: 27
                    Layout.preferredHeight: Math.max(14, root.islandHeight - 14)
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    Repeater {
                        model: [0.45, 0.86, 0.58, 0.74, 0.36]

                        Rectangle {
                            property real barLevel: modelData

                            width: 3
                            height: Math.max(4, parent.height * barLevel)
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2
                            color: "#c026d3"
                            opacity: root.isPlaying ? 1 : 0.48

                            SequentialAnimation on barLevel {
                                running: root.isPlaying
                                loops: Animation.Infinite

                                PauseAnimation {
                                    duration: index * 55
                                }

                                NumberAnimation {
                                    to: Math.max(0.28, 1 - modelData * 0.35)
                                    duration: 210 + index * 20
                                    easing.type: Easing.InOutSine
                                }

                                NumberAnimation {
                                    to: modelData
                                    duration: 240 + index * 25
                                    easing.type: Easing.InOutSine
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    Component {
        id: compactJobIndicator

        RowLayout {
            spacing: 6

            QQC2.Label {
                text: notifications.jobsPercentage >= 0 ? notifications.jobsPercentage + "%" : ""
                visible: text.length > 0
                color: "#c7f9d4"
                font.pixelSize: 9
                font.weight: Font.Bold
            }

            ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                from: 0
                to: 100
                value: Math.max(0, notifications.jobsPercentage)
                accent: "#42d77d"
            }

        }

    }

    Component {
        id: compactNoticeIndicator

        RowLayout {
            spacing: 5

            Rectangle {
                Layout.preferredWidth: 6
                Layout.preferredHeight: 6
                radius: 3
                color: "#ff9f0a"
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: notifications.unreadNotificationsCount > 0 ? notifications.unreadNotificationsCount + "" : "!"
                color: "#ffd7a1"
                font.pixelSize: 10
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignRight
            }

        }

    }

    Component {
        id: popupComponent

        MouseArea {
            id: popupRoot

            property real morph: root.islandOpen ? 1 : 0
            readonly property real contentOpacity: Math.max(0, Math.min(1, (morph - 0.42) / 0.58))
            readonly property real compactOpacity: Math.max(0, Math.min(1, (0.34 - morph) / 0.34))
            readonly property real collapsedWidth: root.realIslandWidth
            readonly property real collapsedHeight: root.realIslandHeight
            readonly property real panelWidth: collapsedWidth + (root.popupWidth - collapsedWidth) * morph
            readonly property real panelHeight: collapsedHeight + (root.popupHeight - collapsedHeight) * morph
            readonly property real panelRadius: collapsedHeight / 2 + (root.popupRadius - collapsedHeight / 2) * morph
            readonly property real collapsedY: root.islandExpandsUp ? root.popupHeight - collapsedHeight : root.islandExpandsDown ? 0 : (root.popupHeight - collapsedHeight) / 2
            readonly property real panelY: collapsedY * (1 - morph)

            implicitWidth: root.popupWidth
            implicitHeight: root.popupHeight
            width: root.popupWidth
            height: root.popupHeight
            Layout.minimumWidth: root.popupWidth
            Layout.maximumWidth: root.popupWidth
            Layout.preferredWidth: root.popupWidth
            Layout.minimumHeight: root.popupHeight
            Layout.maximumHeight: root.popupHeight
            Layout.preferredHeight: root.popupHeight
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onEntered: {
                root.popupAcceptsFocus = true;
                if (islandDialog.requestActivate)
                    islandDialog.requestActivate();

            }
            onExited: {
                root.popupAcceptsFocus = false;
            }
            onClicked: (mouse) => {
                root.closeIsland();
                mouse.accepted = true;
            }
            opacity: 1

            Rectangle {
                id: popupShadow

                x: (parent.width - width) / 2
                y: popupRoot.panelY
                width: popupRoot.panelWidth
                height: popupRoot.panelHeight
                radius: popupRoot.panelRadius
                color: "#050507"
                opacity: 0
            }

            Rectangle {
                id: contentPanel

                x: popupShadow.x
                y: popupShadow.y
                width: popupShadow.width
                height: popupShadow.height
                radius: popupShadow.radius
                color: "#050507"
                border.color: "#202027"
                border.width: 1
                clip: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    enabled: root.islandOpen
                    propagateComposedEvents: true
                    onClicked: (mouse) => {
                        root.closeIsland();
                        mouse.accepted = false;
                    }
                }

                Loader {
                    anchors.fill: parent
                    anchors.margins: root.popupMode === "control" ? 14 : 12
                    opacity: popupRoot.contentOpacity
                    visible: opacity > 0
                    sourceComponent: root.popupMode === "control" ? controlCenterPage : activityPage
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 5
                    opacity: popupRoot.compactOpacity
                    visible: opacity > 0

                    Rectangle {
                        Layout.preferredWidth: root.compactArtworkSize
                        Layout.preferredHeight: root.compactArtworkSize
                        color: "transparent"

                        MaskedArtwork {
                            anchors.fill: parent
                            artworkSource: root.hasPlayer ? root.player.artUrl : ""
                            cornerRadius: Math.min(height / 2, 8 + (height / 2 - 8) * (1 - Math.min(1, popupRoot.morph / 0.34)))
                            mode: root.activityMode()
                            progress: Math.max(0, notifications.jobsPercentage) / 100
                            playing: root.isPlaying
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Loader {
                            anchors.fill: parent
                            active: root.hasActivity
                            sourceComponent: root.hasJobs ? compactJobIndicator : root.hasPlayer ? compactMediaIndicator : compactNoticeIndicator
                        }

                    }

                    Rectangle {
                        visible: !root.hasActivity
                        Layout.preferredWidth: 5
                        Layout.preferredHeight: 5
                        radius: 3
                        color: "#27272d"
                    }

                }

            }

            Behavior on morph {
                NumberAnimation {
                    duration: 340
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.2, 0.82, 0.18, 1, 1, 1]
                }

            }

        }

    }

    Component {
        id: activityPage

        RowLayout {
            anchors.fill: parent
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 58
                Layout.preferredHeight: 58
                radius: 16
                color: "transparent"

                MaskedArtwork {
                    anchors.fill: parent
                    artworkSource: root.hasPlayer ? root.player.artUrl : ""
                    cornerRadius: 16
                    glyphSize: 32
                    mode: root.activityMode()
                    progress: Math.max(0, notifications.jobsPercentage) / 100
                    playing: root.isPlaying
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.primaryText()
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.secondaryText()
                    color: "#9d9da7"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    visible: root.hasJobs || (root.hasPlayer && root.player.length > 0)
                    from: 0
                    to: root.hasJobs ? 100 : Math.max(1, root.player ? root.player.length : 1)
                    value: root.hasJobs ? Math.max(0, notifications.jobsPercentage) : root.player ? root.player.position : 0
                    accent: root.hasJobs ? "#42d77d" : "#5ac8fa"
                }

            }

            RowLayout {
                visible: root.hasPlayer
                spacing: 6

                IslandButton {
                    iconName: "media-skip-backward"
                    compact: true
                    enabled: root.player && root.player.canGoPrevious
                    onClicked: root.player.Previous()
                }

                IslandButton {
                    iconName: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                    compact: true
                    emphasized: true
                    enabled: root.player && (root.player.canPlay || root.player.canPause)
                    onClicked: root.player.PlayPause()
                }

                IslandButton {
                    iconName: "media-skip-forward"
                    compact: true
                    enabled: root.player && root.player.canGoNext
                    onClicked: root.player.Next()
                }

            }

        }

    }

    Component {
        id: controlCenterPage

        Item {
            id: controlPage

            anchors.fill: parent

            Component.onCompleted: root.activeControlPage = controlPage
            Component.onDestruction: {
                if (root.activeControlPage === controlPage)
                    root.activeControlPage = null;

            }

            function containsPoint(item, x, y) {
                if (!item || !item.visible)
                    return false;

                const p = item.mapFromItem(dialogHost, x, y);
                return p.x >= 0 && p.y >= 0 && p.x <= item.width && p.y <= item.height;
            }

            function cellAtPoint(x, y) {
                const p = moduleGrid.mapFromItem(dialogHost, x, y);
                const pitch = moduleGrid.unitSize + moduleGrid.gap;
                const size = draggedSize();
                const maxOffsetCol = Math.max(0, Math.min(moduleGrid.columns, Math.round(size.w || 1)) - 1);
                const maxOffsetRow = Math.max(0, Math.round(size.h || 1) - 1);
                return {
                    "col": Math.max(0, Math.min(moduleGrid.columns - 1, Math.floor(p.x / pitch) - Math.max(0, Math.min(maxOffsetCol, root.controlDragOffsetCol)))),
                    "row": Math.max(0, Math.floor(p.y / pitch) - Math.max(0, Math.min(maxOffsetRow, root.controlDragOffsetRow)))
                };
            }

            function draggedSize() {
                if (!root.controlDragSource)
                    return { "w": 1, "h": 1 };

                if (root.controlDragSource.fromPalette) {
                    const size = defaultModuleSize(root.controlDragSource.moduleId);
                    return { "w": size.w, "h": size.h };
                }

                return {
                    "w": root.controlDragSource.moduleWidthUnits || 1,
                    "h": root.controlDragSource.moduleHeightUnits || 1
                };
            }

            function defaultModuleSize(id) {
                return root.controlModuleDefaultSize(id);
            }

            function visualLayout() {
                const layout = root.controlLayout().slice();
                const hasCellTarget = root.controlDropCol >= 0 && root.controlDropRow >= 0;
                if (root.controlResizeActive && root.controlResizeSource && root.controlResizeIndex >= 0 && root.controlResizeIndex < layout.length) {
                    const resized = layout.splice(root.controlResizeIndex, 1)[0];
                    const basePlaced = packLayout([resized].concat(layout));
                    const basePlacement = basePlaced[resized.id] || { "col": resized.col || 0, "row": resized.row || 0 };
                    resized.w = root.controlResizeWidthUnits;
                    resized.h = root.controlResizeHeightUnits;
                    resized.col = Math.max(0, Math.min(moduleGrid.columns - Math.max(1, resized.w || 1), Math.round(basePlacement.col || 0)));
                    resized.row = Math.max(0, Math.round(basePlacement.row || 0));
                    layout.unshift(resized);
                    return layout;
                }

                if (!root.controlDragActive || !root.controlDragSource || root.controlDropOnPalette || !hasCellTarget)
                    return layout;

                const placeholder = root.controlDragSource.fromPalette
                    ? defaultModuleSize(root.controlDragSource.moduleId)
                    : {
                        "id": "__dropPlaceholder",
                        "w": root.controlDragSource.moduleWidthUnits || 1,
                        "h": root.controlDragSource.moduleHeightUnits || 1,
                        "v": 2
                    };
                placeholder.id = "__dropPlaceholder";
                placeholder.col = root.controlDropCol;
                placeholder.row = root.controlDropRow;

                if (root.controlDragSource.fromPalette) {
                    const existing = layout.findIndex(item => item.id === root.controlDragSource.moduleId);
                    if (existing >= 0)
                        return layout;
                } else {
                    const from = root.controlDragSource.moduleIndex;
                    if (from >= 0 && from < layout.length)
                        layout.splice(from, 1);
                }

                layout.unshift(placeholder);
                return layout;
            }

            function canPlace(occupied, col, row, w, h) {
                if (col + w > moduleGrid.columns)
                    return false;

                for (let y = row; y < row + h; ++y) {
                    for (let x = col; x < col + w; ++x) {
                        if (occupied[y + ":" + x])
                            return false;

                    }
                }
                return true;
            }

            function occupy(occupied, col, row, w, h) {
                for (let y = row; y < row + h; ++y) {
                    for (let x = col; x < col + w; ++x)
                        occupied[y + ":" + x] = true;

                }
            }

            function canDropAtCell(col, row) {
                if (!root.controlDragSource || col < 0 || row < 0)
                    return false;

                const size = draggedSize();
                const w = Math.max(1, Math.min(moduleGrid.columns, Math.round(size.w || 1)));
                return col + w <= moduleGrid.columns;
            }

            function packLayout(layout) {
                const occupied = {};
                const placed = {};
                let rows = 0;

                for (let i = 0; i < layout.length; ++i) {
                    const item = layout[i] || {};
                    const w = Math.max(1, Math.min(moduleGrid.columns, Math.round(item.w || 1)));
                    const h = Math.max(1, Math.min(6, Math.round(item.h || 1)));
                    let row = 0;
                    let found = false;
                    if (isFinite(Number(item.col)) && isFinite(Number(item.row))) {
                        const col = Math.max(0, Math.min(moduleGrid.columns - w, Math.round(item.col)));
                        row = Math.max(0, Math.round(item.row));
                        if (canPlace(occupied, col, row, w, h)) {
                            occupy(occupied, col, row, w, h);
                            placed[item.id] = { "col": col, "row": row, "w": w, "h": h, "order": i };
                            rows = Math.max(rows, row + h);
                            found = true;
                        }
                    }

                    row = 0;
                    while (!found) {
                        for (let col = 0; col <= moduleGrid.columns - w; ++col) {
                            if (!canPlace(occupied, col, row, w, h))
                                continue;

                            occupy(occupied, col, row, w, h);
                            placed[item.id] = { "col": col, "row": row, "w": w, "h": h, "order": i };
                            rows = Math.max(rows, row + h);
                            found = true;
                            break;
                        }
                        if (!found)
                            row++;
                    }
                }

                placed.__rows = Math.max(1, rows);
                return placed;
            }

            function packedLayout() {
                root.controlLayoutRevision;
                root.controlDragActive;
                root.controlDropOnPalette;
                root.controlDropCol;
                root.controlDropRow;
                root.controlResizeActive;
                root.controlResizeIndex;
                root.controlResizeWidthUnits;
                root.controlResizeHeightUnits;
                return packLayout(visualLayout());
            }

            function placementFor(id) {
                const placed = packedLayout();
                return placed[id] || { "col": 0, "row": 0, "w": 1, "h": 1, "order": 0 };
            }

            function dropPlaceholderPlacement() {
                if (!root.controlEditMode || !root.controlDragActive || root.controlDropOnPalette || root.controlDropCol < 0 || root.controlDropRow < 0)
                    return { "visible": false, "col": 0, "row": 0, "w": 1, "h": 1 };

                const placed = packedLayout();
                const placeholder = placed.__dropPlaceholder;
                if (!placeholder)
                    return { "visible": false, "col": 0, "row": 0, "w": 1, "h": 1 };

                return {
                    "visible": true,
                    "col": placeholder.col,
                    "row": placeholder.row,
                    "w": placeholder.w,
                    "h": placeholder.h
                };
            }

            function gridX(col) {
                return col * (moduleGrid.unitSize + moduleGrid.gap);
            }

            function gridY(row) {
                return row * (moduleGrid.unitSize + moduleGrid.gap);
            }

            function gridWidth(widthUnits) {
                const units = Math.max(1, Math.round(widthUnits || 1));
                return units * moduleGrid.unitSize + (units - 1) * moduleGrid.gap;
            }

            function gridHeight(heightUnits) {
                const units = Math.max(1, Math.round(heightUnits || 1));
                return units * moduleGrid.unitSize + (units - 1) * moduleGrid.gap;
            }

            function packedHeight() {
                const placed = packedLayout();
                return placed.__rows * moduleGrid.unitSize + Math.max(0, placed.__rows - 1) * moduleGrid.gap;
            }

            function previewControlDrop(x, y) {
                root.controlDropOnPalette = containsPoint(palette, x, y);
                if (root.controlDropOnPalette || !containsPoint(moduleFlickable, x, y)) {
                    root.controlDropCol = -1;
                    root.controlDropRow = -1;
                    return ;
                }

                const cell = cellAtPoint(x, y);
                if (canDropAtCell(cell.col, cell.row)) {
                    root.controlDropCol = cell.col;
                    root.controlDropRow = cell.row;
                    return ;
                }

                root.controlDropCol = -1;
                root.controlDropRow = -1;
            }

            function finishControlDrop(source, x, y) {
                if (!source)
                    return ;

                previewControlDrop(x, y);

                if (root.controlDropOnPalette) {
                    if (!source.fromPalette)
                        root.removeControlModule(source.moduleIndex);

                    return ;
                }

                if (root.controlDropCol >= 0 && root.controlDropRow >= 0) {
                    commitControlDropAtCell(source, root.controlDropCol, root.controlDropRow);

                    return ;
                }

                if (source.fromPalette && containsPoint(moduleFlickable, x, y))
                    root.addControlModule(source.moduleId);
            }

            function commitControlDropAtCell(source, col, row) {
                const layout = root.controlLayout();
                let item = null;

                if (source.fromPalette) {
                    for (let i = 0; i < layout.length; ++i) {
                        if (layout[i].id === source.moduleId)
                            return ;
                    }
                    item = defaultModuleSize(source.moduleId);
                } else {
                    if (source.moduleIndex < 0 || source.moduleIndex >= layout.length)
                        return ;

                    item = layout.splice(source.moduleIndex, 1)[0];
                }

                item.col = Math.max(0, Math.min(moduleGrid.columns - Math.max(1, item.w || 1), Math.round(col)));
                item.row = Math.max(0, Math.round(row));

                const ordered = [item].concat(layout);
                const placed = packLayout(ordered);
                const saved = [];
                for (let i = 0; i < ordered.length; ++i) {
                    const module = ordered[i];
                    const placement = placed[module.id];
                    if (!placement)
                        continue;

                    saved.push({
                        "id": module.id,
                        "w": placement.w,
                        "h": placement.h,
                        "col": placement.col,
                        "row": placement.row,
                        "v": 2
                    });
                }
                root.updateControlLayout(saved);
            }

            function commitControlResize(source, widthUnits, heightUnits) {
                const layout = root.controlLayout();
                if (!source || source.moduleIndex < 0 || source.moduleIndex >= layout.length)
                    return ;

                const item = layout.splice(source.moduleIndex, 1)[0];
                const basePlaced = packLayout([item].concat(layout));
                const basePlacement = basePlaced[item.id] || { "col": item.col || 0, "row": item.row || 0 };
                const size = root.clampedControlModule(item.id, widthUnits, heightUnits);
                item.w = size.w;
                item.h = size.h;
                item.col = Math.max(0, Math.min(moduleGrid.columns - item.w, Math.round(basePlacement.col || 0)));
                item.row = Math.max(0, Math.round(basePlacement.row || 0));
                item.v = 2;

                const ordered = [item].concat(layout);
                const placed = packLayout(ordered);
                const saved = [];
                for (let i = 0; i < ordered.length; ++i) {
                    const module = ordered[i];
                    const placement = placed[module.id];
                    if (!placement)
                        continue;

                    saved.push({
                        "id": module.id,
                        "w": placement.w,
                        "h": placement.h,
                        "col": placement.col,
                        "row": placement.row,
                        "v": 2
                    });
                }
                root.updateControlLayout(saved);
            }

            RowLayout {
                id: editBar

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 34
                spacing: 8

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.controlEditMode ? "Edit control center" : "Control center"
                    color: "#f8f8fb"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                IslandButton {
                    visible: !root.controlEditMode
                    iconName: "document-edit"
                    compact: true
                    tooltipText: "Edit layout"
                    onClicked: root.beginControlEdit()
                }

                IslandButton {
                    visible: root.controlEditMode
                    iconName: "dialog-cancel"
                    compact: true
                    tooltipText: "Cancel changes"
                    onClicked: root.cancelControlEdit()
                }

                IslandButton {
                    visible: root.controlEditMode
                    iconName: "restore-defaults"
                    compact: true
                    tooltipText: "Reset draft to default"
                    onClicked: root.resetControlLayout()
                }

                IslandButton {
                    visible: root.controlEditMode
                    iconName: "dialog-ok-apply"
                    compact: true
                    emphasized: true
                    tooltipText: "Save layout"
                    onClicked: root.saveControlEdit()
                }
            }

            Flickable {
                id: moduleFlickable

                anchors.left: parent.left
                anchors.right: root.controlEditMode ? palette.left : parent.right
                anchors.rightMargin: root.controlEditMode ? 10 : 0
                anchors.top: editBar.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                clip: true
                interactive: !root.controlDragActive && !root.controlResizeActive
                contentWidth: width
                contentHeight: moduleGrid.height

                Item {
                    id: moduleGrid

                    width: parent.width
                    height: controlPage.packedHeight()
                    property int columns: 8
                    property int gap: 8
                    property real unitSize: Math.floor((width - gap * (columns - 1)) / columns)
                    readonly property var dropPreview: controlPage.dropPlaceholderPlacement()

                    Rectangle {
                        id: dropReservedSpace

                        visible: moduleGrid.dropPreview.visible
                        x: controlPage.gridX(moduleGrid.dropPreview.col)
                        y: controlPage.gridY(moduleGrid.dropPreview.row)
                        width: controlPage.gridWidth(moduleGrid.dropPreview.w)
                        height: controlPage.gridHeight(moduleGrid.dropPreview.h)
                        radius: Math.min(18, Math.min(width, height) / 2)
                        color: "#171824"
                        border.color: "#8e8eff"
                        border.width: 2
                        opacity: visible ? 0.92 : 0
                        z: 0

                        Behavior on x {
                            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
                        }

                        Behavior on y {
                            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
                        }

                        Behavior on width {
                            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
                        }

                        Behavior on height {
                            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: Math.max(1, parent.radius - 5)
                            color: "transparent"
                            border.color: "#3e4052"
                            border.width: 1
                            opacity: 0.85
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Math.max(16, Math.min(30, parent.width - 18, parent.height - 18))
                            height: width
                            source: root.controlDragIcon
                            color: "#d8d8ff"
                            opacity: 0.62
                        }
                    }

                    Repeater {
                        id: moduleRepeater

                        model: root.controlLayout()

                        ModuleCard {
                            required property var modelData
                            required property int index

                            readonly property var packed: controlPage.placementFor(modelData.id)

                            x: controlPage.gridX(packed.col)
                            y: controlPage.gridY(packed.row)
                            width: controlPage.gridWidth(packed.w)
                            height: controlPage.gridHeight(packed.h)
                            moduleId: modelData.id
                            moduleIndex: index
                            moduleWidthUnits: modelData.w || 1
                            moduleHeightUnits: modelData.h || 1
                            gridUnitSize: moduleGrid.unitSize
                            gridGap: moduleGrid.gap
                        }
                    }
                }
            }

            Rectangle {
                id: palette

                visible: root.controlEditMode
                anchors.right: parent.right
                anchors.top: editBar.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                width: root.controlEditMode ? 150 : 0
                radius: 20
                color: root.controlDropOnPalette ? "#171824" : "#0d0e14"
                border.color: root.controlDropOnPalette ? "#8e8eff" : "#282933"
                border.width: root.controlDropOnPalette ? 2 : 1
                clip: true

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "Modules"
                        color: "#f8f8fb"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "Drag into the grid. Drop a tile here to hide it."
                        color: "#8f9099"
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        interactive: !root.controlDragActive && !root.controlResizeActive
                        contentWidth: width
                        contentHeight: paletteColumn.implicitHeight

                        ColumnLayout {
                            id: paletteColumn

                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: root.controlModules

                                PaletteModule {
                                    Layout.fillWidth: true
                                    moduleId: modelData.id
                                    title: modelData.name
                                }
                            }
                        }
                    }
                }
            }

        }

    }

    component ModuleCard: Rectangle {
        id: moduleCard

        property string moduleId: ""
        property int moduleIndex: -1
        property int moduleWidthUnits: 1
        property int moduleHeightUnits: 1
        property real gridUnitSize: 64
        property real gridGap: 8
        property bool fromPalette: false
        radius: 18
        color: "#101116"
        border.color: root.controlEditMode ? "#4b4c58" : "#202129"
        border.width: 1
        clip: true
        opacity: root.controlDragActive && root.controlDragSource === moduleCard ? 0 : 1
        z: 2
        scale: 1

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }

        Behavior on x {
            enabled: root.controlEditMode
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            enabled: root.controlEditMode
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Behavior on width {
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Loader {
            anchors.fill: parent
            anchors.margins: root.controlEditMode ? Math.min(8, Math.max(4, Math.min(moduleCard.width, moduleCard.height) * 0.1)) : 0
            sourceComponent: {
                if (moduleCard.moduleId === "userPower")
                    return userPowerModule;
                if (moduleCard.moduleId === "volume")
                    return volumeModule;
                if (moduleCard.moduleId === "brightness")
                    return brightnessModule;
                if (moduleCard.moduleId === "wifi")
                    return wifiModule;
                if (moduleCard.moduleId === "wifiDevices")
                    return wifiDevicesModule;
                if (moduleCard.moduleId === "bluetooth")
                    return bluetoothModule;
                if (moduleCard.moduleId === "bluetoothDiscovery")
                    return bluetoothDiscoveryModule;
                if (moduleCard.moduleId === "notifications")
                    return notificationsModule;
                if (moduleCard.moduleId === "batteryStatus")
                    return batteryStatusModule;
                if (moduleCard.moduleId === "batteryPercent")
                    return batteryPercentModule;
                if (moduleCard.moduleId === "powerMode")
                    return powerModeModule;
                if (moduleCard.moduleId === "appearanceMode")
                    return appearanceModeModule;
                if (moduleCard.moduleId === "theme")
                    return themeModule;
                if (moduleCard.moduleId === "media")
                    return mediaModule;
                if (moduleCard.moduleId === "kdeConnect")
                    return kdeConnectModule;
                if (moduleCard.moduleId === "settings")
                    return settingsModule;
                return emptyModule;
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.controlEditMode
            color: "transparent"
            border.color: "#7a7b88"
            border.width: 1
            radius: parent.radius
        }

        MouseArea {
            id: dragArea

            visible: root.controlEditMode
            anchors.fill: parent
            anchors.margins: 2
            hoverEnabled: true
            drag.threshold: 8
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            onPressed: (mouse) => {
                mouse.accepted = true;
                const local = dragArea.mapToItem(moduleCard, mouse.x, mouse.y);
                const pitch = Math.max(1, moduleCard.gridUnitSize + moduleCard.gridGap);
                root.controlDragOffsetCol = Math.max(0, Math.min(moduleCard.moduleWidthUnits - 1, Math.floor(local.x / pitch)));
                root.controlDragOffsetRow = Math.max(0, Math.min(moduleCard.moduleHeightUnits - 1, Math.floor(local.y / pitch)));
                root.beginControlDrag(moduleCard, dragArea, mouse, 54);
            }
            onPositionChanged: (mouse) => {
                mouse.accepted = true;
                root.updateControlDrag(dragArea, mouse);
            }
            onReleased: (mouse) => {
                mouse.accepted = true;
                root.endControlDrag(dragArea, mouse, true);
            }
            onCanceled: root.endControlDrag(null, null, false)
        }

        Rectangle {
            visible: root.controlEditMode
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 7
            radius: 9
            color: "#1b1c24"
            border.color: "#42434d"
            border.width: 1
            width: moduleLabel.implicitWidth + 16
            height: 22

            QQC2.Label {
                id: moduleLabel

                anchors.centerIn: parent
                text: root.moduleInfo(moduleCard.moduleId).name
                color: "#d8d8e2"
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: resizeHandle

            property real startPointerX: 0
            property real startPointerY: 0
            property int startW: 1
            property int startH: 1

            visible: root.controlEditMode
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Math.min(34, Math.max(24, Math.min(moduleCard.width, moduleCard.height) * 0.55))
            height: width
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            preventStealing: true
            onPressed: (mouse) => {
                mouse.accepted = true;
                const p = resizeHandle.mapToItem(dialogHost, mouse.x, mouse.y);
                startPointerX = p.x;
                startPointerY = p.y;
                startW = moduleCard.moduleWidthUnits;
                startH = moduleCard.moduleHeightUnits;
                root.beginControlResize(moduleCard);
            }
            onPositionChanged: (mouse) => {
                if (!pressed || !root.controlResizeActive)
                    return ;

                mouse.accepted = true;
                const p = resizeHandle.mapToItem(dialogHost, mouse.x, mouse.y);
                const step = Math.max(1, moduleCard.gridUnitSize + moduleCard.gridGap);
                const newW = startW + Math.round((p.x - startPointerX) / step);
                const newH = startH + Math.round((p.y - startPointerY) / step);
                root.updateControlResize(moduleCard, newW, newH);
            }
            onReleased: (mouse) => {
                mouse.accepted = true;
                root.endControlResize(moduleCard, true);
            }
            onCanceled: root.endControlResize(moduleCard, false)

            Canvas {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 24
                height: 24
                opacity: resizeHandle.containsMouse ? 1 : 0.62

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#8e8eff";
                    ctx.lineWidth = 2;
                    for (let i = 0; i < 3; ++i) {
                        ctx.beginPath();
                        ctx.moveTo(width - 5 - i * 6, height - 2);
                        ctx.lineTo(width - 2, height - 5 - i * 6);
                        ctx.stroke();
                    }
                }
            }
        }

        Component {
            id: userPowerModule

            Item {
                id: userPowerContent

                anchors.fill: parent
                readonly property bool narrow: width < 82
                readonly property bool compact: width < 150 || height < 74
                readonly property bool shortTile: height < 62
                readonly property bool micro: narrow || width < 108
                readonly property real pad: compact ? 7 : 10
                readonly property real avatarSize: Math.max(18, Math.min(compact ? 34 : 38, height - pad * 2, narrow ? width - pad * 2 : width * 0.36))
                readonly property real buttonSize: Math.max(22, Math.min(compact ? 30 : 34, width - pad * 2, height - pad * 2))

                Rectangle {
                    id: profileAvatarFrame

                    width: userPowerContent.avatarSize
                    height: width
                    x: userPowerContent.narrow ? Math.round((parent.width - width) / 2) : userPowerContent.pad
                    y: userPowerContent.narrow && !userPowerContent.shortTile ? userPowerContent.pad : Math.round((parent.height - height) / 2)
                    radius: width / 2
                    color: "#24252e"
                    clip: true

                    Image {
                        id: profileAvatarImage

                        anchors.fill: parent
                        source: root.profileFaceUrl()
                        fillMode: Image.PreserveAspectCrop
                        visible: root.profileFaceUrl().length > 0 && status === Image.Ready
                        layer.enabled: visible

                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSpreadAtMax: 1
                            maskSpreadAtMin: 1
                            maskThresholdMin: 0.5

                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: profileAvatarImage.width
                                    height: profileAvatarImage.height
                                    radius: Math.min(width, height) / 2
                                    color: "#ffffff"
                                }
                            }
                        }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: "user-identity"
                        color: "#f8f8fb"
                        visible: !profileAvatarImage.visible
                    }
                }

                Column {
                    id: profileTextColumn

                    visible: !userPowerContent.micro || userPowerContent.shortTile && userPowerContent.width >= 92
                    x: userPowerContent.shortTile ? profileAvatarFrame.x + profileAvatarFrame.width + 8 : userPowerContent.compact ? userPowerContent.pad : profileAvatarFrame.x + profileAvatarFrame.width + 10
                    y: userPowerContent.shortTile ? Math.round((parent.height - height) / 2) : userPowerContent.compact ? profileAvatarFrame.y + profileAvatarFrame.height + 6 : Math.round((parent.height - height) / 2)
                    width: userPowerContent.shortTile ? Math.max(1, (powerButton.visible ? powerButton.x - x - 8 : parent.width - x - userPowerContent.pad)) : userPowerContent.compact ? Math.max(1, parent.width - userPowerContent.pad * 2) : Math.max(1, powerButton.x - x - 10)
                    spacing: userPowerContent.shortTile ? -1 : 1

                    QQC2.Label {
                        width: parent.width
                        text: root.systemUsername || "User"
                        color: "#f8f8fb"
                        font.pixelSize: userPowerContent.shortTile ? 10 : userPowerContent.compact ? 11 : 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    QQC2.Label {
                        visible: !userPowerContent.compact || userPowerContent.height >= 34
                        width: parent.width
                        text: root.systemHostname || "KDE Plasma"
                        color: "#8f9099"
                        font.pixelSize: userPowerContent.shortTile ? 8 : userPowerContent.compact ? 9 : 10
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                IslandButton {
                    id: powerButton

                    x: userPowerContent.narrow ? Math.round((parent.width - width) / 2) : parent.width - width - userPowerContent.pad
                    y: userPowerContent.narrow ? parent.height - height - userPowerContent.pad : userPowerContent.compact ? userPowerContent.pad : Math.round((parent.height - height) / 2)
                    width: userPowerContent.buttonSize
                    height: width
                    visible: !userPowerContent.shortTile && (!userPowerContent.narrow || parent.height >= profileAvatarFrame.height + height + userPowerContent.pad * 3)
                    iconName: "system-shutdown"
                    compact: true
                    onClicked: powerMenu.open()

                    QQC2.Menu {
                        id: powerMenu

                        QQC2.MenuItem { text: "Lock"; onTriggered: root.runPowerAction("lock") }
                        QQC2.MenuItem { text: "Logout"; onTriggered: root.runPowerAction("logout") }
                        QQC2.MenuItem { text: "Sleep"; onTriggered: root.runPowerAction("sleep") }
                        QQC2.MenuItem { text: "Hibernate"; onTriggered: root.runPowerAction("hibernate") }
                        QQC2.MenuSeparator {}
                        QQC2.MenuItem { text: "Reboot"; onTriggered: root.runPowerAction("reboot") }
                        QQC2.MenuItem { text: "Shutdown"; onTriggered: root.runPowerAction("shutdown") }
                    }
                }

                Row {
                    visible: !userPowerContent.compact && userPowerContent.width >= 210 && userPowerContent.height >= 116
                    x: profileTextColumn.x
                    y: parent.height - height - userPowerContent.pad
                    spacing: 7

                    IslandButton {
                        width: 28
                        height: 28
                        iconName: "system-lock-screen"
                        compact: true
                        onClicked: root.runPowerAction("lock")
                    }

                    IslandButton {
                        width: 28
                        height: 28
                        iconName: "system-suspend"
                        compact: true
                        onClicked: root.runPowerAction("sleep")
                    }

                    IslandButton {
                        width: 28
                        height: 28
                        iconName: "preferences-desktop-theme-global"
                        compact: true
                        onClicked: root.launchAppearanceSettings()
                    }

                    IslandButton {
                        width: 28
                        height: 28
                        iconName: "systemsettings"
                        compact: true
                        onClicked: root.launchSystemSettings()
                    }
                }
            }
        }

        Component {
            id: volumeModule

            ControlSlider {
                anchors.fill: parent
                anchors.margins: 0
                title: "Volume"
                iconName: {
                    const sink = root.defaultSink();
                    return sink && sink.muted ? "audio-volume-muted" : "audio-volume-high";
                }
                valueText: {
                    const sink = root.defaultSink();
                    return sink && sink.muted ? "Muted" : root.systemVolumePercent() + "%";
                }
                value: Math.min(100, root.systemVolumePercent())
                toValue: 100
                accent: "#5ac8fa"
                enabled: root.defaultSink() !== null
                actionIconName: {
                    const sink = root.defaultSink();
                    return sink && sink.muted ? "audio-volume-high" : "audio-volume-muted";
                }
                secondaryActionIconName: "settings"
                onActionTriggered: root.toggleSystemMute()
                onSecondaryActionTriggered: root.launchPavucontrol()
                onMoved: (value) => root.setSystemVolumePercent(value)
            }
        }

        Component {
            id: brightnessModule

            ControlSlider {
                anchors.fill: parent
                title: "Brightness"
                iconName: "brightness-high"
                valueText: screenBrightness.isBrightnessAvailable ? root.displayedScreenBrightnessPercent() + "%" : "--"
                value: root.displayedScreenBrightnessPercent()
                accent: "#f5d64a"
                enabled: screenBrightness.isBrightnessAvailable
                actionIconName: "video-display"
                secondaryActionIconName: keyboardBrightness.isBrightnessAvailable ? "input-keyboard" : ""
                onActionTriggered: root.launchDisplaySettings()
                onSecondaryActionTriggered: root.setKeyboardBrightnessPercent(root.keyboardBrightnessPercent() <= 20 ? 100 : 0)
                onMoved: (value) => root.setScreenBrightnessPercent(value)
            }
        }

        Component {
            id: wifiModule

            SimpleModuleTile {
                iconName: enabledConnections.wirelessEnabled ? "network-wireless-on" : "network-wireless-off"
                title: "Wi-Fi"
                subtitle: root.wifiPrimaryNetwork()
                active: enabledConnections.wirelessEnabled
                accent: "#0a84ff"
                progress: root.wifiSignalPercent()
                detailText: root.wifiTitle()
                footerText: enabledConnections.wirelessHwEnabled ? "Click to toggle" : "No adapter"
                actionIconName: "settings"
                onActionTriggered: root.launchNetworkSettings()
                onTriggered: root.toggleWifi()
            }
        }

        Component {
            id: wifiDevicesModule

            NetworkListModule {}
        }

        Component {
            id: mediaModule

            ActivitySummary {
                anchors.fill: parent
                mediaOnly: true
                radius: moduleCard.radius
                border.width: 0
            }
        }

        Component {
            id: notificationsModule

            Item {
                id: notificationsContent

                anchors.fill: parent
                readonly property int notificationTotal: root.notificationCount()
                readonly property bool iconOnly: width < 100 || height < 62
                readonly property bool compact: width < 165 || height < 115

                ColumnLayout {
                    visible: !notificationsContent.iconOnly
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Kirigami.Icon {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            source: notificationsContent.notificationTotal > 0 ? "notifications" : "notifications-disabled"
                            color: notificationsContent.notificationTotal > 0 ? "#ff9f0a" : "#8f9099"
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: notificationsContent.notificationTotal > 0 ? notificationsContent.notificationTotal + " notifications" : "Notifications"
                            color: "#f8f8fb"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        IslandButton {
                            visible: !notificationsContent.compact
                            iconName: "edit-clear-all"
                            compact: true
                            enabled: notificationsContent.notificationTotal > 0
                            onClicked: root.clearNotifications()
                        }

                        IslandButton {
                            visible: !notificationsContent.compact
                            iconName: "settings"
                            compact: true
                            onClicked: root.launchNotificationSettings()
                        }
                    }

                    Repeater {
                        model: root.notificationRows(notificationsContent.compact ? 2 : 4)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.preferredWidth: 5
                                Layout.preferredHeight: 5
                                radius: 3
                                color: "#ff9f0a"
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: root.cleanText(root.rowValue(modelData, NotificationManager.Notifications.SummaryRole, "Notification"))
                                color: "#c9c9d2"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            IslandButton {
                                visible: !notificationsContent.compact
                                iconName: "window-close"
                                compact: true
                                enabled: root.rowValue(modelData, NotificationManager.Notifications.ClosableRole, true)
                                onClicked: notifications.close(notifications.index(modelData, 0))
                            }
                        }
                    }

                    QQC2.Label {
                        visible: notificationsContent.notificationTotal <= 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "Quiet"
                        color: "#777884"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Kirigami.Icon {
                    visible: notificationsContent.iconOnly
                    anchors.centerIn: parent
                    width: Math.max(20, Math.min(34, parent.width - 14, parent.height - 14))
                    height: width
                    source: notificationsContent.notificationTotal > 0 ? "notifications" : "notifications-disabled"
                    color: notificationsContent.notificationTotal > 0 ? "#ff9f0a" : "#8f9099"
                }

                Rectangle {
                    visible: notificationsContent.iconOnly && notificationsContent.notificationTotal > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 7
                    width: Math.max(16, countLabel.implicitWidth + 8)
                    height: 16
                    radius: 8
                    color: "#ff453a"

                    QQC2.Label {
                        id: countLabel

                        anchors.centerIn: parent
                        text: notificationsContent.notificationTotal
                        color: "#ffffff"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }
        }

        Component {
            id: bluetoothModule

            SimpleModuleTile {
                iconName: "preferences-system-bluetooth"
                title: "Bluetooth"
                subtitle: root.bluetoothPowered ? root.bluetoothDevicesText.length > 0 ? root.bluetoothDevicesText.split("\n")[0] : "On" : "Off"
                active: root.bluetoothPowered
                accent: "#0a84ff"
                detailText: root.bluetoothPowered ? root.bluetoothDevicesText.length > 0 ? root.bluetoothDevicesText : "No connected devices" : "Radio disabled"
                footerText: "Click to toggle"
                actionIconName: "settings"
                onActionTriggered: root.launchBluetoothSettings()
                onTriggered: root.toggleBluetoothPower()
            }
        }

        Component {
            id: bluetoothDiscoveryModule

            SimpleModuleTile {
                iconName: "preferences-system-bluetooth"
                title: "Discover"
                subtitle: root.bluetoothPowered ? root.bluetoothDevicesText.length > 0 ? root.bluetoothDevicesText.split("\n")[0] : "Devices" : "Turn on first"
                active: true
                accent: "#5ac8fa"
                detailText: root.bluetoothPowered ? root.bluetoothDevicesText.length > 0 ? root.bluetoothDevicesText : "Pair, trust and connect" : "Bluetooth is off"
                footerText: "Open Bluetooth"
                onTriggered: root.launchBluetoothDiscovery()
            }
        }

        Component {
            id: batteryStatusModule

            SimpleModuleTile {
                iconName: batteryControl.pluggedIn ? "battery-charging" : "battery"
                title: "Battery"
                subtitle: batteryControl.pluggedIn ? "Charging" : "On battery"
                active: batteryControl.pluggedIn
                accent: "#34c759"
                progress: batteryControl.hasInternalBatteries ? batteryControl.percent : 100
                detailText: root.batteryText()
                footerText: batteryControl.hasInternalBatteries ? (batteryControl.pluggedIn ? "Plugged in" : "Discharging") : "Desktop power"
                actionIconName: "settings"
                onActionTriggered: root.launchPowerSettings()
            }
        }

        Component {
            id: batteryPercentModule

            SimpleModuleTile {
                iconName: batteryControl.pluggedIn ? "battery-charging" : "battery"
                title: root.batteryText()
                subtitle: "Battery"
                active: batteryControl.pluggedIn
                accent: "#34c759"
                progress: batteryControl.hasInternalBatteries ? batteryControl.percent : 100
                detailText: batteryControl.pluggedIn ? "Charging" : "Power"
                actionIconName: "settings"
                onActionTriggered: root.launchPowerSettings()
            }
        }

        Component {
            id: powerModeModule

            SimpleModuleTile {
                iconName: root.powerProfileIcon()
                title: root.powerProfileTitle()
                subtitle: "Power mode"
                active: true
                accent: "#ffd60a"
                detailText: powerProfiles.profiles && powerProfiles.profiles.length > 1 ? "Click to cycle" : "Current profile"
                footerText: powerProfiles.activeProfile
                actionIconName: "settings"
                onActionTriggered: root.launchPowerSettings()
                onTriggered: root.cyclePowerProfile()
            }
        }

        Component {
            id: appearanceModeModule

            SimpleModuleTile {
                iconName: "preferences-desktop-theme"
                title: Brightness.DarkModeControl.darkMode ? "Dark" : "Light"
                subtitle: "Appearance"
                active: Brightness.DarkModeControl.darkMode
                accent: "#bf5af2"
                detailText: "Desktop color scheme"
                footerText: "Click to switch"
                onTriggered: root.toggleAppearanceMode()
            }
        }

        Component {
            id: themeModule

            SimpleModuleTile {
                iconName: "preferences-desktop-theme-global"
                title: "Theme"
                subtitle: "Global themes"
                active: true
                accent: "#bf5af2"
                detailText: "Open KDE themes"
                onTriggered: root.launchAppearanceSettings()
            }
        }

        Component {
            id: kdeConnectModule

            SimpleModuleTile {
                iconName: "kdeconnect"
                title: "KDE Connect"
                subtitle: "Devices"
                active: true
                accent: "#5ac8fa"
                detailText: "Phones and paired devices"
                onTriggered: root.launchKdeConnectSettings()
            }
        }

        Component {
            id: settingsModule

            SimpleModuleTile {
                iconName: "systemsettings"
                title: "Settings"
                subtitle: "System"
                active: true
                accent: "#8e8eff"
                detailText: "Open System Settings"
                onTriggered: root.launchSystemSettings()
            }
        }

        Component {
            id: emptyModule

            SimpleModuleTile {
                iconName: "unknown"
                title: moduleCard.moduleId
                subtitle: "Unknown"
                active: false
            }
        }
    }

    component NetworkListModule: MouseArea {
        id: networkList

        readonly property bool compact: width < 150 || height < 86
        readonly property bool iconOnly: width < 96 || height < 58
        readonly property var rows: root.wifiRows(compact ? 2 : 4)

        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.controlEditMode
        onClicked: root.launchNetworkSettings()

        Rectangle {
            anchors.fill: parent
            radius: Math.min(18, Math.min(width, height) / 2)
            color: networkList.pressed ? "#242630" : networkList.containsMouse ? "#1a1b24" : "#15161d"
            border.color: enabledConnections.wirelessEnabled ? "#29485f" : "#2a2b35"
            border.width: 1

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(3, parent.height * root.wifiSignalPercent() / 100)
                radius: parent.radius
                color: "#5ac8fa"
                opacity: enabledConnections.wirelessEnabled ? 0.18 : 0
            }
        }

        ColumnLayout {
            visible: !networkList.iconOnly
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Kirigami.Icon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    source: enabledConnections.wirelessEnabled ? "network-wireless-on" : "network-wireless-off"
                    color: enabledConnections.wirelessEnabled ? "#5ac8fa" : "#8f9099"
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: enabledConnections.wirelessEnabled ? "Networks" : "Wi-Fi Off"
                    color: "#f8f8fb"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                QQC2.Label {
                    visible: networkList.width >= 156
                    text: root.wifiSignalPercent() > 0 ? root.wifiSignalPercent() + "%" : ""
                    color: "#8f9099"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                IslandButton {
                    visible: !networkList.compact
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    iconName: "reset"
                    compact: true
                    onClicked: wifiRefreshTimer.restart()
                }

                IslandButton {
                    visible: !networkList.compact
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    iconName: "settings"
                    compact: true
                    onClicked: root.launchNetworkSettings()
                }
            }

            Repeater {
                model: networkList.rows.length > 0 ? networkList.rows : [enabledConnections.wirelessEnabled ? "No visible networks" : "Click to manage"]

                QQC2.Label {
                    Layout.fillWidth: true
                    text: modelData
                    color: String(modelData).indexOf("• ") === 0 ? "#f8f8fb" : "#9b9ca6"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        Kirigami.Icon {
            visible: networkList.iconOnly
            anchors.centerIn: parent
            width: Math.max(20, Math.min(36, parent.width - 14, parent.height - 14))
            height: width
            source: enabledConnections.wirelessEnabled ? "network-wireless-on" : "network-wireless-off"
            color: enabledConnections.wirelessEnabled ? "#5ac8fa" : "#8f9099"
        }

        QQC2.ToolTip.visible: networkList.containsMouse
        QQC2.ToolTip.text: root.networkSummary()
        QQC2.ToolTip.delay: 350
    }

    component PaletteModule: Rectangle {
        id: paletteModule

        property string moduleId: ""
        property string title: ""
        property bool fromPalette: true

        implicitHeight: 42
        radius: 13
        color: paletteDrag.pressed ? "#2b2c35" : root.controlDropOnPalette ? "#25263a" : "#171820"
        border.color: root.controlDropOnPalette ? "#8e8eff" : "#2a2b35"
        border.width: 1
        opacity: root.controlDragActive && root.controlDragSource === paletteModule ? 0.48 : 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 7

            Kirigami.Icon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: root.moduleIcon(paletteModule.moduleId)
                color: "#f1f1f6"
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: paletteModule.title
                color: "#f1f1f6"
                font.pixelSize: 10
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: paletteDrag

            property real pressX: 0
            property real pressY: 0
            property bool movedEnough: false

            anchors.fill: parent
            hoverEnabled: true
            drag.threshold: 8
            preventStealing: true
            onClicked: {
                if (!movedEnough)
                    root.addControlModule(paletteModule.moduleId);

            }
            onPressed: (mouse) => {
                mouse.accepted = true;
                pressX = mouse.x;
                pressY = mouse.y;
                movedEnough = false;
                root.controlDragOffsetCol = 0;
                root.controlDragOffsetRow = 0;
                root.beginControlDrag(paletteModule, paletteDrag, mouse, 48);
            }
            onPositionChanged: (mouse) => {
                if (Math.abs(mouse.x - pressX) > 8 || Math.abs(mouse.y - pressY) > 8)
                    movedEnough = true;

                mouse.accepted = true;
                root.updateControlDrag(paletteDrag, mouse);
            }
            onReleased: (mouse) => {
                mouse.accepted = true;
                root.endControlDrag(paletteDrag, mouse, movedEnough);
            }
            onCanceled: root.endControlDrag(null, null, false)
        }

    }

    component SimpleModuleTile: MouseArea {
        id: simpleTile

        property string iconName: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property color accent: "#5ac8fa"
        property real progress: -1
        property string detailText: ""
        property string footerText: ""
        property string actionIconName: ""
        readonly property bool iconOnly: width < 92 || height < 54
        readonly property bool detailed: !iconOnly && width >= 142 && height >= 88
        readonly property bool hasAction: actionIconName.length > 0
        readonly property real contentMargin: iconOnly ? 6 : 8
        readonly property real safeProgress: root.clampNumber(progress, 0, 100)

        signal triggered()
        signal actionTriggered()

        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.controlEditMode
        onClicked: simpleTile.triggered()

        Rectangle {
            anchors.fill: parent
            radius: Math.min(18, Math.min(width, height) / 2)
            color: simpleTile.pressed ? "#242630" : simpleTile.containsMouse ? "#1a1b24" : simpleTile.active ? "#171821" : "#15161d"
            border.color: simpleTile.active ? Qt.rgba(simpleTile.accent.r, simpleTile.accent.g, simpleTile.accent.b, 0.5) : "#2a2b35"
            border.width: 1
        }

        Rectangle {
            visible: simpleTile.progress >= 0
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * simpleTile.safeProgress / 100
            radius: Math.min(18, Math.min(parent.width, parent.height) / 2)
            color: simpleTile.accent
            opacity: 0.18
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: simpleTile.contentMargin
            anchors.rightMargin: simpleTile.detailed && simpleTile.hasAction ? 40 : simpleTile.contentMargin
            spacing: simpleTile.iconOnly ? 0 : 8

            Kirigami.Icon {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: Math.max(18, Math.min(simpleTile.detailed ? 30 : 34, simpleTile.width - simpleTile.contentMargin * 2, simpleTile.height - simpleTile.contentMargin * 2))
                Layout.preferredHeight: Layout.preferredWidth
                source: simpleTile.iconName
                color: simpleTile.active ? simpleTile.accent : "#9c9da8"
            }

            ColumnLayout {
                visible: !simpleTile.iconOnly
                Layout.fillWidth: true
                spacing: simpleTile.detailed ? 4 : 1

                QQC2.Label {
                    Layout.fillWidth: true
                    text: simpleTile.title
                    color: "#f8f8fb"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: simpleTile.subtitle
                    color: "#8f9099"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                QQC2.Label {
                    visible: simpleTile.detailed && simpleTile.detailText.length > 0
                    Layout.fillWidth: true
                    text: simpleTile.detailText
                    color: "#c9c9d2"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Rectangle {
                    visible: simpleTile.detailed && simpleTile.progress >= 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    color: "#2a2b35"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * simpleTile.safeProgress / 100
                        radius: parent.radius
                        color: simpleTile.accent
                    }
                }

                QQC2.Label {
                    visible: simpleTile.detailed && simpleTile.footerText.length > 0
                    Layout.fillWidth: true
                    text: simpleTile.footerText
                    color: "#777884"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        IslandButton {
            visible: simpleTile.detailed && simpleTile.hasAction
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            width: 26
            height: 26
            compact: true
            iconName: simpleTile.actionIconName
            onClicked: simpleTile.actionTriggered()
        }

        QQC2.ToolTip.visible: simpleTile.containsMouse && (simpleTile.detailText.length > 0 || simpleTile.footerText.length > 0)
        QQC2.ToolTip.text: simpleTile.title + (simpleTile.subtitle.length > 0 ? " · " + simpleTile.subtitle : "") + (simpleTile.detailText.length > 0 ? "\n" + simpleTile.detailText : "")
        QQC2.ToolTip.delay: 350
    }

    component ActivitySummary: Rectangle {
        id: activitySummary

        property bool mediaOnly: false
        readonly property bool showMedia: root.hasPlayer
        readonly property bool showAnyActivity: mediaOnly ? showMedia : root.hasActivity
        readonly property string summaryMode: mediaOnly ? root.hasPlayer ? "media" : "idle" : root.activityMode()
        readonly property color activityColor: mediaOnly ? "#5ac8fa" : root.isPlaying ? "#c026d3" : root.hasNotifications ? "#ff9f0a" : root.hasJobs ? "#34c759" : "#54545f"
        readonly property bool iconOnly: width < 100 || height < 62
        readonly property bool compact: width < 190 || height < 112
        readonly property real artSize: iconOnly ? Math.max(24, Math.min(width, height) - 18) : compact ? Math.max(36, Math.min(52, height - 22)) : Math.max(48, Math.min(64, height - 28))

        radius: 22
        color: "#101116"
        border.color: "#202129"
        border.width: 1
        clip: true

        RowLayout {
            visible: !activitySummary.iconOnly
            anchors.fill: parent
            anchors.margins: activitySummary.compact ? 10 : 14
            spacing: activitySummary.compact ? 9 : 13

            MaskedArtwork {
                Layout.preferredWidth: activitySummary.artSize
                Layout.preferredHeight: activitySummary.artSize
                artworkSource: root.hasPlayer ? root.player.artUrl : ""
                cornerRadius: activitySummary.compact ? 12 : 16
                glyphSize: activitySummary.compact ? 28 : 36
                mode: activitySummary.summaryMode
                progress: Math.max(0, notifications.jobsPercentage) / 100
                playing: root.isPlaying
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: activitySummary.showAnyActivity ? root.primaryText() : activitySummary.mediaOnly ? "Nothing playing" : "Ready"
                            color: "#ffffff"
                            font.pixelSize: activitySummary.compact ? 12 : 15
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: activitySummary.showAnyActivity ? root.secondaryText() : activitySummary.mediaOnly ? "" : "Media, notifications and jobs"
                            color: "#9b9ba6"
                            font.pixelSize: activitySummary.compact ? 10 : 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                    }

                    IslandBars {
                        visible: !activitySummary.compact || width >= 260
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 28
                        color: activitySummary.activityColor
                        playing: activitySummary.mediaOnly ? root.isPlaying : root.isPlaying || root.hasJobs || root.hasNotifications
                    }

                }

                ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    visible: !activitySummary.compact && ((!activitySummary.mediaOnly && root.hasJobs) || (root.hasPlayer && root.player.length > 0))
                    from: 0
                    to: !activitySummary.mediaOnly && root.hasJobs ? 100 : Math.max(1, root.player ? root.player.length : 1)
                    value: !activitySummary.mediaOnly && root.hasJobs ? Math.max(0, notifications.jobsPercentage) : root.player ? root.player.position : 0
                    accent: !activitySummary.mediaOnly && root.hasJobs ? "#34c759" : "#5ac8fa"
                }

                RowLayout {
                    visible: !activitySummary.compact
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        visible: root.hasPlayer
                        spacing: 8

                        IslandButton {
                            iconName: "media-skip-backward"
                            compact: true
                            enabled: root.player && root.player.canGoPrevious
                            onClicked: root.player.Previous()
                        }

                        IslandButton {
                            iconName: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                            compact: true
                            emphasized: true
                            enabled: root.player && (root.player.canPlay || root.player.canPause)
                            onClicked: root.player.PlayPause()
                        }

                        IslandButton {
                            iconName: "media-skip-forward"
                            compact: true
                            enabled: root.player && root.player.canGoNext
                            onClicked: root.player.Next()
                        }

                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: activitySummary.mediaOnly ? root.hasPlayer ? root.player.identity || "Media player" : "" : root.hasJobs ? "Download active" : root.hasNotifications ? notifications.unreadNotificationsCount + " unread" : enabledConnections.networkingEnabled ? "Wired connected" : "Network offline"
                        color: "#8f9099"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }

                }

            }

        }

        MaskedArtwork {
            visible: activitySummary.iconOnly
            anchors.centerIn: parent
            width: activitySummary.artSize
            height: width
            artworkSource: root.hasPlayer ? root.player.artUrl : ""
            cornerRadius: 10
            glyphSize: width * 0.7
            mode: activitySummary.summaryMode
            progress: Math.max(0, notifications.jobsPercentage) / 100
            playing: root.isPlaying
        }

        IslandBars {
            visible: activitySummary.iconOnly && (activitySummary.mediaOnly ? root.isPlaying : root.isPlaying || root.hasJobs || root.hasNotifications) && width >= 58
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            spacing: 2
            color: activitySummary.activityColor
            playing: true
        }

    }

    component IslandBars: Row {
        id: islandBars

        property bool playing: false
        property color color: "#c026d3"

        spacing: 4

        Repeater {
            model: [0.42, 0.88, 0.55, 0.74, 0.36]

            Rectangle {
                property real level: modelData

                width: 4
                height: Math.max(5, islandBars.height * level)
                y: (islandBars.height - height) / 2
                radius: 2
                color: islandBars.color
                opacity: islandBars.playing ? 1 : 0.45

                SequentialAnimation on level {
                    running: islandBars.playing
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: index * 55
                    }

                    NumberAnimation {
                        to: Math.max(0.24, 1 - modelData * 0.35)
                        duration: 210 + index * 20
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: modelData
                        duration: 240 + index * 25
                        easing.type: Easing.InOutSine
                    }

                }

            }

        }

    }

    component MaskedArtwork: Item {
        id: maskedArtwork

        property var artworkSource: ""
        property real cornerRadius: height / 2
        property string mode: "idle"
        property real progress: 0
        property bool playing: false
        property real glyphSize: width * 0.74
        readonly property bool hasArtworkSource: artworkSource && artworkSource.toString().length > 0
        readonly property bool hasArtwork: hasArtworkSource && maskedImage.status === Image.Ready

        Rectangle {
            anchors.fill: parent
            radius: maskedArtwork.cornerRadius
            color: "#101015"
        }

        Image {
            id: maskedImage

            anchors.fill: parent
            source: maskedArtwork.artworkSource
            fillMode: Image.PreserveAspectCrop
            visible: maskedArtwork.hasArtwork
            layer.enabled: visible

            layer.effect: MultiEffect {
                maskEnabled: true
                maskSpreadAtMax: 1
                maskSpreadAtMin: 1
                maskThresholdMin: 0.5

                maskSource: ShaderEffectSource {

                    sourceItem: Rectangle {
                        width: maskedImage.width
                        height: maskedImage.height
                        radius: maskedArtwork.cornerRadius
                        color: "#ffffff"
                    }

                }

            }

        }

        IslandGlyph {
            anchors.centerIn: parent
            width: maskedArtwork.glyphSize
            height: width
            mode: maskedArtwork.mode
            progress: maskedArtwork.progress
            playing: maskedArtwork.playing
            visible: !maskedArtwork.hasArtwork
        }

    }

    component ControlTile: MouseArea {
        id: tile

        property string iconName: ""
        property string label: ""
        property string tooltip: ""
        property bool active: false
        property bool interactive: true
        property color accent: "#5ac8fa"

        implicitWidth: 70
        implicitHeight: 66
        hoverEnabled: true
        enabled: interactive
        QQC2.ToolTip.visible: tile.containsMouse && tile.tooltip.length > 0
        QQC2.ToolTip.text: tile.tooltip
        QQC2.ToolTip.delay: 450

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: tile.pressed ? "#33343d" : tile.containsMouse && tile.interactive ? "#25262e" : tile.active ? "#1d1e27" : "#15161d"
            border.color: tile.active ? Qt.rgba(tile.accent.r, tile.accent.g, tile.accent.b, 0.52) : "#2a2b35"
            border.width: 1
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 10
            spacing: 3

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: tile.iconName
                color: tile.active ? tile.accent : "#8e8f99"
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: tile.label
                color: tile.active ? "#f8f8fb" : "#b8b8c1"
                font.pixelSize: 9
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }

        }

    }

    component ControlSlider: Item {
        id: controlSlider

        property string title: ""
        property string iconName: ""
        property string valueText: ""
        property real value: 0
        property real toValue: 100
        property color accent: "#5ac8fa"
        property string actionIconName: ""
        property string secondaryActionIconName: ""
        readonly property real safeToValue: Math.max(1, root.finiteNumber(toValue, 100))
        readonly property real safeValue: Math.max(0, Math.min(safeToValue, root.finiteNumber(value, 0)))
        readonly property real ratio: safeValue / safeToValue
        readonly property real fillRatio: ratio
        readonly property bool vertical: height > width * 1.25
        readonly property bool showActions: width >= 142 && height >= 72 && (actionIconName.length > 0 || secondaryActionIconName.length > 0)

        signal moved(real value)
        signal actionTriggered()
        signal secondaryActionTriggered()

        implicitHeight: 116

        Rectangle {
            anchors.fill: parent
            radius: Math.min(18, Math.min(width, height) / 2)
            color: "#15161d"
            border.color: "#2a2b35"
            border.width: 1

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: controlSlider.vertical ? parent.width : parent.width * controlSlider.fillRatio
                height: controlSlider.vertical ? parent.height * controlSlider.fillRatio : parent.height
                radius: parent.radius
                color: controlSlider.accent
                opacity: controlSlider.enabled ? (root.controlEditMode ? 0.72 : 0.92) : 0.16
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: "#31323d"
                border.width: 1
            }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.max(16, Math.min(34, parent.width - 14, parent.height - 14))
            height: width
            source: controlSlider.iconName
            color: "#f8f8fb"
            opacity: controlSlider.enabled ? 1 : 0.42
        }

        QQC2.Label {
            visible: controlSlider.width >= 116 && !controlSlider.showActions
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            text: controlSlider.valueText
            color: "#f8f8fb"
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        QQC2.ToolTip.visible: hoverArea.containsMouse
        QQC2.ToolTip.text: controlSlider.title + " " + controlSlider.valueText
        QQC2.ToolTip.delay: 350

        MouseArea {
            id: hoverArea

            anchors.fill: parent
            hoverEnabled: true
            enabled: controlSlider.enabled && !root.controlEditMode
            preventStealing: true

            function valueFromMouse(mouse) {
                const pct = controlSlider.vertical ? 1 - mouse.y / Math.max(1, height) : mouse.x / Math.max(1, width);
                return Math.round(Math.max(0, Math.min(1, pct)) * controlSlider.safeToValue);
            }

            onPressed: (mouse) => {
                mouse.accepted = true;
                controlSlider.moved(valueFromMouse(mouse));
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    mouse.accepted = true;
                    controlSlider.moved(valueFromMouse(mouse));
                }

            }
        }

        Row {
            visible: controlSlider.showActions
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 6
            z: 3

            IslandButton {
                visible: controlSlider.actionIconName.length > 0
                width: 26
                height: 26
                compact: true
                iconName: controlSlider.actionIconName
                onClicked: controlSlider.actionTriggered()
            }

            IslandButton {
                visible: controlSlider.secondaryActionIconName.length > 0
                width: 26
                height: 26
                compact: true
                iconName: controlSlider.secondaryActionIconName
                onClicked: controlSlider.secondaryActionTriggered()
            }
        }

        QQC2.Label {
            visible: controlSlider.showActions && controlSlider.width >= 180
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            text: controlSlider.valueText
            color: "#f8f8fb"
            font.pixelSize: 11
            font.weight: Font.Bold
        }

    }

    component StatusChip: MouseArea {
        id: chip

        property string label: ""
        property bool active: false
        property color dotColor: "#777781"

        implicitHeight: 28
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: chip.pressed ? "#303039" : chip.containsMouse ? "#24242b" : "#16161d"
            border.color: chip.active ? "#3a3a44" : "#202027"
            border.width: 1
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 6

            Rectangle {
                Layout.preferredWidth: 6
                Layout.preferredHeight: 6
                radius: 3
                color: chip.dotColor
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: chip.label
                color: "#f4f4f8"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

        }

    }

}
