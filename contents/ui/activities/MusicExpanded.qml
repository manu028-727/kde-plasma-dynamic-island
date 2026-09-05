import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: musicPage

    property var app: null
    readonly property bool hasPlayer: app && app.hasPlayer

    RowLayout {
        anchors.fill: parent
        spacing: 10

        ArtworkVisual {
            Layout.preferredWidth: 58
            Layout.preferredHeight: 58
            Layout.alignment: Qt.AlignVCenter
            source: musicPage.hasPlayer ? musicPage.app.player.artUrl : ""
            cornerRadius: 16
            fallbackMode: "media"
            progress: musicPage.hasPlayer ? musicPage.app.player.position / Math.max(1, musicPage.app.player.length) : 0
            playing: musicPage.hasPlayer && musicPage.app.isPlaying
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            PlasmaLabel {
                Layout.fillWidth: true
                text: musicPage.hasPlayer ? musicPage.app.player.track || musicPage.app.player.identity || i18n("Media") : i18n("Media")
                color: "#ffffff"
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                PlasmaLabel {
                    Layout.fillWidth: true
                    text: musicPage.hasPlayer ? musicPage.app.player.artist || musicPage.app.player.album || musicPage.app.player.identity || "" : ""
                    color: "#9d9da7"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                AudioBars {
                    Layout.preferredWidth: 27
                    Layout.preferredHeight: 12
                    playing: musicPage.hasPlayer && musicPage.app.isPlaying
                    barWidth: 3
                }
            }

            ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                visible: musicPage.hasPlayer && musicPage.app.player.length > 0
                from: 0
                to: Math.max(1, musicPage.hasPlayer ? musicPage.app.player.length : 1)
                value: musicPage.hasPlayer ? musicPage.app.player.position : 0
                accent: "#5ac8fa"
            }

            PlasmaLabel {
                Layout.fillWidth: true
                visible: musicPage.hasPlayer && musicPage.app.player.length > 0
                text: musicPage.hasPlayer ? musicPage.app.formatMediaProgress(musicPage.app.player.position, musicPage.app.player.length) : ""
                color: "#777781"
                font.pixelSize: 8
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            spacing: 5

            IslandButton {
                iconName: "media-skip-backward"
                compact: true
                enabled: musicPage.hasPlayer && musicPage.app.player.canGoPrevious
                onClicked: musicPage.app.mediaPrevious()
            }

            IslandButton {
                iconName: musicPage.hasPlayer && musicPage.app.isPlaying ? "media-playback-pause" : "media-playback-start"
                compact: true
                emphasized: true
                enabled: musicPage.hasPlayer && (musicPage.app.player.canPlay || musicPage.app.player.canPause)
                onClicked: musicPage.app.mediaPlayPause()
            }

            IslandButton {
                iconName: "media-skip-forward"
                compact: true
                enabled: musicPage.hasPlayer && musicPage.app.player.canGoNext
                onClicked: musicPage.app.mediaNext()
            }
        }
    }
}
