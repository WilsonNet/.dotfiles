local vars = require("modules.vars")
local mainMod = vars.mainMod

hl.bind(mainMod .. " + RETURN",              hl.dsp.exec_cmd(vars.terminal))
hl.bind(mainMod .. " + SHIFT + C",           hl.dsp.window.close())
hl.bind(mainMod .. " + M",                   hl.dsp.exec_cmd("pavucontrol"))
hl.bind(mainMod .. " + E",                   hl.dsp.exec_cmd(vars.fileManager))
hl.bind(mainMod .. " + V",                   hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R",                   hl.dsp.exec_cmd(vars.menu))
hl.bind(mainMod .. " + P",                   hl.dsp.window.pseudo())
hl.bind(mainMod .. " + down",               hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + T",                   hl.dsp.window.pin())
hl.bind(mainMod .. " + B",                   hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. " + SHIFT + S",           hl.dsp.exec_cmd("transformers_ocr recognize"))
hl.bind("Print",                             hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + W",                   hl.dsp.exec_cmd("rofi -show window"))
hl.bind(mainMod .. " + L",                   hl.dsp.exec_cmd("sleep 1 && systemctl suspend"))
hl.bind(mainMod .. " + F",                   hl.dsp.window.fullscreen())

hl.bind(mainMod .. " + G",                   hl.dsp.group.toggle())
hl.bind(mainMod .. " + Tab",                 hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + Tab",         hl.dsp.group.prev())
hl.bind(mainMod .. " + SHIFT + G",           hl.dsp.window.deny_from_group())
hl.bind(mainMod .. " + CTRL + G",            hl.dsp.group.lock_active({ action = "toggle" }))

hl.bind(mainMod .. " + SHIFT + D",           hl.dsp.exec_cmd("bash /home/wilsonn/bin/ames.sh -s"))
hl.bind(mainMod .. " + SHIFT + A",           hl.dsp.exec_cmd("bash /home/wilsonn/bin/ames.sh -r"))
hl.bind(mainMod .. " + SHIFT + Z",           hl.dsp.exec_cmd("bash /home/wilsonn/bin/ames.sh -c"))

hl.bind(mainMod .. " + h",                   hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j",                   hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k",                   hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l",                   hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("F8",                                hl.dsp.focus({ workspace = 8 }))
hl.bind("F9",                                hl.dsp.focus({ workspace = 9 }))

hl.bind(mainMod .. " + Y",                   hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + Y",           hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd(
    [[hyprctl eval '
for _, m in ipairs(hl.get_monitors()) do
  if m.name ~= "eDP-1" and m.description then
    if m.description:find("LG ULTRAWIDE") then
      hl.monitor({output="desc:LG Electronics LG ULTRAWIDE 209AZPU4U744", mode="2560x1440@120", position="auto", scale="1.333333"})
    elseif m.description:find("LG HDR WFHD") then
      hl.monitor({output="desc:LG Electronics LG HDR WFHD 0x01010101", mode="1920x1080@60", position="auto", scale="1.333333"})
    end
    break
  end
end
']]
))
hl.bind(mainMod .. " + CTRL + U", hl.dsp.exec_cmd(
    [[hyprctl eval '
for _, m in ipairs(hl.get_monitors()) do
  if m.name ~= "eDP-1" and m.description then
    if m.description:find("LG ULTRAWIDE") then
      hl.monitor({output="desc:LG Electronics LG ULTRAWIDE 209AZPU4U744", mode="3440x1440@84.96", position="auto", scale="1.333333"})
    elseif m.description:find("LG HDR WFHD") then
      hl.monitor({output="desc:LG Electronics LG HDR WFHD 0x01010101", mode="2560x1080@74.99", position="auto", scale="1.333333"})
    end
    break
  end
end
']]
))

hl.bind(mainMod .. " + mouse_down",          hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",            hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272",           hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",           hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",             hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",             hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { locked = true, repeating = true })
hl.bind("XF86AudioMute",                    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",                 hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",              hl.dsp.exec_cmd("brightnessctl s 10%+"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",            hl.dsp.exec_cmd("brightnessctl s 10%-"),                        { locked = true, repeating = true })

hl.bind("XF86AudioNext",                    hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause",                   hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",                    hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",                    hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(
    [[hyprctl eval 'hl.monitor({output="eDP-1", disabled=true})']]
), { locked = true })

hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(
    [[hyprctl eval 'hl.monitor({output="eDP-1", mode="preferred", position="auto", scale="1.6"})']]
), { locked = true })
