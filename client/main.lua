local QBCore = exports['qb-core']:GetCoreObject()
local tabletOpen = false

local function openTablet()
    if tabletOpen then return end
    QBCore.Functions.TriggerCallback('qb-tablet:server:getBootstrap', function(data)
        tabletOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', payload = data })
    end)
end

local function closeTablet()
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.TabletCommand, function()
    openTablet()
end)

RegisterNUICallback('tablet:close', function(_, cb)
    closeTablet()
    cb({ ok = true })
end)

RegisterNUICallback('tablet:completeSetup', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:completeSetup', function(ok, message)
        cb({ ok = ok, message = message })
    end, data)
end)

RegisterNUICallback('tablet:unlock', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:unlock', function(ok)
        cb({ ok = ok })
    end, data.pin)
end)

RegisterNUICallback('tablet:getFaction', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:getFactionData', function(payload)
        cb(payload)
    end)
end)

RegisterNUICallback('tablet:createFamily', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:createFamily', function(resp)
        cb(resp)
    end, data)
end)

RegisterNUICallback('tablet:factionAction', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-tablet:server:factionAction', function(resp)
        cb(resp)
    end, data)
end)

RegisterNetEvent('qb-tablet:client:notify', function(message, type)
    QBCore.Functions.Notify(message, type or 'primary')
end)
