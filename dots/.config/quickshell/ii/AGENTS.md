# ii Architecture — AGENTS.md

Module structure, anti-patterns, service initialization conventions, and symbol map
for the ii Quickshell extension.

---

## Module Hierarchy

```
ii/
├── AGENTS.md                    ← This file
├── shell.qml                    ← Entry point; imports modules/services via module system
├── GlobalStates.qml             ← Legacy location (prefer modules/globals/GlobalStates.qml)
│
├── modules/
│   ├── common/                  ← Shared infrastructure (Config, Appearance, Icons, functions/)
│   │   ├── Config.qml           ← Config singleton (FileView + JsonAdapter, pragma Singleton)
│   │   ├── Appearance.qml       ← Appearance state
│   │   ├── Directories.qml      ← XDG path singletons
│   │   ├── Icons.qml            ← Icon registry
│   │   ├── Persistent.qml       ← Persistent storage helper
│   │   ├── functions/           ← Pure-utility QML modules (ColorUtils, FileUtils, …)
│   │   │   └── qmldir           ← module qs.modules.common.functions
│   │   ├── models/              ← Data models, gCloud, quickToggles/
│   │   ├── services/            ← Service override hooks (MaterialYou, WallpaperService)
│   │   ├── shaders/             ← GLSL shaders with qmldir
│   │   ├── utils/              ← Utility processes (ScreenshotAction, ImageDownloader)
│   │   │   └── qmldir          ← module qs.modules.common.utils
│   │   └── widgets/            ← Shared UI primitives (Box, Button, MaterialSymbol …)
│   │       ├── qmldir          ← module qs.modules.common.widgets
│   │       └── shapes/          ← Material shapes system
│   │
│   ├── globals/                 ← Global UI state singletons (NEW)
│   │   ├── GlobalStates.qml     ← Central boolean flags (barOpen, sidebarRightOpen …)
│   │   └── qmldir              ← module qs.modules.globals
│   │
│   ├── bar/                    ← Re-export of ii/bar (pragma-free bar components)
│   │   └── qmldir              ← module qs.modules.bar
│   │
│   ├── dashboard/              ← Re-export of ii/dashboard (home-screen widgets)
│   │   └── qmldir              ← module qs.modules.dashboard
│   │
│   ├── tools/                  ← Re-export of ii/tools (ColorPicker, Screenrecord …)
│   │   └── qmldir              ← module qs.modules.tools
│   │
│   ├── theme/                  ← Colors, typography, spacing design tokens (NEW)
│   │   ├── Colors.qml          ← Color palette + dark/light variants
│   │   ├── Typography.qml      ← Font roles and sizes
│   │   └── qmldir              ← module qs.modules.theme
│   │
│   ├── widgets/               ← Launcher, powermenu, overview (NEW — re-export of ii/)
│   │   ├── launcher/          ← Dock + app launcher
│   │   ├── powermenu/         ← PowerWindow
│   │   ├── overview/          ← Overview, SearchWidget, TileLayout
│   │   └── qmldir             ← module qs.modules.widgets
│   │
│   ├── components/            ← Shared UI primitives (NEW — curated from common/widgets)
│   │   ├── Button.qml
│   │   ├── IconButton.qml
│   │   ├── Popup.qml
│   │   └── qmldir             ← module qs.modules.components
│   │
│   ├── services/              ← All service singletons (moved from services/)
│   │   ├── qmldir             ← module qs.modules.services
│   │   ├── ai/                ← AI chat service
│   │   ├── booru/             ← Image board providers
│   │   ├── metrics/           ← CPU, Memory, Disk, GPU
│   │   └── network/           ← WifiAccessPoint
│   │
│   ├── ii/                    ← Primary UI modules (bar, dashboard, sidebarLeft …)
│   │   ├── bar/               ← Top bar with qmldir (module qs.modules.ii.bar)
│   │   ├── dashboard/
│   │   ├── sidebarLeft/       ← AI chat, anime, translator
│   │   ├── sidebarRight/      ← Quick toggles, calendar, volume mixer
│   │   └── …
│   │
│   ├── waffle/               ← Alternative panel family
│   │   ├── bar/
│   │   ├── looks/            ← W* widget primitives (WButton, WText …)
│   │   └── …
│   │
│   └── settings/             ← Settings window pages
│       └── qmldir            ← module qs.modules.ii.settings
│
├── services/                  ← [DEPRECATED — use modules/services/]
│
├── defaults/                  ← JSON default prompts (ai/, wallpapers/)
│
├── config/
│   └── defaults/             ← JSON default config values (bar, appearance …)
│
└── panelFamilies/            ← Panel family definitions
```

