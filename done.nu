# done.nu — Desktop notifications for long-running commands in Nushell
#
# Usage:  use done.nu
# Hooks are auto-installed. Configurable via $env.DONE_* variables.
#
# Inspired by fish's 'done' plugin (franciscolourenco/done).

export-env {
    # — config defaults ———————————————————————————————————————

    $env.DONE_MIN_DURATION = ($env.DONE_MIN_DURATION? | default 5000)
    $env.DONE_EXCLUDE = ($env.DONE_EXCLUDE? | default [
        '^git (?!push|pull|fetch|clone)'
        '^vim '
        '^nvim '
        '^less '
        '^man '
        '^top$'
        '^htop$'
        '^btm$'
    ])
    $env.DONE_NOTIFICATION_DURATION = ($env.DONE_NOTIFICATION_DURATION? | default 3000)
    $env.DONE_NOTIFICATION_DAEMON_MODE = ($env.DONE_NOTIFICATION_DAEMON_MODE? | default false)
    $env.DONE_KITTY_PASSWORD = ($env.DONE_KITTY_PASSWORD? | default '')

    # — pre_execution: record current window before command ——---

    $env.config.hooks.pre_execution = (
        $env.config.hooks.pre_execution | default [] | append {||
            $env.DONE_LAST_CMD = (commandline | str trim)
            $env.DONE_INITIAL_WINDOW_ID = (
                if (which lsappinfo | is-not-empty) {
                    ^lsappinfo info -only bundleID (^lsappinfo front | str replace 'ASN:0x0-' '0x') | cut -d '"' -f4 | str trim
                } else if (which swaymsg | is-not-empty) and ($env.SWAYSOCK? | is-not-empty) and (which jq | is-not-empty) {
                    ^swaymsg --type get_tree | ^jq '.. | objects | select(.focused == true) | .id' | str trim
                } else if (which hyprctl | is-not-empty) and ($env.HYPRLAND_INSTANCE_SIGNATURE? | is-not-empty) {
                    ^hyprctl activewindow | awk 'NR==1 {print $2}' | str trim
                } else if (which niri | is-not-empty) and ($env.NIRI_SOCKET? | is-not-empty) and (which jq | is-not-empty) {
                    ^niri msg --json focused-window | ^jq '.id' | str trim
                } else if (which mmsg | is-not-empty) and ($env.MANGO_INSTANCE_SIGNATURE? | is-not-empty) and (which jq | is-not-empty) {
                    ^mmsg get focusing-client | ^jq '.id' | str trim
                } else if ($env.XDG_SESSION_DESKTOP? | default '') == 'gnome' and (which gdbus | is-not-empty) {
                    ^gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'global.display.focus_window.get_id()' | str replace -r ".*'([0-9]+)'.*" '$1' | str trim
                } else if ($env.KITTY_PID? | is-not-empty) and (which kitty | is-not-empty) and (which jq | is-not-empty) {
                    if ($env.DONE_KITTY_PASSWORD? | default '' | is-not-empty) {
                        ^kitty @ --password=($env.DONE_KITTY_PASSWORD) ls | ^jq -r '.[].tabs[] | select(any(.windows[]; .is_self)) | .id' | str trim
                    } else {
                        ^kitty @ ls | ^jq -r '.[].tabs[] | select(any(.windows[]; .is_self)) | .id' | str trim
                    }
                } else if (which xprop | is-not-empty) and ($env.DISPLAY? | is-not-empty) {
                    ^xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}' | str trim
                } else if ($env.TMUX? | is-not-empty) and (which tmux | is-not-empty) {
                    '__tmux__'
                } else if ($env.STY? | is-not-empty) and (which screen | is-not-empty) {
                    '__screen__'
                } else if (^uname -a | str contains -i 'microsoft') {
                    ^powershell.exe -Command "Add-Type -Name WinCompat -Namespace Demo -MemberDefinition '[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();'; [Demo.WinCompat]::GetForegroundWindow()" | str trim
                } else {
                    '__no_wm__'
                }
            )
        }
    )

    # — pre_prompt: check duration, focus, exclude; then notify —

    $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt | default [] | append {||
            let dur = ($env.CMD_DURATION_MS? | default 0 | into int)
            if $dur == 0 or $dur <= ($env.DONE_MIN_DURATION | into int) {
                return
            }

            let last_cmd = ($env.DONE_LAST_CMD? | default 'unknown')

            mut skip = false
            for p in ($env.DONE_EXCLUDE | default []) {
                if ($last_cmd =~ $p) { $skip = true; break }
            }
            if $skip { return }

            # —— window focus detection ————————————————————————

            let current_win = (
                if (which lsappinfo | is-not-empty) {
                    ^lsappinfo info -only bundleID (^lsappinfo front | str replace 'ASN:0x0-' '0x') | cut -d '"' -f4 | str trim
                } else if (which swaymsg | is-not-empty) and ($env.SWAYSOCK? | is-not-empty) and (which jq | is-not-empty) {
                    ^swaymsg --type get_tree | ^jq '.. | objects | select(.focused == true) | .id' | str trim
                } else if (which hyprctl | is-not-empty) and ($env.HYPRLAND_INSTANCE_SIGNATURE? | is-not-empty) {
                    ^hyprctl activewindow | awk 'NR==1 {print $2}' | str trim
                } else if (which niri | is-not-empty) and ($env.NIRI_SOCKET? | is-not-empty) and (which jq | is-not-empty) {
                    ^niri msg --json focused-window | ^jq '.id' | str trim
                } else if (which mmsg | is-not-empty) and ($env.MANGO_INSTANCE_SIGNATURE? | is-not-empty) and (which jq | is-not-empty) {
                    ^mmsg get focusing-client | ^jq '.id' | str trim
                } else if ($env.XDG_SESSION_DESKTOP? | default '') == 'gnome' and (which gdbus | is-not-empty) {
                    ^gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'global.display.focus_window.get_id()' | str replace -r ".*'([0-9]+)'.*" '$1' | str trim
                } else if ($env.KITTY_PID? | is-not-empty) and (which kitty | is-not-empty) and (which jq | is-not-empty) {
                    if ($env.DONE_KITTY_PASSWORD? | default '' | is-not-empty) {
                        ^kitty @ --password=($env.DONE_KITTY_PASSWORD) ls | ^jq -r '.[].tabs[] | select(any(.windows[]; .is_self)) | .id' | str trim
                    } else {
                        ^kitty @ ls | ^jq -r '.[].tabs[] | select(any(.windows[]; .is_self)) | .id' | str trim
                    }
                } else if (which xprop | is-not-empty) and ($env.DISPLAY? | is-not-empty) {
                    ^xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}' | str trim
                } else if ($env.TMUX? | is-not-empty) and (which tmux | is-not-empty) {
                    '__tmux__'
                } else if ($env.STY? | is-not-empty) and (which screen | is-not-empty) {
                    '__screen__'
                } else if (^uname -a | str contains -i 'microsoft') {
                    ^powershell.exe -Command "Add-Type -Name WinCompat -Namespace Demo -MemberDefinition '[DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();'; [Demo.WinCompat]::GetForegroundWindow()" | str trim
                } else {
                    '__no_wm__'
                }
            )
            let initial = ($env.DONE_INITIAL_WINDOW_ID? | default '')

            # Skip only if window is still focused.
            # For multiplexers, also check pane/window focus.
            if $initial != '' and $initial != '0x0' and $current_win == $initial {
                if ($env.TMUX? | is-not-empty) and (which tmux | is-not-empty) {
                    mut active = false
                    for l in (^tmux list-panes -a -F '#{session_attached} #{window_active} #{pane_pid}' | lines) {
                        if ($l | str starts-with '1 1 ') { $active = true; break }
                    }
                    if $active { return }
                } else if ($env.STY? | is-not-empty) and (which screen | is-not-empty) {
                    if (^screen -ls | str contains '(Attached)') { return }
                } else {
                    return
                }
            }

            # —— build notification ————————————————————————————

            let exit_code = ($env.LAST_EXIT_CODE? | default 0 | into int)
            let secs = ($dur // 1000) mod 60
            let mins = ($dur // 60000) mod 60
            let hours = $dur // 3600000

            mut parts = []
            if $hours > 0 { $parts = ($parts | append $"($hours)h") }
            if $mins > 0 { $parts = ($parts | append $"($mins)m") }
            $parts = ($parts | append $"($secs)s")
            let humanized = ($parts | str join ' ')

            let wd = ($env.PWD | str replace $env.HOME '~')

            let title = if $exit_code != 0 {
                $"Failed \(($exit_code)\) after ($humanized)"
            } else {
                $"Done in ($humanized)"
            }
            let message = if ($env.TMUX_PANE? | is-not-empty) and (which tmux | is-not-empty) {
                let pane_label = (^tmux lsw -F '[#{window_index}]' -f $"#{==:#{pane_id},($env.TMUX_PANE)}" | str trim)
                $"($pane_label) ($wd)/ ($last_cmd)"
            } else {
                $"($wd)/ ($last_cmd)"
            }

            # —— send notification ——————————————————————————————
            # Matches fish-done's backend priority: Kitty → Ghostty/WezTerm
            # → iTerm2 → terminal-notifier → osascript → notify-send
            # → Windows Toast → bell

            if ($env.KITTY_WINDOW_ID? | is-not-empty) {
                print -n $"\e]99;i=done:d=0;($title)\e\\"
                print -n $"\e]99;i=done:d=1:p=body;($message)\e\\"
            } else if ($env.TERM_PROGRAM? | default '') in ['ghostty' 'WezTerm'] {
                print -n $"\e]777;notify;($title);($message)\e\\"
            } else if ($env.TERM_PROGRAM? | default '') == 'iTerm.app' {
                print -n $"\e]9;($title): ($message)\e\\"
            } else if (which terminal-notifier | is-not-empty) {
                ^terminal-notifier -title $title -message $message
            } else if (which osascript | is-not-empty) {
                ^osascript -e $"display notification \"($message | str replace -a '\"' '\\\"')\" with title \"($title | str replace -a '\"' '\\\"')\""
            } else if (which notify-send | is-not-empty) {
                let urgency = if $exit_code != 0 { 'critical' } else { 'normal' }
                let daemon_mode = ($env.DONE_NOTIFICATION_DAEMON_MODE? | default false)
                mut notify_args = [$"--urgency=($urgency)", "--icon=utilities-terminal", "--app-name=nushell"]
                if not $daemon_mode {
                    $notify_args = ($notify_args | append $"--expire-time=($env.DONE_NOTIFICATION_DURATION)")
                }
                $notify_args = ($notify_args | append [$title, $message])
                ^notify-send ...$notify_args
            } else if (^uname -a | str contains -i 'microsoft') {
                ^powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('nushell').Show((New-Object Windows.UI.Notifications.ToastNotification (New-Object Windows.Data.Xml.Dom.XmlDocument)))"
            } else {
                print -n "\a"
            }
        }
    )
}

