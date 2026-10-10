# XDG_RUNTIME_DIR — required by quickshell and many Wayland apps
set -gx XDG_RUNTIME_DIR /run/user/(id -u)

# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use oh-my-posh with atomic theme
    if test "$TERM" != "linux"
        if test -f /usr/share/oh-my-posh/themes/atomic.omp.json
            oh-my-posh init fish --config /usr/share/oh-my-posh/themes/atomic.omp.json | source
        else
            eval (oh-my-posh init fish | string split '\n')
        end
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end

    # ===== Enhanced keybindings =====
    # Ctrl+Z: toggle background job (fg if stopped, bg if running)
    function __toggle-bg
        if jobs -l | string match -rq '^\s+\[.*\]\s+'
            fg 2>/dev/null; and return
        end
        commandline -f execute \cz
    end
    bind -M insert \cz __toggle-bg
    bind -M visual \cz __toggle-bg

    # Alt+Left: backward word
    bind -M insert \e\[1\;3D backward-word
    # Alt+Right: forward word
    bind -M insert \e\[1\;3C forward-word
    # Alt+Backspace: kill word backward
    bind -M insert \e\[27\;3\x7f kill-word
    # Alt+D: kill word forward
    bind -M insert \e\d kill-word
end
