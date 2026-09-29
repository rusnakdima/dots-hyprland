-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- Window rule: VNC viewer showing app-host goes to workspace 10 and floats
hl.window_rule({ match = { class = "vncviewer", title = "app-host" }, workspace = "10", float = true })
