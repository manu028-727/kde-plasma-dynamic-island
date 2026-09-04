import QtQuick

QtObject {
    property string key: ""
    property bool active: false
    property int priority: 0
    property string title: ""
    property string subtitle: ""
    property var artwork: null
    property bool progressVisible: false
    property real progressFrom: 0
    property real progressTo: 1
    property real progressValue: 0
    property color progressAccent: "#5ac8fa"
    property bool mediaControlsVisible: false
    property int autoCloseMs: 3000
    property Component visualComponent
    property Component compactComponent
    property Component expandedComponent
}
