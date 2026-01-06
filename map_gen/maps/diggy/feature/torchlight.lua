local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local RS = require 'map_gen.shared.redmew_surface'

local TICK_INTERVAL = 60
local TICKS_PER_WOOD = 60 * 60 * 1
local AFTERBURNER_TICKS = 60 * 17
local LIGHT_SCALE = 2.0

local torchlight_button_name = Gui.uid_name()

-- "map" from player index to {enabled, remaining_ticks, light_ids}
local player_light_data = {}

-- "map" from position to {remaining_ticks, light_ids}
local corpse_light_data = {}

Global.register(
    {
        player_light_data = player_light_data,
        corpse_light_data = corpse_light_data,
    },
    function(tbl)
        player_light_data = tbl.player_light_data
        corpse_light_data = tbl.corpse_light_data
    end
)

local Torchlight = {}

function create_gui_button(player)
    Gui.add_top_element(player, {
        type = 'sprite-button',
        name = torchlight_button_name,
        sprite = 'achievement/pyromaniac',
        tooltip = 'Turn on/off torch light',
        auto_toggle = true,
        toggled = player_light_data[player.index].enabled
      })
end

function create_main_light(target, surface)
    return rendering.draw_light
        {
          sprite = 'utility/light_medium',
          color = {250,200,120},
          surface = surface,
          target = target,
        }
end

function create_effect_light_1(target, surface)
    return rendering.draw_light
        {
            sprite = 'utility/light_medium',
            color = {170,40,0},
            surface = surface,
            target = target,
            intensity = 0.25,
            blink_interval = 11
        }
end

function create_effect_light_2(target, surface)
    return rendering.draw_light
       {
           sprite = 'utility/light_medium',
           color = {200,100,0},
           surface = surface,
           target = target,
           intensity = 0.25,
           blink_interval = 13
       }
end

function create_or_restore_player_light(player)
    local light_data = player_light_data[player.index]

    if (light_data == nil) then
        local main_light = create_main_light(player.character, player.surface)
        local effect_light_1 = create_effect_light_1(player.character, player.surface)
        local effect_light_2 = create_effect_light_2(player.character, player.surface)
        light_data = {
            enabled = true,
            remaining_ticks = 0,
            light_ids = {main_light.id, effect_light_1.id, effect_light_2.id}
        }
        player_light_data[player.index] = light_data
        return
    end

    local main_light = rendering.get_object_by_id(light_data.light_ids[1])
    if (main_light == nil) then
        main_light = create_main_light(player.character, player.surface)
        light_data.light_ids[1] = main_light.id
    end

    local effect_light_1 = rendering.get_object_by_id(light_data.light_ids[2])
    if (effect_light_1 == nil) then
        effect_light_1 = create_effect_light_1(player.character, player.surface)
        light_data.light_ids[2] = effect_light_1.id
    end

    local effect_light_2 = rendering.get_object_by_id(light_data.light_ids[3])
    if (effect_light_2 == nil) then
        effect_light_2 = create_effect_light_2(player.character, player.surface)
        light_data.light_ids[3] = effect_light_2.id
    end

    return
end

function get_intensity(remaining_ticks)
    if (remaining_ticks <= 0) then
        return 0.0
    end
    if (remaining_ticks <= AFTERBURNER_TICKS) then
        return remaining_ticks / AFTERBURNER_TICKS
    end
    return 1.0
end

function update_light(light_data)
    local intensity = get_intensity(light_data.remaining_ticks)

    local main_light = rendering.get_object_by_id(light_data.light_ids[1])
    local effect_light_1 = rendering.get_object_by_id(light_data.light_ids[2])
    local effect_light_2 = rendering.get_object_by_id(light_data.light_ids[3])

    if (intensity == 0) then
        main_light.visible = false
        effect_light_1.visible = false
        effect_light_2.visible = false
        return
    end

    main_light.visible = true
    effect_light_1.visible = true
    effect_light_2.visible = true

    main_light.scale = LIGHT_SCALE * intensity
    effect_light_1.scale = LIGHT_SCALE * 1.15 * intensity
    effect_light_2.scale = LIGHT_SCALE * 1.15 * intensity
end

function remove_one_wood(inventory, player)
    inventory.remove({name = 'wood', count = 1})
    player.create_local_flying_text
    {
        text = '-1 wood',
        surface = player.surface,
        position = player.position,
    }
end

