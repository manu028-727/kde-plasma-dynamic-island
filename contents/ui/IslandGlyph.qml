import QtQuick

Item {
    id: glyph

    property string mode: "idle"
    property real progress: 0
    property bool playing: false

    onModeChanged: canvas.requestPaint()
    onProgressChanged: canvas.requestPaint()
    onPlayingChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        function roundedRect(ctx, x, y, w, h, r) {
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
        }

        anchors.fill: parent
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width;
            const h = height;
            const cx = w / 2;
            const cy = h / 2;
            const r = Math.min(w, h) / 2 - 2;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            if (glyph.mode === "job") {
                ctx.strokeStyle = "rgba(255,255,255,.16)";
                ctx.lineWidth = 2.5;
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI * 1.5);
                ctx.stroke();
                ctx.strokeStyle = "#42d77d";
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.02, Math.min(1, glyph.progress)));
                ctx.stroke();
                ctx.fillStyle = "#42d77d";
                ctx.fillRect(cx - 2, cy - 7, 4, 10);
                ctx.beginPath();
                ctx.moveTo(cx - 6, cy);
                ctx.lineTo(cx, cy + 6);
                ctx.lineTo(cx + 6, cy);
                ctx.fill();
                return ;
            }
            if (glyph.mode === "media") {
                ctx.fillStyle = "#5ac8fa";
                const bars = [0.42, 0.78, 0.58];
                for (let i = 0; i < 3; ++i) {
                    const bw = w / 7;
                    const bh = h * bars[i] * (glyph.playing ? 1 : 0.62);
                    const x = w * 0.25 + i * bw * 1.55;
                    roundedRect(ctx, x, cy - bh / 2, bw, bh, bw / 2);
                    ctx.fill();
                }
                return ;
            }
            if (glyph.mode === "notice") {
                ctx.fillStyle = "#ff9f0a";
                ctx.beginPath();
                ctx.arc(cx, cy, r * 0.76, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = "#050507";
                ctx.font = "bold " + Math.floor(h * 0.64) + "px sans-serif";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText("!", cx, cy + 0.5);
                return ;
            }
            ctx.fillStyle = "#303039";
            ctx.beginPath();
            ctx.arc(cx, cy, r * 0.52, 0, Math.PI * 2);
            ctx.fill();
        }
    }

}
