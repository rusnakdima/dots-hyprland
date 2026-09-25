/**
 * FuzzyNullGuard — fork override for AppSearch.qml
 *
 * Problem: Fuzzy.go() or Fuzzy.prepare() can crash when passed null/undefined
 * values in the index, particularly with empty strings or malformed desktop
 * entries.
 *
 * Fix: Add null guards before fuzzy operations. This override extends the
 * AppSearch singleton to handle edge cases: empty query, special characters,
 * very long query strings, and null entries in the prepped lists.
 *
 * https://github.com/end-4/dots-hyprland/issues/3630
 */

import QtQuick

AppSearch {
    // Override fuzzyQuery to add null guards
    function fuzzyQuery(search: string): var {
        // Guard: empty or whitespace-only search
        if (!search || typeof search !== "string" || search.trim().length === 0) {
            return [];
        }

        // Guard: excessively long query (prevent ReDoS / memory exhaustion)
        if (search.length > 500) {
            search = search.slice(0, 500);
        }

        // Guard: null/undefined preppedNames
        if (!root.preppedNames || !Array.isArray(root.preppedNames)) {
            return [];
        }

        try {
            if (root.sloppySearch) {
                const results = root.list.map(obj => ({
                    entry: obj,
                    score: Levendist.computeScore(
                        (obj?.name ?? "").toLowerCase(),
                        search.toLowerCase()
                    )
                })).filter(item => item.score > root.scoreThreshold)
                    .sort((a, b) => b.score - a.score)
                return results.map(item => item.entry)
            }

            const safeSearch = String(search)
            const validPrepped = root.preppedNames.filter(
                item => item && item.obj && item.obj.entry
            )

            return Fuzzy.go(safeSearch, validPrepped, {
                all: true,
                key: "name"
            }).map(r => {
                return r.obj ? r.obj.entry : null
            }).filter(entry => entry !== null && entry !== undefined)
        } catch (e) {
            console.log("[AppSearch] FuzzyNullGuard: error in fuzzyQuery:", e)
            return []
        }
    }

    // Override guessIcon to add null guards
    function guessIcon(str) {
        // Guard: null/undefined/empty input
        if (!str || typeof str !== "string" || str.length === 0) {
            return "image-missing";
        }

        try {
            // Use original implementation but wrapped in try/catch
            return _original_guessIcon(str)
        } catch (e) {
            console.log("[AppSearch] FuzzyNullGuard: error in guessIcon:", e)
            return "image-missing"
        }
    }

    // Store reference to original guessIcon
    property var _original_guessIcon: (function(str) {
        // Delegate to parent AppSearch's logic by calling methods directly
        if (!str || str.length == 0) return "image-missing";

        const entry = DesktopEntries.byId(str);
        if (entry) return entry.icon;

        if (root.substitutions[str]) return root.substitutions[str];
        if (root.substitutions[str.toLowerCase()]) return root.substitutions[str.toLowerCase()];

        for (let i = 0; i < root.regexSubstitutions.length; i++) {
            const substitution = root.regexSubstitutions[i];
            const replacedName = str.replace(substitution.regex, substitution.replace);
            if (replacedName != str) return replacedName;
        }

        if (root.iconExists(str)) return str;

        const lowercased = str.toLowerCase();
        if (root.iconExists(lowercased)) return lowercased;

        return "application-x-executable";
    })
}
