-- style.lua

local styles = data.raw["gui-style"].default

-- New style that inherits from inside_shallow_frame
styles["dcs_inner_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame",
    top_padding = 4,
    right_padding = 4,
    bottom_padding = 4,
    left_padding = 4
}

-- New style that inherits from inside_deep_frame
styles["dcs_deep_frame"] = {
    type = "frame_style",
    parent = "inside_deep_frame",
    top_padding = 6,
    right_padding = 8,
    bottom_padding = 6,
    left_padding = 8
}
