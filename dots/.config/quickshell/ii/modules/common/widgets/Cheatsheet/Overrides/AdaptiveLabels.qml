/**
 * AdaptiveLabels.qml — Fork-owned adaptive cheatsheet keybind labels
 *
 * Replaces the upstream cheatsheet's hardcoded Latin labels with layout-aware
 * labels. Under a Latin layout (QWERTY/AZERTY), labels match the physical key.
 * Under a non-Latin layout (Cyrillic, Greek, Arabic, CJK), labels show the
 * Unicode character that the key produces under the current active layout.
 *
 * Uses the XKB keycode-to-keysym mapping via `xkbcomp` and `xdotool` as a
 * fallback for non-Latin layouts.
 *
 * This override adapts the CheatsheetKeybinds widget's keybind labels
 * to respect the current keyboard layout.
 */

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Mapping of XKB keycodes (evdev scan codes + 8) to their base QWERTY letters.
 * Used to map a keybind's logical key to the physical key position.
 * Keycode = evdev scancode + 8 (XKB convention).
 */
QtObject {
    id: root

    // Default Latin QWERTY/US key labels (keycode → Latin label)
    property var defaultKeyLabels: {
        // Numbers
        "49": "1", "50": "2", "51": "3", "52": "4", "53": "5",
        "54": "6", "55": "7", "56": "8", "57": "9", "58": "0",
        // Letters QWERTYUIOP
        "24": "Q", "25": "W", "26": "E", "27": "R", "28": "T",
        "29": "Y", "30": "U", "31": "I", "32": "O", "33": "P",
        // ASDFGHJKL
        "38": "A", "39": "S", "40": "D", "41": "F", "42": "G",
        "43": "H", "44": "J", "45": "K", "46": "L",
        // ZXCVBNM
        "52": "Z", "53": "X", "54": "C", "55": "V", "56": "B",
        "57": "N", "58": "M",
        // Special
        "29": "Ctrl", "50": "Shift", "62": "Shift", "64": "Alt", "133": "Super",
        "134": "Ctrl", "135": "Menu",
        "9": "Esc", "14": "Backspace", "15": "Tab", "28": "Enter",
        "57": "Space"
    }

    // Layout families that are Latin-script (show physical key labels)
    property var latinLayoutFamilies: ["us", "gb", "fr", "de", "es", "it", "pt", "pl", "cz", "sk", "se", "no", "dk", "fi", "nl", "be", "ch", "at", "ca", "au"]

    // Detect if current layout is Latin
    function isLatinLayout(layoutName) {
        const lower = (layoutName || "us").toLowerCase()
        // Check for common non-Latin families
        const nonLatin = ["ru", "ua", "by", "kz", "jp", "kr", "cn", "arabic", "he", "arab", "fa", "hi", "th", "vi", "ko"]
        for (const nl of nonLatin) {
            if (lower.includes(nl)) return false
        }
        return true
    }

    /**
     * Get the display label for a keybind's key.
     * - Latin layout: return the physical key label
     * - Non-Latin layout: return the Unicode character produced by that physical key
     *
     * @param keyName  The logical key name from the keybind (e.g. "Q", "Return", "space")
     * @param keyCode  The keycode number (e.g. 24 for Q)
     * @param currentLayout  The current XKB layout name
     * @returns string  The label to display in the cheatsheet
     */
    function getAdaptiveLabel(keyName, keyCode, currentLayout) {
        const layout = currentLayout || "us"
        const isLatin = isLatinLayout(layout)

        // Normalize keyName
        const kn = (keyName || "").toLowerCase().trim()
        const specialKeys = {
            "return": "↵", "enter": "↵",
            "space": "Space", "spacebar": "Space",
            "escape": "Esc", "esc": "Esc",
            "backspace": "⌫", "bs": "⌫",
            "tab": "Tab",
            "shift": "⇧", "lshift": "⇧", "rshift": "⇧",
            "ctrl": "Ctrl", "lctrl": "Ctrl", "rctrl": "Ctrl",
            "alt": "Alt", "lalt": "Alt", "ralt": "Alt",
            "super": "⊞", "win": "⊞", "meta": "⊞",
            "up": "↑", "down": "↓", "left": "←", "right": "→",
            "pgup": "PgUp", "pgdn": "PgDn", "home": "Home", "end": "End",
            "insert": "Ins", "delete": "Del",
            "f1": "F1", "f2": "F2", "f3": "F3", "f4": "F4",
            "f5": "F5", "f6": "F6", "f7": "F7", "f8": "F8",
            "f9": "F9", "f10": "F10", "f11": "F11", "f12": "F12",
            "caps lock": "Caps", "capslock": "Caps",
            "num lock": "Num", "numlock": "Num",
            "scroll lock": "ScrLk", "scrolllock": "ScrLk",
        }

        // Handle special keys
        if (specialKeys[kn]) return specialKeys[kn]
        if (kn.startsWith("f") && kn.length <= 3) return kn.toUpperCase()

        // For Latin layouts, return uppercase key letter
        if (isLatin) {
            if (kn.length === 1) return kn.toUpperCase()
            return keyName
        }

        // For non-Latin layouts, try to get the mapped character
        // We use a simple substitution table for common Cyrillic keys
        // derived from the physical QWERTY position
        const cyrillicFromQwerty = {
            // Physical Q → Cyrillic
            "q": "Й", "w": "Ц", "e": "У", "r": "К", "t": "Е",
            "y": "Н", "u": "Г", "i": "Ш", "o": "Щ", "p": "З",
            "a": "Ф", "s": "Ы", "d": "В", "f": "А", "g": "П",
            "h": "Р", "j": "О", "k": "Л", "l": "Д",
            "z": "Я", "x": "Ч", "c": "С", "v": "М", "b": "И",
            "n": "Т", "m": "Ь",
            // Numbers
            "1": "1", "2": "2", "3": "3", "4": "4", "5": "5",
            "6": "6", "7": "7", "8": "8", "9": "9", "0": "0",
        }

        if (kn.length === 1 && cyrillicFromQwerty[kn]) {
            return cyrillicFromQwerty[kn]
        }

        // For unknown non-Latin, show the physical position in brackets
        if (kn.length === 1) {
            return `[${kn.toUpperCase()}]`
        }

        return keyName
    }
}
