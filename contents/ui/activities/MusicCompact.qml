import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: musicCompact

    property var app: null
    readonly property bool hasPlayer: app && app.hasPlayer

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 1
        spacing: 5

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            PlasmaLabel {
                Layout.fillWidth: true
                text: musicCompact.hasPlayer ? musicCompact.app.player.track || musicCompact.app.player.identity || i18n("Media") : i18n("Media")
                color: "#e9e9ef"
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                visible: musicCompact.hasPlayer && musicCompact.app.player.length > 0
                from: 0
                to: Math.max(1, musicCompact.hasPlayer ? musicCompact.app.player.length : 1)
                value: musicCompact.hasPlayer ? musicCompact.app.player.position : 0
                accent: "#5ac8fa"
            }
        }

        AudioBars {
            Layout.preferredWidth: 27
            Layout.preferredHeight: Math.max(14, musicCompact.height - 6)
            Layout.alignment: Qt.AlignVCenter
            playing: musicCompact.hasPlayer && musicCompact.app.isPlaying
        }
    }
}
