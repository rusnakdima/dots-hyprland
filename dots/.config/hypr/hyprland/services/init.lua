-- Read machine profile from MACHINE file and export as Hyprland env var
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local machine_file = config_home .. "/dots-hyprland/MACHINE"
local f = io.open(machine_file, "r")
if f then
  local profile = f:read("*a"):gsub("%s+", "")
  f:close()
  if profile and profile ~= "" then
    hl.env("MACHINE_PROFILE", profile)
  else
    hl.env("MACHINE_PROFILE", "desktop")
  end
else
  hl.env("MACHINE_PROFILE", "desktop")
end

require("hyprland/services/create_custom_config")