# — manual notification ———————————————————————————————————————

export def notify [
    title: string
    body: string
] {
    if ($env.KITTY_WINDOW_ID? | is-not-empty) {
        print -n $"\e]99;i=done:d=0;($title)\e\\"
        print -n $"\e]99;i=done:d=1:p=body;($body)\e\\"
    } else if ($env.TERM_PROGRAM? | default '') in ['ghostty' 'WezTerm'] {
        print -n $"\e]777;notify;($title);($body)\e\\"
    } else if ($env.TERM_PROGRAM? | default '') == 'iTerm.app' {
        print -n $"\e]9;($title): ($body)\e\\"
    } else if (which terminal-notifier | is-not-empty) {
        ^terminal-notifier -title $title -message $body
    } else if (which osascript | is-not-empty) {
        ^osascript -e $"display notification \"($body | str replace -a '\"' '\\\"')\" with title \"($title | str replace -a '\"' '\\\"')\""
    } else if (which notify-send | is-not-empty) {
        let daemon_mode = ($env.DONE_NOTIFICATION_DAEMON_MODE? | default false)
        mut notify_args = ["--urgency=normal", "--icon=utilities-terminal", "--app-name=nushell"]
        if not $daemon_mode {
            $notify_args = ($notify_args | append $"--expire-time=($env.DONE_NOTIFICATION_DURATION)")
        }
        $notify_args = ($notify_args | append [$title, $body])
        ^notify-send ...$notify_args
    } else {
        print -n "\a"
    }
}

# — status ——————————————————————————————————————————————————————

export def status [] {
    print $"done: threshold = ($env.DONE_MIN_DURATION)ms"
    print $"done: notification duration = ($env.DONE_NOTIFICATION_DURATION)ms"
    let mode = if ($env.DONE_NOTIFICATION_DAEMON_MODE? | default false) { "daemon (passthrough)" } else { "override (own timeout)" }
    print $"done: notification mode = ($mode)"
    print "done: excluded patterns:"
    for p in ($env.DONE_EXCLUDE) {
        print $"  - ($p)"
    }
}
