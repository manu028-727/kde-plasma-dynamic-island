import QtQuick

Item {
    id: control

    property string iconName: ""
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
            if (control.iconName.indexOf("close") !== -1 || control.iconName.indexOf("stop") !== -1) {
                ctx.beginPath();
                ctx.moveTo(w * 0.25, h * 0.25);
                ctx.lineTo(w * 0.75, h * 0.75);
                ctx.moveTo(w * 0.75, h * 0.25);
                ctx.lineTo(w * 0.25, h * 0.75);
                ctx.stroke();
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

}
