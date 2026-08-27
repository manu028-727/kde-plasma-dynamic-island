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
    readonly property var player: mprisModel.currentPlayer
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
    readonly property int popupWidth: popupMode === "control" ? 430 : 294
    readonly property int popupHeight: popupMode === "control" ? 540 : 104
    readonly property int popupRadius: popupMode === "control" ? 34 : 26
    readonly property bool islandExpandsUp: Plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property bool islandExpandsDown: Plasmoid.location === PlasmaCore.Types.TopEdge
    property bool dialogVisible: false
    property bool islandOpen: false
    property bool panelHidden: false
    property bool popupAcceptsFocus: false
    property string popupMode: "control"
    property int clickButton: Qt.NoButton

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
        const displays = screenBrightness.displays;
        if (!screenBrightness.isBrightnessAvailable || !displays || displays.count <= 0)
            return 0;

        const idx = displays.index(0, 0);
        const value = displays.data(idx, 258) || displays.data(idx, 257) || 0;
        const max = displays.data(idx, 259) || displays.data(idx, 260) || 100;
        return Math.max(0, Math.min(100, Math.round(value / Math.max(1, max) * 100)));
    }

    function keyboardBrightnessPercent() {
        if (!keyboardBrightness.isBrightnessAvailable || keyboardBrightness.brightnessMax <= 0)
            return 0;

        return Math.max(0, Math.min(100, Math.round(keyboardBrightness.brightness / keyboardBrightness.brightnessMax * 100)));
    }

    function setKeyboardBrightnessPercent(value) {
        if (!keyboardBrightness.isBrightnessAvailable || keyboardBrightness.brightnessMax <= 0)
            return ;

        keyboardBrightness.brightness = Math.round(keyboardBrightness.brightnessMax * Math.max(0, Math.min(100, value)) / 100);
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

        return Math.max(0, Math.min(150, Math.round(sink.volume / PulseAudio.NormalVolume * 100)));
    }

    function setSystemVolumePercent(value) {
        const sink = defaultSink();
        if (!sink)
            return ;

        sink.muted = false;
        sink.volume = Math.round(PulseAudio.NormalVolume * Math.max(0, Math.min(150, value)) / 100);
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

        onCurrentPlayerChanged: root.bump()
    }

    Brightness.ScreenBrightnessControl {
        id: screenBrightness

        isSilent: true
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

    Plasma5Support.DataSource {
        id: executable

        function exec(cmd) {
            if (cmd)
                connectSource(cmd);

        }

        engine: "executable"
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
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

        }
        onWidthChanged: root.positionIslandDialog()
        onHeightChanged: root.positionIslandDialog()

        mainItem: Loader {
            id: dialogLoader

            width: root.popupWidth
            height: root.popupHeight
            active: root.dialogVisible
            sourceComponent: popupComponent
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

        ColumnLayout {
            anchors.fill: parent
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 15
                    color: "#15161d"
                    border.color: "#2a2b35"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 11
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 10
                            color: "#24252e"

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: "start-here-kde"
                                color: "#f5f5f7"
                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: root.hasActivity ? root.primaryText() : "KDE Plasma"
                                color: "#f8f8fb"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: root.hasActivity ? root.secondaryText() : (powerProfiles.activeProfile || "Desktop")
                                color: "#8f9099"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                        }

                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            source: enabledConnections.networkingEnabled ? "network-wired-activated" : "network-wired-disconnected"
                            color: enabledConnections.networkingEnabled ? "#34c759" : "#6e6e78"
                        }

                    }

                }

                Rectangle {
                    Layout.preferredWidth: 76
                    Layout.fillHeight: true
                    radius: 15
                    color: "#15161d"
                    border.color: "#2a2b35"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            source: batteryControl.pluggedIn ? "battery-charging" : "battery"
                            color: batteryControl.pluggedIn ? "#34c759" : "#f5f5f7"
                        }

                        QQC2.Label {
                            text: root.batteryText()
                            color: "#f8f8fb"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }

                    }

                }

                MouseArea {
                    Layout.preferredWidth: 50
                    Layout.fillHeight: true
                    hoverEnabled: true
                    onClicked: powerMenu.open()

                    Rectangle {
                        anchors.fill: parent
                        radius: 15
                        color: parent.pressed ? "#2f3039" : parent.containsMouse ? "#24252d" : "#15161d"
                        border.color: "#2a2b35"
                        border.width: 1
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: "system-shutdown"
                        color: "#f8f8fb"
                    }

                    QQC2.Menu {
                        id: powerMenu

                        QQC2.MenuItem {
                            text: "Lock"
                            onTriggered: root.runPowerAction("lock")
                        }

                        QQC2.MenuItem {
                            text: "Logout"
                            onTriggered: root.runPowerAction("logout")
                        }

                        QQC2.MenuItem {
                            text: "Sleep"
                            onTriggered: root.runPowerAction("sleep")
                        }

                        QQC2.MenuItem {
                            text: "Hibernate"
                            onTriggered: root.runPowerAction("hibernate")
                        }

                        QQC2.MenuSeparator {
                        }

                        QQC2.MenuItem {
                            text: "Reboot"
                            onTriggered: root.runPowerAction("reboot")
                        }

                        QQC2.MenuItem {
                            text: "Shutdown"
                            onTriggered: root.runPowerAction("shutdown")
                        }

                    }

                }

            }

            ActivitySummary {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 118
                spacing: 9

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    columnSpacing: 7
                    rowSpacing: 7

                    ControlTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: root.hasJobs ? "download" : "kdeconnect"
                        label: root.hasJobs ? "Jobs" : "Connect"
                        active: true
                        accent: root.hasJobs ? "#34c759" : "#5ac8fa"
                        tooltip: root.hasJobs ? "Active jobs" : "KDE Connect"
                        onClicked: root.hasJobs ? root.showActivityPopup(false) : root.launchKdeConnectSettings()
                    }

                    ControlTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: root.hasNotifications ? "notifications" : "notifications-disabled"
                        label: root.hasNotifications ? notifications.unreadNotificationsCount + " unread" : "Notify"
                        active: root.hasNotifications
                        accent: "#ff9f0a"
                        tooltip: "Notification settings"
                        onClicked: root.hasNotifications ? root.showActivityPopup(false) : root.launchNotificationSettings()
                    }

                    ControlTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "preferences-system-bluetooth"
                        label: "Bluetooth"
                        active: true
                        accent: "#0a84ff"
                        tooltip: "Bluetooth settings"
                        onClicked: root.launchBluetoothSettings()
                    }

                    ControlTile {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "systemsettings"
                        label: "Settings"
                        active: true
                        accent: "#8e8eff"
                        tooltip: "System Settings"
                        onClicked: root.launchSystemSettings()
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 7

                    ControlSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        title: "Display Brightness"
                        iconName: "brightness-high"
                        valueText: screenBrightness.isBrightnessAvailable ? root.screenBrightnessPercent() + "%" : "--"
                        value: root.screenBrightnessPercent()
                        enabled: screenBrightness.isBrightnessAvailable
                        onMoved: (value) => {
                            return screenBrightness.adjustBrightnessRatio((value - root.screenBrightnessPercent()) / 100);
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 7

                        ControlTile {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconName: root.powerProfileIcon()
                            label: powerProfiles.activeProfile === "performance" ? "Performance" : powerProfiles.activeProfile === "power-saver" ? "Saver" : "Balanced"
                            active: true
                            accent: "#ffd60a"
                            tooltip: "Cycle power profile"
                            onClicked: root.cyclePowerProfile()
                        }

                        ControlTile {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconName: "preferences-desktop-theme"
                            label: "Theme"
                            active: true
                            accent: "#bf5af2"
                            tooltip: "Appearance settings"
                            onClicked: root.launchAppearanceSettings()
                        }

                    }

                }

            }

            ControlSlider {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                title: "Volume"
                iconName: {
                    const sink = root.defaultSink();
                    return sink && sink.muted ? "audio-volume-muted" : "audio-volume-high";
                }
                valueText: {
                    const sink = root.defaultSink();
                    return sink && sink.muted ? "Muted" : root.systemVolumePercent() + "%";
                }
                value: root.systemVolumePercent()
                toValue: 150
                enabled: root.defaultSink() !== null
                onMoved: (value) => {
                    return root.setSystemVolumePercent(value);
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                spacing: 8

                ControlTile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconName: {
                        const sink = root.defaultSink();
                        return sink && sink.muted ? "audio-volume-muted" : "audio-volume-high";
                    }
                    label: {
                        const sink = root.defaultSink();
                        return sink && sink.muted ? "Unmute" : "Mute";
                    }
                    active: {
                        const sink = root.defaultSink();
                        return sink && !sink.muted;
                    }
                    accent: "#5ac8fa"
                    tooltip: "Toggle mute"
                    onClicked: root.toggleSystemMute()
                }

                ControlTile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconName: "audio-card"
                    label: "Mixer"
                    active: true
                    accent: "#30d158"
                    tooltip: "Open pavucontrol"
                    onClicked: root.launchPavucontrol()
                }

                ControlTile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconName: "video-display"
                    label: "Display"
                    active: screenBrightness.isBrightnessAvailable
                    accent: "#ffd60a"
                    tooltip: "Display settings"
                    onClicked: root.launchDisplaySettings()
                }

                ControlTile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    iconName: "input-keyboard"
                    label: keyboardBrightness.isBrightnessAvailable ? "Keys" : "Keys --"
                    active: keyboardBrightness.isBrightnessAvailable
                    accent: "#64d2ff"
                    tooltip: "Keyboard brightness"
                }

            }

            ControlSlider {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                title: "Keyboard"
                iconName: "input-keyboard"
                valueText: keyboardBrightness.isBrightnessAvailable ? root.keyboardBrightnessPercent() + "%" : "--"
                value: root.keyboardBrightnessPercent()
                enabled: keyboardBrightness.isBrightnessAvailable
                onMoved: (value) => {
                    return root.setKeyboardBrightnessPercent(value);
                }
            }

        }

    }

    component ActivitySummary: Rectangle {
        id: activitySummary

        radius: 22
        color: "#101116"
        border.color: "#202129"
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 13

            MaskedArtwork {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                artworkSource: root.hasPlayer ? root.player.artUrl : ""
                cornerRadius: 16
                glyphSize: 36
                mode: root.activityMode()
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
                            text: root.hasActivity ? root.primaryText() : "Ready"
                            color: "#ffffff"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.hasActivity ? root.secondaryText() : "Media, notifications and jobs"
                            color: "#9b9ba6"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                    }

                    IslandBars {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 28
                        color: root.isPlaying ? "#c026d3" : root.hasNotifications ? "#ff9f0a" : root.hasJobs ? "#34c759" : "#54545f"
                        playing: root.isPlaying || root.hasJobs || root.hasNotifications
                    }

                }

                ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    visible: root.hasJobs || (root.hasPlayer && root.player.length > 0)
                    from: 0
                    to: root.hasJobs ? 100 : Math.max(1, root.player ? root.player.length : 1)
                    value: root.hasJobs ? Math.max(0, notifications.jobsPercentage) : root.player ? root.player.position : 0
                    accent: root.hasJobs ? "#34c759" : "#5ac8fa"
                }

                RowLayout {
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
                        text: root.hasJobs ? "Download active" : root.hasNotifications ? notifications.unreadNotificationsCount + " unread" : enabledConnections.networkingEnabled ? "Wired connected" : "Network offline"
                        color: "#8f9099"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }

                }

            }

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
        readonly property bool hasArtwork: artworkSource && artworkSource.toString().length > 0

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

        signal moved(real value)

        implicitHeight: 72

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#15161d"
            border.color: "#2a2b35"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 13
            anchors.rightMargin: 13
            anchors.topMargin: 9
            anchors.bottomMargin: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QQC2.Label {
                    Layout.fillWidth: true
                    text: controlSlider.title
                    color: "#f8f8fb"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                QQC2.Label {
                    text: controlSlider.valueText
                    color: "#f8f8fb"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Kirigami.Icon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    source: controlSlider.iconName
                    color: "#f8f8fb"
                }

                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: controlSlider.toValue
                    value: controlSlider.value
                    enabled: controlSlider.enabled
                    live: false
                    onMoved: controlSlider.moved(value)
                }

            }

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

    component MiniSlider: Item {
        id: mini

        property string label: ""
        property string valueText: ""
        property real value: 0
        property real toValue: 100

        signal moved(real value)

        implicitHeight: 36

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "#15151b"
            border.color: "#23232a"
            border.width: 1
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 7

            QQC2.Label {
                text: mini.label
                color: "#ffffff"
                font.pixelSize: 9
                font.weight: Font.Bold
            }

            QQC2.Slider {
                Layout.fillWidth: true
                from: 0
                to: mini.toValue
                value: mini.value
                enabled: mini.enabled
                live: false
                onMoved: mini.moved(value)
            }

            QQC2.Label {
                text: mini.valueText
                color: "#8f8f98"
                font.pixelSize: 9
            }

        }

    }

}
