import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

MouseArea {
    id: simpleTile

    required property var app
    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property color accent: "#5ac8fa"
    property real progress: -1
    property string detailText: ""
    property string footerText: ""
    property string actionIconName: ""
    property bool available: true
    readonly property bool iconOnly: width < 92 || height < 54
    readonly property bool detailed: !iconOnly && width >= 142 && height >= 88
    readonly property bool tiny: width < 72 || height < 72
    readonly property bool hasAction: actionIconName.length > 0
    readonly property bool showProgressFill: progress >= 0 && !iconOnly && detailed
    readonly property real contentMargin: iconOnly ? 6 : 8
    readonly property real safeProgress: app.clampNumber(progress, 0, 100)

    signal triggered()
    signal actionTriggered()

    anchors.fill: parent
    hoverEnabled: true
    enabled: !app.controlEditMode
    onClicked: simpleTile.triggered()

    Rectangle {
        anchors.fill: parent
        radius: Math.min(18, Math.min(width, height) / 2)
        color: !simpleTile.available ? "#12131a" : simpleTile.pressed ? "#242630" : simpleTile.containsMouse ? "#1a1b24" : simpleTile.active ? "#171821" : "#15161d"
        border.color: simpleTile.active && !simpleTile.iconOnly ? Qt.rgba(simpleTile.accent.r, simpleTile.accent.g, simpleTile.accent.b, 0.42) : "#2a2b35"
        border.width: 1
    }

    Rectangle {
        visible: simpleTile.showProgressFill
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * simpleTile.safeProgress / 100
        radius: Math.min(18, Math.min(parent.width, parent.height) / 2)
        color: simpleTile.accent
        opacity: 0.18
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: simpleTile.contentMargin
        anchors.rightMargin: simpleTile.detailed && simpleTile.hasAction ? 40 : simpleTile.contentMargin
        spacing: simpleTile.iconOnly ? 0 : 8

        Kirigami.Icon {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.max(18, Math.min(simpleTile.detailed ? 30 : 34, simpleTile.width - simpleTile.contentMargin * 2, simpleTile.height - simpleTile.contentMargin * 2))
            Layout.preferredHeight: Layout.preferredWidth
            source: simpleTile.iconName
            color: simpleTile.active ? simpleTile.accent : "#9c9da8"
            opacity: simpleTile.available ? 1 : 0.45
        }

        ColumnLayout {
            visible: !simpleTile.iconOnly
            Layout.fillWidth: true
            spacing: simpleTile.detailed ? 4 : 1

            QQC2.Label {
                Layout.fillWidth: true
                text: simpleTile.title
                color: "#f8f8fb"
                font.pixelSize: simpleTile.tiny ? 10 : 11
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: simpleTile.subtitle
                color: "#8f9099"
                font.pixelSize: 9
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            QQC2.Label {
                visible: simpleTile.detailed && simpleTile.detailText.length > 0
                Layout.fillWidth: true
                text: simpleTile.detailText
                color: "#c9c9d2"
                font.pixelSize: 10
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Rectangle {
                visible: simpleTile.showProgressFill
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: "#2a2b35"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * simpleTile.safeProgress / 100
                    radius: parent.radius
                    color: simpleTile.accent

                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            QQC2.Label {
                visible: simpleTile.detailed && simpleTile.footerText.length > 0
                Layout.fillWidth: true
                text: simpleTile.footerText
                color: "#777884"
                font.pixelSize: 9
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    IslandButton {
        visible: simpleTile.detailed && simpleTile.hasAction
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        width: 26
        height: 26
        compact: true
        iconName: simpleTile.actionIconName
        onClicked: simpleTile.actionTriggered()
    }

    QQC2.ToolTip.visible: simpleTile.containsMouse && (simpleTile.detailText.length > 0 || simpleTile.footerText.length > 0)
    QQC2.ToolTip.text: simpleTile.title + (simpleTile.subtitle.length > 0 ? " - " + simpleTile.subtitle : "") + (simpleTile.detailText.length > 0 ? "\n" + simpleTile.detailText : "")
    QQC2.ToolTip.delay: 350
}
