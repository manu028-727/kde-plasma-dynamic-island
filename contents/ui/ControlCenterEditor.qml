import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: editor

    required property var app
    required property Item hostItem
    required property Component moduleCardDelegate

    anchors.fill: parent

    Component.onCompleted: {
        if (app)
            app.activeControlPage = editor;

    }

    Component.onDestruction: {
        if (app && app.activeControlPage === editor)
            app.activeControlPage = null;

    }

    function containsPoint(item, x, y) {
        if (!item || !item.visible || !hostItem || !item.mapFromItem)
            return false;

        const p = item.mapFromItem(hostItem, x, y);
        return p.x >= 0 && p.y >= 0 && p.x <= item.width && p.y <= item.height;
    }

    function cellAtPoint(x, y) {
        if (!hostItem || !moduleGrid.mapFromItem)
            return { "col": 0, "row": 0 };

        const p = moduleGrid.mapFromItem(hostItem, x, y);
        const pitch = Math.max(1, moduleGrid.unitSize + moduleGrid.gap);
        const size = draggedSize();
        const maxOffsetCol = Math.max(0, gridUnitWidth(size) - 1);
        const maxOffsetRow = Math.max(0, gridUnitHeight(size) - 1);
        return {
            "col": Math.max(0, Math.min(moduleGrid.columns - 1, Math.floor(p.x / pitch) - Math.max(0, Math.min(maxOffsetCol, app.controlDragOffsetCol)))),
            "row": Math.max(0, Math.floor(p.y / pitch) - Math.max(0, Math.min(maxOffsetRow, app.controlDragOffsetRow)))
        };
    }

    function draggedSize() {
        if (!app || !app.controlDragSource)
            return { "w": 1, "h": 1 };

        if (app.controlDragSource.fromPalette) {
            const size = defaultModuleSize(app.controlDragSource.moduleId);
            return { "w": size.w, "h": size.h };
        }

        return {
            "w": app.controlDragSource.moduleWidthUnits,
            "h": app.controlDragSource.moduleHeightUnits
        };
    }

    function defaultModuleSize(id) {
        return app.controlModuleDefaultSize(id);
    }

    function visualLayout() {
        const layout = app.controlLayout().slice();
        const hasCellTarget = app.controlDropCol >= 0 && app.controlDropRow >= 0;
        if (app.controlResizeActive && app.controlResizeSource && app.controlResizeIndex >= 0 && app.controlResizeIndex < layout.length) {
            const resized = layout.splice(app.controlResizeIndex, 1)[0];
            const basePlaced = packLayout([resized].concat(layout));
            const basePlacement = basePlaced[resized.id] || {
                "col": app.finiteNumber(resized.col, 0),
                "row": app.finiteNumber(resized.row, 0)
            };
            resized.w = app.controlResizeWidthUnits;
            resized.h = app.controlResizeHeightUnits;
            resized.col = Math.max(0, Math.min(moduleGrid.columns - gridUnitWidth(resized), Math.round(app.finiteNumber(basePlacement.col, 0))));
            resized.row = Math.max(0, Math.round(app.finiteNumber(basePlacement.row, 0)));
            layout.unshift(resized);
            return layout;
        }

        if (!app.controlDragActive || !app.controlDragSource || app.controlDropOnPalette || !hasCellTarget)
            return layout;

        const placeholder = app.controlDragSource.fromPalette
            ? defaultModuleSize(app.controlDragSource.moduleId)
            : {
                "id": "__dropPlaceholder",
                "w": app.controlDragSource.moduleWidthUnits,
                "h": app.controlDragSource.moduleHeightUnits,
                "v": 2
            };
        placeholder.id = "__dropPlaceholder";
        placeholder.col = app.controlDropCol;
        placeholder.row = app.controlDropRow;

        if (app.controlDragSource.fromPalette) {
            const existing = layout.findIndex(item => item.id === app.controlDragSource.moduleId);
            if (existing >= 0)
                return layout;
        } else {
            const from = app.controlDragSource.moduleIndex;
            if (from >= 0 && from < layout.length)
                layout.splice(from, 1);
        }

        layout.unshift(placeholder);
        return layout;
    }

    function canPlace(occupied, col, row, w, h) {
        if (col < 0 || row < 0 || w <= 0 || h <= 0 || col + w > moduleGrid.columns)
            return false;

        for (let y = row; y < row + h; ++y) {
            for (let x = col; x < col + w; ++x) {
                if (occupied[y + ":" + x])
                    return false;

            }
        }
        return true;
    }

    function occupy(occupied, col, row, w, h) {
        for (let y = row; y < row + h; ++y) {
            for (let x = col; x < col + w; ++x)
                occupied[y + ":" + x] = true;

        }
    }

    function canDropAtCell(col, row) {
        if (!app.controlDragSource || col < 0 || row < 0)
            return false;

        const size = draggedSize();
        const w = gridUnitWidth(size);
        return col + w <= moduleGrid.columns;
    }

    function gridUnitWidth(item) {
        return Math.round(app.clampNumber(item ? item.w : 1, 1, moduleGrid.columns));
    }

    function gridUnitHeight(item) {
        return Math.round(app.clampNumber(item ? item.h : 1, 1, 6));
    }

    function packLayout(layout) {
        const occupied = {};
        const placed = {};
        let rows = 0;

        for (let i = 0; i < layout.length; ++i) {
            const item = layout[i] || {};
            const w = gridUnitWidth(item);
            const h = gridUnitHeight(item);
            let row = 0;
            let found = false;
            if (isFinite(Number(item.col)) && isFinite(Number(item.row))) {
                const col = Math.max(0, Math.min(moduleGrid.columns - w, Math.round(item.col)));
                row = Math.max(0, Math.round(item.row));
                if (canPlace(occupied, col, row, w, h)) {
                    occupy(occupied, col, row, w, h);
                    placed[item.id] = { "col": col, "row": row, "w": w, "h": h, "order": i };
                    rows = Math.max(rows, row + h);
                    found = true;
                }
            }

            row = 0;
            while (!found) {
                for (let col = 0; col <= moduleGrid.columns - w; ++col) {
                    if (!canPlace(occupied, col, row, w, h))
                        continue;

                    occupy(occupied, col, row, w, h);
                    placed[item.id] = { "col": col, "row": row, "w": w, "h": h, "order": i };
                    rows = Math.max(rows, row + h);
                    found = true;
                    break;
                }
                if (!found)
                    row++;
            }
        }

        placed.__rows = Math.max(1, rows);
        return placed;
    }

    function packedLayout() {
        app.controlLayoutRevision;
        app.controlDragActive;
        app.controlDropOnPalette;
        app.controlDropCol;
        app.controlDropRow;
        app.controlResizeActive;
        app.controlResizeIndex;
        app.controlResizeWidthUnits;
        app.controlResizeHeightUnits;
        return packLayout(visualLayout());
    }

    function placementFor(id, placedLayout) {
        const placed = placedLayout || packedLayout();
        return placed[id] || { "col": 0, "row": 0, "w": 1, "h": 1, "order": 0 };
    }

    function dropPlaceholderPlacement(placedLayout) {
        if (!app.controlEditMode || !app.controlDragActive || app.controlDropOnPalette || app.controlDropCol < 0 || app.controlDropRow < 0) {
            if (app.controlDropInvalid) {
                const size = draggedSize();
                return {
                    "visible": true,
                    "invalid": true,
                    "col": Math.max(0, moduleGrid.columns - gridUnitWidth(size)),
                    "row": 0,
                    "w": gridUnitWidth(size),
                    "h": gridUnitHeight(size)
                };
            }

            return { "visible": false, "col": 0, "row": 0, "w": 1, "h": 1 };
        }

        const placed = placedLayout || packedLayout();
        const placeholder = placed.__dropPlaceholder;
        if (!placeholder)
            return { "visible": false, "col": 0, "row": 0, "w": 1, "h": 1 };

        return {
            "visible": true,
            "invalid": false,
            "col": placeholder.col,
            "row": placeholder.row,
            "w": placeholder.w,
            "h": placeholder.h
        };
    }

    function gridX(col) {
        return Math.max(0, Math.round(app.finiteNumber(col, 0))) * Math.max(1, moduleGrid.unitSize + moduleGrid.gap);
    }

    function gridY(row) {
        return Math.max(0, Math.round(app.finiteNumber(row, 0))) * Math.max(1, moduleGrid.unitSize + moduleGrid.gap);
    }

    function gridWidth(widthUnits) {
        const units = Math.round(app.clampNumber(widthUnits, 1, moduleGrid.columns));
        return units * moduleGrid.unitSize + (units - 1) * moduleGrid.gap;
    }

    function gridHeight(heightUnits) {
        const units = Math.round(app.clampNumber(heightUnits, 1, 6));
        return units * moduleGrid.unitSize + (units - 1) * moduleGrid.gap;
    }

    function packedHeight() {
        const placed = packedLayout();
        const rows = Math.max(1, Math.round(app.finiteNumber(placed.__rows, 1)));
        return rows * moduleGrid.unitSize + Math.max(0, rows - 1) * moduleGrid.gap;
    }

    function previewControlDrop(x, y) {
        app.controlDropOnPalette = containsPoint(palette, x, y);
        if (app.controlDropOnPalette || !containsPoint(moduleFlickable, x, y)) {
            app.controlDropCol = -1;
            app.controlDropRow = -1;
            app.controlDropInvalid = false;
            return ;
        }

        const cell = cellAtPoint(x, y);
        if (canDropAtCell(cell.col, cell.row)) {
            app.controlDropCol = cell.col;
            app.controlDropRow = cell.row;
            app.controlDropInvalid = false;
            return ;
        }

        app.controlDropCol = -1;
        app.controlDropRow = -1;
        app.controlDropInvalid = true;
    }

    function finishControlDrop(source, x, y) {
        if (!source)
            return ;

        previewControlDrop(x, y);

        if (app.controlDropOnPalette) {
            if (!source.fromPalette)
                app.removeControlModule(source.moduleIndex);

            return ;
        }

        if (app.controlDropCol >= 0 && app.controlDropRow >= 0) {
            commitControlDropAtCell(source, app.controlDropCol, app.controlDropRow);

            return ;
        }

        if (source.fromPalette && containsPoint(moduleFlickable, x, y))
            app.addControlModule(source.moduleId);
    }

    function commitControlDropAtCell(source, col, row) {
        const layout = app.controlLayout();
        let item = null;

        if (source.fromPalette) {
            for (let i = 0; i < layout.length; ++i) {
                if (layout[i].id === source.moduleId)
                    return ;
            }
            item = defaultModuleSize(source.moduleId);
        } else {
            if (source.moduleIndex < 0 || source.moduleIndex >= layout.length)
                return ;

            item = layout.splice(source.moduleIndex, 1)[0];
        }

        item.col = Math.max(0, Math.min(moduleGrid.columns - gridUnitWidth(item), Math.round(col)));
        item.row = Math.max(0, Math.round(row));

        const ordered = [item].concat(layout);
        const placed = packLayout(ordered);
        const saved = [];
        for (let i = 0; i < ordered.length; ++i) {
            const module = ordered[i];
            const placement = placed[module.id];
            if (!placement)
                continue;

            saved.push({
                "id": module.id,
                "w": placement.w,
                "h": placement.h,
                "col": placement.col,
                "row": placement.row,
                "v": 2
            });
        }
        app.updateControlLayout(saved);
    }

    function commitControlResize(source, widthUnits, heightUnits) {
        const layout = app.controlLayout();
        if (!source || source.moduleIndex < 0 || source.moduleIndex >= layout.length)
            return ;

        const item = layout.splice(source.moduleIndex, 1)[0];
        const basePlaced = packLayout([item].concat(layout));
        const basePlacement = basePlaced[item.id] || {
            "col": app.finiteNumber(item.col, 0),
            "row": app.finiteNumber(item.row, 0)
        };
        const size = app.clampedControlModule(item.id, widthUnits, heightUnits);
        item.w = size.w;
        item.h = size.h;
        item.col = Math.max(0, Math.min(moduleGrid.columns - item.w, Math.round(app.finiteNumber(basePlacement.col, 0))));
        item.row = Math.max(0, Math.round(app.finiteNumber(basePlacement.row, 0)));
        item.v = 2;

        const ordered = [item].concat(layout);
        const placed = packLayout(ordered);
        const saved = [];
        for (let i = 0; i < ordered.length; ++i) {
            const module = ordered[i];
            const placement = placed[module.id];
            if (!placement)
                continue;

            saved.push({
                "id": module.id,
                "w": placement.w,
                "h": placement.h,
                "col": placement.col,
                "row": placement.row,
                "v": 2
            });
        }
        app.updateControlLayout(saved);
    }

    RowLayout {
        id: editBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 34
        spacing: 8

        PlasmaLabel {
            Layout.fillWidth: true
            text: app.controlEditMode ? app.controlLayoutDirty ? "Edit control center *" : "Edit control center" : "Control center"
            color: "#f8f8fb"
            font.pixelSize: 13
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        PlasmaLabel {
            visible: app.controlEditMode
            Layout.maximumWidth: 150
            text: app.controlLayoutDirty ? "Unsaved" : "Saved"
            color: app.controlLayoutDirty ? "#ffd60a" : "#8f9099"
            font.pixelSize: 10
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        IslandButton {
            visible: !app.controlEditMode
            iconName: "document-edit"
            compact: true
            tooltipText: "Edit layout"
            onClicked: app.beginControlEdit()
        }

        IslandButton {
            visible: app.controlEditMode
            iconName: "dialog-cancel"
            compact: true
            emphasized: app.controlLayoutDirty
            tooltipText: app.controlLayoutDirty ? "Cancel changes" : "Exit edit mode"
            onClicked: app.cancelControlEdit()
        }

        IslandButton {
            visible: app.controlEditMode
            iconName: "restore-defaults"
            compact: true
            tooltipText: "Reset draft to default"
            onClicked: app.resetControlLayout()
        }

        IslandButton {
            visible: app.controlEditMode
            iconName: "dialog-ok-apply"
            compact: true
            enabled: app.controlLayoutDirty
            emphasized: app.controlLayoutDirty
            tooltipText: app.controlLayoutDirty ? "Save layout" : "No changes"
            onClicked: app.saveControlEdit()
        }
    }

    Flickable {
        id: moduleFlickable

        anchors.left: parent.left
        anchors.right: app.controlEditMode ? palette.left : parent.right
        anchors.rightMargin: app.controlEditMode ? 10 : 0
        anchors.top: editBar.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        clip: true
        interactive: !app.controlDragActive && !app.controlResizeActive
        contentWidth: width
        contentHeight: moduleGrid.height

        Item {
            id: moduleGrid

            width: parent.width
            height: editor.packedHeight()
            property int columns: 8
            property int gap: 8
            property real unitSize: Math.max(1, Math.floor((width - gap * (columns - 1)) / columns))
            readonly property var packedLayoutState: editor.packedLayout()
            readonly property var dropPreview: editor.dropPlaceholderPlacement(packedLayoutState)

            ReservedSpacePreview {
                visible: moduleGrid.dropPreview.visible
                x: editor.gridX(moduleGrid.dropPreview.col)
                y: editor.gridY(moduleGrid.dropPreview.row)
                width: editor.gridWidth(moduleGrid.dropPreview.w)
                height: editor.gridHeight(moduleGrid.dropPreview.h)
                opacity: visible ? 0.92 : 0
                z: 0
                iconName: app.controlDragIcon
                invalid: moduleGrid.dropPreview.invalid || false
            }

            Repeater {
                model: app.controlLayout()

                Loader {
                    required property var modelData
                    required property int index

                    readonly property var packed: editor.placementFor(modelData.id, moduleGrid.packedLayoutState)

                    x: editor.gridX(packed.col)
                    y: editor.gridY(packed.row)
                    width: editor.gridWidth(packed.w)
                    height: editor.gridHeight(packed.h)
                    sourceComponent: editor.moduleCardDelegate
                    z: 2

                    function applyModuleProperties() {
                        if (!item)
                            return ;

                        item.moduleId = modelData.id;
                        item.moduleIndex = index;
                        item.moduleWidthUnits = editor.gridUnitWidth(modelData);
                        item.moduleHeightUnits = editor.gridUnitHeight(modelData);
                        item.gridUnitSize = moduleGrid.unitSize;
                        item.gridGap = moduleGrid.gap;
                    }

                    onLoaded: applyModuleProperties()
                    onModelDataChanged: applyModuleProperties()
                    onIndexChanged: applyModuleProperties()
                    onWidthChanged: applyModuleProperties()
                    onHeightChanged: applyModuleProperties()
                }
            }
        }
    }

    Rectangle {
        id: palette

        visible: app.controlEditMode
        anchors.right: parent.right
        anchors.top: editBar.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        width: app.controlEditMode ? 150 : 0
        radius: 20
        color: app.controlDropOnPalette ? "#171824" : "#0d0e14"
        border.color: app.controlDropOnPalette ? "#8e8eff" : "#282933"
        border.width: app.controlDropOnPalette ? 2 : 1
        clip: true

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            PlasmaLabel {
                Layout.fillWidth: true
                text: "Modules"
                color: "#f8f8fb"
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: app.controlDropOnPalette ? "Release to hide this tile." : "Drag into the grid. Drop here to hide."
                color: app.controlDropOnPalette ? "#d8d8ff" : "#8f9099"
                font.pixelSize: 9
                wrapMode: Text.WordWrap
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: !app.controlDragActive && !app.controlResizeActive
                contentWidth: width
                contentHeight: paletteColumn.implicitHeight

                ColumnLayout {
                    id: paletteColumn

                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: app.controlModules

                        PaletteModule {
                            Layout.fillWidth: true
                            moduleId: modelData.id
                            title: modelData.name
                            app: editor.app
                        }
                    }
                }
            }
        }
    }

    component ReservedSpacePreview: Rectangle {
        id: control

        property string iconName: ""
        property bool invalid: false

        radius: Math.min(18, Math.min(width, height) / 2)
        color: invalid ? "#211516" : "#171824"
        border.color: invalid ? "#ff453a" : "#8e8eff"
        border.width: 2

        Behavior on x {
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Behavior on y {
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Behavior on width {
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: 105; easing.type: Easing.OutCubic }
        }

        Behavior on border.color {
            ColorAnimation { duration: 110 }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: Math.max(1, parent.radius - 5)
            color: "transparent"
            border.color: control.invalid ? "#693234" : "#3e4052"
            border.width: 1
            opacity: 0.85
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.max(16, Math.min(30, parent.width - 18, parent.height - 18))
            height: width
            source: control.iconName
            color: control.invalid ? "#ffb4ae" : "#d8d8ff"
            opacity: 0.62
        }
    }

    component PaletteModule: Rectangle {
        id: paletteModule

        property var app
        property string moduleId: ""
        property string title: ""
        property bool fromPalette: true

        implicitHeight: 42
        radius: 13
        color: paletteDrag.pressed ? "#2b2c35" : app.controlDropOnPalette ? "#25263a" : "#171820"
        border.color: app.controlDropOnPalette ? "#8e8eff" : "#2a2b35"
        border.width: 1
        opacity: app.controlDragActive && app.controlDragSource === paletteModule ? 0.48 : 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 7

            Kirigami.Icon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: app.moduleIcon(paletteModule.moduleId)
                color: "#f1f1f6"
            }

            PlasmaLabel {
                Layout.fillWidth: true
                text: paletteModule.title
                color: "#f1f1f6"
                font.pixelSize: 10
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: paletteDrag

            property real pressX: 0
            property real pressY: 0
            property bool movedEnough: false

            anchors.fill: parent
            hoverEnabled: true
            drag.threshold: 8
            preventStealing: true
            onClicked: {
                if (!movedEnough)
                    app.addControlModule(paletteModule.moduleId);

            }
            onPressed: (mouse) => {
                mouse.accepted = true;
                pressX = mouse.x;
                pressY = mouse.y;
                movedEnough = false;
                app.controlDragOffsetCol = 0;
                app.controlDragOffsetRow = 0;
                app.beginControlDrag(paletteModule, paletteDrag, mouse, 48);
            }
            onPositionChanged: (mouse) => {
                if (Math.abs(mouse.x - pressX) > 8 || Math.abs(mouse.y - pressY) > 8)
                    movedEnough = true;

                mouse.accepted = true;
                app.updateControlDrag(paletteDrag, mouse);
            }
            onReleased: (mouse) => {
                mouse.accepted = true;
                app.endControlDrag(paletteDrag, mouse, movedEnough);
            }
            onCanceled: app.endControlDrag(null, null, false)
        }
    }
}
