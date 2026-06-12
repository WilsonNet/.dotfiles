local function has_external()
    local monitors = hl.get_monitors()
    for _, m in ipairs(monitors) do
        if m.name ~= "eDP-1" then
            return true
        end
    end
    return false
end

local function get_ext_descriptor()
    local monitors = hl.get_monitors()
    for _, m in ipairs(monitors) do
        if m.name ~= "eDP-1" then
            return m.description
        end
    end
    return nil
end

local function disable_laptop()
    hl.monitor({ output = "eDP-1", disabled = true })
end

local function enable_laptop()
    hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = "1.6" })
end

local function reapply()
    local has_ext = has_external()

    if has_ext then
        local desc = get_ext_descriptor()
        if desc and desc:find("LG ULTRAWIDE") then
            hl.monitor({ output = "desc:LG Electronics LG ULTRAWIDE 209AZPU4U744", mode = "3440x1440@84.96", position = "auto", scale = "1.333333" })
        elseif desc and desc:find("LG HDR WFHD") then
            hl.monitor({ output = "desc:LG Electronics LG HDR WFHD 0x01010101", mode = "2560x1080@74.99", position = "auto", scale = "1.333333" })
        end
        disable_laptop()
    else
        enable_laptop()
    end
end

hl.on("hyprland.start", reapply)
hl.on("monitor.added", reapply)
hl.on("monitor.removed", reapply)
