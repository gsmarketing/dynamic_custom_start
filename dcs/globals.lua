-- globals.lua

return {
	-- Debug mode flag
	dcs_debug_mode = false,
	-- Initialize the GUI active flag
	dcs_gui_active = false,
	-- Player table in global
	players = {},
	-- Initialize the max unique items count in global
	max_unique_items = settings.startup["dcs-max-unique-items"].value,
	-- Initialize the update_results_ident variable
	update_results_ident = nil,
	-- Initialize the inventory items table in global
	inventory_items = {},
	-- Create a table to store the localized names of the items
	localized_item_names = {},
	-- Store debounce timers for each player
	debounce_timers = {} -- corrected typo here
}
