import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

MouseArea {
    id: kdeTile

    required property var app
    readonly property var devices: app.kdeConnectDevices(rowLimit)
    readonly property int totalDevices: app.kdeConnectDevices(0).length
    readonly property int reachableDevices: app.kdeConnectReachableCount()
    readonly property bool hasDevices: totalDevices > 0
    readonly property bool iconOnly: width < 92 || height < 54
    readonly property bool compact: width < 160 || height < 110
    readonly property bool detailed: width >= 220 && height >= 145
    readonly property int rowLimit: compact ? 1 : Math.max(1, Math.floor((height - 54) / 44))
    readonly property int visibleDeviceCount: devices ? devices.length : 0

    function deviceText(device, key, fallbackValue) {
        if (!device || device[key] === undefined || device[key] === null)
            return fallbackValue;

        return app.cleanText(device[key]);
    }

    anchors.fill: parent
    hoverEnabled: true
    enabled: !app.controlEditMode
    onClicked: app.launchKdeConnectSettings()

    Rectangle {
        anchors.fill: parent
        radius: Math.min(18, Math.min(width, height) / 2)
        color: kdeTile.pressed ? "#242630" : kdeTile.containsMouse ? "#1a1b24" : kdeTile.hasDevices ? "#171821" : "#15161d"
        border.color: kdeTile.hasDevices && !kdeTile.iconOnly ? Qt.rgba(0.35, 0.78, 0.98, 0.42) : "#2a2b35"
        border.width: 1
    }

    ColumnLayout {
        visible: !kdeTile.iconOnly
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Kirigami.Icon {
                Layout.preferredWidth: 19
                Layout.preferredHeight: 19
                source: "kdeconnect"
                color: kdeTile.reachableDevices > 0 ? "#5ac8fa" : kdeTile.hasDevices ? "#8e8eff" : "#8f9099"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

                PlasmaLabel {
                    Layout.fillWidth: true
                    text: "KDE Connect"
                    color: "#f8f8fb"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                PlasmaLabel {
                    Layout.fillWidth: true
                    text: kdeTile.reachableDevices > 0 ? kdeTile.reachableDevices + " reachable" : app.kdeConnectSummary()
                    color: "#8f9099"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            IslandButton {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "view-refresh"
                tooltipText: "Refresh devices"
                compact: true
                onClicked: app.refreshKdeConnectDevices()
            }

            IslandButton {
                visible: !kdeTile.compact
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "settings"
                tooltipText: "Open KDE Connect"
                compact: true
                onClicked: app.launchKdeConnectSettings()
            }
        }

        Repeater {
            model: kdeTile.devices

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: kdeTile.detailed ? 42 : 30
                radius: 12
                color: "#11121a"
                border.color: modelData && modelData.reachable ? Qt.rgba(0.35, 0.78, 0.98, 0.32) : "#242631"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 7

                    Rectangle {
                        Layout.preferredWidth: 7
                        Layout.preferredHeight: 7
                        radius: 4
                        color: modelData && modelData.reachable ? "#34c759" : modelData && modelData.paired ? "#8e8eff" : "#777884"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -1

                        PlasmaLabel {
                            Layout.fillWidth: true
                            text: kdeTile.deviceText(modelData, "name", "Device")
                            color: "#f4f4f8"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        PlasmaLabel {
                            visible: kdeTile.detailed
                            Layout.fillWidth: true
                            text: kdeTile.deviceText(modelData, "status", "available")
                            color: "#8f9099"
                            font.pixelSize: 9
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Row {
                        visible: kdeTile.deviceText(modelData, "id", "").length > 0 && kdeTile.detailed
                        spacing: 5

                        IslandButton {
                            width: 22
                            height: 22
                            iconName: "dialog-information"
                            tooltipText: "Ping device"
                            compact: true
                            onClicked: app.runKdeConnectDeviceAction(kdeTile.deviceText(modelData, "id", ""), "ping")
                        }

                        IslandButton {
                            width: 22
                            height: 22
                            iconName: "notifications"
                            tooltipText: "Ring device"
                            compact: true
                            onClicked: app.runKdeConnectDeviceAction(kdeTile.deviceText(modelData, "id", ""), "ring")
                        }

                        IslandButton {
                            visible: kdeTile.width >= 285
                            width: 22
                            height: 22
                            iconName: "folder"
                            tooltipText: "Mount files"
                            compact: true
                            onClicked: app.runKdeConnectDeviceAction(kdeTile.deviceText(modelData, "id", ""), "mount")
                        }
                    }
                }
            }
        }

        PlasmaLabel {
            visible: !kdeTile.hasDevices
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "No devices found"
            color: "#777884"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        PlasmaLabel {
            visible: kdeTile.hasDevices && kdeTile.totalDevices > kdeTile.visibleDeviceCount
            Layout.fillWidth: true
            text: "+" + (kdeTile.totalDevices - kdeTile.visibleDeviceCount) + " more"
            color: "#777884"
            font.pixelSize: 9
            horizontalAlignment: Text.AlignRight
        }
    }

    Kirigami.Icon {
        visible: kdeTile.iconOnly
        anchors.centerIn: parent
        width: Math.max(20, Math.min(36, parent.width - 14, parent.height - 14))
        height: width
        source: "kdeconnect"
        color: kdeTile.reachableDevices > 0 ? "#5ac8fa" : kdeTile.hasDevices ? "#8e8eff" : "#8f9099"
    }

    Rectangle {
        visible: kdeTile.iconOnly && kdeTile.hasDevices
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 7
        width: 8
        height: 8
        radius: 4
        color: kdeTile.reachableDevices > 0 ? "#34c759" : "#8e8eff"
    }

    QQC2.ToolTip.visible: kdeTile.containsMouse
    QQC2.ToolTip.text: kdeTile.hasDevices ? app.kdeConnectSummary() : "No reachable KDE Connect devices"
    QQC2.ToolTip.delay: 350
}
