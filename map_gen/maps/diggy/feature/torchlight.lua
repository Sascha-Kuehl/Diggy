local Event = require 'utils.event'
local TorchlightData = require 'map_gen.maps.diggy.feature.torchlight.torchlight_data'
local TorchlightLights = require 'map_gen.maps.diggy.feature.torchlight.torchlight_lights'
local TorchlightGui = require 'map_gen.maps.diggy.feature.torchlight.torchlight_gui'
local InventoryTransferUtil = require 'map_gen.maps.diggy.feature.torchlight.inventory_transfer_util'

local TICK_INTERVAL = 60
local TICKS_PER_WOOD = 60 * 60 * 1
local AFTERBURNER_TICKS = 60 * 17
local INITIAL_WOOD_COUNT = 10

local Torchlight = {}

function Torchlight.on_player_created(event)
    local player = game.get_player(event.player_index)
    player.disable_flashlight()

    Torchlight.create_or_restore_player_light(player)
    Torchlight.create_player_torchlight_inventory(player)
    TorchlightGui.create_gui_button(player, true)
    Torchlight.update_player_light(player)
end

function Torchlight.on_player_respawned(event)
    local player = game.get_player(event.player_index)
    player.disable_flashlight()

    Torchlight.create_or_restore_player_light(player)
    Torchlight.update_player_light(player)
    TorchlightGui.set_visible(player, true)
end

function Torchlight.on_player_joined_game(event)
    local player = game.get_player(event.player_index)

    Torchlight.create_or_restore_player_light(player)
    Torchlight.update_player_light(player)
end

function Torchlight.on_pre_player_died(event)
    local player = game.get_player(event.player_index)
    player.character_inventory_slots_bonus = player.character_inventory_slots_bonus + 1
    local inventory = TorchlightData.get_player_inventory(player.index)
    local torchlight_stack = inventory[1]
    player.character.get_main_inventory().find_empty_stack().transfer_stack(torchlight_stack)
end

function Torchlight.build_corpse_id(corpse)
    return tostring(corpse.character_corpse_player_index) .. '-' .. tostring(corpse.character_corpse_tick_of_death)
end

function Torchlight.on_player_died(event)
    local player = game.get_player(event.player_index)

    player.character_inventory_slots_bonus = player.character_inventory_slots_bonus - 1

    local corpses = player.surface.find_entities_filtered({name = 'character-corpse', position = player.position})
    local corpse
    for _, a_corpse in pairs(corpses) do
        if a_corpse.character_corpse_player_index == player.index and a_corpse.character_corpse_tick_of_death == event.tick then
            corpse = a_corpse
            break
        end
    end
    if not corpse then
        return
    end
    local corpse_id = Torchlight.build_corpse_id(corpse)

    local light_data = TorchlightData.get_player_light_info(player.index)

    local corpse_light_data = {
        remaining_ticks = light_data.remaining_ticks,
        light_ids = Torchlight.create_light_ids(corpse, player.surface)
    }
    TorchlightData.set_corpse_light_data(corpse_id, corpse_light_data)
    
    light_data.remaining_ticks = 0
    Torchlight.update_player_light(player)
    Torchlight.update_corpse_light(corpse_id)
    TorchlightGui.set_visible(player, false)
end

function Torchlight.on_tick()
    if game.tick % TICK_INTERVAL ~= 0 then
        return
    end
    Torchlight.update_player_lights_on_tick()
    Torchlight.update_corpse_lights_on_tick()
end

function Torchlight.on_torchlight_button_pressed(event)
    local player = event.player
    Torchlight.update_player_light(player)
end

function Torchlight.on_player_display_resolution_changed(event)
    local player = game.get_player(event.player_index)
    TorchlightGui.realign_torchlight_frame(player)
end

function Torchlight.on_player_display_scale_changed(event)
    local player = game.get_player(event.player_index)
    TorchlightGui.realign_torchlight_frame(player)
end

function Torchlight.on_torchlight_fuel_pressed(event)
    local player = game.get_player(event.player_index)
    local inventory = TorchlightData.get_player_inventory(player.index)
    InventoryTransferUtil.handle_inventory_slot_click(inventory, inventory[1], event, { 'wood' })
    TorchlightGui.update_inventory_button(player, inventory)
