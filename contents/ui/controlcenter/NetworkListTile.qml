import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

MouseArea {
    id: networkList

    required property var app
    readonly property var networkStatus: app.networkState
    readonly property bool compact: width < 150 || height < 86
    readonly property bool iconOnly: width < 96 || height < 58
    readonly property bool detailed: width >= 190 && height >= 112

    anchors.fill: parent
    hoverEnabled: true
    enabled: !app.controlEditMode
    onClicked: app.launchNetworkSettings()

    Rectangle {
        anchors.fill: parent
        radius: Math.min(18, Math.min(width, height) / 2)
        color: networkList.pressed ? "#242630" : networkList.containsMouse ? "#1a1b24" : networkList.networkStatus.connected ? "#171821" : "#15161d"
        border.color: networkList.networkStatus.connected && !networkList.iconOnly ? Qt.rgba(0.35, 0.78, 0.98, 0.36) : "#2a2b35"
        border.width: 1
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
                source: networkList.networkStatus.icon
                color: networkList.networkStatus.connected ? "#5ac8fa" : "#8f9099"
            }
            PlasmaLabel {
                Layout.fillWidth: true
                text: networkList.networkStatus.title
                textFormat: Text.PlainText
                color: "#f8f8fb"
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            PlasmaLabel {
                visible: networkList.width >= 156 && networkList.networkStatus.signal >= 0
                text: networkList.networkStatus.signal + "%"
                color: "#5ac8fa"
                font.pixelSize: 10
                font.weight: Font.Bold
            }
            IslandButton {
                visible: !networkList.compact
                enabled: networkList.enabled
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "view-refresh"
                tooltipText: "Refresh network status"
                compact: true
                onClicked: networkList.app.refreshWifiNetworks()
            }
            IslandButton {
                visible: !networkList.compact && networkList.width >= 230
                enabled: networkList.enabled
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "settings"
                tooltipText: "Network settings"
                compact: true
                onClicked: networkList.app.launchNetworkSettings()
            }
        }

        PlasmaLabel {
            Layout.fillWidth: true
            text: networkList.networkStatus.summary
            textFormat: Text.PlainText
            color: "#f8f8fb"
            font.pixelSize: networkList.compact ? 10 : 12
            font.weight: Font.Bold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        PlasmaLabel {
            visible: networkList.detailed
            Layout.fillWidth: true
            text: networkList.networkStatus.detailLine
            textFormat: Text.PlainText
            color: "#8f9099"
            font.pixelSize: 10
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Item {
            visible: networkList.detailed
            Layout.fillHeight: true
        }

        RowLayout {
            visible: networkList.detailed
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                radius: 4
                color: networkList.networkStatus.connected ? "#34c759" : "#ff453a"
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: networkList.networkStatus.footer
                color: "#777884"
                font.pixelSize: 9
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
        source: networkList.networkStatus.icon
        color: networkList.networkStatus.connected ? "#5ac8fa" : "#8f9099"
    }

    QQC2.ToolTip {
        id: networkToolTip

        visible: networkList.containsMouse
        text: networkList.networkStatus.detail
        delay: 350
        contentItem: PlasmaLabel {
            text: networkToolTip.text
            textFormat: Text.PlainText
            color: networkToolTip.palette.toolTipText
            wrapMode: Text.Wrap
        }
    }
}
