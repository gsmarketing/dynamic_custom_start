-- control.lua

-- Require the GUI module
require('dcs.ui.main')

-- Define the cleanup function
local function cleanup(player)
    -- Destroy the GUI
    if player.gui.screen["dcs_main_frame"] then
        player.gui.screen["dcs_main_frame"].destroy()
    end

    -- Clear the globals
    global.selected_item_name = nil
    global.inventory_items = {}
    global.dcs_gui_active = false
end

-- This function is called when the game starts
script.on_init(function()
    -- Initialize the GUI active flag
    global.dcs_gui_active = false

    -- Store the initial tick count
    global.initial_tick = game.tick

    -- Player table in global
    global.players = {}

    -- Initialize the max unique items count in global
    global.max_unique_items = settings.startup["dcs-max-unique-items"].value

    -- Initialize the inventory items table in global
    global.inventory_items = {}
end)

-- This function is called when a new player is created
script.on_event(defines.events.on_player_created, function(event)
    -- Calculate the elapsed ticks since the game started
    local elapsed_ticks = game.tick - global.initial_tick

    -- Convert the elapsed ticks to minutes
    local elapsed_minutes = elapsed_ticks / 60 / 60

    -- Get the value of the setting
    local max_allowed_item_time = settings.startup["dcs-max-allowed-item-time"].value

    -- Check if the elapsed time is below the threshold
    if elapsed_minutes < max_allowed_item_time then
        -- Get the player who was created
        local player = game.players[event.player_index]

        -- Update the global inventory items table
        for name, prototype in pairs(game.item_prototypes) do
            table.insert(global.inventory_items, name)
        end

        -- Check if the player's controller type is not a cutscene
        if player.controller_type ~= defines.controllers.cutscene then
            -- Call the function to create the GUI
            create_gui(player, global.inventory_items)
        else
            -- Store the player's index in the global table to create the GUI later
            global.pending_gui_creation = event.player_index
        end
    end
end)

-- Register the on_gui_checked_state_changed event
script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    -- Get the player who changed the checkbox
    local player = game.players[event.player_index]

    -- Check if the changed element is the confirm close checkbox
    if event.element.name == "dcs_close_window_checkbox" then
        -- Check if the checkbox is checked
        if event.element.state then
            -- Enable the close button
            player.gui.screen["dcs_main_frame"]["dcs_content_nav_frame"]["dcs_close_window_frame"]["dcs_shut_vault"].enabled = true
        else
            -- Disable the close button
            player.gui.screen["dcs_main_frame"]["dcs_content_nav_frame"]["dcs_close_window_frame"]["dcs_shut_vault"].enabled = false
        end
    end
end)

