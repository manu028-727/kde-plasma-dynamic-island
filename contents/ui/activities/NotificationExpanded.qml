import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

Item {
    id: notificationPage

    property var app: null
    readonly property int notificationRow: app ? app.notificationLatestRow() : -1
    readonly property bool hasNotification: notificationRow >= 0

    RowLayout {
        anchors.fill: parent
        spacing: 10

        NotificationVisual {
            Layout.preferredWidth: 58
            Layout.preferredHeight: 58
            Layout.alignment: Qt.AlignVCenter
            source: notificationPage.hasNotification && notificationPage.app.notificationImagesEnabled ? notificationPage.app.notificationMainImage(notificationPage.notificationRow) : null
            fallbackSource: notificationPage.hasNotification ? notificationPage.app.notificationMainIcon(notificationPage.notificationRow) : "notifications"
            fallbackColor: notificationPage.hasNotification ? notificationPage.app.notificationAccent(notificationPage.notificationRow) : "#ff9f0a"
            cornerRadius: 16
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Kirigami.Icon {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    source: notificationPage.hasNotification ? notificationPage.app.notificationAppIcon(notificationPage.notificationRow) : "notifications"
                }

                PlasmaLabel {
                    Layout.fillWidth: true
                    text: notificationPage.hasNotification ? notificationPage.app.notificationAppName(notificationPage.notificationRow) : i18n("Notification")
                    color: "#a6a6af"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: notificationPage.hasNotification ? notificationPage.app.notificationAccent(notificationPage.notificationRow) : "#ff9f0a"
                }
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: notificationPage.hasNotification ? notificationPage.app.notificationTitle(notificationPage.notificationRow) : i18n("Notification")
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaLabel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: text.length > 0
                text: notificationPage.hasNotification ? notificationPage.app.notificationBody(notificationPage.notificationRow) : ""
                textFormat: Text.PlainText
                color: "#b3b3bd"
                font.pixelSize: 9
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: notificationPage.app ? notificationPage.app.notificationBodyLines : 3
            }
        }
    }
}
