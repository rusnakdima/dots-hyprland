pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import Quickshell

/**
 * BrightnessSetup — placeholder for brightness hardware detection.
 *
 * Auto-detection requires the Process type from Quickshell.Io, which is
 * not available in the current quickshell build. Hardware detection is
 * skipped; users can manually set brightnessctlDevice in config if needed.
 */
Singleton {
    id: root

    // Always report that setup is done — skip auto-detection
    readonly property bool needsSetup: false
}
