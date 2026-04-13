# Hyprland Configuration Notes for AI Agents

## Checking for Configuration Errors

To check for Hyprland configuration errors, use:

```bash
hyprctl configerrors
```

This command will display any syntax errors in your `hyprland.conf` file with line numbers and descriptions.

## Common Issues

### Window Rules Syntax (Hyprland 0.54+)

The `windowrule` syntax requires proper field names and values:

**Correct syntax:**
```ini
windowrule = float on, match:class ^(app-name)$
windowrule = pin on, match:class ^(app-name)$
windowrule = suppress_event maximize, match:class .*
windowrule = no_focus on, match:class ^$, match:title ^$
```

**Incorrect (will cause errors):**
```ini
windowrule = float, class:^(app-name)$  # Missing "on" value
windowrule = pin, class:^(app-name)$     # Missing "on" value
```

### Field Names

- Effects (static): `float on`, `pin on`, `fullscreen on`, etc.
- Effects (with args): `size W H`, `move X Y`, `suppress_event TYPES`
- Matchers: `match:class REGEX`, `match:title REGEX`, `match:float BOOL`, etc.

### Kanshi Display Profiles

This config uses kanshi for automatic display profile management. Profiles are defined in `~/.config/kanshi/config`.

**Always run `hyprctl configerrors` after making config changes to catch syntax issues immediately.**