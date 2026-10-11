pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    // Deduped list to fix double icons
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .filter((app, index, self) => 
            index === self.findIndex((t) => (
                t.id === app.id
            ))
    )
    
    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property var preppedIcons: list.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        // Guard: empty or whitespace-only search
        if (!search || typeof search !== "string" || search.trim().length === 0) {
            return [];
        }
        // Guard: excessively long query (prevent ReDoS / memory exhaustion)
        if (search.length > 500) {
            search = search.slice(0, 500);
        }
        // Guard: null/undefined preppedNames
        if (!preppedNames || !Array.isArray(preppedNames)) {
            return [];
        }

        try {
            if (root.sloppySearch) {
                const results = list.map(obj => ({
                    entry: obj,
                    score: Levendist.computeScore((obj?.name ?? "").toLowerCase(), search.toLowerCase())
                })).filter(item => item.score > root.scoreThreshold)
                    .sort((a, b) => b.score - a.score)
                return results
                    .map(item => item.entry)
            }

            const validPrepped = preppedNames.filter(item => item && item.name && item.entry)
            return Fuzzy.go(String(search), validPrepped, {
                all: true,
                key: "name"
            }).map(r => {
                return r.obj ? r.obj.entry : null
            }).filter(entry => entry !== null && entry !== undefined);
        } catch (e) {
            console.log("[AppSearch] fuzzyQuery error:", e)
            return []
        }
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0]
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    function guessIcon(str) {
        // Guard: null/undefined/non-string/empty input
        if (!str || typeof str !== "string" || str.length === 0) return "image-missing";

        try {
            // Quickshell's desktop entry lookup
            const entry = DesktopEntries.byId(str);
            if (entry) return entry.icon;

            // Normal substitutions
            if (substitutions[str]) return substitutions[str];
            if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

            // Regex substitutions
            for (let i = 0; i < regexSubstitutions.length; i++) {
                const substitution = regexSubstitutions[i];
                const replacedName = str.replace(
                    substitution.regex,
                    substitution.replace,
                );
                if (replacedName != str) return replacedName;
            }

            // Icon exists -> return as is
            if (iconExists(str)) return str;


            // Simple guesses
            const lowercased = str.toLowerCase();
            if (iconExists(lowercased)) return lowercased;

            const reverseDomainNameAppName = getReverseDomainNameAppName(str);
            if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

            const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
            if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

            const kebabNormalizedGuess = getKebabNormalizedAppName(str);
            if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

            const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
            if (iconExists(undescoreToKebabGuess)) return undescoreToKebabGuess;

            // Search in desktop entries
            const iconSearchResults = Fuzzy.go(str, preppedIcons, {
                all: true,
                key: "name"
            }).map(r => {
                return r.obj.entry
            });
            if (iconSearchResults.length > 0) {
                const guess = iconSearchResults[0].icon
                if (iconExists(guess)) return guess;
            }

            const nameSearchResults = root.fuzzyQuery(str);
            if (nameSearchResults.length > 0) {
                const guess = nameSearchResults[0].icon
                if (iconExists(guess)) return guess;
            }

            // Quickshell's desktop entry lookup
            const heuristicEntry = DesktopEntries.heuristicLookup(str);
            if (heuristicEntry) return heuristicEntry.icon;

            // Give up
            return "application-x-executable";
        } catch (e) {
            console.log("[AppSearch] guessIcon error:", e)
            return "image-missing"
        }
    }
}
