const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

// Run the same Qt JavaScript helper without requiring a Plasma session.
const source = fs.readFileSync(path.join(__dirname, '../contents/ui/controlcenter/NetworkState.js'), 'utf8');
const network = vm.createContext({});
vm.runInContext(source.replace(/^\.pragma library\s*/, ''), network);
const state = (devices = '', addresses = '', wifi = '', enabled = true, wireless = true) => network.summarize(
    network.parseDevices(devices), network.parseAddresses(addresses), network.parseWifi(wifi), enabled, wireless);

const wifiDevice = 'wifi:wlan0:connected:Home';
const wiredDevice = 'ethernet:eth0:connected:Office';

test('enabled networking and nearby access points do not imply a connection', () => {
    const result = state('', '', ':Nearby:99:wlan0');
    assert.equal(result.connected, false);
    assert.equal(result.summary, 'Disconnected');
    assert.equal(result.signal, -1);
    assert.equal(result.wifiSummary, 'Not connected');
});

test('disabled networking hides cached connections, addresses and signal', () => {
    const result = state(wifiDevice, 'GENERAL.DEVICE:wlan0\nIP4.ADDRESS[1]:192.0.2.1/24', '*:Home:80:wlan0', false);
    assert.equal(result.connected, false);
    assert.equal(result.summary, 'Offline');
    assert.equal(result.address, '');
    assert.equal(result.signal, -1);
    assert.equal(result.detail, 'Networking disabled');
});

test('disabling Wi-Fi retains a wired connection and clears wireless data', () => {
    const result = state(wifiDevice + '\n' + wiredDevice, '', '*:Home:80:wlan0', true, false);
    assert.equal(result.summary, 'Office');
    assert.equal(result.title, 'Wired');
    assert.equal(result.wifiSummary, 'Disabled');
    assert.equal(result.wifiSignal, -1);
    assert.equal(state(wifiDevice, '', '*:Home:80:wlan0', true, false).connected, false);
});

test('signal comes from the active access point on the selected Wi-Fi device', () => {
    const result = state(wifiDevice, '', ':Nearby:99:wlan0\n:Other:95:wlan0\n:Guest:90:wlan0\n*:Second adapter:88:wlan1\n*:Home:42:wlan0');
    assert.equal(result.signal, 42);
    assert.equal(result.wifiSummary, 'Home');
});

test('zero is a valid signal and missing or invalid signal stays unknown', () => {
    for (const signal of ['', 'NaN', 'Infinity', '--'])
        assert.equal(state(wifiDevice, '', `*:Home:${signal}:wlan0`).signal, -1);
    assert.equal(state(wifiDevice, '', '*:Home:0:wlan0').signal, 0);
    assert.equal(state(wifiDevice, '', '*:Home:150:wlan0').signal, 100);
    assert.equal(state(wifiDevice, '', '*:Home:-10:wlan0').signal, 0);
});

test('IP address belongs to the selected interface, even after loopback and virtual interfaces', () => {
    const result = state('bridge:docker0:connected (externally):Docker\n' + wiredDevice,
        'GENERAL.DEVICE:lo\nIP4.ADDRESS[1]:127.0.0.1/8\nGENERAL.DEVICE:docker0\nIP4.ADDRESS[1]:172.17.0.1/16\nGENERAL.DEVICE:eth0\nIP4.ADDRESS[1]:192.0.2.10/24');
    assert.equal(result.summary, 'Office');
    assert.equal(result.address, '192.0.2.10');
    assert.ok(!result.detail.includes('127.0.0.1'));
    assert.ok(result.detail.includes('eth0 192.0.2.10'));
});

test('IPv6-only connections show an address and IPv4 is preferred when available', () => {
    const addresses = 'GENERAL.DEVICE:wlan0\nIP6.ADDRESS[1]:2001\\:db8\\:\\:1/64';
    assert.equal(state(wifiDevice, addresses).address, '2001:db8::1');
    assert.equal(state(wifiDevice, addresses + '\nIP4.ADDRESS[1]:192.0.2.2/24').address, '192.0.2.2');
});

test('loopback, disconnected, connecting and malformed records are excluded', () => {
    const devices = 'loopback:lo:connected (externally):lo\nethernet:eth0:disconnected:--\nwifi:wlan0:connecting (prepare):Home\ninvalid';
    assert.equal(state(devices).connected, false);
    assert.equal(network.parseWifi('invalid').length, 0);
    assert.equal(network.parseAddresses('IP4.ADDRESS[1]:192.0.2.2/24').length, 0);
    assert.equal(state(null, null, null).connected, false);
});

test('escaped names, CRLF, and names resembling connection types are preserved', () => {
    const devices = String.raw`wifi:wlan0:connected:Wired Cafe\: \\back` + '\r\n';
    const wifi = String.raw`*:<b>Cafe\: \\back</b>:75:wlan0` + '\r\n';
    const result = state(devices, '', wifi);
    assert.equal(result.title, 'Wi-Fi');
    assert.equal(result.summary, String.raw`Wired Cafe: \back`);
    assert.equal(result.wifiSummary, String.raw`<b>Cafe: \back</b>`);
    assert.equal(network.splitFields(String.raw`a:b\\c`)[1], String.raw`b\c`);
});

test('mobile and virtual connections are not labeled as wireless', () => {
    assert.equal(state('gsm:wwan0:connected:Carrier').footer, 'Mobile');
    const result = state('tun:tun0:connected (externally):Wired VPN');
    assert.equal(result.footer, 'Connected');
    assert.equal(result.title, 'Network');
});

test('stale access points alone and addresses from disconnected interfaces are hidden', () => {
    const result = state(wiredDevice, 'GENERAL.DEVICE:wlan0\nIP4.ADDRESS[1]:192.0.2.4/24', '*:Old Wi-Fi:80:wlan0');
    assert.equal(result.address, '');
    assert.equal(result.signal, -1);
    assert.equal(result.wifiSignal, -1);
    assert.equal(result.wifiSummary, 'Not connected');
});
