SvConfig = {}

SvConfig.removeMoney = function(source, amount)
    return exports.ox_inventory:RemoveItem(source, 'money', amount)
end

SvConfig.canAffordModification = function(source, modType, level)
    local price = Config.ModPrices[modType]
    if type(price) == "table" then
        price = price[level]
    end

    local money = exports.ox_inventory:GetItem(source, 'money', nil, true)
    return money >= price, price
end

SvConfig.ServerNotify = function(source, Type, description)
    TriggerClientEvent('ox_lib:notify', source, {type = Type, description = description})
end