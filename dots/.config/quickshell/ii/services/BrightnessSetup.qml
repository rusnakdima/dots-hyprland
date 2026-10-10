pragma Singleton

import qs.modules.common
import Quickshell
import Quickshell.Io

/**
 * BrightnessSetup — runs once on first launch, auto-detects the brightnessctl
 * backlight device, and stores the result in Config so Brightness.qml uses it.
 *
 * Excludes nvidia* devices (wrong hardware class) and picks the first device
 * whose max_brightness > 1000 (distinguishes integrated panel from USB/external).
 */
Singleton {
    id: root

    // Guard: only run if brightnessctlDevice is still empty (not yet set)
    readonly property bool needsSetup: !Config.options?.light?.brightness?.brightnessctlDevice

    // Detect asynchronously so we don't block shell startup.
    Process {
        id: detectProc
        command: [
            "sh", "-c",
            "for dir in /sys/class/backlight/*/; do name=\"$(basename \"$dir\")\"; case \"$name\" in nvidia*) continue ;; esac; max=\"$(cat \"$dir/max_brightness\" 2>/dev/null)\"; [[ \"${max}\" -gt 1000 ]] || continue; if grep -q 'POWER_SUPPLY_TYPE=backlight' \"$dir/uevent\" 2>/dev/null; then echo \"$name\"; exit 0; fi; done; for dir in /sys/class/backlight/*/; do name=\"$(basename \"$dir\")\"; case \"$name\" in nvidia*) continue ;; esac; max=\"$(cat \"$dir/max_brightness\" 2>/dev/null)\"; [[ \"${max}\" -gt 1000 ]] && { echo \"$name\"; exit 0; }; done; echo ''"
        ]

        onExited: {
            const device = (stdout.trim() || "");
            if (device) {
                // Write the discovered device into config and persist to disk
                Config.options.light.brightness.brightnessctlDevice = device;
                Config.save();
            }
        }
    }

    // Trigger detection when the shell starts and needsSetup is true.
    // We use a Connections block so the trigger fires after Config is ready.
    Component.onCompleted: {
        if (root.needsSetup) {
            detectProc.running = true;
        }
    }
}
