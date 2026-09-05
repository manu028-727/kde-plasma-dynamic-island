import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

Item {
    id: jobPage

    property var app: null
    readonly property int row: app ? app.activeJobRow() : -1
    readonly property var details: app ? app.jobDetails(row) : null
    readonly property int percentage: app ? app.jobPercentage(row) : -1
    readonly property bool suspended: app ? app.jobIsSuspended(row) : false

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 58
            Layout.preferredHeight: 58
            Layout.alignment: Qt.AlignVCenter
            radius: 16
            color: "#101714"
            border.color: "#243a2b"
            border.width: 1

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 34
                height: 34
                source: jobPage.row >= 0 ? jobPage.app.jobIcon(jobPage.row) : "folder-download"
                fallback: "folder-download"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            PlasmaLabel {
                Layout.fillWidth: true
                text: jobPage.row >= 0 ? jobPage.app.jobTitle(jobPage.row) : i18n("Working")
                color: "#ffffff"
                font.pixelSize: 12
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: jobPage.row >= 0 ? jobPage.app.jobText(jobPage.row) : ""
                color: "#a7aaa9"
                font.pixelSize: 9
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 5
                    from: 0
                    to: 100
                    value: Math.max(0, jobPage.percentage)
                    accent: jobPage.suspended ? "#ff9f0a" : "#42d77d"
                }

                PlasmaLabel {
                    visible: jobPage.percentage >= 0
                    text: jobPage.percentage + "%"
                    color: jobPage.suspended ? "#ffd7a1" : "#c7f9d4"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: jobPage.row >= 0 ? jobPage.app.jobDetailsText(jobPage.row) : ""
                color: "#777f7a"
                font.pixelSize: 8
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        RowLayout {
            spacing: 5

            IslandButton {
                visible: jobPage.row >= 0 && jobPage.app.jobSuspendable(jobPage.row)
                iconName: jobPage.suspended ? "media-playback-start" : "media-playback-pause"
                tooltipText: jobPage.suspended ? i18n("Resume") : i18n("Pause")
                compact: true
                emphasized: jobPage.suspended
                onClicked: jobPage.app.toggleJobSuspended(jobPage.row)
            }

            IslandButton {
                visible: jobPage.row >= 0 && jobPage.app.jobKillable(jobPage.row)
                iconName: "process-stop"
                tooltipText: i18n("Cancel")
                compact: true
                onClicked: jobPage.app.cancelJob(jobPage.row)
            }
        }
    }
}
