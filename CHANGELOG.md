# Changelog

All notable changes to this project are documented in this file.

## [Unreleased] — 470f03e8 (HEAD)

> Unreleased — pending push to origin/main

### Commits ahead of origin/main (not yet pushed)
- `470f03e8` feat(ii): apply OpenSpec fixes — QML cleanup, panel opacity, CI tooling
- `REFACTOR` refactor: reorganize project structure — `sdata/` → `src/`, `dots-extra/` → `sys/`, `scripts/` → `src/cmd/` (where applicable); all internal path references updated; `./setup` and `./refresh-configs` kept as thin root shims delegating to `src/setup` and `src/cmd/refresh-configs`
- `XXXXXX` fix(notifications): notification UI overhaul — add Config.options.notifications.{popup,group,unread} schema keys, wire dead NotificationEnableGuard override into popup/waffle guards, decouple unread counter from popup-inhibited, add Low urgency styling, make urgent icon shape deterministic, add live time-string refresh (30s polling), delete unreferenced IconOverflow override, make collapsed max height and expanded spacings config-driven
- `8edc9881` fix(hyprland): remove 15min suspend timeout, switch keyboard layout via hyprctl
- `010414e4` feat(quickshell): add hotspot toggle and wifi network dialog
- REMOVE hotspot feature (broken): removes Network.qml hotspot properties/functions/processes, deletes hotspot-start/stop/status/aic-iface-detect shell scripts, deletes HotspotToggle/HotspotDialog/AndroidHotspotToggle QML files, removes sidebar hotspot plumbing (showHotspotDialog property, ToggleDialog block, openHotspotDialog signals/handlers), removes "hotspot" from AndroidQuickPanel.availableToggleTypes, removes hotspot DelegateChoice from AndroidToggleDelegateChooser; NOTE: `sudo rm /etc/sudoers.d/hotspot` must be run manually to revoke the NOPASSWD grant for hotspot-start/stop
- `546ae246` fix: Hyprland window and cursor settings
- `108b87d3` feat: add atomic.omp.json managed config

### Full history
`git log --oneline origin/main..HEAD`

---

## [Previous releases]
See `git log --oneline origin/main` for past commits.