end

function Torchlight.create_or_restore_player_light(player)
    local light_data = TorchlightData.get_player_light_info(player.index)

    if not light_data then
        local light_ids = Torchlight.create_light_ids(player.character, player.surface)
        light_data = TorchlightData.create_player_light_data(light_ids)
        TorchlightData.set_player_light_data(player.index, light_data)
        return
    end

    Torchlight.restore_missing_lights(light_data, player.character, player.surface)
end

function Torchlight.create_player_torchlight_inventory(player)
    local inventory = game.create_inventory(1)
    inventory.insert({ name = 'wood', count = INITIAL_WOOD_COUNT })
    TorchlightData.set_torchlight_inventory(player.index, inventory)
end

function Torchlight.update_player_light(player)
    if player.ticks_to_respawn then
        return
    end

    local light_data = TorchlightData.get_player_light_info(player.index)
    local inventory = TorchlightData.get_player_inventory(player.index)
    local enabled = TorchlightGui.is_light_enabled(player)

    -- the light is burning and has enough "fuel"
    -- or player has deactivated the light, so we will not burn more wood
    if light_data.remaining_ticks > AFTERBURNER_TICKS or not enabled then
        TorchlightLights.update_light(light_data, light_data.remaining_ticks, AFTERBURNER_TICKS)
        return
    end

    local woodCount = inventory.get_item_count('wood')

    -- player has wood, so we can burn it
    if woodCount > 0 then
        inventory.remove({ name = 'wood', count = 1 })
        light_data.remaining_ticks = TICKS_PER_WOOD + AFTERBURNER_TICKS
    end

    TorchlightLights.update_light(light_data, light_data.remaining_ticks, AFTERBURNER_TICKS)
    TorchlightGui.update_inventory_button(player, inventory)
end

function Torchlight.update_player_lights_on_tick()
    for _, player in pairs(game.connected_players) do
        local light_data = TorchlightData.get_player_light_info(player.index)
        light_data.remaining_ticks = light_data.remaining_ticks - TICK_INTERVAL
        if light_data.remaining_ticks <= 0 then
            light_data.remaining_ticks = 0
        end
        Torchlight.update_player_light(player)
        TorchlightGui.update_torchlight_progressbar(player, light_data.remaining_ticks, AFTERBURNER_TICKS, TICKS_PER_WOOD)

        local enabled = TorchlightGui.is_light_enabled(player)
        -- player runs out of wood so we show a message
        if enabled
                and light_data.remaining_ticks > 0
                and light_data.remaining_ticks < AFTERBURNER_TICKS
                and light_data.remaining_ticks % 180 == 0 then
            player.create_local_flying_text {
                text = 'no more wood',
                surface = player.surface,
                position = player.character.position,
                color = { 250, 0, 0 }
            }
        end
    end
end

function Torchlight.update_corpse_light(corpse_id)
    local light_data = TorchlightData.get_corpse_light_info(corpse_id)

    if not light_data then
        return
    end

    if light_data.remaining_ticks > 0 then
        TorchlightLights.update_light(light_data, light_data.remaining_ticks, AFTERBURNER_TICKS)
        return
    end

    -- light burned out
    TorchlightLights.destroy_lights(light_data.light_ids)
    TorchlightData.remove_corpse_light_data(corpse_id)
end

function Torchlight.update_corpse_lights_on_tick()
    local corpse_light_data = TorchlightData.get_corpse_light_data()
    for corpse_id, light_data in pairs(corpse_light_data) do
        light_data.remaining_ticks = light_data.remaining_ticks - TICK_INTERVAL
        Torchlight.update_corpse_light(corpse_id)
    end
end

function Torchlight.move_wood_to_torchlight_inventory(player, corpse)
    local corpse_inventory = corpse.get_inventory(defines.inventory.character_corpse)
    local torchlight_inventory = TorchlightData.get_player_inventory(player.index)
    local wood_stack = corpse_inventory.find_item_stack('wood')
    if wood_stack and wood_stack.valid_for_read then
        torchlight_inventory[1].transfer_stack(wood_stack)
        TorchlightGui.update_inventory_button(player, torchlight_inventory)
    end
end

