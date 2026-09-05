.pragma library

function splitFields(line) {
    const fields = [];
    let current = "";
    let escaped = false;
    const text = String(line || "").replace(/\r$/, "");
    for (let i = 0; i < text.length; ++i) {
        const ch = text.charAt(i);
        if (escaped) {
            current += ch;
            escaped = false;
        } else if (ch === "\\") {
            escaped = true;
        } else if (ch === ":") {
            fields.push(current);
            current = "";
        } else {
            current += ch;
        }
    }
    fields.push(current + (escaped ? "\\" : ""));
    return fields;
}

function parseWifi(text) {
    const networks = [];
    const lines = String(text || "").split("\n");
    for (let i = 0; i < lines.length; ++i) {
        const fields = splitFields(lines[i]);
        if (fields.length < 4 || !fields[3])
            continue;
        const signal = Number(fields[2]);
        networks.push({
            "active": fields[0] === "*",
            "ssid": fields[1] || "Hidden network",
            "signal": fields[2].trim().length > 0 && isFinite(signal) ? Math.round(Math.max(0, Math.min(100, signal))) : -1,
            "device": fields[3]
        });
    }
    return networks;
}

function connectionRank(connection) {
    if (connection.type === "ethernet")
        return 0;
    if (connection.type === "wifi")
        return 1;
    if (connection.type === "gsm" || connection.type === "cdma")
        return 2;
    return 3;
}

function parseDevices(text) {
    const devices = [];
    const lines = String(text || "").split("\n");
    for (let i = 0; i < lines.length; ++i) {
        const fields = splitFields(lines[i]);
        if (fields.length < 4 || !fields[1] || fields[0] === "loopback"
                || (fields[2] !== "connected" && fields[2] !== "connected (externally)"))
            continue;
        devices.push({ "type": fields[0], "device": fields[1], "name": fields[3] && fields[3] !== "--" ? fields[3] : fields[1] });
    }
    // Prefer a physical connection over a local bridge or tunnel in the summary.
    return devices.sort(function(left, right) { return connectionRank(left) - connectionRank(right); });
}

function parseAddresses(text) {
    const addresses = [];
    const lines = String(text || "").split("\n");
    let device = "";
    for (let i = 0; i < lines.length; ++i) {
        const fields = splitFields(lines[i]);
        if (fields.length < 2)
            continue;
        if (fields[0] === "GENERAL.DEVICE") {
            device = fields[1];
        } else if (/^IP[46]\.ADDRESS\[\d+\]$/.test(fields[0]) && device && device !== "lo") {
            const address = fields[1].replace(/\/\d+$/, "");
            if (address && address !== "--" && address !== "::1" && !/^127\./.test(address))
                addresses.push({ "device": device, "address": address });
        }
    }
    return addresses;
}

function addressFor(addresses, device) {
    const matches = addresses.filter(function(address) { return address.device === device; });
    const ipv4 = matches.find(function(address) { return address.address.indexOf(":") < 0; });
    return ipv4 ? ipv4.address : matches.length > 0 ? matches[0].address : "";
}

function connectionTitle(connection) {
    if (connection.type === "ethernet")
        return "Wired";
    if (connection.type === "wifi")
        return "Wi-Fi";
    if (connection.type === "gsm" || connection.type === "cdma")
        return "Mobile";
    return "Network";
}

function summarize(devices, addresses, wifi, networkingEnabled, wirelessEnabled) {
    const connections = networkingEnabled ? devices.filter(function(device) {
        return device.type !== "wifi" || wirelessEnabled;
    }) : [];
    const primary = connections.length > 0 ? connections[0] : null;
    const wireless = connections.find(function(device) { return device.type === "wifi"; });
    const accessPoint = wireless ? wifi.find(function(network) { return network.active && network.device === wireless.device; }) : null;
    const address = primary ? addressFor(addresses, primary.device) : "";
    const title = primary ? connectionTitle(primary) : !networkingEnabled ? "Offline" : wirelessEnabled ? "Wi-Fi" : "Network";
    const details = connections.map(function(connection) {
        const ip = addressFor(addresses, connection.device);
        return connectionTitle(connection) + " " + connection.name + (ip ? "\n" + connection.device + " " + ip : "");
    });
    return {
        "connected": primary !== null,
        "title": title,
        "summary": primary ? primary.name : networkingEnabled ? "Disconnected" : "Offline",
        "address": address,
        "detailLine": primary ? address || "Connected" : networkingEnabled ? wirelessEnabled ? "No active connection" : "Wi-Fi disabled" : "Networking disabled",
        "footer": primary ? primary.type === "ethernet" ? "Ethernet" : primary.type === "wifi" ? "Wireless" : title === "Mobile" ? "Mobile" : "Connected" : "No connection",
        "icon": primary ? primary.type === "ethernet" ? "network-wired-activated" : primary.type === "wifi" ? "network-wireless-on" : "network-connect" : networkingEnabled && wirelessEnabled ? "network-wireless-on" : "network-offline",
        "signal": primary && primary.type === "wifi" && accessPoint ? accessPoint.signal : -1,
        "wifiSignal": accessPoint ? accessPoint.signal : -1,
        "wifiSummary": wireless ? accessPoint ? accessPoint.ssid : wireless.name : networkingEnabled && wirelessEnabled ? "Not connected" : "Disabled",
        "detail": details.length > 0 ? details.join("\n") : networkingEnabled ? "No active connections" : "Networking disabled"
    };
}
