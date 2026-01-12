local Table = require 'utils.table'

local InventoryUtil = {}

function is_stack_empty(itemStack)
    return not itemStack.valid_for_read
end

function isLeftClick(click_event)
    return click_event.button == defines.mouse_button_type.left
end

function isRightClick(click_event)
    return click_event.button == defines.mouse_button_type.right
end

function get_pickup_count(total, click_event)
    if (isLeftClick(click_event)) then
        return total
    elseif (isRightClick(click_event)) then
        if (total == 1) then
            return 1
        end
        return math.floor(total / 2)
    else
        return 0
    end
end

function copy_stack_with_new_count(stack, count)
    return {
        name = stack.name,
        quality = stack.quality,
        health = stack.health,
        durability = stack.is_tool and stack.durability or nil,
        ammo = stack.is_ammo and stack.ammo or nil,
        spoil_percent = stack.spoil_percent,
        count = count
    }
end

function transfer_whole_inventory_to_main(player, source_inventory, click_event)
    -- not implemented :)
end

function transfer_items_to_main(player, source_inventory, source_stack, click_event, count)
    local main_inventory = player.character.get_main_inventory()
    local pick_count = get_pickup_count(count, click_event)

    local insertable_count = main_inventory.get_insertable_count(source_stack)
    if (insertable_count < pick_count) then
        pick_count = insertable_count
    end

    local transfer_stack = copy_stack_with_new_count(source_stack, pick_count);
    main_inventory.insert(transfer_stack)
    source_inventory.remove(transfer_stack)

    player.play_sound({path = 'item-move/'..transfer_stack.name})
end

function transfer_all_stacks_to_main(player, source_inventory, source_stack, click_event)
    local item_count = source_inventory.get_item_count(source_stack)
    transfer_items_to_main(player, source_inventory, source_stack, click_event, item_count)
end

function transfer_stack_to_main(player, source_inventory, source_stack, click_event)
    transfer_items_to_main(player, source_inventory, source_stack, click_event, source_stack.count)
end

function pickup_stack_to_cursor(player, source_stack, cursor_stack, click_event)
    local pick_count = get_pickup_count(source_stack.count, click_event)
    cursor_stack.transfer_stack(source_stack, pick_count)

    player.play_sound({path = 'item-pick/'..cursor_stack.name})
end

function push_stack_from_cursor(player, source_stack, cursor_stack, click_event)
    if (isLeftClick(click_event) and (is_stack_empty(source_stack) or cursor_stack.name ~= source_stack.name or cursor_stack.quality ~= source_stack.quality)) then
        source_stack.swap_stack(cursor_stack)
        player.play_sound({path = 'item-drop/'..source_stack.name})
        return
    end

    local push_count
    if (isLeftClick(click_event)) then
        push_count = cursor_stack.count
    elseif (isRightClick(click_event)) then
        push_count = 1
    else
        return
    end

    source_stack.transfer_stack(cursor_stack, push_count)
    player.play_sound({path = 'item-drop/'..source_stack.name})
end

function InventoryUtil.handle_inventory_slot_click(source_inventory, source_stack, click_event, accepted_items)
    local player = game.get_player(click_event.player_index)
    local cursor_stack = player.cursor_stack
    if (cursor_stack == nil) then
        return
    end

    if (click_event.control) then
        if (is_stack_empty(source_stack)) then
            transfer_whole_inventory_to_main(player, source_inventory, click_event)
        else
            transfer_all_stacks_to_main(player, source_inventory, source_stack, click_event)
        end
    elseif (click_event.shift) then
        transfer_stack_to_main(player, source_inventory, source_stack, click_event)
    else
        if (is_stack_empty(cursor_stack)) then
            pickup_stack_to_cursor(player, source_stack, cursor_stack, click_event)
        else
            if (not Table.contains(accepted_items, cursor_stack.name)) then
                return
            end
            push_stack_from_cursor(player, source_stack, cursor_stack, click_event)
        end
    end
end

return InventoryUtil