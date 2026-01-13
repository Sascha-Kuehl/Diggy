local Global = require 'utils.global'

--- Maps player index to light data: {enabled, remaining_ticks, light_ids}
--- enabled (boolean): whether the player has the light turned on
--- remaining_ticks (number): fuel remaining in ticks
--- light_ids (table): array of 3 rendering IDs {main, effect1, effect2}
local player_light_data = {}

--- Maps corpse id to light data: {remaining_ticks, light_ids}
--- remaining_ticks (number): fuel remaining in ticks
--- light_ids (table): array of 3 rendering IDs {main, effect1, effect2}
local corpse_light_data = {}

--- Maps player index to their torchlight inventory (LuaInventory)
local torchlight_inventory = {}

Global.register(
        {
            player_light_data = player_light_data,
            corpse_light_data = corpse_light_data,
            torchlight_inventory = torchlight_inventory
        },
        function(tbl)
            player_light_data = tbl.player_light_data
            corpse_light_data = tbl.corpse_light_data
            torchlight_inventory = tbl.torchlight_inventory
        end
)

local TorchlightData = {}

function TorchlightData.get_player_light_data()
    return player_light_data
end

function TorchlightData.get_corpse_light_data()
    return corpse_light_data
end

function TorchlightData.get_torchlight_inventory()
    return torchlight_inventory
end

function TorchlightData.set_player_light_data(player_index, data)
    player_light_data[player_index] = data
end

function TorchlightData.set_corpse_light_data(corpse_id, data)
    corpse_light_data[corpse_id] = data
end

function TorchlightData.set_torchlight_inventory(player_index, inventory)
    torchlight_inventory[player_index] = inventory
end

function TorchlightData.get_player_light_info(player_index)
    return player_light_data[player_index]
end

function TorchlightData.get_corpse_light_info(corpse_id)
    return corpse_light_data[corpse_id]
end

function TorchlightData.get_player_inventory(player_index)
    return torchlight_inventory[player_index]
end

function TorchlightData.create_player_light_data(light_ids)
    return {
        enabled = true,
        remaining_ticks = 0,
        light_ids = light_ids
    }
end

function TorchlightData.create_corpse_light_data(remaining_ticks, light_ids)
    return {
        remaining_ticks = remaining_ticks,
        light_ids = light_ids
    }
end

function TorchlightData.remove_corpse_light_data(corpse_id)
    corpse_light_data[corpse_id] = nil
end

return TorchlightData
