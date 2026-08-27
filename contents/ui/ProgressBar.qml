import QtQuick

Item {
    id: control

    property real from: 0
    property real to: 100
    property real value: 0
    property color accent: "#5ac8fa"
    readonly property real amount: Math.max(0, Math.min(1, (value - from) / Math.max(1, to - from)))

    implicitHeight: 8

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#24242b"
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(parent.height, parent.width * control.amount)
        radius: height / 2
        color: control.accent

        Behavior on width {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }

        }

    }

}
