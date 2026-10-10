-- Profile: laptop — single-screen workspace bindings
-- These ADD to/override the base keybinds.lua workspace bindings for laptop profile.
-- keybinds.lua already has full workspace bindings; laptop profile adds
-- simplified single-monitor focus for workspaces 1-5 without group logic.

-- Laptop: workspaces 1-5 focus (single monitor, no group/wrap logic)
for i = 1, 5 do
    hl.bind("SUPER + " .. (i % 10), function()
        hl.dispatch(hl.dsp.focus({ workspace = i }))
    end, { description = "[laptop] Workspace: Focus " .. i })
end
