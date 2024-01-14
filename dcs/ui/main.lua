-- main.lua

-- Function to create the GUI
function create_gui(player, inventory_items)
    -- Set the GUI active flag
    global.dcs_gui_active = true

    -- Get the screen GUI root
    local screen_element = player.gui.screen

    -- Create the main frame
    local main_frame = screen_element.add {
        type = "frame",
        name = "dcs_main_frame",
        direction = "horizontal",
        caption = {"gui-text.dcs-frame-title"}
    }

    -- Auto center the main frame
    main_frame.auto_center = true

    -- Create the main content frame
    local main_content_frame = main_frame.add {
        type = "frame",
        name = "dcs_main_content_frame",
        direction = "vertical",
        style = "dcs_deep_frame"
    }

    -- Add a text field for item filtering
    local item_filter_field = main_content_frame.add {
        type = "textfield",
        name = "dcs_item_filter_field"
    }
    -- Set the size of the item_filter_field
    item_filter_field.style.minimal_width = 320
    item_filter_field.style.maximal_width = 320
    item_filter_field.style.bottom_margin = 8

    -- Create the scroll-pane inside the main content frame
    local item_scroll_pane = main_content_frame.add {
        type = "scroll-pane",
        name = "dcs_item_scroll_pane",
        vertical_scroll_policy = "auto",
        horizontal_scroll_policy = "never"
    }
    -- Set the size of the scroll_pane
    item_scroll_pane.style.minimal_width = 290
    item_scroll_pane.style.minimal_height = 180
    item_scroll_pane.style.maximal_height = 180

    -- Add a table to the scroll-pane
    local sprite_table = item_scroll_pane.add {
        type = "table",
        name = "dcs_sprite_table",
        column_count = 7
    }

    -- Initialize the counter
    local num_items_added = 0

    -- Add sprite buttons to the table
    for i, item in ipairs(inventory_items) do
        local sprite_path = "item/" .. item
        if game.is_valid_sprite_path(sprite_path) then
            -- Get the item prototype
            local item_prototype = game.item_prototypes[item]

            -- Check if the item is hidden and the "dcs-show-hidden-items" setting is false
            if not (item_prototype.flags and item_prototype.flags["hidden"] and not settings.startup["dcs-show-hidden-items"].value) then
                -- Get the localized name of the item
                local localized_item_name = item_prototype.localised_name

                -- Store the localized name in the table
                global.localized_item_names["dcs_sprite_button_" .. i] = localized_item_name

                local sprite_button = sprite_table.add {
                    type = "sprite-button",
                    name = "dcs_sprite_button_" .. i,
                    sprite = sprite_path,
                    tooltip = localized_item_name  -- Set the tooltip to the localized name of the item
                }

                -- Increment the counter
                num_items_added = num_items_added + 1
            end
        end
    end

    -- Print the total number of items added, if debug mode is enabled
    if global.dcs_debug_mode then
        game.print("Total number of items added to the sprite table: " .. num_items_added)
    end

    -- Create a dummy frame for spacing (if needed)
    local v_spacer_frame = main_frame.add {
        type = "frame",
        name = "dcs_v_spacer_frame",
        style = "inside_shallow_frame"
    }
    -- Set the size of the v_spacer_frame
    v_spacer_frame.style.width = 1
    v_spacer_frame.style.minimal_height = 230

    -- Create the content navigation frame
    local content_nav_frame = main_frame.add {
        type = "frame",
        name = "dcs_content_nav_frame",
        direction = "vertical",
        style = "dcs_deep_frame"
    }
    -- Set the size of the content_nav_frame
    content_nav_frame.style.minimal_width = 114
    content_nav_frame.style.minimal_height = 230

    -- Create the content controls frame
    local content_controls_frame = content_nav_frame.add {
        type = "frame",
        name = "dcs_content_controls_frame",
        direction = "horizontal",
        style = "borderless_frame"
    }

    -- Add a text field for item count
    local item_count_text_field = content_controls_frame.add {
        type = "textfield",
        name = "dcs_item_count_text_field",
        numeric=true,
        allow_decimal=false,
        allow_negative=false,
        text="0"  -- Set the initial value
    }
    -- Set the size of the item_count_text_field
    item_count_text_field.style.minimal_width = 40
    item_count_text_field.style.maximal_width = 80
    item_count_text_field.style.right_margin = 8

    -- Add a switch for Item / Stack
    local item_stack_switch = content_controls_frame.add {
        type = "switch",
        name = "dcs_item_stack_switch",
        switch_state = "left",
        left_label_caption = {"gui-text.dcs-switch-items-tag"},
        right_label_caption = {"gui-text.dcs-switch-stack-tag"}
    }

    -- Create the selected item label
    local selected_item_label = content_nav_frame.add {
        type = "label",
        name = "dcs_selected_item_label",
        caption = {"gui-text.dcs-label-placeholder"}
    }
    -- Set the size of the selected_item_label
    selected_item_label.style.top_margin = 8

    -- Create a dummy frame for spacing (if needed)
    local h_spacer_frame = content_nav_frame.add {
        type = "frame",
        name = "dcs_h_spacer_frame",
        style = "inside_shallow_frame"
    }
    -- Set the size of the h_spacer_frame
    h_spacer_frame.style.minimal_width = 114
    h_spacer_frame.style.height = 1
    h_spacer_frame.style.top_margin = 8
    h_spacer_frame.style.bottom_margin = 8

    -- Create the items allowed frame
    local items_allowed_frame = content_nav_frame.add {
        type = "frame",
        name = "dcs_items_allowed_frame",
        direction = "horizontal",
        style = "borderless_frame"
    }

    -- Create the items allowed count label
    local items_allowed_count_label = items_allowed_frame.add {
        type = "label",
        name = "dcs_items_allowed_count_label",
        caption = {"gui-text.dcs-item-count-allowed-label"}
    }
    -- Set the size of the items_allowed_count_label
    items_allowed_count_label.style.top_margin = 2
    items_allowed_count_label.style.right_margin = 8

    -- Add a text field for items allowed_values
    local items_allowed_count_field = items_allowed_frame.add {
        type = "textfield",
        name = "dcs_items_allowed_count_field",
        numeric=true,
        allow_decimal=false,
        allow_negative=false,
        text = tostring(global.max_unique_items)
    }
    -- Set the size of the items_allowed_count_field
    items_allowed_count_field.style.minimal_width = 20
    items_allowed_count_field.style.maximal_width = 40
    -- Disable the items_allowed_count_field
    items_allowed_count_field.enabled = false

    -- Create the Get Item button
    local get_item_button = content_nav_frame.add {
        type = "button",
        name = "dcs_get_item_button",
        caption = {"gui-text.dcs-get-item-button"}
    }
    -- Set the size of the get_item_button
    get_item_button.style.top_margin = 8

    -- Create the close button frame
    local close_window_frame = content_nav_frame.add {
        type = "frame",
        name = "dcs_close_window_frame",
        direction = "horizontal",
        style = "borderless_frame"
    }
    -- Set the size of the close_window_frame
    close_window_frame.style.top_margin = 16

    -- Create a checkbox to enable the close button
    local close_window_checkbox = close_window_frame.add {
        type = "checkbox",
        name = "dcs_close_window_checkbox",
        caption = {"gui-text.dcs-close-window-checkbox"},
        state = false
    }
    -- Set the size of the close_window_checkbox
    close_window_checkbox.style.top_margin = 2
    close_window_checkbox.style.right_margin = 8

    -- Create the Get Item button
    local close_window_button = close_window_frame.add {
        type = "button",
        name = "dcs_shut_vault",
        caption = {"gui-text.dcs-close-window-button"}
    }
    -- Disable the close_window_button
    close_window_button.enabled = false

    -- -- Create the items allowed count label
    -- local close_window_notice_label = content_nav_frame.add {
    --     type = "label",
    --     name = "dcs_close_window_notice_label",
    --     caption = {"gui-text.dcs-close-warning-notice"}
    -- }
    -- -- Set the size of the close_window_notice_label
    -- close_window_notice_label.style.maximal_width = 114
    -- close_window_notice_label.style.top_margin = 2
    -- close_window_notice_label.style.single_line = false
    -- close_window_notice_label.style.font = "default-small"

end
