import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

MouseArea {
    id: networkList

    required property var app
    required property var connectionsSource
    readonly property bool compact: width < 150 || height < 86
    readonly property bool iconOnly: width < 96 || height < 58
    readonly property var rows: app.wifiRows(compact ? 2 : 4)
    readonly property var connectedRows: app.connectedNetworkRows(compact ? 1 : 2)
    readonly property var ipRows: !compact && app.networkIpText.length > 0 ? app.networkIpText.split("\n").slice(0, 2) : []
    readonly property var visibleRows: connectedRows && connectedRows.length > 0 ? connectedRows.concat(ipRows || []).concat(rows || []) : rows && rows.length > 0 ? rows : [connectionsSource.wirelessEnabled ? "No visible networks" : "Open network settings"]

    anchors.fill: parent
    hoverEnabled: true
    enabled: !app.controlEditMode
    onClicked: app.launchNetworkSettings()

    Rectangle {
        anchors.fill: parent
        radius: Math.min(18, Math.min(width, height) / 2)
        color: networkList.pressed ? "#242630" : networkList.containsMouse ? "#1a1b24" : "#15161d"
        border.color: "#2a2b35"
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: app.wifiSignalPercent() > 0 ? Math.max(3, parent.height * app.wifiSignalPercent() / 100) : 0
            radius: parent.radius
            color: "#5ac8fa"
            opacity: connectionsSource.wirelessEnabled && app.wifiSignalPercent() > 0 && !networkList.iconOnly ? 0.1 : 0
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
                source: app.networkTitle() === "Wired" ? "network-wired-activated" : connectionsSource.wirelessEnabled ? "network-wireless-on" : "network-wireless-off"
                color: connectionsSource.networkingEnabled ? "#5ac8fa" : "#8f9099"
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: app.networkTitle()
                color: "#f8f8fb"
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            QQC2.Label {
                visible: networkList.width >= 156
                text: app.wifiSignalPercent() > 0 ? app.wifiSignalPercent() + "%" : ""
                color: "#8f9099"
                font.pixelSize: 10
                font.weight: Font.Bold
            }
            IslandButton {
                visible: !networkList.compact
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "view-refresh"
                compact: true
                onClicked: app.refreshWifiNetworks()
            }
            IslandButton {
                visible: !networkList.compact
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "settings"
                compact: true
                onClicked: app.launchNetworkSettings()
            }
        }

        Repeater {
            model: networkList.visibleRows
            QQC2.Label {
                Layout.fillWidth: true
                text: modelData
                color: String(modelData).indexOf("* ") === 0 || String(modelData).indexOf("• ") === 0 ? "#f8f8fb" : "#9b9ca6"
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
        source: app.networkTitle() === "Wired" ? "network-wired-activated" : connectionsSource.wirelessEnabled ? "network-wireless-on" : "network-wireless-off"
        color: connectionsSource.networkingEnabled ? "#5ac8fa" : "#8f9099"
    }

    QQC2.ToolTip.visible: networkList.containsMouse
    QQC2.ToolTip.text: app.networkDetail()
    QQC2.ToolTip.delay: 350
}
