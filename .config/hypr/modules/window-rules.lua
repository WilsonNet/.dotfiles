hl.window_rule({
    name  = "youtube-thorium",
    match = { class = ".*thorium.*", title = ".*YouTube.*" },
    float = true,
    size  = "640 360",
    move  = "100%-660 100%-380",
    pin   = true,
})

hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "ardour-no-initial-focus",
    match = { class = "^Ardour.*$" },
    no_initial_focus = true,
})
