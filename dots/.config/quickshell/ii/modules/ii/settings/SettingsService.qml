pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Settings window state and page registry — Singleton for qs.modules.ii.settings
Singleton {
    id: root

    property bool visible: false
    property string currentPage: "appearance"

    readonly property var categories: ["Appearance", "Shell", "System"]

    readonly property var pages: [
        {
            id: "appearance",
            label: "Appearance",
            icon: "\u{e3b4}",
            description: "Dark mode, fonts, transparency, wallpaper theming and color palette",
            category: "Appearance"
        },
        {
            id: "background",
            label: "Background",
            icon: "\u{e3f4}",
            description: "Clock and weather widgets, widget styles",
            category: "Appearance"
        },
        {
            id: "bar",
            label: "Bar",
            icon: "\u{e0be}",
            description: "Bar style, position, size, workspaces, elements and utility buttons",
            category: "Shell"
        },
        {
            id: "workspaces",
            label: "Workspaces",
            icon: "\u{e8f9}",
            description: "Workspace display, app icons and number labels",
            category: "Shell"
        },
        {
            id: "lock",
            label: "Lock Screen",
            icon: "\u{e8e8}",
            description: "Hyprlock, blur, clock position and security options",
            category: "Shell"
        },
        {
            id: "sidebar",
            label: "Sidebar",
            icon: "\u{e9ef}",
            description: "Translator, AI chat, booru, corner open and quick toggles/sliders",
            category: "Shell"
        },
        {
            id: "quickSettings",
            label: "Quick Settings",
            icon: "\u{e8e5}",
            description: "Toggle and slider visibility in the quick settings panel",
            category: "Shell"
        },
        {
            id: "notifications",
            label: "Notifications",
            icon: "\u{e7f4}",
            description: "Popup timeout, monitor, group sizes and unread count",
            category: "Shell"
        },
        {
            id: "about",
            label: "About",
            icon: "\u{e88e}",
            description: "ii version, system information and update check",
            category: "System"
        }
    ]

    readonly property var currentEntry: pages.find(p => p.id === currentPage) ?? pages[0]
    readonly property var pageOrder: categories.reduce((ids, c) => ids.concat(pages.filter(p => p.category === c).map(p => p.id)), [])

    function stepPage(delta: int) {
        const i = pageOrder.indexOf(currentEntry.id);
        currentPage = pageOrder[(i + delta + pageOrder.length) % pageOrder.length];
    }

    // ================= SEARCH =================
    property var searchIndex: []
    property bool indexing: false
    property var pendingReveal: null

    signal revealRequested

    readonly property var rowTypes: ["SettingRow", "ToggleRow", "SliderRow", "StepperRow", "SelectRow", "TextFieldRow", "InfoRow"]
    readonly property var groupTypes: ["SettingsGroup"]
    readonly property string pagesDir: Qt.resolvedUrl("./pages/").toString().replace("file://", "")

    function pageFile(id: string): string {
        return id.charAt(0).toUpperCase() + id.slice(1) + "Page.qml";
    }

    function buildIndex() {
        if (indexing || searchIndex.length > 0)
            return;
        indexing = true;
        indexProc.command = ["sh", "-c", 'for f in "$@"; do printf "\\n@@FILE %s\\n" "$f"; cat "$f"; done', "sh"].concat(pages.map(p => pagesDir + pageFile(p.id)));
        indexProc.running = true;
    }

    function parsePage(page: var, text: string): var {
        const out = [];
        const stack = [];
        const unescape = t => t.replace(/\\(.)/g, "$1");
        const groupOf = () => {
            for (let i = stack.length - 1; i >= 0; i--) {
                if (root.groupTypes.includes(stack[i].type))
                    return stack[i].props.title?.text ?? "";
            }
            return "";
        };
        const finish = e => {
            const label = e.props.label?.text ?? e.props.title?.text ?? "";
            if (label === "")
                return;
            const isRow = root.rowTypes.includes(e.type);
            if (!isRow && !root.groupTypes.includes(e.type))
                return;
            out.push({
                kind: isRow ? "row" : "group",
                page: page.id,
                pageLabel: page.label,
                icon: page.icon,
                group: isRow ? groupOf() : "",
                label: label,
                description: e.props.description?.text ?? "",
                words: e.props.description?.words ?? ""
            });
        };

        for (const raw of text.split("\n")) {
            const literals = [];
            const code = raw.replace(/"((?:[^"\\]|\\.)*)"/g, (m, g) => {
                literals.push(unescape(g));
                return '""';
            }).replace(/\/\/.*$/, "");
            const prop = code.match(/^\s*(label|title|description)\s*:\s*(.*)$/);
            if (prop && stack.length > 0 && stack[stack.length - 1].type !== "") {
                const pure = prop[2].trim() === '""' && literals.length === 1;
                stack[stack.length - 1].props[prop[1]] = {
                    text: pure ? literals[0] : "",
                    words: literals.join(" ")
                };
            }
            const type = code.match(/^\s*([A-Z]\w*)\s*\{/);
            let opened = false;
            for (const ch of code) {
                if (ch === "{") {
                    stack.push({
                        type: type && !opened ? type[1] : "",
                        props: {}
                    });
                    opened = true;
                } else if (ch === "}") {
                    const e = stack.pop();
                    if (e)
                        finish(e);
                }
            }
        }
        return out;
    }

    function parseIndex(text: string) {
        const byFile = {};
        for (const chunk of text.split("\n@@FILE ").slice(1)) {
            const nl = chunk.indexOf("\n");
            byFile[chunk.slice(0, nl)] = chunk.slice(nl + 1);
        }
        let index = [];
        for (const page of pages) {
            index.push({
                kind: "page",
                page: page.id,
                pageLabel: page.label,
                icon: page.icon,
                group: "",
                label: page.label,
                description: page.description,
                words: page.description + " " + page.category
            });
            index = index.concat(parsePage(page, byFile[pagesDir + pageFile(page.id)] ?? ""));
        }
        searchIndex = index;
    }

    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (q === "")
            return [];
        const words = q.split(/\s+/);
        const scored = [];
        searchIndex.forEach((e, i) => {
            const label = e.label.toLowerCase();
            const hay = (e.label + " " + e.group + " " + e.pageLabel + " " + e.words).toLowerCase();
            if (!words.every(w => hay.includes(w)))
                return;
            let score = e.kind === "page" ? 3 : e.kind === "group" ? 2 : 0;
            if (label === q)
                score += 100;
            else if (label.startsWith(q))
                score += 80;
            else if (label.includes(q))
                score += 60;
            else if (words.every(w => label.includes(w)))
                score += 40;
            else if (words.every(w => (e.group + " " + e.pageLabel).toLowerCase().includes(w)))
                score += 20;
            scored.push({ e: e, score: score, i: i });
        });
        scored.sort((a, b) => b.score - a.score || a.i - b.i);
        return scored.slice(0, 50).map(r => r.e);
    }

    function reveal(entry: var) {
        pendingReveal = entry.kind === "page" ? null : {
            page: entry.page,
            group: entry.group !== "" ? entry.group : (entry.kind === "group" ? entry.label : ""),
            label: entry.kind === "row" ? entry.label : ""
        };
        if (currentPage === entry.page) {
            if (pendingReveal)
                revealRequested();
        } else {
            currentPage = entry.page;
        }
    }

    Process {
        id: indexProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseIndex(text);
                root.indexing = false;
            }
        }
    }

    function open(page: string) {
        if (page && pages.some(p => p.id === page))
            currentPage = page;
        visible = true;
    }

    function close() {
        visible = false;
    }

    function toggle() {
        visible = !visible;
    }

    IpcHandler {
        target: "settings"

        function open(page: string): void {
            root.open(page);
        }

        function toggle(): void {
            root.toggle();
        }

        function close(): void {
            root.close();
        }
    }
}
