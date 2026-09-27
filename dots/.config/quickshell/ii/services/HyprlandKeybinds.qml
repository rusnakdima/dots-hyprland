pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * A service that provides access to Hyprland keybinds.
 * Uses the `get_keybinds.py` script to parse comments in config files in a certain format and convert to JSON.
 */
Singleton {
    id: root
    property var keybinds: []
    property var keybindCategories: []

    // Custom hl.bind() keybinds defined in hypr/hyprland/keybinds.lua
    FileView {
        id: userBindsFile
        printErrors: false
        path: Directories.config + "/hypr/hyprland/keybinds.lua"
    }

    /**
     * Parse hl.bind("MOD1+MOD2+Key", hl.dsp.dispatcher("arg"), {description = "..."})
     * statements from the custom keybinds Lua file into objects shaped like
     * `hyprctl binds -j` entries so they merge seamlessly into keybinds.
     */
    function parseUserBinds(content: string): var {
        const results = []
        if (!content || content.length === 0) return results

        const keyPattern = /hl\.bind\s*\(\s*"([^"]+)"/
        const dispatcherPattern = /hl\.dsp\.(\w+)\s*\(/
        const argPattern = /\(\s*"([^"]*)"\s*\)/
        const descPattern = /description\s*=\s*"([^"]*)"/
        // Settings-generated lines append the description as a trailing Lua comment
        const commentDescPattern = /\)\)\s*--\s*(.+?)\s*$/
        const modBits = ({
            SHIFT: 1, CAPS: 2, CTRL: 4, CONTROL: 4, ALT: 8,
            MOD2: 16, MOD3: 32, SUPER: 64, MOD5: 128,
        })

        const pushBind = (block) => {
            const keyMatch = block.match(keyPattern)
            if (!keyMatch) return
            const descMatch = block.match(descPattern)
            const dispatcherMatch = block.match(dispatcherPattern)
            const argMatch = block.match(argPattern)

            // Split "CTRL+SUPER+Key" (or "CTRL,SUPER,Key") into mods + key
            const tokens = keyMatch[1].split(/[+,]/)
            const key = tokens.pop()
            let modmask = 0
            for (const token of tokens) {
                modmask |= modBits[token.toUpperCase()] ?? 0
            }

            let description = descMatch ? descMatch[1] : ""
            if (description.length === 0) {
                const commentMatch = block.match(commentDescPattern)
                if (commentMatch) description = commentMatch[1]
            }

            results.push({
                key: key,
                modmask: modmask,
                dispatcher: dispatcherMatch ? dispatcherMatch[1] : "",
                arg: argMatch ? argMatch[1] : "",
                description: description,
                // Flag as user-defined so consumers can mark them differently
                _isUserBind: true,
            })
        }

        // Track brace-balanced hl.bind(...) blocks across lines
        let depth = 0
        let inBind = false
        let block = ""

        for (const line of content.split("\n")) {
            if (inBind) {
                block += line + "\n"
                for (const ch of line) {
                    if (ch === "{") depth++
                    else if (ch === "}") depth--
                }
                if (depth === 0) {
                    pushBind(block)
                    inBind = false
                    block = ""
                }
            } else {
                const idx = line.indexOf("hl.bind(")
                if (idx !== -1) {
                    inBind = true
                    depth = 0
                    block = line.substring(idx) + "\n"
                    for (let i = idx; i < line.length; i++) {
                        const ch = line[i]
                        if (ch === "{") depth++
                        else if (ch === "}") depth--
                    }
                    if (depth === 0) {
                        pushBind(block)
                        inBind = false
                        block = ""
                    }
                }
            }
        }

        return results
    }

    /**
     * Prepend parsed user binds to the upstream `hyprctl binds -j` list,
     * dropping upstream duplicates (same key + mods + description).
     */
    function mergeUserBinds(userBinds: var, upstreamBinds: var): var {
        const merged = [...userBinds]
        for (const upstream of upstreamBinds) {
            const isDup = merged.some(userBind =>
                userBind.key === upstream.key
                && (userBind.modmask ?? 0) === (upstream.modmask ?? 0)
                && (userBind.description ?? "") === (upstream.description ?? "")
            )
            if (!isDup) merged.push(upstream)
        }
        return merged
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                userBindsFile.reload()
                getKeybinds.running = true
            }
        }
    }

    Process {
        id: getKeybinds
        running: true
        command: ["hyprctl", "binds", "-j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const upstreamBinds = JSON.parse(text)
                    root.keybinds = root.mergeUserBinds(root.parseUserBinds(userBindsFile.text()), upstreamBinds)
                    var groups = []
                    for (var i = 0; i < root.keybinds.length; i++) {
                        var bind = root.keybinds[i].description
                        var group = bind.substring(0, bind.indexOf(":"))
                        if (!groups.includes(group) && group.length > 0) {
                            groups.push(group)
                        }
                    }
                    root.keybindCategories = groups
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }
}

