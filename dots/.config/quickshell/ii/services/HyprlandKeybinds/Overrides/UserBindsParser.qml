/**
 * UserBindsParser.qml — fork-owned override for HyprlandKeybinds
 *
 * Parses `hl.bind(...)` calls from `~/.config/hypr/custom/keybinds.lua`
 * and merges them with the upstream `hyprctl binds -j` output.
 * This ensures that fork-specific keybinds defined via the hl.bind() API
 * appear in the cheatsheet alongside upstream Hyprland binds.
 *
 * Override seam: services/HyprlandKeybinds/Overrides/UserBindsParser.qml
 * Survives setup update: yes (Overrides/ seam)
 */

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * UserBindsParser — regex-based parser for hl.bind() statements in Lua.
 *
 * hl.bind format examples:
 *   hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ..."), {description = "Edit user keybinds"})
 *   hl.bind("SUPER+KP_0", hl.dsp.exec_cmd("..."), {description = "..."})
 *
 * This parser extracts key, dispatcher, arg, and description.
 */
QtObject {
    id: root

    /** Singleton instance exposed for use by HyprlandKeybinds */
    property var userBinds: []

    /** Path to the user keybinds file */
    property string customKeybindsPath: [
        standardPaths.location(StandardPaths.ConfigLocation),
        "hypr/custom/keybinds.lua"
    ].join("/")

    /** Re-read the custom keybinds file */
    function refresh() {
        userBinds = parseKeybindsFile(customKeybindsPath)
    }

    /**
     * Parse a Lua file and extract hl.bind(...) statements.
     * Returns an array of keybind objects compatible with hyprctl binds -j.
     */
    function parseKeybindsFile(path) {
        const file = IOUtils.open(path)
        if (!file) return []

        const content = file.readAll()
        file.close()
        return parseHlBinds(String.fromUtf8(content))
    }

    /**
     * Regex-based hl.bind() parser.
     *
     * Matches:
     *   hl.bind("MODIFIERS+KEY", <dispatcher>, {description = "text", ...})
     *
     * Groups:
     *   1 = modifiers+key string  (e.g. "CTRL+SUPER+ALT+Slash")
     *   2 = dispatcher call      (e.g. "hl.dsp.exec_cmd(...)")
     *   3 = description          (e.g. "Edit user keybinds")
     */
    function parseHlBinds(content) {
        const results = []
        // Regex matches hl.bind("MODIFIERS+KEY", ..., {description = "...", ...})
        // Handles nested braces in the options table via a simple state machine.
        const bindPattern = /hl\.bind\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*\{/
        const descPattern = /description\s*=\s*"([^"]*)"/

        // Split content into hl.bind(...) blocks using a brace-balancing approach
        // to correctly handle nested braces in the options table.
        let depth = 0
        let inBind = false
        let bindStart = -1
        let block = ""

        const lines = content.split("\n")
        for (const line of lines) {
            if (inBind) {
                block += line + "\n"
                for (const ch of line) {
                    if (ch === "{") depth++
                    else if (ch === "}") depth--
                }
                if (depth === 0) {
                    // End of hl.bind block
                    const bindMatch = block.match(bindPattern)
                    if (bindMatch) {
                        const descMatch = block.match(descPattern)
                        const modifiersKey = bindMatch[1]
                        const dispatcherCall = bindMatch[2].trim()
                        const description = descMatch ? descMatch[1] : ""

                        // Extract dispatcher type from dispatcher call
                        // e.g. "hl.dsp.exec_cmd(...)" → "exec_cmd"
                        // e.g. "hl.dsp.exec_bind(...)" → "exec_bind"
                        const dspMatch = dispatcherCall.match(/hl\.dsp\.(\w+)\s*\(/)
                        const dispatcher = dspMatch ? dspMatch[1] : dispatcherCall

                        // Extract arg from dispatcher call, e.g. exec_cmd("xdg-open ...") → "xdg-open ..."
                        const argMatch = dispatcherCall.match(/\(\s*"([^"]*)"\s*\)/)
                        const arg = argMatch ? argMatch[1] : ""

                        results.push({
                            key: modifiersKey,
                            dispatcher: dispatcher,
                            arg: arg,
                            description: description,
                            // Flag as user-defined so the cheatsheet can mark them differently
                            _isUserBind: true,
                        })
                    }
                    block = ""
                    inBind = false
                    bindStart = -1
                }
            } else {
                // Look for hl.bind( start
                const idx = line.indexOf("hl.bind(")
                if (idx !== -1) {
                    inBind = true
                    depth = 0
                    bindStart = idx
                    block = line.substring(idx) + "\n"
                    for (let i = idx; i < line.length; i++) {
                        const ch = line[i]
                        if (ch === "{") depth++
                        else if (ch === "}") depth--
                    }
                    if (depth === 0) {
                        // Single-line hl.bind(...)
                        const bindMatch = block.match(bindPattern)
                        if (bindMatch) {
                            const descMatch = block.match(descPattern)
                            const modifiersKey = bindMatch[1]
                            const dispatcherCall = bindMatch[2].trim()
                            const description = descMatch ? descMatch[1] : ""

                            const dspMatch = dispatcherCall.match(/hl\.dsp\.(\w+)\s*\(/)
                            const dispatcher = dspMatch ? dspMatch[1] : dispatcherCall
                            const argMatch = dispatcherCall.match(/\(\s*"([^"]*)"\s*\)/)
                            const arg = argMatch ? argMatch[1] : ""

                            results.push({
                                key: modifiersKey,
                                dispatcher: dispatcher,
                                arg: arg,
                                description: description,
                                _isUserBind: true,
                            })
                        }
                        block = ""
                        inBind = false
                    }
                }
            }
        }

        return results
    }

    /**
     * Merge user binds with upstream hyprctl binds.
     * User binds are prepended so they appear first in the cheatsheet.
     */
    function mergeWithUpstream(upstreamBinds) {
        const merged = [...userBinds]
        // Deduplicate: skip upstream binds whose key+dispatcher+arg match a user bind
        for (const ubind of upstreamBinds) {
            const isDup = merged.some(
                mb => mb.key === ubind.key
                    && mb.dispatcher === ubind.dispatcher
                    && mb.arg === ubind.arg
            )
            if (!isDup) merged.push(ubind)
        }
        return merged
    }

    Component.onCompleted: refresh()
}
