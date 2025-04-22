SvConfig = {}

-- Framework detection
SvConfig.Framework = 'standalone' -- Default to standalone
SvConfig.ESX = nil

-- Initialize framework
CreateThread(function()
    if GetResourceState('es_extended') ~= 'missing' then
        SvConfig.Framework = 'esx'
        SvConfig.ESX = exports['es_extended']:getSharedObject()
        print('[hajden_tuning] ESX framework detected')
    else
        print('[hajden_tuning] Running in standalone mode')
    end
end)

-- Get player job
SvConfig.getPlayerJob = function(source)
    if SvConfig.Framework == 'esx' and SvConfig.ESX then
        local xPlayer = SvConfig.ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getJob().name
        end
    end
    return 'unemployed' -- Default job if framework not found
end

-- Check if player is a mechanic
SvConfig.isPlayerMechanic = function(source)
    if not Config.RestrictToMechanics then
        return true -- If restriction is disabled, everyone can tune
    end
    
    if SvConfig.Framework == 'esx' and SvConfig.ESX then
        local job = SvConfig.getPlayerJob(source)
        return job == Config.MechanicJobName
    end
    
    return true -- Default to true if framework not found
end

SvConfig.removeMoney = function(source, amount)
    if SvConfig.Framework == 'esx' and SvConfig.ESX then
        local xPlayer = SvConfig.ESX.GetPlayerFromId(source)
        if xPlayer then
            if xPlayer.getMoney() >= amount then
                xPlayer.removeMoney(amount)
                return true
            else
                return false
            end
        end
    else
        -- Fallback to ox_inventory if ESX is not detected
        return exports.ox_inventory:RemoveItem(source, 'money', amount)
    end
end

SvConfig.canAffordModification = function(source, modType, level)
    local price = Config.ModPrices[modType]
    if type(price) == "table" then
        price = price[level]
    end

    if SvConfig.Framework == 'esx' and SvConfig.ESX then
        local xPlayer = SvConfig.ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getMoney() >= price, price
        end
    else
        -- Fallback to ox_inventory if ESX is not detected
        local money = exports.ox_inventory:GetItem(source, 'money', nil, true)
        return money >= price, price
    end
    
    return false, price
end

SvConfig.ServerNotify = function(source, Type, description)
    TriggerClientEvent('ox_lib:notify', source, {type = Type, description = description})
end