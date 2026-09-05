import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: notificationCompact

    property var app: null
    readonly property int row: app ? app.notificationLatestRow() : -1
    readonly property int unreadCount: app ? app.notificationUnreadCount : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 2
        spacing: 5

        PlasmaLabel {
            Layout.fillWidth: true
            text: notificationCompact.row >= 0 ? notificationCompact.app.notificationTitle(notificationCompact.row) : i18n("Notification")
            color: "#f2f2f7"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Item {
            Layout.preferredWidth: Math.max(18, unreadLabel.implicitWidth + 10)
            Layout.preferredHeight: 18

            Rectangle {
                id: unreadPulse

                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: height / 2
                color: "#ff9f0a"
                opacity: 0.16

                SequentialAnimation on scale {
                    running: notificationCompact.unreadCount > 0
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.12; duration: 520; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#2a1c0c"
                border.color: "#73480d"
                border.width: 1
            }

            PlasmaLabel {
                id: unreadLabel

                anchors.centerIn: parent
                text: notificationCompact.unreadCount > 0 ? String(notificationCompact.unreadCount) : "!"
                color: "#ffd7a1"
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }
    }
}