function update_player_light(player)
    if (player.ticks_to_respawn ~= nil) then
        return
    end

    local light_data = player_light_data[player.index]

    -- the light is burning and has enough "fuel"
    -- or player has deactivated the light, so we will not burn more wood
    if (light_data.remaining_ticks > AFTERBURNER_TICKS or not light_data.enabled) then
        update_light(light_data)
        return
    end

    local inventory = player.character.get_inventory(defines.inventory.character_main)
    local woodCount = inventory.get_item_count('wood')

    -- player has wood, so we can burn it
    if (woodCount ~= 0) then
        remove_one_wood(inventory, player)
        light_data.remaining_ticks = TICKS_PER_WOOD + AFTERBURNER_TICKS
    end

    update_light(light_data)
end

function update_player_lights_on_tick()
    for _, player in pairs(game.connected_players) do
        local light_data = player_light_data[player.index]
        light_data.remaining_ticks = light_data.remaining_ticks - TICK_INTERVAL
        if (light_data.remaining_ticks <= 0) then
            light_data.remaining_ticks = 0
        end
        update_player_light(player)

        -- player runs out of wood so we show a message
        if (light_data.enabled
                and light_data.remaining_ticks > 0
                and light_data.remaining_ticks < AFTERBURNER_TICKS
                and light_data.remaining_ticks % 180 == 0) then
            player.create_local_flying_text
            {
                text = 'no more wood',
                surface = player.surface,
                position = player.position,
                color = {250, 0, 0}
            }
        end
    end
end

function update_corpse_light(position)
    local light_data = corpse_light_data[position]

    if (light_data.remaining_ticks > 0) then
        update_light(light_data)
        return
    end

    -- light burned out
    for _, id in pairs(light_data.light_ids) do
        local light_rendering = rendering.get_object_by_id(id)
        light_rendering.destroy()
    end
    corpse_light_data[position] = nil
end

function update_corpse_lights_on_tick()
    for position, light_data in pairs(corpse_light_data) do
        light_data.remaining_ticks = light_data.remaining_ticks - TICK_INTERVAL
        update_corpse_light(position)
    end
end

function on_player_created(event)
    local player = game.get_player(event.player_index)
    player.disable_flashlight()

    create_or_restore_player_light(player)
    update_player_light(player)
    create_gui_button(player)
end

function on_player_respawned(event)
    local player = game.get_player(event.player_index)
    player.disable_flashlight()

    create_or_restore_player_light(player)
    update_player_light(player)
end

function on_player_joined_game(event)
    local player = game.get_player(event.player_index)

    create_or_restore_player_light(player)
    update_player_light(player)
end

function on_player_died(event)
    local player = game.get_player(event.player_index)
    local light_data = player_light_data[player.index]
    local position = player.position

    corpse_light_data[position] = {
        remaining_ticks = light_data.remaining_ticks,
        light_ids = {
            create_main_light(position, player.surface).id,
            create_effect_light_1(position, player.surface).id,
            create_effect_light_2(position, player.surface).id
        }
    }
    player_light_data[player.index].remaining_ticks = 0
    update_player_light(player)
    update_corpse_light(position)
end

function on_player_main_inventory_changed(event)
    local player = game.get_player(event.player_index)
    update_player_light(player)
end

function on_tick()
    if (game.tick % TICK_INTERVAL ~= 0) then
        return
    end
    update_player_lights_on_tick()
    update_corpse_lights_on_tick()
end

function on_torchlight_button_pressed(event)
    local player = event.player
    local button = Gui.get_top_element(player, torchlight_button_name)
    player_light_data[player.index].enabled = button.toggled
    update_player_light(player)
end

function configure_wood_in_market()
    local redmew_config = storage.config
    for _, entry in pairs(redmew_config.experience.unlockables) do
        if (entry.name == 'wood') then
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

function Torchlight.register()
    Event.add(defines.events.on_player_created, on_player_created)
    Event.add(defines.events.on_player_respawned, on_player_respawned)
    Event.add(defines.events.on_player_joined_game, on_player_joined_game)
    Event.add(defines.events.on_player_died, on_player_died)
    Event.add(defines.events.on_player_main_inventory_changed, on_player_main_inventory_changed)
    Event.add(defines.events.on_tick, on_tick)
    
    Gui.on_click(torchlight_button_name, on_torchlight_button_pressed)
end

function Torchlight.on_init()
    local surface = RS.get_surface()

    rendering.draw_light
        {
            sprite = 'utility/light_medium',
            scale = 2.5,
            color = {255,255,255},
            surface = surface,
            target = {x = 0, y = 0}
        }

    configure_wood_in_market()
end

return Torchlight