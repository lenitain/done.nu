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

In `~/.config/nushell/config.nu`, set these before the `use` line:

```nu
$env.DONE_MIN_DURATION = 10000          # minimum duration in ms (default: 5000)
$env.DONE_EXCLUDE = ['^vim ' '^ssh ']   # excluded commands (regex)
$env.DONE_NOTIFICATION_DURATION = 5000  # notification timeout in ms (default: 3000)
$env.DONE_KITTY_PASSWORD = ''             # Kitty remote control password if set

use ~/.config/nushell/done.nu
```

## Remove

1. Remove the `use` line and config variables from `config.nu`
2. Delete `done.nu`
3. Stop immediately in current session: `$env.config.hooks.pre_prompt = []`
