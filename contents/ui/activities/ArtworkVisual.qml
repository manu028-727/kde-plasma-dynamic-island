import QtQuick
import QtQuick.Effects
import ".."

Item {
    id: artwork

    property var source: ""
    property real cornerRadius: Math.min(width, height) / 2
    property string fallbackMode: "media"
    property real progress: 0
    property bool playing: false
    property real glyphSize: width * 0.7

    readonly property bool hasSource: source !== undefined && source !== null && String(source).length > 0
    readonly property bool ready: hasSource && image.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        radius: artwork.cornerRadius
        color: "#101015"
        border.color: "#262631"
        border.width: 1
    }

    Image {
        id: image

        anchors.fill: parent
        source: artwork.source
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        visible: artwork.ready
        layer.enabled: visible

        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMax: 1
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5

            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: image.width
                    height: image.height
                    radius: artwork.cornerRadius
                    color: "#ffffff"
                }
            }
        }
    }

    IslandGlyph {
        anchors.centerIn: parent
        width: artwork.glyphSize
        height: width
        mode: artwork.fallbackMode
        progress: artwork.progress
        playing: artwork.playing
        visible: !artwork.ready
    }
}
