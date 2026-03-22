local QBCore = exports['qb-core']:GetCoreObject()

local Tablet = { opened = false, bootstrap = nil }

function Tablet:open()
    if self.opened then return end
    QBCore.Functions.TriggerCallback('qb-tablet:server:getBootstrap', function(payload)
        self.bootstrap = payload
        self.opened = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'tablet:open', payload = payload })
    end)
end

function Tablet:close()
    self.opened = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'tablet:close' })
end

RegisterCommand(Config.TabletCommand, function() Tablet:open() end)

RegisterNetEvent('qb-tablet:client:notify', function(message, kind)
    QBCore.Functions.Notify(message, kind or 'primary')
end)

RegisterNetEvent('qb-tablet:client:transportBlip', function(payload)
    local blip = AddBlipForCoord(payload.x, payload.y, payload.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 3)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Dostawa transportu')
    EndTextCommandSetBlipName(blip)
end)


RegisterCommand('tabletkey', function()
    Tablet:open()
end, false)

RegisterKeyMapping('tabletkey', 'Otwórz tablet', 'keyboard', '5')
