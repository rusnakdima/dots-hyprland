# dots-extra — manual installation steps

This directory holds optional components that must be installed manually
because they require `sudo` or are machine-specific.

---

## Keyboard RGB backlight (`dots-extra/etc/udev/rules.d/90-kbd-backlight.rules`)

The Quickshell `KeyboardBacklight` service writes to
`/sys/class/leds/rgb:kbd_backlight/multi_intensity` to change the keyboard
backlight color. By default this sysfs node is owned by `root:root` with mode
`0644`, so non-root users cannot write to it.

The udev rule in this directory fixes the permissions so that members of the
`input` group can write without `sudo`:

```bash
# 1. Install the rule
sudo install -Dm644 etc/udev/rules.d/90-kbd-backlight.rules \
    /etc/udev/rules.d/90-kbd-backlight.rules

# 2. Reload udev so the rule takes effect immediately
sudo udevadm control --reload-rules && sudo udevadm trigger

# 3. Verify your user is in the `input` group
groups | grep input   # should show 'input'
# If not: sudo usermod -aG input "$USER" then log out and back in

# 4. Verify permissions are correct
ls -l /sys/class/leds/rgb:kbd_backlight/multi_intensity
# Expected: -rw-rw-r-- 1 root input ... /sys/.../multi_intensity
```

After this the keyboard backlight color can be changed from Settings →
Appearance or from the sidebarRight panel without any password prompt.

---

## TUXEDO / QC71 keyboard backlight (hardware-specific)

The rule above applies to any LED device named `rgb:kbd_backlight`, which
covers the TUXEDO/QC71 laptops found on this system. If your hardware uses a
different LED name you will need to adjust the `KERNEL==` match accordingly.
