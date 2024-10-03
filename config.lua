Config = {}

Config.Notify = function(Type, description)
    lib.notify({type = Type, description = description})
end

-- Available modification types
Config.ModificationTypes = {
    'engine',
    'brakes',
    'transmission',
    'suspension',
    'armor',
    'turbo',
    'color'
}

Config.ModTypeIndexes = {
    engine = 11,
    brakes = 12,
    transmission = 13,
    suspension = 15,
    armor = 16,
    -- Add other mod types and their corresponding indices here
}

Config.ModIcons = {
    engine = "gears",
    brakes = "hand",
    transmission = "cogs",
    suspension = "bars",
    armor = "shield-alt",
    turbo = "wind",
    color = "palette"
}

-- Prices for each modification type and level
Config.ModPrices = {
    engine = {1000, 2000, 3000, 4000},
    brakes = {500, 1000, 1500, 2000},
    transmission = {500, 1000, 1500, 2000},
    suspension = {500, 1000, 1500, 2000},
    armor = {500, 1000, 1500, 2000, 2500},
    primary_color = 1000,
    secondary_color = 1000,
    pearlescent_color = 2000,
    turbo = {5000},
    color = {1000}
}

-- Maximum levels for each modification type
Config.MaxLevels = {
    engine = 4,
    brakes = 3,
    transmission = 3,
    suspension = 4,
    armor = 5,
    turbo = 1
}

-- Error messages
Config.ErrorMessages = {
    not_in_vehicle = "You must be in a vehicle to use this command.",
    not_driver = "You must be the driver to modify this vehicle.",
    insufficient_funds = "You don't have enough money for this modification.",
    max_level_reached = "This modification is already at its maximum level."
}