-- Register the on_gui_click event
script.on_event(defines.events.on_gui_click, function(event)
    -- Check if the GUI is active
    if not global.dcs_gui_active then
        return
    end

    -- Get the clicked element
    local element = event.element

    -- Check if the clicked element is part of your GUI
    if not element.valid or not element.name:find("dcs_") then
        return
    end

    -- Get the player who clicked the button
    local player = game.players[event.player_index]

    -- Get the dcs_item_stack_switch
    local item_stack_switch = player.gui.screen["dcs_main_frame"]["dcs_content_nav_frame"]["dcs_content_controls_frame"]["dcs_item_stack_switch"]

    -- Get the switch state
    local switch_state = item_stack_switch.switch_state

    -- Get the dcs_item_count_text_field
    local item_count_text_field = player.gui.screen["dcs_main_frame"]["dcs_content_nav_frame"]["dcs_content_controls_frame"]["dcs_item_count_text_field"]

    -- Get the value from the text field
    local item_count = tonumber(item_count_text_field.text)

    -- Get the get item button
    local get_item_button = player.gui.screen["dcs_main_frame"]["dcs_content_nav_frame"]["dcs_get_item_button"]

    -- Check if the clicked element is a sprite button
    if string.find(event.element.name, "dcs_sprite_button_") then
        -- Get the index of the clicked button
        local index = tonumber(string.match(event.element.name, "%d+"))

        -- Get the player who clicked the button
        local player = game.players[event.player_index]

        -- Get the selected item label
        local selected_item_label = player.gui.screen["dcs_main_frame"]["dcs_content_nav_frame"]["dcs_selected_item_label"]

        -- Check if the selected item label exists
        if selected_item_label then
            -- Get the name of the corresponding item
            local item_name = global.inventory_items[index]

            -- Get the localized prefix
            local prefix = {"gui-text.dcs-selected-text"}

            -- Update the caption of the selected_item_label to the name of the selected item
            selected_item_label.caption = {'', prefix, " ", item_name}

            -- Store the selected item's name in the global table
            global.selected_item_name = item_name

        else
            game.print("selected_item_label not found")
        end

    -- Check if the clicked element is the get item button
    elseif event.element.name == "dcs_get_item_button" then
        -- Get the items allowed count field
        local get_items_allowed_count = player.gui.screen["dcs_main_frame"]["dcs_content_nav_frame"]["dcs_items_allowed_frame"]["dcs_items_allowed_count_field"]

        -- Check if an item has been selected and max unique items count is greater than 0
        if global.selected_item_name and global.max_unique_items > 0 then
            -- Get the item prototype
            local item_prototype = game.item_prototypes[global.selected_item_name]

            -- Check if the switch state is "right" (Stack)
            if switch_state == "right" then
                -- Multiply the item count by the stack size of the item
                item_count = item_count * item_prototype.stack_size
            end

            -- Validate the item count
            if not item_count or item_count <= 0 then
                game.print("Item count must be a positive number")
                return
            end

            -- Try to add the selected item to the player's inventory
            local inserted_count = player.insert{name=global.selected_item_name, count=item_count}

            -- Check if the item was successfully added to the inventory
            if inserted_count > 0 then
                -- Decrement the max unique items count
                global.max_unique_items = global.max_unique_items - 1

                -- Update the items allowed count field with the new max_unique_items value
                get_items_allowed_count.text = tostring(global.max_unique_items)

                -- Disable the button if max_unique_items is 0
                if global.max_unique_items <= 0 then
                    get_item_button.enabled = false
                end

                -- Print a message indicating the number of items or stacks added to the inventory
                if switch_state == "right" then
                    local stack_count = inserted_count / item_prototype.stack_size
                    game.print(stack_count .. " stacks of " .. global.selected_item_name .. " were added to the inventory")
                else
                    game.print(inserted_count .. " items of " .. global.selected_item_name .. " were added to the inventory")
                end

            else
                game.print("Item could not be added to inventory")
            end
        else
            game.print("No item selected or max unique items count reached")
        end

    -- Check if the clicked element is the close window button
    elseif event.element.name == "dcs_shut_vault" then
        -- Get the player who clicked the button
        local player = game.players[event.player_index]

        -- Call the cleanup function
        cleanup(player)
    end
end)

-- Register the on_cutscene_started, on_cutscene_finished, and on_cutscene_cancelled events
script.on_event(
    { defines.events.on_cutscene_started, defines.events.on_cutscene_finished, defines.events.on_cutscene_cancelled },
    function(event)
        -- Check if there's a pending GUI creation for this player
        if global.pending_gui_creation == event.player_index then
            -- Get the player
            local player = game.players[event.player_index]

            -- Check if the player's controller type is not a cutscene
            if player.controller_type ~= defines.controllers.cutscene then
                -- Call the function to create the GUI
                create_gui(player, global.inventory_items)

                -- Clear the pending GUI creation
                global.pending_gui_creation = nil
            end
        end
    end
)

-- This function is called when the game's configuration changes
script.on_configuration_changed(function()
    -- Initialize the GUI active flag if it is nil
    if global.dcs_gui_active == nil then
        global.dcs_gui_active = false
    end
end)
