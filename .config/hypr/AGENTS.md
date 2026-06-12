# Hyprland Configuration Notes for AI Agents

## Config Format

Hyprland now uses Lua (hyprland.lua) instead of hyprlang (hyprland.conf). The old config is backed up at `hyprland.conf.bak`.

## Module Structure

The config is modularized into `modules/`:

| File | Purpose |
|---|---|
| `modules/vars.lua` | Shared variables (program paths, mod key) |
| `modules/env.lua` | Environment variables and autostart |
| `modules/settings.lua` | Look/feel: general, decoration, input, device config |
| `modules/animations.lua` | Animation curves and animation settings |
| `modules/keybinds.lua` | All keybindings and bind options |
| `modules/window-rules.lua` | Window rules (float, size, position, events) |

To add a new module, create `modules/myfeature.lua` and add `require("modules.myfeature")` to `hyprland.lua`.

Note: `require` uses Lua's standard module caching. On config reload, Hyprland clears the require cache so changes take effect.

## Checking for Configuration Errors

```bash
hyprctl configerrors
```

To validate Lua syntax:
```bash
luac -p ~/.config/hypr/hyprland.lua
```

The Lua stubs are at `/usr/share/hypr/stubs/hl.meta.lua` — set up your LSP to use them for autocompletions.

## Lua Config API Reference

### Core Functions

| Function | Purpose |
|---|---|
| `hl.config({...})` | Set config blocks (general, decoration, input, misc, etc.) |
| `hl.bind(key, dispatcher, opts?)` | Keybindings (returns `HL.Keybind` handle) |
| `hl.window_rule({...})` | Window rules (returns `HL.WindowRule` handle) |
| `hl.layer_rule({...})` | Layer surface rules |
| `hl.workspace_rule({...})` | Workspace rules |
| `hl.monitor({...})` | Monitor configuration |
| `hl.device({...})` | Per-device input config |
| `hl.curve(name, {...})` | Define animation curves |
| `hl.animation({leaf, ...})` | Animation settings |
| `hl.gesture({...})` | Touch gestures |
| `hl.env(key, value)` | Environment variables |
| `hl.exec_cmd(cmd)` | Run command at startup (use inside `hl.on(...)` |
| `hl.on(event, fn)` | Subscribe to events (returns subscription handle) |
| `hl.timer(fn, opts)` | Create timers |
| `hl.dispatch(dispatcher)` | Execute a dispatcher |
| `hl.get_monitors()` | Query monitor info |
| `hl.get_windows()` | Query window info |
| `hl.get_active_window()` | Get focused window |
| `hl.get_config(key)` | Get config value at runtime |
| `hl.notification.create({...})` | Create desktop notifications |

### Dispatchers (hl.dsp.*)

```lua
-- Focus / Workspace
hl.dsp.focus({ direction = "left"|"right"|"up"|"down" })
hl.dsp.focus({ workspace = id|"e+1"|"e-1" })

-- Window operations
hl.dsp.window.close()
hl.dsp.window.float({ action = "toggle" })
hl.dsp.window.fullscreen()
hl.dsp.window.pin()
hl.dsp.window.pseudo()
hl.dsp.window.move({ workspace = id|"special:name" })
hl.dsp.window.drag()     -- for mouse bindings
hl.dsp.window.resize()   -- for mouse bindings
hl.dsp.window.center()
hl.dsp.window.deny_from_group()  -- moveoutofgroup

-- Group operations
hl.dsp.group.toggle()
hl.dsp.group.next()     -- changegroupactive f
hl.dsp.group.prev()     -- changegroupactive b
hl.dsp.group.lock_active({ action = "toggle" })

-- Special workspaces
hl.dsp.workspace.toggle_special("name")

-- Layout messages
hl.dsp.layout("togglesplit")  -- dwindle only

-- Execute commands
hl.dsp.exec_cmd("command")

-- Mouse bindings (bindm)
hl.bind("mod + mouse:272", hl.dsp.window.drag(), { mouse = true })
```

### Bind Options

```lua
-- bindl (locked) equivalent
{ locked = true }

-- bindel (locked + repeating) equivalent  
{ locked = true, repeating = true }

-- bindm (mouse) equivalent
{ mouse = true }
```

### Window Rules

```lua
hl.window_rule({
    name  = "rule-name",                    -- required for identification
    match = { class = "regex", title = "regex", xwayland = true, ... },
    float = true,
    size  = "WxH" or "W H",
    move  = "X Y",
    pin   = true,
    no_focus = true,
    no_initial_focus = true,
    suppress_event = "maximize",
    border_size = 0,
    rounding = 0,
})
```

### Config Blocks

```lua
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(...)", "rgba(...)"}, angle = 45 },
            inactive_border = "rgba(...)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        shadow = {
            enabled = true,
            color  = 0xee1a1a1a,   -- or "rgba(...)"
        },
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
        },
    },
    input = {
        kb_layout  = "us",
        kb_variant = "",
        touchpad = {
            natural_scroll = false,
        },
    },
    misc = {
        force_default_wallpaper = -1,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    xwayland = {
        force_zero_scaling = true,
    },
})
```

### Animations

```lua
hl.curve("name", { type = "bezier", points = { {x1, y1}, {x2, y2} } })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint", style = "popin 87%" })
```

### Autostart

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
end)
```