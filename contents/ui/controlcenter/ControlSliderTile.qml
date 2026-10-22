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
    property string actionTooltip: ""
    property string secondaryActionTooltip: ""
    // A missing audio sink or backlight should disable the slider, not the
    // settings action buttons in the corner of the tile.
    property bool sliderEnabled: true
    readonly property bool sliderAvailable: enabled && sliderEnabled
    readonly property real safeToValue: Math.max(1, app.finiteNumber(toValue, 100))
    readonly property real safeValue: Math.max(0, Math.min(safeToValue, app.finiteNumber(value, 0)))
    readonly property real ratio: safeValue / safeToValue
    readonly property real fillRatio: ratio
    readonly property bool vertical: height > width * 1.25
    readonly property bool showActions: width >= 142 && height >= 72 && (actionIconName.length > 0 || secondaryActionIconName.length > 0)
    readonly property real keyboardStep: Math.max(1, Math.round(safeToValue / 20))

    signal moved(real value)
    signal actionTriggered()
    signal secondaryActionTriggered()

    implicitHeight: 116
    activeFocusOnTab: sliderAvailable
    Accessible.role: Accessible.Slider
    Accessible.name: title
    Accessible.description: valueText
    Accessible.onIncreaseAction: adjustBy(keyboardStep)
    Accessible.onDecreaseAction: adjustBy(-keyboardStep)
    Keys.onLeftPressed: adjustBy(-keyboardStep)
    Keys.onRightPressed: adjustBy(keyboardStep)
    Keys.onUpPressed: adjustBy(keyboardStep)
    Keys.onDownPressed: adjustBy(-keyboardStep)

    function adjustBy(delta) {
        if (!sliderAvailable)
            return ;
        controlSlider.moved(Math.max(0, Math.min(safeToValue, safeValue + delta)));
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(18, Math.min(width, height) / 2)
        color: "#15161d"
        border.color: controlSlider.activeFocus ? "#8e8eff" : "#2a2b35"
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: controlSlider.vertical ? parent.width : parent.width * controlSlider.fillRatio
            height: controlSlider.vertical ? parent.height * controlSlider.fillRatio : parent.height
            radius: parent.radius
            color: controlSlider.accent
            opacity: controlSlider.sliderAvailable ? (app.controlEditMode ? 0.72 : 0.92) : 0.16

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
        opacity: controlSlider.sliderAvailable ? 1 : 0.42
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
        enabled: controlSlider.sliderAvailable && !app.controlEditMode
        preventStealing: true

        function valueFromMouse(mouse) {
            const pct = controlSlider.vertical ? 1 - mouse.y / Math.max(1, height) : mouse.x / Math.max(1, width);
            return Math.round(Math.max(0, Math.min(1, pct)) * controlSlider.safeToValue);
        }

        onPressed: (mouse) => {
            controlSlider.forceActiveFocus();
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
            tooltipText: controlSlider.actionTooltip
            onClicked: controlSlider.actionTriggered()
        }

        IslandButton {
            visible: controlSlider.secondaryActionIconName.length > 0
            width: 26
            height: 26
            compact: true
            iconName: controlSlider.secondaryActionIconName
            tooltipText: controlSlider.secondaryActionTooltip
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

