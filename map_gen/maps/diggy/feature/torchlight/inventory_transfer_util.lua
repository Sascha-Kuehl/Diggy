local Table = require 'utils.table'

--- Utility module for managing inventory transfers in Factorio
local InventoryUtil = {}

local LEFT_CLICK = defines.mouse_button_type.left
local RIGHT_CLICK = defines.mouse_button_type.right

local function is_left_click(click_event)
    return click_event.button == LEFT_CLICK
end

local function is_right_click(click_event)
    return click_event.button == RIGHT_CLICK
end

-- Get pickup count: left click = all, right click = half (or 1)
local function get_pickup_count(total, click_event)
    if is_left_click(click_event) then
        return total
    end
    if is_right_click(click_event) then
        return total == 1 and 1 or math.floor(total / 2)
    end
    return 0
end

-- Copy stack with new count, preserving all properties
local function copy_stack_with_new_count(stack, count)
    return {
        name = stack.name,
        quality = stack.quality,
        health = stack.health,
        durability = stack.is_tool and stack.durability,
        ammo = stack.is_ammo and stack.ammo,
        spoil_percent = stack.spoil_percent,
        count = count
    }
end

-- Transfer items from source to main inventory
local function transfer_items_to_main(player, source_inventory, source_stack, click_event, count)
    if not (player and player.character) then
        return
    end
    local main_inventory = player.character.get_main_inventory()
    if not main_inventory then
        return
    end

    local pick_count = math.min(get_pickup_count(count, click_event), main_inventory.get_insertable_count(source_stack))
    if pick_count <= 0 then
        return
    end

    local transfer_stack = copy_stack_with_new_count(source_stack, pick_count)
    main_inventory.insert(transfer_stack)
    source_inventory.remove(transfer_stack)
    if transfer_stack.name then
        player.play_sound({ path = 'item-move/' .. transfer_stack.name })
    end
end

-- Transfer all stacks of item type to main inventory
local function transfer_all_stacks_to_main(player, source_inventory, source_stack, click_event)
    transfer_items_to_main(player, source_inventory, source_stack, click_event, source_inventory.get_item_count(source_stack))
end

-- Transfer one stack to main inventory
local function transfer_stack_to_main(player, source_inventory, source_stack, click_event)
    transfer_items_to_main(player, source_inventory, source_stack, click_event, source_stack.count)
end

-- Pick up stack to cursor
local function pickup_stack_to_cursor(player, source_stack, cursor_stack, click_event)
    local pick_count = get_pickup_count(source_stack.count, click_event)
    if pick_count <= 0 then
        return
    end
    cursor_stack.transfer_stack(source_stack, pick_count)
    if cursor_stack.name then
        player.play_sound({ path = 'item-pick/' .. cursor_stack.name })
    end
end

-- Push items from cursor to slot
local function push_stack_from_cursor(player, source_stack, cursor_stack, click_event)
    -- Swap if destination is empty or items don't match
    if is_left_click(click_event) and (source_stack.count == 0 or cursor_stack.name ~= source_stack.name or cursor_stack.quality ~= source_stack.quality) then
        source_stack.swap_stack(cursor_stack)
        if source_stack.name then
            player.play_sound({ path = 'item-drop/' .. source_stack.name })
        end
        return
    end

    local push_count = is_left_click(click_event) and cursor_stack.count or (is_right_click(click_event) and 1 or 0)
    if push_count <= 0 then
        return
    end
    source_stack.transfer_stack(cursor_stack, push_count)
    if source_stack.name then
        player.play_sound({ path = 'item-drop/' .. source_stack.name })
    end
end

--- Handles inventory slot click events with keyboard modifiers and mouse buttons
--- Control + Click: transfer all stacks to main inventory
--- Shift + Click: transfer one stack to main inventory
--- Left Click: pickup to cursor or push from cursor
--- Right Click: pickup half stack or push 1 item
--- @param source_inventory table The inventory being clicked
--- @param source_stack table The stack at the clicked slot
--- @param click_event table The click event containing button and modifier info
--- @param accepted_items table Array of item names that can be pushed to this inventory
function InventoryUtil.handle_inventory_slot_click(source_inventory, source_stack, click_event, accepted_items)
    if not (click_event and click_event.player_index) then
        return
    end
    local player = game.get_player(click_event.player_index)
    if not (player and player.cursor_stack) then
        return
    end

    if click_event.control then
        if source_stack.count > 0 then
            transfer_all_stacks_to_main(player, source_inventory, source_stack, click_event)
        else
            transfer_whole_inventory_to_main(player, source_inventory, click_event)
        end
    elseif click_event.shift then
        transfer_stack_to_main(player, source_inventory, source_stack, click_event)
    elseif player.cursor_stack.count == 0 then
        if source_stack.count > 0 then
            pickup_stack_to_cursor(player, source_stack, player.cursor_stack, click_event)
        end
    else
        if accepted_items and Table.contains(accepted_items, player.cursor_stack.name) then
            push_stack_from_cursor(player, source_stack, player.cursor_stack, click_event)
        end
    end
end

-- TODO: Implement bulk transfer of entire inventory to main
local function transfer_whole_inventory_to_main(player, source_inventory, click_event)
end

return InventoryUtil