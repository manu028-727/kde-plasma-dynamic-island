import QtQuick

Row {
    id: islandBars

    property bool playing: false
    property color color: "#c026d3"

    spacing: 4

    Repeater {
        model: [0.42, 0.88, 0.55, 0.74, 0.36]
        Rectangle {
            property real level: modelData
            width: 4
            height: Math.max(5, islandBars.height * level)
            y: (islandBars.height - height) / 2
            radius: 2
            color: islandBars.color
            opacity: islandBars.playing ? 1 : 0.45
            SequentialAnimation on level {
                running: islandBars.playing
                loops: Animation.Infinite
                PauseAnimation { duration: index * 55 }
                NumberAnimation { to: Math.max(0.24, 1 - modelData * 0.35); duration: 210 + index * 20; easing.type: Easing.InOutSine }
                NumberAnimation { to: modelData; duration: 240 + index * 25; easing.type: Easing.InOutSine }
            }
        }
    }
}

