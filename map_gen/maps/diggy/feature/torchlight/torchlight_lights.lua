local LIGHT_SCALE = 2.0

local TorchlightLights = {}

function TorchlightLights.create_main_light(target, surface)
    return rendering.draw_light {
        sprite = 'utility/light_medium',
        color = { 250, 200, 120 },
        surface = surface,
        target = target,
    }
end

function TorchlightLights.create_effect_light_1(target, surface)
    return rendering.draw_light {
        sprite = 'utility/light_medium',
        color = { 170, 40, 0 },
        surface = surface,
        target = target,
        intensity = 0.25,
        blink_interval = 11
    }
end

function TorchlightLights.create_effect_light_2(target, surface)
    return rendering.draw_light {
        sprite = 'utility/light_medium',
        color = { 200, 100, 0 },
        surface = surface,
        target = target,
        intensity = 0.25,
        blink_interval = 13
    }
end

function TorchlightLights.get_intensity(remaining_ticks, afterburner_ticks)
    if (remaining_ticks <= 0) then
        return 0.0
    end
    if (remaining_ticks <= afterburner_ticks) then
        return remaining_ticks / afterburner_ticks
    end
    return 1.0
end

function TorchlightLights.update_light(light_data, remaining_ticks, afterburner_ticks)
    local intensity = TorchlightLights.get_intensity(remaining_ticks, afterburner_ticks)

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

function TorchlightLights.destroy_lights(light_ids)
    for _, id in pairs(light_ids) do
        local light_rendering = rendering.get_object_by_id(id)
        if light_rendering then
            light_rendering.destroy()
        end
    end
end

return TorchlightLights
