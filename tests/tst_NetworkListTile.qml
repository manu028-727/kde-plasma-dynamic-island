import QtQuick
import QtTest
import "../contents/ui/controlcenter" as Tiles
import "../contents/ui/controlcenter/NetworkState.js" as NetworkState

Item {
    id: testRoot
    width: 500
    height: 400

    QtObject {
        id: testApp
        property bool controlEditMode: false
        property bool networkingEnabled: true
        property int settingsOpened: 0
        property int refreshes: 0
        readonly property var networkState: NetworkState.summarize(
            NetworkState.parseDevices("wifi:wlan0:connected:<b>A very long network name</b>"),
            NetworkState.parseAddresses("GENERAL.DEVICE:wlan0\nIP4.ADDRESS[1]:192.0.2.1/24"),
            NetworkState.parseWifi("*:Example:100:wlan0"), networkingEnabled, true)
        function launchNetworkSettings() { settingsOpened++; }
        function refreshWifiNetworks() { refreshes++; }
    }

    Component {
        id: tileHost
        Item {
            width: 250
            height: 140
            Tiles.NetworkListTile {
                objectName: "networkTile"
                app: testApp
            }
        }
    }

    TestCase {
        name: "NetworkListTile"
        when: windowShown

        function initTestCase() {
            failOnWarning(/.*/);
        }

        function init() {
            testApp.controlEditMode = false;
            testApp.networkingEnabled = true;
            testApp.settingsOpened = 0;
            testApp.refreshes = 0;
        }

        function findButton(item, icon) {
            if (item.iconName === icon)
                return item;
            for (let i = 0; i < item.children.length; ++i) {
                const found = findButton(item.children[i], icon);
                if (found)
                    return found;
            }
            return null;
        }

        function verifyBounds(item, tile) {
            if (!item.visible)
                return;
            const p = item.mapToItem(tile, 0, 0);
            verify(p.x >= -1 && p.y >= -1 && p.x + item.width <= tile.width + 1 && p.y + item.height <= tile.height + 1,
                   String(item) + " exceeds " + tile.width + "x" + tile.height + ": " + p.x + "," + p.y + " " + item.width + "x" + item.height);
            if (item.text === "<b>A very long network name</b>")
                compare(item.textFormat, Text.PlainText);
            // Check layout children, leaving each control's internal styling to Qt.
            if (item.spacing !== undefined) {
                for (let i = 0; i < item.children.length; ++i)
                    verifyBounds(item.children[i], tile);
            }
        }

        function test_sizes_data() {
            return [
                {tag: "icon", w: 48, h: 48},
                {tag: "minimum text", w: 96, h: 58},
                {tag: "compact", w: 149, h: 85},
                {tag: "actions threshold", w: 150, h: 86},
                {tag: "signal threshold", w: 156, h: 86},
                {tag: "details threshold", w: 190, h: 112},
                {tag: "settings threshold", w: 230, h: 112},
                {tag: "large", w: 420, h: 240}
            ];
        }

        function test_sizes(data) {
            const host = createTemporaryObject(tileHost, testRoot, {width: data.w, height: data.h});
            verify(host);
            const tile = findChild(host, "networkTile");
            wait(30);
            compare(tile.width, data.w);
            compare(tile.height, data.h);
            for (let i = 0; i < tile.children.length; ++i)
                verifyBounds(tile.children[i], tile);
        }

        function test_connectionChange() {
            const host = createTemporaryObject(tileHost, testRoot);
            const tile = findChild(host, "networkTile");
            compare(tile.networkStatus.connected, true);
            testApp.networkingEnabled = false;
            compare(tile.networkStatus.connected, false);
            compare(tile.networkStatus.summary, "Offline");
            compare(tile.networkStatus.address, "");
            compare(tile.networkStatus.signal, -1);
        }

        function test_clicksAndEditMode() {
            const host = createTemporaryObject(tileHost, testRoot);
            const tile = findChild(host, "networkTile");
            wait(30);
            mouseClick(tile, 30, tile.height - 20);
            compare(testApp.settingsOpened, 1);
            const refresh = findButton(tile, "view-refresh");
            const settings = findButton(tile, "settings");
            verify(refresh && settings);
            mouseClick(refresh, refresh.width / 2, refresh.height / 2);
            compare(testApp.refreshes, 1);
            compare(testApp.settingsOpened, 1);
            mouseClick(settings, settings.width / 2, settings.height / 2);
            compare(testApp.settingsOpened, 2);
            testApp.controlEditMode = true;
            mouseClick(tile, 30, tile.height - 20);
            mouseClick(refresh, refresh.width / 2, refresh.height / 2);
            compare(testApp.settingsOpened, 2);
            compare(testApp.refreshes, 1);
        }
    }
}
