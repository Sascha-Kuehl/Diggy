local Gui = require 'utils.gui'

local torchlight_frame_name = Gui.uid_name()
local torchlight_enabled_button_name = Gui.uid_name()
local torchlight_flow_name = Gui.uid_name()
local torchlight_inventory_button_name = Gui.uid_name()
local torchlight_progressbar_name = Gui.uid_name()

local TorchlightGui = {}

function TorchlightGui.is_light_enabled(player)
    return player.gui.screen[torchlight_frame_name][torchlight_enabled_button_name].toggled
end

function TorchlightGui.set_visible(player, visible)
    player.gui.screen[torchlight_frame_name].visible = visible
end

function TorchlightGui.register_click_handlers(on_enabled_button_clicked, on_inventory_button_clicked)
    Gui.on_click(torchlight_enabled_button_name, on_enabled_button_clicked)
    Gui.on_click(torchlight_inventory_button_name, on_inventory_button_clicked)
end

function TorchlightGui.realign_torchlight_frame(player)
    local frame = player.gui.screen[torchlight_frame_name]

    local resolution = player.display_resolution
    local scale = player.display_scale

    frame.location = { 190 * scale, resolution.height - (96 * scale) }
end

function TorchlightGui.update_torchlight_progressbar(player, remaining_ticks, afterburner_ticks, ticks_per_wood)
    local progressbar = player.gui.screen[torchlight_frame_name][torchlight_flow_name][torchlight_progressbar_name]

    local remaining_percent = (remaining_ticks - afterburner_ticks) / ticks_per_wood
    if (remaining_percent < 0) then
        remaining_percent = 0
    end

    progressbar.value = remaining_percent
    progressbar.tooltip = tostring(remaining_percent * ticks_per_wood / 60) .. ' sec'
end

function TorchlightGui.create_gui_button(player, enabled)
    local frame = player.gui.screen.add {
        type = 'frame',
        name = torchlight_frame_name,
        direction = 'vertical'
    }
    frame.style.padding = 0

    local enabled_button = frame.add {
        type = 'sprite-button',
        name = torchlight_enabled_button_name,
        tooltip = 'Switch light on/off',
        sprite = 'virtual-signal/signal-sun',
        auto_toggle = true,
        toggled = enabled,
        style = 'quick_bar_page_button'
    }
    enabled_button.style.width = 38
    enabled_button.style.height = 38

    local flow = frame.add {
        type = 'flow',
        name = torchlight_flow_name,
        direction = 'vertical'
    }
    flow.style.vertical_spacing = 0

    local slot_button = flow.add {
        type = 'sprite-button',
        name = torchlight_inventory_button_name,
        sprite = 'virtual-signal/signal-fire',
        style = 'tool_equip_ammo_slot'
    }
    slot_button.style.width = 38
    slot_button.style.height = 38

    local progressbar = flow.add {
        type = 'progressbar',
        name = torchlight_progressbar_name,
        value = 0.0
    }
    progressbar.style.width = 38

    TorchlightGui.realign_torchlight_frame(player)
end

function TorchlightGui.update_inventory_button(player, inventory)
    local inventory_button = player.gui.screen[torchlight_frame_name][torchlight_flow_name][torchlight_inventory_button_name]

    local stack = inventory[1];

    if (stack.count == 0) then
        inventory_button.sprite = 'virtual-signal/signal-fire'
        inventory_button.number = nil
    else
        inventory_button.sprite = 'item/' .. stack.name
        inventory_button.number = stack.count
    end
end

return TorchlightGui
