-- control.lua

-- Require the Globals module
local globals = require('dcs.globals')
-- Require the GUI module
require('dcs.ui.main')
-- Require flib
local flib_dictionary = require("__flib__.dictionary-lite")

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
    global.debouce_timers = {}
	-- Clear the dictionary for the specific player
	global.localized_item_names[player.index] = flib_dictionary.new("item_names")
end

-- This function is called when the game starts
script.on_init(function()
    -- Initialize global variables from the globals table
    for k, v in pairs(globals) do
        global[k] = v
    end

    -- Initialize globals
    global.initial_tick = game.tick
    global.max_unique_items = settings.startup["dcs-max-unique-items"].value

    -- Initialize the dictionary
    flib_dictionary.on_init()
    global.localized_item_names = {}
end)

-- This function is called every time a save game is loaded
script.on_load(function()
	-- Set up the metatable for the dictionaries
    flib_dictionary.on_load()

    -- Check if the global table has been initialized
    if global.localized_item_names then
        -- Set up the metatable for the dictionaries
        for player_index, dictionary in pairs(global.localized_item_names) do
            setmetatable(dictionary, {__index = flib_dictionary.metatable})
        end
    end
end)

-- This function is called when a new player is created
script.on_event(defines.events.on_player_created, function(event)
	-- Calculate the elapsed ticks since the game started
	local elapsed_ticks = game.tick - global.initial_tick

	-- Convert the elapsed ticks to minutes
	local elapsed_minutes = elapsed_ticks / 60 / 60

	-- Get the value of the setting
	local max_allowed_item_time = settings.startup["dcs-max-allowed-item-time"].value

	-- Initialize global.localized_item_names if it's not already initialized
	if not global.localized_item_names then
		global.localized_item_names = {}
	end

	-- Check if the elapsed time is below the threshold
	if elapsed_minutes < max_allowed_item_time then
		-- Get the player who was created
		local player = game.players[event.player_index]

		-- Check if the dictionary already exists
		if not global.localized_item_names[player.index] then
			-- Create a new dictionary for the item names
			global.localized_item_names[player.index] = flib_dictionary.new("item_names")
		end

		-- Update the global inventory items table and localized item names table
		for name, prototype in pairs(game.item_prototypes) do
			table.insert(global.inventory_items, name)
			-- Add the localized name table of the item to the dictionary
			flib_dictionary.add(global.localized_item_names[player.index], name, prototype.localised_name)
		end

		-- Check if the player's controller type is not a cutscene
		if player.controller_type ~= defines.controllers.cutscene then
			-- Check if the dictionary is complete
			local is_complete = true
			for name, _ in pairs(game.item_prototypes) do
				if not flib_dictionary.get(global.localized_item_names[player.index], name) then
					is_complete = false
					break
				end
			end
			if is_complete then
				-- Call the function to create the GUI
				create_gui(player, global.inventory_items)
			else
				-- Store the player's index in the global table to create the GUI later
				global.pending_gui_creation = event.player_index
			end
		else
			-- Store the player's index in the global table to create the GUI later
			global.pending_gui_creation = event.player_index
		end
	end
end)

-- -- This function is called when a new player is created
-- script.on_event(defines.events.on_player_created, function(event)
--     -- Calculate the elapsed ticks since the game started
--     local elapsed_ticks = game.tick - global.initial_tick

--     -- Convert the elapsed ticks to minutes
--     local elapsed_minutes = elapsed_ticks / 60 / 60

--     -- Get the value of the setting
--     local max_allowed_item_time = settings.startup["dcs-max-allowed-item-time"].value

--     -- Check if the elapsed time is below the threshold
--     if elapsed_minutes < max_allowed_item_time then
--         -- Get the player who was created
--         local player = game.players[event.player_index]

--         -- Update the global inventory items table
--         for name, prototype in pairs(game.item_prototypes) do
--             table.insert(global.inventory_items, name)
--         end

--         -- Check if the player's controller type is not a cutscene
--         if player.controller_type ~= defines.controllers.cutscene then
--             -- Call the function to create the GUI
--             create_gui(player, global.inventory_items)
--         else
--             -- Store the player's index in the global table to create the GUI later
--             global.pending_gui_creation = event.player_index
--         end
--     end
-- end)

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

