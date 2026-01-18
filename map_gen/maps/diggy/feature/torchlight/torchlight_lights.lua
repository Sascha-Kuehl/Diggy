local LIGHT_SCALE = 2.0
local LIGHT_SCALE_EFFECT = 1.15
local MAIN_LIGHT_COLOR = { 250, 200, 120 }
local EFFECT_LIGHT_1_COLOR = { 170, 40, 0 }
local EFFECT_LIGHT_2_COLOR = { 200, 100, 0 }
local EFFECT_LIGHT_INTENSITY = 0.25
local EFFECT_LIGHT_1_BLINK = 11
local EFFECT_LIGHT_2_BLINK = 13

local TorchlightLights = {}

-- Create a light with specified config
local function create_light(color, blink_interval, target, surface)
    return rendering.draw_light {
        sprite = 'utility/light_medium',
        color = color,
        surface = surface,
        target = target,
        intensity = blink_interval and EFFECT_LIGHT_INTENSITY or 1,
        blink_interval = blink_interval
    }
end

-- Creates the main bright light
function TorchlightLights.create_main_light(target, surface)
    return create_light(MAIN_LIGHT_COLOR, nil, target, surface)
end

-- Creates the first effect light (reddish glow with blinking)
function TorchlightLights.create_effect_light_1(target, surface)
    return create_light(EFFECT_LIGHT_1_COLOR, EFFECT_LIGHT_1_BLINK, target, surface)
end

-- Creates the second effect light (orange glow with different blinking)
function TorchlightLights.create_effect_light_2(target, surface)
    return create_light(EFFECT_LIGHT_2_COLOR, EFFECT_LIGHT_2_BLINK, target, surface)
end

-- Updates the visibility and scale of the torchlight's lights
function TorchlightLights.update_light(light_data, enabled)
    local lights = {
        rendering.get_object_by_id(light_data.light_ids[1]),
        rendering.get_object_by_id(light_data.light_ids[2]),
        rendering.get_object_by_id(light_data.light_ids[3])
    }

    local should_show = light_data.intensity >= 0.001 and (enabled or light_data.intensity_per_tick ~= 0) and 
                       (light_data.light_ticks < light_data.light_ticks_total or light_data.intensity_per_tick ~= 0)
    
    for _, light in ipairs(lights) do
        light.visible = should_show
    end

    if should_show then
        lights[1].scale = LIGHT_SCALE * light_data.intensity
        lights[2].scale = LIGHT_SCALE * LIGHT_SCALE_EFFECT * light_data.intensity
        lights[3].scale = LIGHT_SCALE * LIGHT_SCALE_EFFECT * light_data.intensity
    end
end

-- Destroys all light rendering objects by their IDs
function TorchlightLights.destroy_lights(light_ids)
    for _, id in ipairs(light_ids) do
        local light = rendering.get_object_by_id(id)
        if light then
            light.destroy()
        end
    end
end

-- Creates light rendering IDs for a target entity
function TorchlightLights.create_light_ids(target, surface)
    return {
        TorchlightLights.create_main_light(target, surface).id,
        TorchlightLights.create_effect_light_1(target, surface).id,
        TorchlightLights.create_effect_light_2(target, surface).id
    }
end

return TorchlightLights
