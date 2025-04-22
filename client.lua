local function isDriver()
    return cache.seat == -1
end

local function isAtTuningLocation()
    if not Config.UseLocationRestrictions then
        return true -- If location restrictions are disabled, return true
    end
    
    local playerCoords = GetEntityCoords(cache.ped)
    
    for _, location in ipairs(Config.TuningLocations) do
        local distance = #(playerCoords - location.coords)
        if distance <= location.radius then
            return true, location.name
        end
    end
    
    return false
end

local function getAvailableModifications()
    local vehicle = cache.vehicle
    if not vehicle then return {} end

    local mods = {}
    for _, modType in ipairs(Config.ModificationTypes) do
        local modTypeIndex = Config.ModTypeIndexes[modType]
        
        if modType ~= 'color' and modType ~= 'turbo' then
            if modTypeIndex then
                local maxMod = GetNumVehicleMods(vehicle, modTypeIndex) - 1
                if maxMod > 0 then
                    mods[modType] = maxMod
                end
            end
        elseif modType == 'turbo' then
            -- Check if turbo is available for this vehicle
            if IsToggleModOn(vehicle, 18) or GetNumVehicleMods(vehicle, 18) > 0 then
                mods[modType] = IsToggleModOn(vehicle, 18) and 1 or 0
            end
        elseif modType == 'color' then
            mods[modType] = true
        end
    end
    return mods
end

local function safeGetVehicleMod(vehicle, modType)
    if not vehicle then return 0 end
    local modTypeIndex = Config.ModTypeIndexes[modType]
    if not modTypeIndex then return 0 end
    if modType == 'turbo' then
        return IsToggleModOn(vehicle, modTypeIndex) and 1 or 0
    else
        return GetVehicleMod(vehicle, modTypeIndex) + 1
    end
end

local function applyModification(modType, level, colorData)
    local vehicle = cache.vehicle
    if not vehicle then
        return false
    end

    if modType == 'primary_color' and colorData then
        SetVehicleCustomPrimaryColour(vehicle, colorData.r, colorData.g, colorData.b)
        return true
    elseif modType == 'secondary_color' and colorData then
        SetVehicleCustomSecondaryColour(vehicle, colorData.r, colorData.g, colorData.b)
        return true
    elseif modType == 'pearlescent_color' and colorData then
        local pearlescentIndex = colorData.r
        local _, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, pearlescentIndex, wheelColor)
        return true
    else
        local modTypeIndex = Config.ModTypeIndexes[modType]
        if modTypeIndex then
            if modType == 'turbo' then
                ToggleVehicleMod(vehicle, modTypeIndex, level == 1)
            else
                SetVehicleMod(vehicle, modTypeIndex, level - 1, false)
            end
            return true
        end
    end

    return false
end

function hexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

