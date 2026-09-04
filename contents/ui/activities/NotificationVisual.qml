import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: visual

    property var source: null
    property var fallbackSource: "notifications"
    property color fallbackColor: "transparent"
    property real cornerRadius: Math.min(width, height) / 2

    readonly property bool hasSource: source !== undefined && source !== null && (typeof source !== "string" || source.length > 0)
    readonly property var effectiveSource: hasSource ? source : fallbackSource

    Rectangle {
        anchors.fill: parent
        radius: visual.cornerRadius
        color: "#101015"
        border.color: "#262631"
        border.width: 1
    }

    Kirigami.Icon {
        anchors.fill: parent
        anchors.margins: visual.hasSource ? 0 : Math.max(3, Math.min(width, height) * 0.18)
        source: visual.effectiveSource
        fallback: typeof visual.fallbackSource === "string" && visual.fallbackSource.length > 0 ? visual.fallbackSource : "notifications"
        color: visual.hasSource ? "transparent" : visual.fallbackColor
        isMask: !visual.hasSource && visual.fallbackColor.a > 0
        roundToIconSize: false
    }
}
