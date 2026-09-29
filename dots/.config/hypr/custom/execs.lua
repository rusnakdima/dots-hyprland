-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- Shared app-host integration: auto-start VNC viewer for app-host (exec-once semantics)
hl.on("hyprland.start", function ()
    hl.exec_cmd("/usr/local/bin/app-host-viewer-start")
end)

-- Keybinding: Super+Shift+Return launches terminal in app-host
hl.bind("SUPER+SHIFT+Return", hl.dsp.exec_cmd("/usr/local/bin/run-on-app-host foot"), { description = "Launch terminal on app-host" })
