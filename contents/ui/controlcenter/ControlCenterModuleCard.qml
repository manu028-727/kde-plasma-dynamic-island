import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.brightnesscontrolplugin as Brightness
import ".."

Rectangle {
    id: moduleCard

    required property var app
    required property Item hostItem
    required property var notificationsSource
    required property var batterySource
    required property var connectionsSource
    required property var screenBrightnessSource
    required property var keyboardBrightnessSource
    required property var powerProfilesSource
    property string moduleId: ""
    property int moduleIndex: -1
    property int moduleWidthUnits: 1
    property int moduleHeightUnits: 1
    property real gridUnitSize: 64
    property real gridGap: 8
    property bool fromPalette: false

    radius: 18
    color: "#101116"
    border.color: app.controlEditMode ? "#4b4c58" : "#202129"
    border.width: 1
    clip: true
    opacity: app.controlDragActive && app.controlDragSource === moduleCard ? 0 : 1
    z: 2
    scale: 1

    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    Behavior on x { enabled: app.controlEditMode; NumberAnimation { duration: 105; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: app.controlEditMode; NumberAnimation { duration: 105; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 105; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 105; easing.type: Easing.OutCubic } }

    Loader {
        anchors.fill: parent
        anchors.margins: app.controlEditMode ? Math.min(8, Math.max(4, Math.min(moduleCard.width, moduleCard.height) * 0.1)) : 0
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
        visible: app.controlEditMode
        color: "transparent"
        border.color: "#7a7b88"
        border.width: 1
        radius: parent.radius
    }

    MouseArea {
        id: dragArea
        visible: app.controlEditMode
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
            app.controlDragOffsetCol = Math.max(0, Math.min(moduleCard.moduleWidthUnits - 1, Math.floor(local.x / pitch)));
            app.controlDragOffsetRow = Math.max(0, Math.min(moduleCard.moduleHeightUnits - 1, Math.floor(local.y / pitch)));
            app.beginControlDrag(moduleCard, dragArea, mouse, 54);
        }
        onPositionChanged: (mouse) => {
            mouse.accepted = true;
            app.updateControlDrag(dragArea, mouse);
        }
        onReleased: (mouse) => {
            mouse.accepted = true;
            app.endControlDrag(dragArea, mouse, true);
        }
        onCanceled: app.endControlDrag(null, null, false)
    }

    Rectangle {
        visible: app.controlEditMode
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 7
        radius: 9
        color: "#1b1c24"
        border.color: "#42434d"
        border.width: 1
        width: moduleLabel.implicitWidth + 16
        height: 22

        PlasmaLabel {
            id: moduleLabel
            anchors.centerIn: parent
            text: app.moduleInfo(moduleCard.moduleId).name
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

        visible: app.controlEditMode
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: Math.min(34, Math.max(24, Math.min(moduleCard.width, moduleCard.height) * 0.55))
        height: width
        hoverEnabled: true
        cursorShape: Qt.SizeFDiagCursor
        preventStealing: true
        onPressed: (mouse) => {
            if (!moduleCard.hostItem || !resizeHandle.mapToItem) {
                mouse.accepted = false;
                return;
            }

            mouse.accepted = true;
            const p = resizeHandle.mapToItem(moduleCard.hostItem, mouse.x, mouse.y);
            startPointerX = p.x;
            startPointerY = p.y;
            startW = moduleCard.moduleWidthUnits;
            startH = moduleCard.moduleHeightUnits;
            app.beginControlResize(moduleCard);
        }
        onPositionChanged: (mouse) => {
            if (!pressed || !app.controlResizeActive || !moduleCard.hostItem || !resizeHandle.mapToItem)
                return;

            mouse.accepted = true;
            const p = resizeHandle.mapToItem(moduleCard.hostItem, mouse.x, mouse.y);
            const step = Math.max(1, moduleCard.gridUnitSize + moduleCard.gridGap);
            const newW = startW + Math.round((p.x - startPointerX) / step);
            const newH = startH + Math.round((p.y - startPointerY) / step);
            app.updateControlResize(moduleCard, newW, newH);
        }
        onReleased: (mouse) => {
            mouse.accepted = true;
            app.endControlResize(moduleCard, true);
        }
        onCanceled: app.endControlResize(moduleCard, false)

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

    Component { id: userPowerModule; UserPowerTile { app: moduleCard.app } }
    Component {
        id: volumeModule
        ControlSliderTile {
            app: moduleCard.app
            title: "Volume"
            iconName: {
                const sink = app.defaultSink();
                if (!sink || app.systemVolumePercent() <= 0 || sink.muted)
                    return "audio-volume-muted";
                return app.systemVolumePercent() < 45 ? "audio-volume-low" : "audio-volume-high";
            }
            valueText: {
                const sink = app.defaultSink();
                return sink && sink.muted ? "Muted" : app.systemVolumePercent() + "%";
            }
            value: Math.min(100, app.systemVolumePercent())
            toValue: 100
            accent: "#5ac8fa"
            enabled: app.defaultSink() !== null
            actionIconName: {
                const sink = app.defaultSink();
                return sink && sink.muted ? "audio-volume-high" : "audio-volume-muted";
            }
            secondaryActionIconName: "settings"
            onActionTriggered: app.toggleSystemMute()
            onSecondaryActionTriggered: app.launchPavucontrol()
            onMoved: (value) => app.setSystemVolumePercent(value)
        }
    }
    Component {
        id: brightnessModule
        ControlSliderTile {
            app: moduleCard.app
            title: "Brightness"
            iconName: value <= 1 ? "brightness-low" : value < 55 ? "brightness-medium" : "brightness-high"
            valueText: screenBrightnessSource.isBrightnessAvailable ? app.displayedScreenBrightnessPercent() + "%" : "--"
            value: app.displayedScreenBrightnessPercent()
            accent: "#f5d64a"
            enabled: screenBrightnessSource.isBrightnessAvailable
            actionIconName: "video-display"
            secondaryActionIconName: keyboardBrightnessSource.isBrightnessAvailable ? "input-keyboard" : ""
            onActionTriggered: app.launchDisplaySettings()
            onSecondaryActionTriggered: app.setKeyboardBrightnessPercent(app.keyboardBrightnessPercent() <= 20 ? 100 : 0)
            onMoved: (value) => app.setScreenBrightnessPercent(value)
        }
    }
    Component {
        id: wifiModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: connectionsSource.wirelessEnabled ? "network-wireless-on" : "network-wireless-off"
            title: "Wi-Fi"
            subtitle: app.wifiPrimaryNetwork()
            active: connectionsSource.wirelessEnabled
            available: connectionsSource.wirelessHwEnabled
            accent: "#0a84ff"
            progress: app.wifiSignalPercent()
            detailText: app.wifiTitle()
            footerText: connectionsSource.wirelessHwEnabled ? (connectionsSource.wirelessEnabled ? "Click to turn off" : "Click to turn on") : "No adapter"
            actionIconName: "settings"
            onActionTriggered: app.launchNetworkSettings()
            onTriggered: connectionsSource.wirelessHwEnabled ? app.toggleWifi() : app.launchNetworkSettings()
        }
    }
    Component { id: wifiDevicesModule; NetworkListTile { app: moduleCard.app; connectionsSource: moduleCard.connectionsSource } }
    Component { id: mediaModule; ActivitySummaryTile { app: moduleCard.app; notificationsSource: moduleCard.notificationsSource; mediaOnly: true; radius: moduleCard.radius; border.width: 0 } }
    Component { id: notificationsModule; NotificationsTile { app: moduleCard.app; notificationsSource: moduleCard.notificationsSource } }
    Component {
        id: bluetoothModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: "preferences-system-bluetooth"
            title: "Bluetooth"
            subtitle: app.bluetoothSummary()
            active: app.bluetoothPowered && app.bluetoothAvailable
            available: app.bluetoothAvailable
            accent: "#0a84ff"
            detailText: app.bluetoothDetail()
            footerText: app.bluetoothAvailable ? (app.bluetoothPowered ? "Click to turn off" : "Click to turn on") : "Open settings"
            actionIconName: "settings"
            onActionTriggered: app.launchBluetoothSettings()
            onTriggered: app.bluetoothAvailable ? app.toggleBluetoothPower() : app.launchBluetoothSettings()
        }
    }
    Component {
        id: bluetoothDiscoveryModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: "preferences-system-bluetooth"
            title: app.bluetoothDeviceCount() > 0 ? "Connected" : "Discover"
            subtitle: app.bluetoothAvailable ? app.bluetoothSummary() : "No adapter"
            active: app.bluetoothPowered && app.bluetoothAvailable
            available: app.bluetoothAvailable
            accent: "#5ac8fa"
            detailText: app.bluetoothDetail()
            footerText: app.bluetoothAvailable ? "Open Bluetooth" : "Open settings"
            onTriggered: app.launchBluetoothDiscovery()
        }
    }
    Component {
        id: batteryStatusModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: batterySource.pluggedIn ? "battery-charging" : "battery"
            title: batterySource.hasInternalBatteries ? (batterySource.pluggedIn ? "Charging" : "Battery") : "Power"
            subtitle: batterySource.hasInternalBatteries ? app.batteryText() : "Desktop"
            active: batterySource.pluggedIn
            accent: batterySource.percent <= 20 && batterySource.hasInternalBatteries ? "#ff453a" : "#34c759"
            progress: batterySource.hasInternalBatteries ? batterySource.percent : 100
            detailText: app.batteryText()
            footerText: batterySource.hasInternalBatteries ? (batterySource.pluggedIn ? "Plugged in" : "Discharging") : "AC power"
            actionIconName: "settings"
            onActionTriggered: app.launchPowerSettings()
        }
    }
    Component {
        id: batteryPercentModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: batterySource.pluggedIn ? "battery-charging" : "battery"
            title: app.batteryText()
            subtitle: batterySource.hasInternalBatteries ? (batterySource.pluggedIn ? "Charging" : "Remaining") : "Power"
            active: batterySource.pluggedIn
            accent: batterySource.percent <= 20 && batterySource.hasInternalBatteries ? "#ff453a" : "#34c759"
            progress: batterySource.hasInternalBatteries ? batterySource.percent : 100
            detailText: batterySource.pluggedIn ? "Charging" : "Power"
            actionIconName: "settings"
            onActionTriggered: app.launchPowerSettings()
        }
    }
    Component {
        id: powerModeModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: app.powerProfileIcon()
            title: app.powerProfileTitle()
            subtitle: "Power mode"
            active: true
            accent: "#ffd60a"
            detailText: powerProfilesSource.profiles && powerProfilesSource.profiles.length > 1 ? "Click to cycle" : "Current profile"
            footerText: powerProfilesSource.activeProfile
            actionIconName: "settings"
            onActionTriggered: app.launchPowerSettings()
            onTriggered: app.cyclePowerProfile()
        }
    }
    Component {
        id: appearanceModeModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: "preferences-desktop-theme"
            title: Brightness.DarkModeControl.darkMode ? "Dark" : "Light"
            subtitle: "Appearance"
            active: Brightness.DarkModeControl.darkMode
            accent: "#bf5af2"
            detailText: "Desktop color scheme"
            footerText: "Click to switch"
            onTriggered: app.toggleAppearanceMode()
        }
    }
    Component {
        id: themeModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: "preferences-desktop-theme-global"
            title: "Theme"
            subtitle: "Global themes"
            active: false
            accent: "#bf5af2"
            detailText: "Open KDE themes"
            onTriggered: app.launchAppearanceSettings()
        }
    }
    Component {
        id: kdeConnectModule
        KdeConnectTile {
            app: moduleCard.app
        }
    }
    Component {
        id: settingsModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: "systemsettings"
            title: "Settings"
            subtitle: "System"
            active: false
            accent: "#8e8eff"
            detailText: "Open System Settings"
            onTriggered: app.launchSystemSettings()
        }
    }
    Component {
        id: emptyModule
        SimpleModuleTile {
            app: moduleCard.app
            iconName: "unknown"
            title: moduleCard.moduleId
            subtitle: "Unknown"
            active: false
        }
    }
}
