var panel = new Panel

panel.location = "top";
panel.height = 50;
panel.alignment = "center";
panel.lengthMode = "fit";
panel.floating = true;
panel.floatingApplets = true;
panel.opacityMode = "translucent";
panel.hiding = "windowsgobelow";

panel.addWidget("com.manu028.dynamicisland");

var colorizer = panel.addWidget("luisbocanegra.panel.colorizer");
if (colorizer) {
    colorizer.currentConfigGroup = ["General"];
    colorizer.writeConfig("hideWidget", true);
    colorizer.writeConfig("globalSettings", JSON.stringify({
        nativePanel: {
            background: {
                enabled: false,
                opacity: 0,
                shadow: false
            },
            floatingDialogs: false,
            floatingDialogsAllowOverride: false,
            fillAreaOnDeFloat: true,
            hideWhenNoWidgetsAreVisible: false
        },
        stockPanelSettings: {
            visibility: {
                enabled: true,
                value: "windowsgobelow"
            }
        }
    }));
    colorizer.reloadConfiguration();
}
