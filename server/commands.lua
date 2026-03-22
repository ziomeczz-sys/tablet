RegisterCommand(Config.LeaderCommand, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    if not targetId then return end

    if src ~= 0 then
        local Player = QBTablet.QBCore.Functions.GetPlayer(src)
        if not Player or Player.PlayerData.job.name ~= 'police' then
            return TriggerClientEvent('qb-tablet:client:notify', src, 'Brak uprawnień', 'error')
        end
    end

    local Target = QBTablet.QBCore.Functions.GetPlayer(targetId)
    if not Target then return end

    Target.Functions.SetJob('police', 2)
    TriggerClientEvent('qb-tablet:client:notify', targetId, 'Nadano rangę Leader LSPD', 'success')
end)

RegisterCommand(Config.GlobalNewsCommand, function(source, args)
    local Player = QBTablet.QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local perms = QBTablet.FactionService.getPlayerPermissions(Player)
    if not perms.canGNews then return end

    local text = table.concat(args, ' ')
    if text == '' then return end

    TriggerClientEvent('chat:addMessage', -1, {
        color = { 52, 152, 219 },
        multiline = true,
        args = { '[LSPD NEWS]', text }
    })
end)
