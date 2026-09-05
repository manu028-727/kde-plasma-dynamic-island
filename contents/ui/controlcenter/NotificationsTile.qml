import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import ".."
import "../activities" as Activities

Item {
    id: notificationsContent

    required property var app
    required property var notificationsSource
    readonly property int notificationTotal: app.notificationCount()
    readonly property bool iconOnly: width < 100 || height < 62
    readonly property bool compact: width < 170 || height < 118
    readonly property bool detailed: width >= 230 && height >= 150
    readonly property int rowHeight: detailed ? 52 : 30
    readonly property int rowLimit: compact ? 1 : Math.max(1, Math.floor((height - 56) / rowHeight))
    readonly property int overflowCount: app.notificationOverflowCount(rowLimit)

    function closeRow(row) {
        if (row < 0 || row >= notificationsSource.count)
            return;

        if (!app.rowValue(row, NotificationManager.Notifications.ClosableRole, true))
            return;

        notificationsSource.close(notificationsSource.index(row, 0));
    }

    anchors.fill: parent

    ColumnLayout {
        visible: !notificationsContent.iconOnly
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Kirigami.Icon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: notificationsContent.notificationTotal > 0 ? "notifications" : "notifications-disabled"
                color: notificationsContent.notificationTotal > 0 ? "#ff9f0a" : "#8f9099"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

                PlasmaLabel {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: "#f8f8fb"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                PlasmaLabel {
                    Layout.fillWidth: true
                    text: app.notificationStatusText()
                    color: "#8f9099"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            IslandButton {
                visible: !notificationsContent.compact
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "edit-clear-all"
                tooltipText: "Clear notifications"
                compact: true
                enabled: notificationsContent.notificationTotal > 0
                onClicked: app.clearNotifications()
            }

            IslandButton {
                visible: !notificationsContent.compact
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "settings"
                tooltipText: "Notification settings"
                compact: true
                onClicked: app.launchNotificationSettings()
            }
        }

        Repeater {
            model: app.notificationRows(notificationsContent.rowLimit)

            delegate: MouseArea {
                id: rowArea

                Layout.fillWidth: true
                Layout.preferredHeight: notificationsContent.rowHeight
                hoverEnabled: true
                enabled: !app.controlEditMode
                onClicked: app.openNotification(modelData)

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: rowArea.pressed ? "#242630" : rowArea.containsMouse ? "#1a1b24" : "#11121a"
                    border.color: rowArea.containsMouse ? "#343542" : "#242631"
                    border.width: 1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: notificationsContent.detailed ? 34 : 22
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: Math.min(10, width / 2)
                        color: Qt.rgba(1, 1, 1, 0.05)

                        Activities.NotificationVisual {
                            anchors.fill: parent
                            source: notificationsContent.detailed && app.notificationImagesEnabled ? app.notificationMainImage(modelData) : app.notificationAppIcon(modelData)
                            fallbackSource: app.notificationMainIcon(modelData)
                            fallbackColor: app.notificationAccent(modelData)
                            cornerRadius: Math.min(10, width / 2)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: notificationsContent.detailed ? 2 : -1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            PlasmaLabel {
                                Layout.fillWidth: true
                                text: app.notificationTitle(modelData)
                                color: "#f4f4f8"
                                font.pixelSize: notificationsContent.detailed ? 11 : 10
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Rectangle {
                                visible: notificationsContent.detailed
                                Layout.preferredWidth: 6
                                Layout.preferredHeight: 6
                                radius: 3
                                color: app.notificationAccent(modelData)
                            }
                        }

                        PlasmaLabel {
                            Layout.fillWidth: true
                            text: notificationsContent.detailed && app.notificationBody(modelData).length > 0 ? app.notificationBody(modelData) : app.notificationAppName(modelData)
                            textFormat: Text.PlainText
                            color: "#9b9ca6"
                            font.pixelSize: 9
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: notificationsContent.detailed ? Math.min(2, app.notificationBodyLines) : 1
                        }
                    }

                    IslandButton {
                        visible: !notificationsContent.compact
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        iconName: "window-close"
                        tooltipText: "Dismiss"
                        compact: true
                        enabled: app.rowValue(modelData, NotificationManager.Notifications.ClosableRole, true)
                        onClicked: notificationsContent.closeRow(modelData)
                    }
                }
            }
        }

        PlasmaLabel {
            visible: notificationsContent.notificationTotal <= 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Quiet"
            color: "#777884"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        PlasmaLabel {
            visible: notificationsContent.notificationTotal > 0 && notificationsContent.overflowCount > 0
            Layout.fillWidth: true
            text: "+" + notificationsContent.overflowCount + " more"
            color: "#777884"
            font.pixelSize: 9
            horizontalAlignment: Text.AlignRight
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

        PlasmaLabel {
            id: countLabel

            anchors.centerIn: parent
            text: notificationsContent.notificationTotal
            color: "#ffffff"
            font.pixelSize: 9
            font.weight: Font.Bold
        }
    }
}
