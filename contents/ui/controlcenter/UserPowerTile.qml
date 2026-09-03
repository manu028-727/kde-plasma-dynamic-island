import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import ".."

Item {
    id: userPowerContent

    required property var app
    readonly property bool narrow: width < 82
    readonly property bool compact: width < 150 || height < 74
    readonly property bool shortTile: height < 62
    readonly property bool micro: narrow || width < 108
    readonly property real pad: compact ? 7 : 10
    readonly property real avatarSize: Math.max(18, Math.min(compact ? 34 : 38, height - pad * 2, narrow ? width - pad * 2 : width * 0.36))
    readonly property real buttonSize: Math.max(22, Math.min(compact ? 30 : 34, width - pad * 2, height - pad * 2))

    anchors.fill: parent

    Rectangle {
        id: profileAvatarFrame
        width: userPowerContent.avatarSize
        height: width
        x: userPowerContent.narrow ? Math.round((parent.width - width) / 2) : userPowerContent.pad
        y: userPowerContent.narrow && !userPowerContent.shortTile ? userPowerContent.pad : Math.round((parent.height - height) / 2)
        radius: width / 2
        color: "#24252e"
        clip: true

        Image {
            id: profileAvatarImage
            anchors.fill: parent
            source: app.profileFaceUrl()
            fillMode: Image.PreserveAspectCrop
            visible: app.profileFaceUrl().length > 0 && status === Image.Ready
            layer.enabled: visible
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSpreadAtMax: 1
                maskSpreadAtMin: 1
                maskThresholdMin: 0.5
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        width: profileAvatarImage.width
                        height: profileAvatarImage.height
                        radius: Math.min(width, height) / 2
                        color: "#ffffff"
                    }
                }
            }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 22
            height: 22
            source: "user-identity"
            color: "#f8f8fb"
            visible: !profileAvatarImage.visible
        }
    }

    Column {
        id: profileTextColumn
        visible: !userPowerContent.micro || userPowerContent.shortTile && userPowerContent.width >= 92
        x: userPowerContent.shortTile ? profileAvatarFrame.x + profileAvatarFrame.width + 8 : userPowerContent.compact ? userPowerContent.pad : profileAvatarFrame.x + profileAvatarFrame.width + 10
        y: userPowerContent.shortTile ? Math.round((parent.height - height) / 2) : userPowerContent.compact ? profileAvatarFrame.y + profileAvatarFrame.height + 6 : Math.round((parent.height - height) / 2)
        width: userPowerContent.shortTile ? Math.max(1, (powerButton.visible ? powerButton.x - x - 8 : parent.width - x - userPowerContent.pad)) : userPowerContent.compact ? Math.max(1, parent.width - userPowerContent.pad * 2) : Math.max(1, powerButton.x - x - 10)
        spacing: userPowerContent.shortTile ? -1 : 1

        QQC2.Label {
            width: parent.width
            text: app.systemUsername || "User"
            color: "#f8f8fb"
            font.pixelSize: userPowerContent.shortTile ? 10 : userPowerContent.compact ? 11 : 13
            font.weight: Font.Bold
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        QQC2.Label {
            visible: !userPowerContent.compact || userPowerContent.height >= 34
            width: parent.width
            text: app.systemHostname || "KDE Plasma"
            color: "#8f9099"
            font.pixelSize: userPowerContent.shortTile ? 8 : userPowerContent.compact ? 9 : 10
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    IslandButton {
        id: powerButton
        x: userPowerContent.narrow ? Math.round((parent.width - width) / 2) : parent.width - width - userPowerContent.pad
        y: userPowerContent.narrow ? parent.height - height - userPowerContent.pad : userPowerContent.compact ? userPowerContent.pad : Math.round((parent.height - height) / 2)
        width: userPowerContent.buttonSize
        height: width
        visible: !userPowerContent.shortTile && (!userPowerContent.narrow || parent.height >= profileAvatarFrame.height + height + userPowerContent.pad * 3)
        iconName: "system-shutdown"
        compact: true
        onClicked: powerMenu.open()

        QQC2.Menu {
            id: powerMenu
            QQC2.MenuItem { text: "Lock"; icon.name: "system-lock-screen"; onTriggered: app.runPowerAction("lock") }
            QQC2.MenuItem { text: "Logout"; icon.name: "system-log-out"; onTriggered: app.runPowerAction("logout") }
            QQC2.MenuItem { text: "Sleep"; icon.name: "system-suspend"; onTriggered: app.runPowerAction("sleep") }
            QQC2.MenuItem { text: "Hibernate"; icon.name: "system-suspend-hibernate"; onTriggered: app.runPowerAction("hibernate") }
            QQC2.MenuSeparator {}
            QQC2.MenuItem { text: "Reboot"; icon.name: "system-reboot"; onTriggered: app.runPowerAction("reboot") }
            QQC2.MenuItem { text: "Shutdown"; icon.name: "system-shutdown"; onTriggered: app.runPowerAction("shutdown") }
        }
    }

    Row {
        visible: !userPowerContent.compact && userPowerContent.width >= 210 && userPowerContent.height >= 116
        x: profileTextColumn.x
        y: parent.height - height - userPowerContent.pad
        spacing: 7

        IslandButton { width: 28; height: 28; iconName: "system-lock-screen"; compact: true; onClicked: app.runPowerAction("lock") }
        IslandButton { width: 28; height: 28; iconName: "system-suspend"; compact: true; onClicked: app.runPowerAction("sleep") }
        IslandButton { width: 28; height: 28; iconName: "preferences-desktop-theme-global"; compact: true; onClicked: app.launchAppearanceSettings() }
        IslandButton { width: 28; height: 28; iconName: "systemsettings"; compact: true; onClicked: app.launchSystemSettings() }
    }
}