-- Register the on_gui_text_changed event
script.on_event(defines.events.on_gui_text_changed, function(event)
	-- Check if the GUI is active
	if not global.dcs_gui_active then
		return
	end

	-- Get the changed element
	local element = event.element

	-- Check if the changed element is your search field
	if element.name == "dcs_item_filter_field" then
		-- Get the text from the search field
		local search_text = element.text

		-- Get the player who changed the text field
		local player_index = event.player_index

		-- Update the debounce timer for this player
		global.debounce_timers[player_index] = {
			tick = game.tick + 30,  -- Delay of 30 ticks (0.5 seconds)
			text = search_text
		}
	end
end)

-- Register the on_tick event
script.on_event(defines.events.on_tick, function(event)
	-- Update the dictionary
    flib_dictionary.on_tick(event)
	-- Iterate over the debounce timers for each player
	for player_index, timer in pairs(global.debounce_timers) do
		-- Check if the debounce timer has expired
		if event.tick >= timer.tick then
			-- Get the player
			local player = game.players[player_index]

			-- Get the search field
			local search_field = player.gui.screen["dcs_main_frame"]["dcs_main_content_frame"]["dcs_item_scroll_pane"]["dcs_item_filter_field"]

			-- Check if the search field still contains the same text as the debounce timer
			if search_field.text == timer.text then
				-- Get the sprite table
				local sprite_table = player.gui.screen["dcs_main_frame"]["dcs_main_content_frame"]["dcs_item_scroll_pane"]["dcs_sprite_table"]

				-- Get the translated item names for this player
				local translated_item_names = flib_dictionary.get(global.localized_item_names[player_index], "item_names")

				-- Iterate over the children of the sprite table
				for _, child in pairs(sprite_table.children) do
					-- Check if the child is a sprite button
					if child.type == "sprite-button" then
						-- Get the name of the item corresponding to the sprite button
						local item_name = string.match(child.name, "dcs_sprite_button_(.*)")

						-- Get the translated name of the item
						local translated_item_name = translated_item_names[item_name]

						-- Check if the translated item's name contains the search text
						if translated_item_name and string.find(string.lower(translated_item_name), string.lower(timer.text), 1, true) then
							-- Show the sprite button
							child.visible = true
						else
							-- Hide the sprite button
							child.visible = false
						end
					end
				end

				-- Remove the debounce timer for this player
				global.debounce_timers[player_index] = nil
			end
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

			-- Get the translated name of the item
			local translated_item_names = flib_dictionary.get(global.localized_item_names[player_index], "item_names")
			local translated_item_name = translated_item_names[item_name]

			-- Check if the translated item name exists
			if not translated_item_name then
				game.print("Translated item name not found for item: " .. item_name)
				return
			end

			-- Get the localized prefix
			local prefix = {"gui-text.dcs-selected-text"}

			-- Update the caption of the selected_item_label to the localized name of the selected item
			selected_item_label.caption = {'', prefix, " ", translated_item_name}

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

-- Register the on_tick event
script.on_event(defines.events.on_tick, function(event)
    -- Iterate over the debounce timers for each player
    for player_index, timer in pairs(global.debounce_timers) do
        -- Check if the debounce timer has expired
        if event.tick >= timer.tick then
            -- Get the player
            local player = game.players[player_index]

            -- Get the sprite table
            local sprite_table = player.gui.screen["dcs_main_frame"]["dcs_main_content_frame"]["dcs_item_scroll_pane"]["dcs_sprite_table"]

            -- Iterate over the children of the sprite table
            for _, child in pairs(sprite_table.children) do
                -- Check if the child is a sprite button
                if child.type == "sprite-button" then
                    -- Get the localized name of the item corresponding to the sprite button
                    local localized_item_name = global.localized_item_names[child.name]

                    -- Convert the localized item name to a string
                    local localized_item_name_str = serpent.block(localized_item_name)

                    -- Check if the localized item's name contains the search text
                    if localized_item_name_str and string.find(localized_item_name_str, timer.text, 1, true) then
                        -- Show the sprite button
                        child.visible = true
                    else
                        -- Hide the sprite button
                        child.visible = false
                    end
                end
            end

            -- Remove the debounce timer for this player
            global.debounce_timers[player_index] = nil
        end
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
	-- Handle configuration changes
    flib_dictionary.on_configuration_changed(data)
    -- Initialize the GUI active flag if it is nil
    if global.dcs_gui_active == nil then
        global.dcs_gui_active = false
    end
end)

-- Handle events
flib_dictionary.handle_events()