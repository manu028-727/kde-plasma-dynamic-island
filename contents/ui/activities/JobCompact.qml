import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Item {
    id: jobCompact

    property var app: null
    readonly property int row: app ? app.activeJobRow() : -1
    readonly property int percentage: app ? app.jobPercentage(row) : -1

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 2
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            PlasmaLabel {
                Layout.fillWidth: true
                text: jobCompact.row >= 0 ? jobCompact.app.jobTitle(jobCompact.row) : i18n("Working")
                color: "#e8f7ec"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaLabel {
                visible: jobCompact.percentage >= 0
                text: jobCompact.percentage + "%"
                color: "#c7f9d4"
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            from: 0
            to: 100
            value: Math.max(0, jobCompact.percentage)
            accent: "#42d77d"
        }
    }
}
