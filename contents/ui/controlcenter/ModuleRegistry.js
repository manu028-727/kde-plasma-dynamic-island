.pragma library

const modules = [
    { "id": "userPower", "name": "User + Power", "icon": "user-identity", "defaultW": 6, "defaultH": 2, "maxH": 3 },
    { "id": "volume", "name": "Volume", "icon": "audio-volume-high", "defaultW": 8, "defaultH": 2 },
    { "id": "brightness", "name": "Brightness", "icon": "brightness-high", "defaultW": 8, "defaultH": 2 },
    { "id": "wifi", "name": "Wi-Fi", "icon": "network-wireless-on", "disabledIcon": "network-wireless-off", "defaultW": 2, "defaultH": 2 },
    { "id": "wifiDevices", "name": "Wi-Fi Networks", "icon": "network-wireless-acquiring", "defaultW": 4, "defaultH": 2 },
    { "id": "bluetooth", "name": "Bluetooth", "icon": "preferences-system-bluetooth", "defaultW": 2, "defaultH": 2 },
    { "id": "bluetoothDiscovery", "name": "Bluetooth Discovery", "icon": "preferences-system-bluetooth", "defaultW": 4, "defaultH": 2 },
    { "id": "notifications", "name": "Notifications", "icon": "notifications", "defaultW": 4, "defaultH": 4, "minW": 2, "minH": 2 },
    { "id": "batteryStatus", "name": "Battery Status", "icon": "battery", "chargingIcon": "battery-charging", "defaultW": 2, "defaultH": 2 },
    { "id": "batteryPercent", "name": "Battery %", "icon": "battery", "chargingIcon": "battery-charging", "defaultW": 2, "defaultH": 2 },
    { "id": "powerMode", "name": "Power Mode", "icon": "battery-profile-balanced", "defaultW": 2, "defaultH": 2 },
    { "id": "appearanceMode", "name": "Light / Dark", "icon": "preferences-desktop-theme", "defaultW": 2, "defaultH": 2 },
    { "id": "theme", "name": "Theme", "icon": "preferences-desktop-theme-global", "defaultW": 2, "defaultH": 2 },
    { "id": "media", "name": "Media", "icon": "multimedia-player", "defaultW": 8, "defaultH": 4, "minW": 2, "minH": 2 },
    { "id": "kdeConnect", "name": "KDE Connect", "icon": "kdeconnect", "defaultW": 2, "defaultH": 2 },
    { "id": "settings", "name": "Settings", "icon": "systemsettings", "defaultW": 2, "defaultH": 2 }
];

const defaultLayoutOrder = [
    "userPower",
    "batteryPercent",
    "media",
    "volume",
    "brightness",
    "wifi",
    "wifiDevices",
    "bluetooth",
    "bluetoothDiscovery",
    "notifications",
    "batteryStatus",
    "powerMode",
    "appearanceMode",
    "theme",
    "kdeConnect",
    "settings"
];

function allModules() {
    return modules.map(function(module) {
        return Object.assign({}, module);
    });
}

function info(id) {
    for (let i = 0; i < modules.length; ++i) {
        if (modules[i].id === id)
            return Object.assign({}, modules[i]);
    }
    return { "id": id, "name": id, "icon": "unknown", "defaultW": 2, "defaultH": 2 };
}

function defaultLayout() {
    return defaultLayoutOrder.map(function(id) {
        const module = info(id);
        return {
            "id": module.id,
            "w": module.defaultW || 2,
            "h": module.defaultH || 2,
            "v": 2
        };
    });
}

function minSize(id) {
    const module = info(id);
    return {
        "w": module.minW || 1,
        "h": module.minH || 1
    };
}

function maxSize(id) {
    const module = info(id);
    return {
        "w": module.maxW || 8,
        "h": module.maxH || 6
    };
}

function defaultSize(id) {
    const module = info(id);
    return {
        "id": id,
        "w": module.defaultW || 2,
        "h": module.defaultH || 2,
        "v": 2
    };
}

function icon(id, state) {
    const module = info(id);
    if (id === "wifi" && state && state.wifiEnabled === false)
        return module.disabledIcon || module.icon;
    if ((id === "batteryStatus" || id === "batteryPercent") && state && state.batteryCharging)
        return module.chargingIcon || module.icon;
    if (id === "powerMode" && state && state.powerProfileIcon)
        return state.powerProfileIcon;
    return module.icon || "unknown";
}
