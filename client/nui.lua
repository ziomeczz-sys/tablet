local QBCore = exports['qb-core']:GetCoreObject()

RegisterNUICallback('tablet:close', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'tablet:close' })
    cb({ ok = true })
end)

RegisterNUICallback('tablet:rpc', function(data, cb)
    if not data or not data.endpoint then return cb({ ok = false }) end
    QBCore.Functions.TriggerCallback(('qb-tablet:server:%s'):format(data.endpoint), function(resp)
        cb(resp)
    end, data.payload)
end)
