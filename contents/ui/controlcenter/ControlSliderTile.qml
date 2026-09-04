import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import ".."

Item {
    id: controlSlider

    required property var app
    property string title: ""
    property string iconName: ""
    property string valueText: ""
    property real value: 0
    property real toValue: 100
    property color accent: "#5ac8fa"
    property string actionIconName: ""
    property string secondaryActionIconName: ""
    readonly property real safeToValue: Math.max(1, app.finiteNumber(toValue, 100))
    readonly property real safeValue: Math.max(0, Math.min(safeToValue, app.finiteNumber(value, 0)))
    readonly property real ratio: safeValue / safeToValue
    readonly property real fillRatio: ratio
    readonly property bool vertical: height > width * 1.25
    readonly property bool showActions: width >= 142 && height >= 72 && (actionIconName.length > 0 || secondaryActionIconName.length > 0)

    signal moved(real value)
    signal actionTriggered()
    signal secondaryActionTriggered()

    implicitHeight: 116

    Rectangle {
        anchors.fill: parent
        radius: Math.min(18, Math.min(width, height) / 2)
        color: "#15161d"
        border.color: "#2a2b35"
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: controlSlider.vertical ? parent.width : parent.width * controlSlider.fillRatio
            height: controlSlider.vertical ? parent.height * controlSlider.fillRatio : parent.height
            radius: parent.radius
            color: controlSlider.accent
            opacity: controlSlider.enabled ? (app.controlEditMode ? 0.72 : 0.92) : 0.16

            Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: "#31323d"
            border.width: 1
        }
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.max(16, Math.min(34, parent.width - 14, parent.height - 14))
        height: width
        source: controlSlider.iconName
        color: "#f8f8fb"
        opacity: controlSlider.enabled ? 1 : 0.42
    }

    PlasmaLabel {
        visible: controlSlider.width >= 116 && !controlSlider.showActions
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        text: controlSlider.valueText
        color: "#f8f8fb"
        font.pixelSize: 11
        font.weight: Font.Bold
    }

    QQC2.ToolTip.visible: hoverArea.containsMouse
    QQC2.ToolTip.text: controlSlider.title + " " + controlSlider.valueText
    QQC2.ToolTip.delay: 350

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: controlSlider.enabled && !app.controlEditMode
        preventStealing: true

        function valueFromMouse(mouse) {
            const pct = controlSlider.vertical ? 1 - mouse.y / Math.max(1, height) : mouse.x / Math.max(1, width);
            return Math.round(Math.max(0, Math.min(1, pct)) * controlSlider.safeToValue);
        }

        onPressed: (mouse) => {
            mouse.accepted = true;
            controlSlider.moved(valueFromMouse(mouse));
        }
        onPositionChanged: (mouse) => {
            if (pressed) {
                mouse.accepted = true;
                controlSlider.moved(valueFromMouse(mouse));
            }
        }
    }

    Row {
        visible: controlSlider.showActions
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 6
        z: 3

        IslandButton {
            visible: controlSlider.actionIconName.length > 0
            width: 26
            height: 26
            compact: true
            iconName: controlSlider.actionIconName
            onClicked: controlSlider.actionTriggered()
        }

        IslandButton {
            visible: controlSlider.secondaryActionIconName.length > 0
            width: 26
            height: 26
            compact: true
            iconName: controlSlider.secondaryActionIconName
            onClicked: controlSlider.secondaryActionTriggered()
        }
    }

    PlasmaLabel {
        visible: controlSlider.showActions && controlSlider.width >= 180
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10
        text: controlSlider.valueText
        color: "#f8f8fb"
        font.pixelSize: 11
        font.weight: Font.Bold
    }
}

