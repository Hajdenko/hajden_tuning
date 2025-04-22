lib.addCommand('tuning', {
    help = 'Open vehicle tuning menu'
}, function(source, args, raw)
    -- Check if player is a mechanic (if restriction is enabled)
    if not SvConfig.isPlayerMechanic(source) then
        SvConfig.ServerNotify(source, 'error', Config.ErrorMessages.not_mechanic)
        return
    end
    
    lib.callback.await('hajden_tuning:openTuning', source)
end)

RegisterNetEvent('vehicleTuning:purchaseModification')
AddEventHandler('vehicleTuning:purchaseModification', function(modType, level, colorData)
    local source = source
    
    -- Check if player is a mechanic (if restriction is enabled)
    if not SvConfig.isPlayerMechanic(source) then
        SvConfig.ServerNotify(source, 'error', Config.ErrorMessages.not_mechanic)
        return
    end
    
    local canAfford, price = SvConfig.canAffordModification(source, modType, level)

    if canAfford then
        if SvConfig.removeMoney(source, price) then
            if modType == 'primary_color' or modType == 'secondary_color' or modType == 'pearlescent_color' then
                TriggerClientEvent('vehicleTuning:applyModification', source, modType, level, colorData)
            else
                TriggerClientEvent('vehicleTuning:applyModification', source, modType, level)
            end
            SvConfig.ServerNotify(source, 'success', 'Modification applied successfully!')
        else
            SvConfig.ServerNotify(source, 'error', Config.ErrorMessages.insufficient_funds)
        end
    else
        SvConfig.ServerNotify(source, 'error', Config.ErrorMessages.insufficient_funds)
    end
end)