local function createModificationMenu(mods)
    local options = {}

    for modType, maxLevel in pairs(mods) do
        local currentLevel = GetVehicleMod(cache.vehicle, Config.ModTypeIndexes[modType]) + 1
        if modType == 'turbo' then
            currentLevel = IsToggleModOn(cache.vehicle, Config.ModTypeIndexes[modType]) and 1 or 0
        end
        
        local levelCount = Config.MaxLevels[modType] or maxLevel

        local progressPercent = -21
        if levelCount ~= true and levelCount ~= nil then
            progressPercent = (currentLevel / levelCount) * 100
        end
        local progressColor = 'red'
        if (currentLevel == 0 and levelCount == 1) then
            progressColor = 'red'
            progressPercent = 25
        elseif (currentLevel == 1 and levelCount == 1) then
            progressColor = 'green'
            progressPercent = 100
        elseif progressPercent >= 75 then
            progressColor = 'green'
        elseif progressPercent >= 35 then
            progressColor = 'orange'
        elseif progressPercent <= 25 and progressPercent ~= -21 then
            progressPercent = 25
        end

        local option = {
            title = modType:gsub("^%l", string.upper),
            description = 'Modify ' .. modType,
            icon = Config.ModIcons[modType],
            progress = progressPercent ~= -21 and progressPercent or nil,
            colorScheme = progressPercent ~= -21 and progressColor or nil,
            menu = modType ~= 'color' and modType .. '_menu' or nil,
            metadata = {
                {label = 'Current Level', value = currentLevel},
                {label = 'Max Level', value = maxLevel}
            }
        }

        if modType == 'color' then
            option.onSelect = function()
                lib.registerContext({
                    id = 'color_menu',
                    title = 'Select Color Type',
                    menu = 'tuning_menu',
                    options = {
                        {
                            title = 'Primary Color',
                            description = 'Modify the primary color',
                            onSelect = function()
                                local input = lib.inputDialog('Choose Primary Color', {
                                    {type = 'color', label = 'Primary Color Picker', default = '#FFFFFF'}
                                })
                                if input then
                                    local r, g, b = hexToRGB(input[1])
                                    TriggerServerEvent('vehicleTuning:purchaseModification', 'primary_color', 1, {r = r, g = g, b = b})
                                end
                            end
                        },
                        {
                            title = 'Secondary Color',
                            description = 'Modify the secondary color',
                            onSelect = function()
                                local input = lib.inputDialog('Choose Secondary Color', {
                                    {type = 'color', label = 'Secondary Color Picker', default = '#FFFFFF'}
                                })
                                if input then
                                    local r, g, b = hexToRGB(input[1])
                                    TriggerServerEvent('vehicleTuning:purchaseModification', 'secondary_color', 1, {r = r, g = g, b = b})
                                end
                            end
                        },
                        {
                            title = 'Pearlescent Color',
                            description = 'Modify the pearlescent color',
                            onSelect = function()
                                local input = lib.inputDialog('Choose Pearlescent Color', {
                                    {type = 'color', label = 'Pearlescent Color Picker', default = '#FFFFFF'}
                                })
                                if input then
                                    local r, g, b = hexToRGB(input[1])
                                    TriggerServerEvent('vehicleTuning:purchaseModification', 'pearlescent_color', 1, {r = r, g = g, b = b})
                                end
                            end
                        }
                    }
                })
                lib.showContext('color_menu')
            end
        else
            local subOptions = {}

            for i = 1, levelCount do
                table.insert(subOptions, {
                    title = 'Level ' .. i,
                    description = 'Upgrade to level ' .. i,
                    onSelect = function()
                        local price = Config.ModPrices[modType]
                        if type(price) == "table" then
                            price = price[i]
                        end
                        local confirm = lib.alertDialog({
                            header = 'Confirm Purchase',
                            content = 'Do you want to spend $' .. price .. ' for ' .. modType .. ' Level ' .. i .. '?',
                            centered = true,
                            cancel = true
                        })
                        if confirm == 'confirm' then
                            TriggerServerEvent('vehicleTuning:purchaseModification', modType, i)
                        end
                    end
                })
            end

            lib.registerContext({
                id = modType .. '_menu',
                title = modType:gsub("^%l", string.upper) .. ' Modifications',
                menu = 'tuning_menu',
                options = subOptions
            })
        end

        table.insert(options, option)
    end

    lib.registerContext({
        id = 'tuning_menu',
        title = 'Vehicle Tuning',
        options = options
    })

    lib.showContext('tuning_menu')
end

lib.callback.register('hajden_tuning:openTuning', function(source)
    if not cache.vehicle then
        Config.Notify('error', Config.ErrorMessages.not_in_vehicle)
        return
    end

    if not isDriver() then
        Config.Notify('error', Config.ErrorMessages.not_driver)
        return
    end
    
    -- Check if player is at a tuning location
    local atTuningLocation, locationName = isAtTuningLocation()
    if not atTuningLocation then
        Config.Notify('error', Config.ErrorMessages.not_at_tuning_location)
        return
    end
    
    if locationName then
        Config.Notify('success', 'Welcome to ' .. locationName)
    end

    local mods = getAvailableModifications()
    createModificationMenu(mods)
end)

RegisterNetEvent('vehicleTuning:applyModification')
AddEventHandler('vehicleTuning:applyModification', function(modType, level, colorData)
    local success = false
    if modType == 'primary_color' and colorData then
        SetVehicleCustomPrimaryColour(cache.vehicle, colorData.r, colorData.g, colorData.b)
        success = true
    elseif modType == 'secondary_color' and colorData then
        SetVehicleCustomSecondaryColour(cache.vehicle, colorData.r, colorData.g, colorData.b)
        success = true
    elseif modType == 'pearlescent_color' and colorData then
        local _, wheelColor = GetVehicleExtraColours(cache.vehicle)
        SetVehicleExtraColours(cache.vehicle, colorData.r, wheelColor)
        success = true
    else
        success = applyModification(modType, level)
    end

    if success then
        Config.Notify('success', 'Modification applied successfully!')
        
        local mods = getAvailableModifications()
        createModificationMenu(mods)
    else
        Config.Notify('error', 'Failed to apply modification.')
    end
end)

-- Add blips for tuning locations if enabled
if Config.UseLocationRestrictions then
    CreateThread(function()
        for _, location in ipairs(Config.TuningLocations) do
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, 446) -- Mechanic blip
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.7)
            SetBlipColour(blip, 5) -- Yellow
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(location.name)
            EndTextCommandSetBlipName(blip)
        end
    end)
end