function Torchlight.takeover_remaining_torchlight_time(player, corpse)
    local corpse_id = Torchlight.build_corpse_id(corpse)
    local corpse_light_data = TorchlightData.get_corpse_light_info(corpse_id)
    local player_light_data = TorchlightData.get_player_light_info(player.index)
    if not corpse_light_data or not player_light_data then
        return
    end

    player_light_data.remaining_ticks = player_light_data.remaining_ticks + corpse_light_data.remaining_ticks
    TorchlightData.remove_corpse_light_data(corpse_id)
    TorchlightGui.update_torchlight_progressbar(player, player_light_data.remaining_ticks, AFTERBURNER_TICKS, TICKS_PER_WOOD)
end

function Torchlight.on_player_mined_entity(event)
    if event.entity and event.entity.type == 'character-corpse' then
        local player = game.get_player(event.player_index)
        Torchlight.takeover_remaining_torchlight_time(player, event.entity)
        Torchlight.update_player_light(player)
    end
end

function Torchlight.on_pre_player_mined_item(event)
    if event.entity and event.entity.type == 'character-corpse' then
        local player = game.get_player(event.player_index)
        Torchlight.move_wood_to_torchlight_inventory(player, event.entity)
    end
end

function Torchlight.register()
    Event.add(defines.events.on_player_created, Torchlight.on_player_created)
    Event.add(defines.events.on_player_respawned, Torchlight.on_player_respawned)
    Event.add(defines.events.on_player_joined_game, Torchlight.on_player_joined_game)
    Event.add(defines.events.on_pre_player_died, Torchlight.on_pre_player_died)
    Event.add(defines.events.on_player_died, Torchlight.on_player_died)
    Event.add(defines.events.on_tick, Torchlight.on_tick)
    Event.add(defines.events.on_player_display_resolution_changed, Torchlight.on_player_display_resolution_changed)
    Event.add(defines.events.on_player_display_scale_changed, Torchlight.on_player_display_scale_changed)
    Event.add(defines.events.on_player_mined_entity, Torchlight.on_player_mined_entity)
    Event.add(defines.events.on_pre_player_mined_item, Torchlight.on_pre_player_mined_item)

    TorchlightGui.register_click_handlers(Torchlight.on_torchlight_button_pressed, Torchlight.on_torchlight_fuel_pressed)
end

--- Ensures wood is available in the market at the configured level and price
function Torchlight.configure_wood_in_market()
    local redmew_config = storage.config
    for _, entry in pairs(redmew_config.experience.unlockables) do
        if entry.name == 'wood' then
            entry.level = 1
            entry.price = 4
            return
        end
    end
    table.insert(redmew_config.experience.unlockables, {
        level = 1,
        price = 4,
        name = 'wood'
    })
end

function Torchlight.on_init()
    Torchlight.configure_wood_in_market()
end

--- Creates light rendering IDs for a target entity
--- @param target LuaEntity to attach lights to
--- @param surface LuaSurface to render on
--- @return table array of light IDs {main_light_id, effect_light_1_id, effect_light_2_id}
function Torchlight.create_light_ids(target, surface)
    return {
        TorchlightLights.create_main_light(target, surface).id,
        TorchlightLights.create_effect_light_1(target, surface).id,
        TorchlightLights.create_effect_light_2(target, surface).id
    }
end

--- Restores missing light rendering objects from stored IDs
--- @param light_data table containing light_ids array
--- @param target LuaEntity to attach lights to
--- @param surface LuaSurface to render on
function Torchlight.restore_missing_lights(light_data, target, surface)
    local main_light = rendering.get_object_by_id(light_data.light_ids[1])
    if not main_light then
        main_light = TorchlightLights.create_main_light(target, surface)
        light_data.light_ids[1] = main_light.id
    end

    local effect_light_1 = rendering.get_object_by_id(light_data.light_ids[2])
    if not effect_light_1 then
        effect_light_1 = TorchlightLights.create_effect_light_1(target, surface)
        light_data.light_ids[2] = effect_light_1.id
    end

    local effect_light_2 = rendering.get_object_by_id(light_data.light_ids[3])
    if not effect_light_2 then
        effect_light_2 = TorchlightLights.create_effect_light_2(target, surface)
        light_data.light_ids[3] = effect_light_2.id
    end
end

return Torchlight