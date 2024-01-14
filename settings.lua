-- settings.lua

-- Define the settings
data:extend{
    {
        name             = "dcs-max-unique-items",
        type             = "int-setting",
        setting_type     = "startup",
        default_value    = 3,
        allowed_values   = {3, 6, 9, 12, 15, 18, 21, 24},
        order            = "dcs-a",
    },
    {
        name             = "dcs-max-allowed-item-time",
        type             = "int-setting",
        setting_type     = "startup",
        default_value    = 5,
        minimum_value    = 1,
        maximum_value    = 6000,
        order            = "dcs-b"
    },
    {
        name             = "dcs-show-hidden-items",
        type             = "bool-setting",
        setting_type     = "startup",
        default_value    = true,
        order            = "dcs-c"
    }
}
