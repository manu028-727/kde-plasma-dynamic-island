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
import "controlcenter"
import "controlcenter/ModuleRegistry.js" as ModuleRegistry

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
    property bool bluetoothAvailable: false
    property string bluetoothAdapterName: ""
    property string bluetoothDevicesText: ""
    property string wifiNetworksText: ""
    property string networkDevicesText: ""
    property string networkIpText: ""
    property string kdeConnectDevicesText: ""
    property string popupMode: "control"
    property string activityPopupMode: "auto"
    property int clickButton: Qt.NoButton
    property int mediaPlayerRevision: 0
    property int lastUnreadNotificationsCount: 0
    property int lastActiveJobsCount: 0
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
    property bool controlDropInvalid: false
    property bool controlResizeActive: false
    property var controlResizeSource: null
    property int controlResizeIndex: -1
    property int controlResizeWidthUnits: 1
    property int controlResizeHeightUnits: 1
    readonly property bool controlLayoutDirty: controlEditMode && controlLayoutRevision >= 0 && !sameControlLayout(controlLayoutDraft, committedControlLayout())
    readonly property string accountIconCommand: "sh -c 'user=$(id -un); path=$(qdbus6 org.freedesktop.Accounts /org/freedesktop/Accounts org.freedesktop.Accounts.FindUserByName \"$user\" 2>/dev/null); test -n \"$path\" && qdbus6 org.freedesktop.Accounts \"$path\" org.freedesktop.Accounts.User.IconFile 2>/dev/null'"
    readonly property string wifiScanCommand: "nmcli -t -f IN-USE,SSID,SIGNAL device wifi list --rescan no"
    readonly property string networkStatusCommand: "nmcli -t -f TYPE,DEVICE,STATE,CONNECTION device status"
    readonly property string networkIpCommand: "nmcli -t -f GENERAL.DEVICE,IP4.ADDRESS device show"
    readonly property string kdeConnectCommand: "kdeconnect-cli --list-devices"

    onControlEditModeChanged: {
        if (!controlEditMode)
            resetControlInteractionState();

    }

    readonly property var controlModules: ModuleRegistry.allModules()

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

        if (popupMode === "control" && controlEditMode)
            cancelControlEdit();

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

    function bump(kind) {
        if (!hasActivity)
            return ;

        const nextMode = resolvedActivityMode(kind || "auto");
        if (islandOpen && popupMode === "activity" && activityPopupTimer.running && activityPriority(nextMode) < activityPriority(resolvedActivityMode(activityPopupMode))) {
            activityPopupTimer.restart();
            return ;
        }
        showActivityPopup(true, nextMode);
    }

    function showActivityPopup(autoClose, kind) {
        activityPopupMode = resolvedActivityMode(kind || "auto");
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
        showActivityPopup(autoClose, "auto");
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
        const maxRows = Math.max(0, Math.round(finiteNumber(limit, 0)));
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

    function notificationAppName(row) {
        const appName = cleanText(rowValue(row, NotificationManager.Notifications.ApplicationNameRole, ""));
        if (appName.length > 0)
            return appName;

        const desktopEntry = cleanText(rowValue(row, NotificationManager.Notifications.DesktopEntryRole, ""));
        return desktopEntry.length > 0 ? desktopEntry : "Notification";
    }

    function notificationTitle(row) {
        const summary = cleanText(rowValue(row, NotificationManager.Notifications.SummaryRole, ""));
        return summary.length > 0 ? summary : notificationAppName(row);
    }

    function notificationBody(row) {
        return cleanText(rowValue(row, NotificationManager.Notifications.BodyRole, ""));
    }

    function notificationIcon(row) {
        const image = rowValue(row, NotificationManager.Notifications.ImageRole, "");
        if (typeof image === "string" && image.length > 0)
            return image;

        const desktopEntry = cleanText(rowValue(row, NotificationManager.Notifications.DesktopEntryRole, ""));
        return desktopEntry.length > 0 ? desktopEntry : "notifications";
    }

    function notificationAccent(row) {
        const urgency = rowValue(row, NotificationManager.Notifications.UrgencyRole, 1);
        if (urgency >= 2)
            return "#ff453a";
        if (urgency <= 0)
            return "#8f9099";
        return "#ff9f0a";
    }

    function notificationLatestRow() {
        const rows = notificationRows(1);
        return rows.length > 0 ? rows[0] : -1;
    }

    function notificationStatusText() {
        const count = notificationCount();
        if (count <= 0)
            return "Quiet";
        if (count === 1)
            return "1 notification";
        return count + " notifications";
    }

    function notificationOverflowCount(limit) {
        return Math.max(0, notificationCount() - Math.max(0, Math.round(finiteNumber(limit, 0))));
    }

    function openNotification(row) {
        if (row < 0 || notifications.count <= row)
            return ;

        const idx = notifications.index(row, 0);
        if (notifications.invokeDefaultAction)
            notifications.invokeDefaultAction(idx);
    }

    function activeRowFor(kind) {
        const mode = resolvedActivityMode(kind || "auto");
        if (mode === "notice") {
            const noticeRow = firstRowOfType(NotificationManager.Notifications.NotificationType);
            if (noticeRow >= 0)
                return noticeRow;
        }

        if (mode === "job") {
            const jobRow = firstRowOfType(NotificationManager.Notifications.JobType);
            if (jobRow >= 0)
                return jobRow;
        }

        const job = firstRowOfType(NotificationManager.Notifications.JobType);
        if (job >= 0)
            return job;

        const notice = firstRowOfType(NotificationManager.Notifications.NotificationType);
        return notice >= 0 ? notice : 0;
    }

    function activeRow() {
        return activeRowFor("auto");
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
        controlDropInvalid = false;
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

    function mediaPrevious() {
        const current = player;
        if (current && current.canGoPrevious)
            current.Previous();
    }

    function mediaPlayPause() {
        const current = player;
        if (current && (current.canPlay || current.canPause))
            current.PlayPause();
    }

    function mediaNext() {
        const current = player;
        if (current && current.canGoNext)
            current.Next();
    }

    function primaryTextFor(kind) {
        const mode = resolvedActivityMode(kind || "auto");
        const row = activeRowFor(mode);
        if (mode === "job" && hasJobs)
            return cleanText(rowValue(row, NotificationManager.Notifications.SummaryRole, "Working"));

        if (mode === "notice" && hasNotifications)
            return cleanText(rowValue(row, NotificationManager.Notifications.SummaryRole, "Notification"));

        if (mode === "media" && hasPlayer)
            return player.track || player.identity || "Media";

        return "Control Center";
    }

    function primaryText() {
        return primaryTextFor("auto");
    }

    function secondaryTextFor(kind) {
        const mode = resolvedActivityMode(kind || "auto");
        const row = activeRowFor(mode);
        if (mode === "job" && hasJobs)
            return notifications.jobsPercentage >= 0 ? notifications.jobsPercentage + "%" : cleanText(rowValue(row, NotificationManager.Notifications.BodyRole, ""));

        if (mode === "notice" && hasNotifications)
            return cleanText(rowValue(row, NotificationManager.Notifications.BodyRole, ""));

        if (mode === "media" && hasPlayer)
            return player.artist || player.album || player.identity || "";

        return "Brightness, audio, network, power";
    }

    function secondaryText() {
        return secondaryTextFor("auto");
    }

    function resolvedActivityMode(kind) {
        if (kind === "job" && hasJobs)
            return "job";

        if (kind === "notice" && hasNotifications)
            return "notice";

        if (kind === "media" && hasPlayer)
            return "media";

        return activityMode();
    }

    function activityPriority(kind) {
        if (kind === "job")
            return 3;
        if (kind === "notice")
            return 2;
        if (kind === "media")
            return 1;
        return 0;
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

    function popupActivityMode() {
        return popupMode === "activity" ? resolvedActivityMode(activityPopupMode) : activityMode();
    }

    function activityArtworkFor(kind) {
        return resolvedActivityMode(kind || "auto") === "media" && hasPlayer ? player.artUrl : "";
    }

    function activityProgressVisible(kind) {
        const mode = resolvedActivityMode(kind || "auto");
        return mode === "job" && hasJobs || mode === "media" && hasPlayer && player.length > 0;
    }

    function activityProgressTo(kind) {
        return resolvedActivityMode(kind || "auto") === "job" ? 100 : Math.max(1, player ? player.length : 1);
    }

    function activityProgressValue(kind) {
        return resolvedActivityMode(kind || "auto") === "job" ? Math.max(0, notifications.jobsPercentage) : player ? player.position : 0;
    }

    function activityProgressAccent(kind) {
        return resolvedActivityMode(kind || "auto") === "job" ? "#42d77d" : "#5ac8fa";
    }

    function activityShowsMediaControls(kind) {
        return resolvedActivityMode(kind || "auto") === "media" && hasPlayer;
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
        executable.exec("kdeconnect-app");
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
        refreshConnectivityState();
    }

    function refreshConnectivityState() {
        executable.exec("bluetoothctl show");
        executable.exec("bluetoothctl devices Connected");
        executable.exec(wifiScanCommand);
        executable.exec(networkStatusCommand);
        executable.exec(networkIpCommand);
        executable.exec(kdeConnectCommand);
    }

    function defaultControlLayout() {
        return ModuleRegistry.defaultLayout();
    }

    function controlModuleMinSize(id) {
        return ModuleRegistry.minSize(id);
    }

    function controlModuleMaxSize(id) {
        return ModuleRegistry.maxSize(id);
    }

    function controlModuleDefaultSize(id) {
        return ModuleRegistry.defaultSize(id);
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
            const size = clampedControlModule(item.id, finiteNumber(item.w, 1) * (migrated ? 1 : 2), finiteNumber(item.h, 1) * (migrated ? 1 : 2));
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

    function sameControlLayout(left, right) {
        return JSON.stringify(sanitizeControlLayout(left || [])) === JSON.stringify(sanitizeControlLayout(right || []));
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

        if (controlLayoutDirty)
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
        return ModuleRegistry.info(id);
    }

    function moduleIcon(id) {
        return ModuleRegistry.icon(id, {
            "wifiEnabled": enabledConnections.wirelessEnabled,
            "batteryCharging": batteryControl.pluggedIn,
            "powerProfileIcon": powerProfileIcon()
        });
    }

    function toggleWifi() {
        networkHandler.enableWireless(!enabledConnections.wirelessEnabled);
        wifiRefreshTimer.restart();
    }

    function refreshWifiNetworks() {
        executable.exec(wifiScanCommand);
        executable.exec(networkStatusCommand);
        executable.exec(networkIpCommand);
    }

    function wifiTitle() {
        if (!enabledConnections.wirelessHwEnabled)
            return "Unavailable";
        return enabledConnections.wirelessEnabled ? "On" : "Off";
    }

    function wifiRows(limit) {
        const rows = [];
        const lines = root.wifiNetworksText.length > 0 ? root.wifiNetworksText.split("\n") : [];
        const maxRows = Math.max(0, Math.round(finiteNumber(limit, 0)));
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

    function connectedNetworkRows(limit) {
        const rows = [];
        const lines = root.networkDevicesText.length > 0 ? root.networkDevicesText.split("\n") : [];
        const maxRows = Math.max(0, Math.round(finiteNumber(limit, 0)));
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
        const rows = connectedNetworkRows(1);
        if (rows.length > 0)
            return rows[0];
        if (enabledConnections.wirelessEnabled && wifiSignalPercent() > 0)
            return wifiSignalPercent() + "% Wi-Fi signal";
        return "Connected";
    }

    function networkTitle() {
        if (!enabledConnections.networkingEnabled)
            return "Offline";
        const rows = connectedNetworkRows(1);
        if (rows.length <= 0)
            return enabledConnections.wirelessEnabled ? "Wi-Fi" : "Network";
        if (rows[0].indexOf("Wired") === 0)
            return "Wired";
        if (rows[0].indexOf("Wi-Fi") === 0)
            return "Wi-Fi";
        return "Network";
    }

    function networkDetail() {
        const rows = connectedNetworkRows(3);
        const ip = cleanText(networkIpText);
        if (rows.length > 0 && ip.length > 0)
            return rows.join("\n") + "\n" + ip;
        if (rows.length > 0)
            return rows.join("\n");
        return enabledConnections.networkingEnabled ? "No active connection details" : "Networking disabled";
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

    function parseNetworkDevices(text) {
        const lines = String(text || "").split("\n");
        const out = [];
        for (let i = 0; i < lines.length; ++i) {
            const parts = splitNmcliFields(lines[i]);
            if (parts.length < 4 || parts[2] !== "connected")
                continue;

            const type = parts[0];
            const device = parts[1] || "";
            const connection = parts[3] || device || "Connected";
            if (type === "ethernet")
                out.push("Wired " + connection);
            else if (type === "wifi")
                out.push("Wi-Fi " + connection);
            else if (type !== "loopback")
                out.push(connection);

            if (out.length >= 3)
                break;

        }
        return out.join("\n");
    }

    function parseNetworkAddresses(text) {
        const lines = String(text || "").split("\n");
        const out = [];
        let device = "";
        for (let i = 0; i < lines.length; ++i) {
            const parts = splitNmcliFields(lines[i]);
            if (parts.length < 2)
                continue;

            if (parts[0] === "GENERAL.DEVICE") {
                device = parts[1];
            } else if (parts[0] === "IP4.ADDRESS[1]" && parts[1].length > 0) {
                out.push((device.length > 0 ? device + " " : "") + parts[1].replace(/\/\d+$/, ""));
                if (out.length >= 2)
                    break;
            }
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

    function parseBluetoothAvailable(text) {
        const out = String(text || "");
        return out.indexOf("Controller ") !== -1 || out.indexOf("Powered:") !== -1 || out.indexOf("Alias:") !== -1;
    }

    function parseBluetoothAdapterName(text) {
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length; ++i) {
            const line = String(lines[i] || "").trim();
            if (line.indexOf("Alias:") === 0)
                return cleanText(line.slice(6));
            if (line.indexOf("Name:") === 0)
                return cleanText(line.slice(5));
        }
        return "";
    }

    function bluetoothDeviceCount() {
        if (bluetoothDevicesText.length <= 0)
            return 0;
        return bluetoothDevicesText.split("\n").filter(function(line) {
            return String(line || "").trim().length > 0;
        }).length;
    }

    function bluetoothSummary() {
        if (!bluetoothAvailable)
            return "No adapter";
        if (!bluetoothPowered)
            return "Off";
        const count = bluetoothDeviceCount();
        if (count <= 0)
            return "On";
        return count === 1 ? bluetoothDevicesText.split("\n")[0] : count + " devices";
    }

    function bluetoothDetail() {
        if (!bluetoothAvailable)
            return "Bluetooth adapter unavailable";
        if (!bluetoothPowered)
            return "Radio disabled";
        if (bluetoothDevicesText.length > 0)
            return bluetoothDevicesText;
        return bluetoothAdapterName.length > 0 ? bluetoothAdapterName : "No connected devices";
    }

    function parseKdeConnectDevices(text) {
        const lines = String(text || "").split("\n");
        const out = [];
        const seen = {};
        for (let i = 0; i < lines.length; ++i) {
            const device = parseKdeConnectDeviceLine(lines[i]);
            if (!device || device.name.length <= 0 || seen[device.name])
                continue;

            seen[device.name] = true;
            out.push(device.name + "|" + device.id + "|" + device.status + "|" + (device.reachable ? "1" : "0") + "|" + (device.paired ? "1" : "0"));
            if (out.length >= 3)
                break;
        }
        return out.join("\n");
    }

    function parseKdeConnectDeviceLine(line) {
        let text = cleanText(line);
        if (text.length <= 0 || text.indexOf("0 devices found") !== -1 || text.indexOf("No devices") !== -1)
            return null;

        if (text.indexOf("- ") === 0)
            text = text.slice(2);

        let name = text;
        let id = "";
        let status = "";
        const idMatch = text.match(/^(.*?):\s*([^()\s]+)\s*(?:\((.*)\))?$/);
        if (idMatch) {
            name = cleanText(idMatch[1]);
            id = cleanText(idMatch[2]);
            status = cleanText(idMatch[3] || "");
        } else {
            const legacyStatus = text.match(/^(.*?)\s+-\s+(.*)$/);
            if (legacyStatus) {
                name = cleanText(legacyStatus[1]);
                status = cleanText(legacyStatus[2]);
            }
            const inlineId = name.match(/^(.*?)\s*\(id:\s*([^)]+)\)$/i);
            if (inlineId) {
                name = cleanText(inlineId[1]);
                id = cleanText(inlineId[2]);
            }
        }

        status = status.replace(/\band\b/gi, ",").replace(/\s*,\s*/g, ", ");
        const lower = status.toLowerCase();
        return {
            "name": name,
            "id": id,
            "status": status.length > 0 ? status : "available",
            "reachable": lower.indexOf("reachable") !== -1 || lower.indexOf("available") !== -1,
            "paired": lower.indexOf("paired") !== -1 || lower.indexOf("trusted") !== -1
        };
    }

    function kdeConnectSummary() {
        if (kdeConnectDevicesText.length <= 0)
            return "No devices";
        const devices = kdeConnectDevices(0);
        const reachable = kdeConnectReachableCount();
        if (devices.length === 1)
            return devices[0].name;
        if (reachable > 0)
            return reachable + " reachable";
        return devices.length + " paired";
    }

    function kdeConnectRows(limit) {
        const devices = kdeConnectDevices(limit);
        const rows = [];
        for (let i = 0; i < devices.length; ++i)
            rows.push(devices[i].name);
        return rows;
    }

    function kdeConnectDevices(limit) {
        const devices = [];
        const lines = kdeConnectDevicesText.length > 0 ? kdeConnectDevicesText.split("\n") : [];
        const maxRows = Math.max(0, Math.round(finiteNumber(limit, 0)));
        for (let i = 0; i < lines.length; ++i) {
            const parts = String(lines[i]).split("|");
            const name = cleanText(parts[0]);
            if (name.length <= 0)
                continue;

            devices.push({
                "name": name,
                "id": cleanText(parts[1]),
                "status": cleanText(parts[2] || "available"),
                "reachable": parts[3] === "1",
                "paired": parts[4] === "1"
            });
            if (maxRows > 0 && devices.length >= maxRows)
                break;
        }
        return devices;
    }

    function kdeConnectReachableCount() {
        const devices = kdeConnectDevices(0);
        let count = 0;
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i].reachable)
                count++;
        }
        return count;
    }

    function refreshKdeConnectDevices() {
        executable.exec("kdeconnect-cli --refresh");
        executable.exec(kdeConnectCommand);
    }

    function shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\"'\"'") + "'";
    }

    function runKdeConnectDeviceAction(deviceId, action) {
        const id = cleanText(deviceId);
        if (id.length <= 0)
            return ;

        if (action === "ping")
            executable.exec("kdeconnect-cli --device " + shellQuote(id) + " --ping");
        else if (action === "ring")
            executable.exec("kdeconnect-cli --device " + shellQuote(id) + " --ring");
        else if (action === "mount")
            executable.exec("kdeconnect-cli --device " + shellQuote(id) + " --mount");
        else if (action === "notifications")
            executable.exec("kdeconnect-cli --device " + shellQuote(id) + " --list-notifications");
    }

    function beginControlDrag(source, item, mouse, size) {
        if (!root.controlEditMode || !dialogHost || !source || !item || !mouse || !item.mapToItem)
            return ;

        const pos = item.mapToItem(dialogHost, mouse.x, mouse.y);
        controlDragSource = source;
        controlDragIcon = moduleIcon(source.moduleId);
        controlDragSize = Math.max(32, Math.min(96, finiteNumber(size, 54)));
        controlDragX = pos.x - controlDragSize / 2;
        controlDragY = pos.y - controlDragSize / 2;
        controlDragActive = true;
    }

    function updateControlDrag(item, mouse) {
        if (!controlDragActive || !dialogHost || !item || !mouse || !item.mapToItem)
            return ;

        const pos = item.mapToItem(dialogHost, mouse.x, mouse.y);
        controlDragX = pos.x - controlDragSize / 2;
        controlDragY = pos.y - controlDragSize / 2;
        if (activeControlPage)
            activeControlPage.previewControlDrop(pos.x, pos.y);
    }

    function endControlDrag(item, mouse, commit) {
        if (commit && controlDragActive && activeControlPage && dialogHost && item && mouse && item.mapToItem) {
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
            root.bump("media");
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
                root.bump("media");
            }
            onTrackChanged: {
                root.mediaPlayerRevision++;
                root.bump("media");
            }
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
            else if (sourceName === "bluetoothctl show") {
                root.bluetoothAvailable = root.parseBluetoothAvailable(stdout);
                root.bluetoothAdapterName = root.parseBluetoothAdapterName(stdout);
                root.bluetoothPowered = out.indexOf("Powered: yes") !== -1;
            }
            else if (sourceName === "bluetoothctl devices Connected")
                root.bluetoothDevicesText = root.parseBluetoothDevices(stdout);
            else if (sourceName === root.wifiScanCommand)
                root.wifiNetworksText = root.parseWifiNetworks(stdout);
            else if (sourceName === root.networkStatusCommand)
                root.networkDevicesText = root.parseNetworkDevices(stdout);
            else if (sourceName === root.networkIpCommand)
                root.networkIpText = root.parseNetworkAddresses(stdout);
            else if (sourceName === root.kdeConnectCommand)
                root.kdeConnectDevicesText = root.parseKdeConnectDevices(stdout);

            disconnectSource(sourceName);
        }
    }

    Component.onCompleted: {
        root.ensureControlLayout();
        root.refreshSystemState();
        root.lastUnreadNotificationsCount = notifications.unreadNotificationsCount;
        root.lastActiveJobsCount = notifications.activeJobsCount;
    }

    Connections {
        function onPlaybackStatusChanged() {
            root.bump("media");
        }

        function onTrackChanged() {
            root.bump("media");
        }

        target: root.player
    }

    Connections {
        function onRowsInserted(parent, first, last) {
            let hasInsertedNotice = false;
            let hasInsertedJob = false;
            for (let row = first; row <= last; ++row) {
                const type = root.rowValue(row, NotificationManager.Notifications.TypeRole, NotificationManager.Notifications.NoType);
                if (type === NotificationManager.Notifications.JobType)
                    hasInsertedJob = true;
                else if (type === NotificationManager.Notifications.NotificationType)
                    hasInsertedNotice = true;
            }
            if (hasInsertedJob)
                root.bump("job");
            else if (hasInsertedNotice)
                root.bump("notice");
        }

        function onActiveJobsCountChanged() {
            const count = notifications.activeJobsCount;
            if (count > root.lastActiveJobsCount)
                root.bump("job");
            root.lastActiveJobsCount = count;
        }

        function onUnreadNotificationsCountChanged() {
            const count = notifications.unreadNotificationsCount;
            if (count > root.lastUnreadNotificationsCount)
                root.bump("notice");
            root.lastUnreadNotificationsCount = count;
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
                root.mediaPlayPause();
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
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: root.refreshConnectivityState()
    }

    Timer {
        id: wifiRefreshTimer

        interval: 900
        repeat: false
        onTriggered: root.refreshWifiNetworks()
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
            focus: root.popupAcceptsFocus
            acceptedButtons: Qt.LeftButton
            Keys.onPressed: (event) => {
                if (event.key !== Qt.Key_Escape)
                    return ;

                if (root.controlDragActive || root.controlResizeActive)
                    root.resetControlInteractionState();
                else if (root.controlEditMode)
                    root.cancelControlEdit();
                else
                    root.closeIsland();

                event.accepted = true;
            }
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
                            artworkSource: root.activityArtworkFor(root.popupActivityMode())
                            cornerRadius: Math.min(height / 2, 8 + (height / 2 - 8) * (1 - Math.min(1, popupRoot.morph / 0.34)))
                            mode: root.popupActivityMode()
                            progress: root.activityProgressValue(root.popupActivityMode()) / Math.max(1, root.activityProgressTo(root.popupActivityMode()))
                            playing: root.popupActivityMode() === "media" ? root.isPlaying : root.popupActivityMode() === "job"
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Loader {
                            anchors.fill: parent
                            active: root.hasActivity
                            sourceComponent: root.popupActivityMode() === "job" ? compactJobIndicator : root.popupActivityMode() === "media" ? compactMediaIndicator : compactNoticeIndicator
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
                    artworkSource: root.activityArtworkFor(root.popupActivityMode())
                    cornerRadius: 16
                    glyphSize: 32
                    mode: root.popupActivityMode()
                    progress: root.activityProgressValue(root.popupActivityMode()) / Math.max(1, root.activityProgressTo(root.popupActivityMode()))
                    playing: root.popupActivityMode() === "media" ? root.isPlaying : root.popupActivityMode() === "job"
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.primaryTextFor(root.popupActivityMode())
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.secondaryTextFor(root.popupActivityMode())
                    color: "#9d9da7"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    visible: root.activityProgressVisible(root.popupActivityMode())
                    from: 0
                    to: root.activityProgressTo(root.popupActivityMode())
                    value: root.activityProgressValue(root.popupActivityMode())
                    accent: root.activityProgressAccent(root.popupActivityMode())
                }

            }

            RowLayout {
                visible: root.activityShowsMediaControls(root.popupActivityMode())
                spacing: 6

                IslandButton {
                    iconName: "media-skip-backward"
                    compact: true
                    enabled: root.player && root.player.canGoPrevious
                    onClicked: root.mediaPrevious()
                }

                IslandButton {
                    iconName: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                    compact: true
                    emphasized: true
                    enabled: root.player && (root.player.canPlay || root.player.canPause)
                    onClicked: root.mediaPlayPause()
                }

                IslandButton {
                    iconName: "media-skip-forward"
                    compact: true
                    enabled: root.player && root.player.canGoNext
                    onClicked: root.mediaNext()
                }

            }

        }

    }

    Component {
        id: controlModuleCardDelegate

        ControlCenterModuleCard {
            anchors.fill: parent
            app: root
            hostItem: dialogHost
            notificationsSource: notifications
            batterySource: batteryControl
            connectionsSource: enabledConnections
            screenBrightnessSource: screenBrightness
            keyboardBrightnessSource: keyboardBrightness
            powerProfilesSource: powerProfiles
        }
    }

    Component {
        id: controlCenterPage

        ControlCenterEditor {
            app: root
            hostItem: dialogHost
            moduleCardDelegate: controlModuleCardDelegate
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
