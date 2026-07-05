# done.nu

Desktop notifications for long-running commands in Nushell.

## Prerequisites

- Linux: `notify-send` (libnotify)
- macOS: `osascript` (built-in) or `terminal-notifier`
- Sway, Niri, Mango, Kitty window detection: `jq`

## Add

```nu
cp done.nu ~/.config/nushell/

# Add to ~/.config/nushell/config.nu:
use ~/.config/nushell/done.nu
```

Restart nushell or run `use ~/.config/nushell/done.nu`.

## Configure

In `~/.config/nushell/config.nu`, you can set these before `use` to override defaults:

```nu
$env.DONE_MIN_DURATION = 10000          # min command duration (ms) to trigger notification (default: 5000)
$env.DONE_EXCLUDE = ['^vim ' '^ssh ']   # excluded commands (regex patterns)
$env.DONE_NOTIFICATION_DURATION = 5000  # notification timeout (ms), only when DAEMON_MODE=false (default: 3000)
$env.DONE_NOTIFICATION_DAEMON_MODE = false  # false=done.nu controls timeout, true=mako/dunst controls (default: false)
$env.DONE_KITTY_PASSWORD = ''             # Kitty remote control password if set

use ~/.config/nushell/done.nu
```

### Notification modes

**use mako/dunst config**

`~/.config/nushell/config.nu`:
```nu
$env.DONE_NOTIFICATION_DAEMON_MODE = true
use ~/.config/nushell/done.nu
```
`~/.config/mako/config`:
```
expire-in=30000
```

**use done.nu config**

`~/.config/nushell/config.nu`:
```nu
$env.DONE_NOTIFICATION_DAEMON_MODE = false
$env.DONE_NOTIFICATION_DURATION = 60000
use ~/.config/nushell/done.nu
```

## Remove

1. Remove the `use` line and config variables from `config.nu`
2. Delete `done.nu`
3. Stop immediately in current session: `$env.config.hooks.pre_prompt = []`
