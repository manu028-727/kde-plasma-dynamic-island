import QtQuick
import QtQuick.Controls as QQC2

Item {
    id: control

    property string iconName: ""
    property string tooltipText: ""
    property bool emphasized: false
    property bool compact: false

    signal clicked()

    implicitWidth: compact ? (emphasized ? 26 : 24) : (emphasized ? 38 : 32)
    implicitHeight: implicitWidth
    opacity: enabled ? 1 : 0.42
    onIconNameChanged: glyph.requestPaint()
    onEnabledChanged: glyph.requestPaint()
    Component.onCompleted: glyph.requestPaint()
    onWidthChanged: glyph.requestPaint()
    onHeightChanged: glyph.requestPaint()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: mouse.pressed ? "#484852" : mouse.containsMouse || control.emphasized ? "#2d2d35" : "#17171d"
        border.color: "#34343c"
        border.width: 1
    }

    Canvas {
        id: glyph

        function triangle(ctx, x1, y1, x2, y2, x3, y3) {
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
            ctx.lineTo(x3, y3);
            ctx.closePath();
            ctx.fill();
        }

        function roundFill(ctx, x, y, w, h, r) {
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.lineTo(x + w - r, y);
            ctx.quadraticCurveTo(x + w, y, x + w, y + r);
            ctx.lineTo(x + w, y + h - r);
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
            ctx.lineTo(x + r, y + h);
            ctx.quadraticCurveTo(x, y + h, x, y + h - r);
            ctx.lineTo(x, y + r);
            ctx.quadraticCurveTo(x, y, x + r, y);
            ctx.closePath();
            ctx.fill();
        }

        anchors.centerIn: parent
        width: control.compact ? (control.emphasized ? 15 : 14) : (control.emphasized ? 20 : 17)
        height: width
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            ctx.reset();
            ctx.fillStyle = "#ffffff";
            ctx.strokeStyle = "#ffffff";
            ctx.lineWidth = Math.max(1.6, w * 0.12);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            if (control.iconName.indexOf("pause") !== -1) {
                roundFill(ctx, w * 0.24, h * 0.18, w * 0.18, h * 0.64, w * 0.06);
                roundFill(ctx, w * 0.58, h * 0.18, w * 0.18, h * 0.64, w * 0.06);
                return ;
            }
            if (control.iconName.indexOf("start") !== -1 || control.iconName.indexOf("play") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.32, h * 0.2);
                ctx.lineTo(w * 0.32, h * 0.8);
                ctx.lineTo(w * 0.78, h * 0.5);
                ctx.closePath();
                ctx.fill();
                return ;
            }
            if (control.iconName.indexOf("backward") !== -1 || control.iconName.indexOf("previous") !== -1) {
                ctx.fillRect(w * 0.18, h * 0.22, w * 0.1, h * 0.56);
                triangle(ctx, w * 0.78, h * 0.2, w * 0.34, h * 0.5, w * 0.78, h * 0.8);
                triangle(ctx, w * 0.58, h * 0.2, w * 0.18, h * 0.5, w * 0.58, h * 0.8);
                return ;
            }
            if (control.iconName.indexOf("forward") !== -1 || control.iconName.indexOf("next") !== -1) {
                ctx.fillRect(w * 0.72, h * 0.22, w * 0.1, h * 0.56);
                triangle(ctx, w * 0.22, h * 0.2, w * 0.66, h * 0.5, w * 0.22, h * 0.8);
                triangle(ctx, w * 0.42, h * 0.2, w * 0.82, h * 0.5, w * 0.42, h * 0.8);
                return ;
            }
            if (control.iconName.indexOf("close") !== -1 || control.iconName.indexOf("cancel") !== -1 || control.iconName.indexOf("stop") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.25, h * 0.25);
                ctx.lineTo(w * 0.75, h * 0.75);
                ctx.moveTo(w * 0.75, h * 0.25);
                ctx.lineTo(w * 0.25, h * 0.75);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("restore") !== -1 || control.iconName.indexOf("defaults") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.2, h * 0.42);
                ctx.lineTo(w * 0.5, h * 0.18);
                ctx.lineTo(w * 0.8, h * 0.42);
                ctx.stroke();
                roundFill(ctx, w * 0.28, h * 0.44, w * 0.44, h * 0.32, w * 0.05);
                ctx.fillStyle = "#17171d";
                roundFill(ctx, w * 0.43, h * 0.56, w * 0.14, h * 0.2, w * 0.03);
                ctx.fillStyle = "#ffffff";
                ctx.beginPath();
                ctx.arc(w * 0.68, h * 0.66, w * 0.18, Math.PI * 0.25, Math.PI * 1.58);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(w * 0.5, h * 0.67);
                ctx.lineTo(w * 0.64, h * 0.8);
                ctx.lineTo(w * 0.66, h * 0.6);
                ctx.fill();
                return ;
            }
            if (control.iconName.indexOf("apply") !== -1 || control.iconName.indexOf("ok") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.18, h * 0.52);
                ctx.lineTo(w * 0.42, h * 0.74);
                ctx.lineTo(w * 0.82, h * 0.28);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("edit") !== -1 || control.iconName.indexOf("document") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.24, h * 0.72);
                ctx.lineTo(w * 0.34, h * 0.48);
                ctx.lineTo(w * 0.68, h * 0.14);
                ctx.lineTo(w * 0.86, h * 0.32);
                ctx.lineTo(w * 0.52, h * 0.66);
                ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(w * 0.28, h * 0.74);
                ctx.lineTo(w * 0.18, h * 0.82);
                ctx.lineTo(w * 0.34, h * 0.78);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("undo") !== -1 || control.iconName.indexOf("reset") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.34, h * 0.26);
                ctx.lineTo(w * 0.16, h * 0.44);
                ctx.lineTo(w * 0.34, h * 0.62);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(w * 0.54, h * 0.54, w * 0.28, Math.PI * 0.88, Math.PI * 1.95);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("clear") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.22, h * 0.32);
                ctx.lineTo(w * 0.78, h * 0.32);
                ctx.moveTo(w * 0.32, h * 0.32);
                ctx.lineTo(w * 0.36, h * 0.78);
                ctx.lineTo(w * 0.64, h * 0.78);
                ctx.lineTo(w * 0.68, h * 0.32);
                ctx.moveTo(w * 0.4, h * 0.22);
                ctx.lineTo(w * 0.6, h * 0.22);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("refresh") !== -1 || control.iconName.indexOf("reload") !== -1) {
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.5, w * 0.3, Math.PI * 0.18, Math.PI * 1.65);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(w * 0.26, h * 0.52);
                ctx.lineTo(w * 0.16, h * 0.68);
                ctx.lineTo(w * 0.34, h * 0.7);
                ctx.fill();
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.5, w * 0.3, Math.PI * 1.18, Math.PI * 2.65);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(w * 0.74, h * 0.48);
                ctx.lineTo(w * 0.84, h * 0.32);
                ctx.lineTo(w * 0.66, h * 0.3);
                ctx.fill();
                return ;
            }
            if (control.iconName.indexOf("information") !== -1 || control.iconName.indexOf("ping") !== -1) {
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.5, w * 0.32, 0, Math.PI * 2);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.34, w * 0.04, 0, Math.PI * 2);
                ctx.fill();
                ctx.beginPath();
                ctx.moveTo(w * 0.5, h * 0.48);
                ctx.lineTo(w * 0.5, h * 0.68);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("notification") !== -1 || control.iconName.indexOf("bell") !== -1) {
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.46, w * 0.22, Math.PI, 0);
                ctx.lineTo(w * 0.72, h * 0.62);
                ctx.lineTo(w * 0.28, h * 0.62);
                ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.72, w * 0.05, 0, Math.PI * 2);
                ctx.fill();
                return ;
            }
            if (control.iconName.indexOf("folder") !== -1 || control.iconName.indexOf("mount") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.18, h * 0.34);
                ctx.lineTo(w * 0.4, h * 0.34);
                ctx.lineTo(w * 0.46, h * 0.44);
                ctx.lineTo(w * 0.82, h * 0.44);
                ctx.lineTo(w * 0.76, h * 0.76);
                ctx.lineTo(w * 0.22, h * 0.76);
                ctx.closePath();
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("shutdown") !== -1 || control.iconName.indexOf("power") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.5, h * 0.16);
                ctx.lineTo(w * 0.5, h * 0.46);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.55, w * 0.3, -Math.PI * 0.72, Math.PI * 1.72);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("lock") !== -1) {
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.42, w * 0.22, Math.PI, 0);
                ctx.stroke();
                roundFill(ctx, w * 0.22, h * 0.43, w * 0.56, h * 0.38, w * 0.09);
                return ;
            }
            if (control.iconName.indexOf("suspend") !== -1 || control.iconName.indexOf("sleep") !== -1) {
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.5, w * 0.32, Math.PI * 0.08, Math.PI * 1.72);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(w * 0.64, h * 0.4, w * 0.26, Math.PI * 0.5, Math.PI * 1.72);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("settings") !== -1) {
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.5, w * 0.16, 0, Math.PI * 2);
                ctx.stroke();
                for (let i = 0; i < 8; ++i) {
                    const a = i * Math.PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(w / 2 + Math.cos(a) * w * 0.27, h / 2 + Math.sin(a) * h * 0.27);
                    ctx.lineTo(w / 2 + Math.cos(a) * w * 0.42, h / 2 + Math.sin(a) * h * 0.42);
                    ctx.stroke();
                }
                return ;
            }
            if (control.iconName.indexOf("theme") !== -1) {
                ctx.beginPath();
                ctx.arc(w * 0.5, h * 0.5, w * 0.34, Math.PI * 0.15, Math.PI * 1.85);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(w * 0.38, h * 0.39, w * 0.04, 0, Math.PI * 2);
                ctx.arc(w * 0.54, h * 0.33, w * 0.04, 0, Math.PI * 2);
                ctx.arc(w * 0.64, h * 0.48, w * 0.04, 0, Math.PI * 2);
                ctx.fill();
                return ;
            }
            if (control.iconName.indexOf("brightness") !== -1) {
                ctx.beginPath();
                ctx.arc(w / 2, h / 2, w * 0.18, 0, Math.PI * 2);
                ctx.fill();
                for (let i = 0; i < 8; ++i) {
                    const a = i * Math.PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(w / 2 + Math.cos(a) * w * 0.31, h / 2 + Math.sin(a) * h * 0.31);
                    ctx.lineTo(w / 2 + Math.cos(a) * w * 0.44, h / 2 + Math.sin(a) * h * 0.44);
                    ctx.stroke();
                }
                return ;
            }
            if (control.iconName.indexOf("display") !== -1 || control.iconName.indexOf("video") !== -1) {
                ctx.strokeRect(w * 0.18, h * 0.22, w * 0.64, h * 0.42);
                ctx.beginPath();
                ctx.moveTo(w * 0.5, h * 0.64);
                ctx.lineTo(w * 0.5, h * 0.78);
                ctx.moveTo(w * 0.34, h * 0.78);
                ctx.lineTo(w * 0.66, h * 0.78);
                ctx.stroke();
                return ;
            }
            if (control.iconName.indexOf("keyboard") !== -1) {
                ctx.strokeRect(w * 0.16, h * 0.28, w * 0.68, h * 0.44);
                for (let row = 0; row < 2; ++row) {
                    for (let col = 0; col < 4; ++col) {
                        ctx.beginPath();
                        ctx.arc(w * (0.29 + col * 0.14), h * (0.42 + row * 0.14), w * 0.018, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
                return ;
            }
            if (control.iconName.indexOf("volume") !== -1 || control.iconName.indexOf("audio") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.16, h * 0.42);
                ctx.lineTo(w * 0.34, h * 0.42);
                ctx.lineTo(w * 0.54, h * 0.24);
                ctx.lineTo(w * 0.54, h * 0.76);
                ctx.lineTo(w * 0.34, h * 0.58);
                ctx.lineTo(w * 0.16, h * 0.58);
                ctx.closePath();
                ctx.fill();
                ctx.beginPath();
                ctx.arc(w * 0.56, h * 0.5, w * 0.22, -0.7, 0.7);
                ctx.stroke();
                return ;
            }
            ctx.beginPath();
            ctx.arc(w / 2, h / 2, w * 0.24, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: control.enabled
        onClicked: control.clicked()
    }

    QQC2.ToolTip.visible: mouse.containsMouse && control.tooltipText.length > 0
    QQC2.ToolTip.text: control.tooltipText
    QQC2.ToolTip.delay: 350

}
