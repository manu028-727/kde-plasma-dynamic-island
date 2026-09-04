import QtQuick

QtObject {
    id: controller

    property list<ActivityProvider> providers

    readonly property var currentProvider: highestPriorityProvider()
    readonly property string currentKey: currentProvider ? currentProvider.key : "idle"

    function providerByKey(key) {
        for (let i = 0; i < providers.length; ++i) {
            if (providers[i].key === key)
                return providers[i];
        }
        return null;
    }

    function highestPriorityProvider() {
        let selected = null;
        for (let i = 0; i < providers.length; ++i) {
            const candidate = providers[i];
            if (!candidate.active)
                continue;
            if (!selected || candidate.priority > selected.priority)
                selected = candidate;
        }
        return selected;
    }

    function providerFor(requestedKey) {
        if (requestedKey && requestedKey !== "auto") {
            const requested = providerByKey(requestedKey);
            if (requested && requested.active)
                return requested;
        }
        return currentProvider;
    }

    function keyFor(requestedKey) {
        const provider = providerFor(requestedKey);
        return provider ? provider.key : "idle";
    }

    function priorityFor(requestedKey) {
        const provider = providerFor(requestedKey);
        return provider ? provider.priority : 0;
    }

    function visualComponentFor(requestedKey) {
        const provider = providerFor(requestedKey);
        return provider ? provider.visualComponent : null;
    }

    function compactComponentFor(requestedKey) {
        const provider = providerFor(requestedKey);
        return provider ? provider.compactComponent : null;
    }

    function expandedComponentFor(requestedKey) {
        const provider = providerFor(requestedKey);
        return provider ? provider.expandedComponent : null;
    }

    function autoCloseMsFor(requestedKey) {
        const provider = providerFor(requestedKey);
        return provider ? Math.max(1000, provider.autoCloseMs) : 3000;
    }
}
