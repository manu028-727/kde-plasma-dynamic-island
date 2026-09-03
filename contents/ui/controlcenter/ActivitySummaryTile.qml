import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import ".."

Rectangle {
    id: activitySummary

    required property var app
    required property var notificationsSource
    property bool mediaOnly: false
    readonly property bool showMedia: app.hasPlayer
    readonly property bool showAnyActivity: mediaOnly ? showMedia : app.hasActivity
    readonly property string summaryMode: mediaOnly ? app.hasPlayer ? "media" : "idle" : app.activityMode()
    readonly property color activityColor: mediaOnly ? "#5ac8fa" : app.isPlaying ? "#c026d3" : app.hasNotifications ? "#ff9f0a" : app.hasJobs ? "#34c759" : "#54545f"
    readonly property bool iconOnly: width < 100 || height < 62
    readonly property bool compact: width < 190 || height < 112
    readonly property real artSize: iconOnly ? Math.max(24, Math.min(width, height) - 18) : compact ? Math.max(36, Math.min(52, height - 22)) : Math.max(48, Math.min(64, height - 28))

    function previous() {
        app.mediaPrevious();
    }

    function playPause() {
        app.mediaPlayPause();
    }

    function next() {
        app.mediaNext();
    }

    radius: 22
    color: "#101116"
    border.color: "#202129"
    border.width: 1
    clip: true

    RowLayout {
        visible: !activitySummary.iconOnly
        anchors.fill: parent
        anchors.margins: activitySummary.compact ? 10 : 14
        spacing: activitySummary.compact ? 9 : 13

        MaskedArtworkTile {
            Layout.preferredWidth: activitySummary.artSize
            Layout.preferredHeight: activitySummary.artSize
            artworkSource: app.hasPlayer ? app.player.artUrl : ""
            cornerRadius: activitySummary.compact ? 12 : 16
            glyphSize: activitySummary.compact ? 28 : 36
            mode: activitySummary.summaryMode
            progress: Math.max(0, notificationsSource.jobsPercentage) / 100
            playing: app.isPlaying
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: activitySummary.showAnyActivity ? app.primaryText() : activitySummary.mediaOnly ? "Nothing playing" : "Ready"
                        color: "#ffffff"
                        font.pixelSize: activitySummary.compact ? 12 : 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: activitySummary.showAnyActivity ? app.secondaryText() : activitySummary.mediaOnly ? "" : "Media, notifications and jobs"
                        color: "#9b9ba6"
                        font.pixelSize: activitySummary.compact ? 10 : 11
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }
                IslandBars {
                    visible: !activitySummary.compact || width >= 260
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 28
                    color: activitySummary.activityColor
                    playing: activitySummary.mediaOnly ? app.isPlaying : app.isPlaying || app.hasJobs || app.hasNotifications
                }
            }

            ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                visible: !activitySummary.compact && ((!activitySummary.mediaOnly && app.hasJobs) || (app.hasPlayer && app.player.length > 0))
                from: 0
                to: !activitySummary.mediaOnly && app.hasJobs ? 100 : Math.max(1, app.player ? app.player.length : 1)
                value: !activitySummary.mediaOnly && app.hasJobs ? Math.max(0, notificationsSource.jobsPercentage) : app.player ? app.player.position : 0
                accent: !activitySummary.mediaOnly && app.hasJobs ? "#34c759" : "#5ac8fa"
            }

            RowLayout {
                visible: !activitySummary.compact
                Layout.fillWidth: true
                spacing: 8
                RowLayout {
                    visible: app.hasPlayer
                    spacing: 8
                    IslandButton { iconName: "media-skip-backward"; compact: true; enabled: app.player && app.player.canGoPrevious; onClicked: activitySummary.previous() }
                    IslandButton { iconName: app.isPlaying ? "media-playback-pause" : "media-playback-start"; compact: true; emphasized: true; enabled: app.player && (app.player.canPlay || app.player.canPause); onClicked: activitySummary.playPause() }
                    IslandButton { iconName: "media-skip-forward"; compact: true; enabled: app.player && app.player.canGoNext; onClicked: activitySummary.next() }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: activitySummary.mediaOnly ? app.hasPlayer ? app.player.identity || "Media player" : "" : app.hasJobs ? "Download active" : app.hasNotifications ? notificationsSource.unreadNotificationsCount + " unread" : "No activity"
                    color: "#8f9099"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }
    }

    MaskedArtworkTile {
        visible: activitySummary.iconOnly
        anchors.centerIn: parent
        width: activitySummary.artSize
        height: width
        artworkSource: app.hasPlayer ? app.player.artUrl : ""
        cornerRadius: 10
        glyphSize: width * 0.7
        mode: activitySummary.summaryMode
        progress: Math.max(0, notificationsSource.jobsPercentage) / 100
        playing: app.isPlaying
    }

    IslandBars {
        visible: activitySummary.iconOnly && (activitySummary.mediaOnly ? app.isPlaying : app.isPlaying || app.hasJobs || app.hasNotifications) && width >= 58
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: 20
        spacing: 2
        color: activitySummary.activityColor
        playing: true
    }
}
