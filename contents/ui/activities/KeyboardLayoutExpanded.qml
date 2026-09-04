import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".."

Item {
    id: keyboardPage

    property var app: null

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 58
            Layout.preferredHeight: 58
            Layout.alignment: Qt.AlignVCenter
            radius: 16
            color: "#14141c"
            border.color: "#353546"
            border.width: 1

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 32
                height: 32
                source: "input-keyboard"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            PlasmaLabel {
                Layout.fillWidth: true
                text: i18n("Keyboard layout")
                color: "#9999a6"
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: keyboardPage.app ? keyboardPage.app.keyboardLayoutLongName : ""
                color: "#ffffff"
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: keyboardPage.app ? keyboardPage.app.keyboardLayoutDisplayName : ""
                visible: text.length > 0 && text !== (keyboardPage.app ? keyboardPage.app.keyboardLayoutLongName : "")
                color: "#aaaab5"
                font.pixelSize: 10
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Rectangle {
            Layout.preferredWidth: Math.max(40, layoutCode.implicitWidth + 18)
            Layout.preferredHeight: 32
            radius: 10
            color: "#242433"
            border.color: "#48485e"
            border.width: 1

            PlasmaLabel {
                id: layoutCode

                anchors.centerIn: parent
                text: keyboardPage.app ? keyboardPage.app.keyboardLayoutShortName.toUpperCase() : ""
                color: "#dadae8"
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }
    }
}
