import QtQuick
import QtQuick.Effects
import ".."

Item {
    id: maskedArtwork

    property var artworkSource: ""
    property real cornerRadius: height / 2
    property string mode: "idle"
    property real progress: 0
    property bool playing: false
    property real glyphSize: width * 0.74
    readonly property bool hasArtworkSource: artworkSource && artworkSource.toString().length > 0
    readonly property bool hasArtwork: hasArtworkSource && maskedImage.status === Image.Ready
    readonly property real safeProgress: isFinite(Number(progress)) ? Math.max(0, Math.min(1, Number(progress))) : 0

    Rectangle { anchors.fill: parent; radius: maskedArtwork.cornerRadius; color: "#101015" }

    Image {
        id: maskedImage
        anchors.fill: parent
        source: maskedArtwork.hasArtworkSource ? maskedArtwork.artworkSource : ""
        fillMode: Image.PreserveAspectCrop
        visible: maskedArtwork.hasArtwork
        layer.enabled: visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMax: 1
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: maskedImage.width
                    height: maskedImage.height
                    radius: maskedArtwork.cornerRadius
                    color: "#ffffff"
                }
            }
        }
    }

    IslandGlyph {
        anchors.centerIn: parent
        width: maskedArtwork.glyphSize
        height: width
        mode: maskedArtwork.mode
        progress: maskedArtwork.safeProgress
        playing: maskedArtwork.playing
        visible: !maskedArtwork.hasArtwork
    }
}