---

## Anti-Patterns

### ❌ Never use raw `Rectangle`

Use styled containers from `modules/common/widgets/` or `modules/waffle/looks/`:

```qml
// BAD — bare Rectangle, no rounding, no blur support
Rectangle { color: "black" }

// GOOD — BodyRectangle with material layer support
BodyRectangle { color: root.color }
```

Rationale: Raw `Rectangle` bypasses the acrylic/mica backdrop system and breaks theming.

### ❌ Never modify `Config` properties directly

```qml
// BAD — mutating Config internals
Config.options.bar.bottom = true  // breaks reactive binding

// GOOD — go through the setNestedValue API
Config.setNestedValue("bar.bottom", true)
```

### ❌ Never create new singletons outside `modules/` or `services/`

All shared state must live in a registered module with a `qmldir`. Anonymous singletons
lacking a `qmldir` are invisible to the module system and cause import failures.

### ❌ Never use hardcoded delays for service initialization

```qml
// BAD
Timer { interval: 500; onTriggered: SomeService.load() }

// GOOD — use dependency signals or Qt.callLater
SomeService {
    readonly property bool _ready: StateService.ready
    on _readyChanged: if (_ready) SomeService.load()
}
```

---

## Service Initialization Order

Critical order (components wait on `StateService.ready`):

```
StateService        — Must load first (holds defaults + user state)
    ↓
GlobalFocusGrab     — Needs Hyprland to be up
    ↓
HyprlandData        — Depends on Hyprland IPC
Hyprsunset          — Needs HyprlandData
ThemeService        — Depends on Config.ready
MaterialThemeLoader — Depends on ThemeService
    ↓
Wallpapers          — Needs MaterialThemeLoader
Cliphist            — Non-critical; Qt.callLater(..., 100)
FirstRunExperience  — Non-critical; Qt.callLater(..., 150)
ConflictKiller      — Non-critical; Qt.callLater(..., 200)
```

Non-critical services use `Qt.callLater(fn, delay)` from `shell.qml Component.onCompleted`.

---

## Symbol → Location Map

| Symbol | Location |
|---|---|
| `Config` | `modules/common/Config.qml` (singleton) |
| `Appearance` | `modules/common/Appearance.qml` |
| `Directories` | `modules/common/Directories.qml` |
| `GlobalStates` | `modules/globals/GlobalStates.qml` |
| `StateService` | `modules/services/StateService.qml` |
| `GlobalFocusGrab` | `modules/services/GlobalFocusGrab.qml` |
| `Wallpapers` | `modules/services/Wallpapers.qml` |
| `Notifications` | Quickshell built-in |
| `Mpris` | Quickshell built-in |
| `Bar` | `modules/ii/bar/Bar.qml` |
| `IllogicalImpulseFamily` | `panelFamilies/IllogicalImpulseFamily.qml` |

---

## Import Conventions

```qml
// Module imports (preferred)
import qs.modules.common        // Config, Appearance, Directories …
import qs.modules.services      // All service singletons
import qs.modules.globals       // GlobalStates
import qs.modules.ii.bar        // Bar, Workspaces …
import qs.modules.waffle.looks // WButton, WText …

// NOT this (old-style relative — being phased out)
import "modules/common"         // legacy
import "services"              // legacy — use qs.modules.services
```
