// FcitxDarkModeHook.qml
// Calls fcitx-render-config.sh whenever Config.options.appearance.darkMode changes,
// keeping fcitx5's UseDarkTheme in sync with the shell dark-mode toggle.
import QtQuick
import Quickshell
import Quickshell.Io

QuickshellModule {
    id: root

    // Re-render fcitx5 config whenever darkMode toggles.
    // Config.options is a JsonObject; we use a QtQuick Binding to call the
    // renderer on change.  The script is idempotent so calling on every
    // toggle (including startup) is safe.
    Binding {
        target: root
        property: "_trigger"
        value: Config.options.appearance?.darkMode
        onChanged: (val) => {
            // val is passed implicitly; trigger rendering
            callRenderer();
        }
    }

    // Keep a signal that fires once the module is initialised so we also
    // apply settings on first launch.
    Component.onCompleted: callRenderer()

    // Resolves the renderer's script path:
    //   1. ~/.dots-local/dots-extra/scripts/fcitx-render-config.sh  (installed)
    //   2. the repo-relative path (development)
    function rendererPath() {
        let home = RealPath.home();
        let installed = home + "/.dots-local/dots-extra/scripts/fcitx-render-config.sh";
        if (FileUtils.exists(installed)) return installed;
        // development: resolve relative to the quickshell config dir
        let repoRoot = FileUtils.realpath(Directories.shellConfigPath + "/../../../../");
        return repoRoot + "/dots-extra/scripts/fcitx-render-config.sh";
    }

    function callRenderer() {
        // Run the renderer script; the script creates ~/.config/fcitx5/conf
        // if needed and is safe to call repeatedly.
        Process.launched("bash", [rendererPath()]);
    }
}
