import QtQuick

Row {
    id: bars

    property bool playing: false
    property color barColor: "#c026d3"
    property int barWidth: 3

    spacing: 3

    Repeater {
        model: [0.45, 0.86, 0.58, 0.74, 0.36]

        Rectangle {
            required property real modelData
            required property int index
            property real level: modelData

            width: bars.barWidth
            height: Math.max(4, bars.height * level)
            anchors.verticalCenter: parent.verticalCenter
            radius: width / 2
            color: bars.barColor
            opacity: bars.playing ? 1 : 0.48

            SequentialAnimation on level {
                running: bars.playing
                loops: Animation.Infinite

                PauseAnimation {
                    duration: index * 55
                }

                NumberAnimation {
                    to: Math.max(0.28, 1 - modelData * 0.35)
                    duration: 210 + index * 20
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: modelData
                    duration: 240 + index * 25
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
