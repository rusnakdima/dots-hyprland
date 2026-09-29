-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- steam_app: AMD RX 7600 tearing fix for fullscreen Steam games
-- See: https://github.com/end-4/dots-hyprland/issues/3532
hl.window_rule({
    match = { class = "^(steam_app).*" },
})
