QBTablet = QBTablet or {}
QBTablet.FactionService = {}

local function fullName(Player)
    local ci = Player.PlayerData.charinfo or {}
    return (ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or '')
end

local function isFaction(Player)
    return Player and Player.PlayerData and Player.PlayerData.job and Config.FactionJobs[Player.PlayerData.job.name] == true
end

local function actorOf(Player)
    return {
        name = fullName(Player),
        id = Player.PlayerData.source,
        rank = (Player.PlayerData.job.grade and Player.PlayerData.job.grade.name) or 'Brak'
    }
end

function QBTablet.FactionService.getPlayerPermissions(Player)
    local grade = (Player.PlayerData.job and Player.PlayerData.job.grade and Player.PlayerData.job.grade.level) or 0
    local rank = QBTablet.State.faction.ranks[grade] or Config.DefaultRanks[grade] or Config.DefaultRanks[0]
    return rank.permissions or {}
end

function QBTablet.FactionService.log(actor, action, comment, amount)
    QBTablet.State.faction.logs[#QBTablet.State.faction.logs + 1] = {
        who = actor.name,
        source = actor.id,
        rank = actor.rank,
        action = action,
        comment = comment or '',
        amount = amount or 0,
        date = os.date('%Y-%m-%d %H:%M:%S')
    }
    QBTablet.TabletService.savePersistentState()

    QBTablet.DB.execute('INSERT INTO tablet_faction_logs (who, src, rank_name, action_name, comment, amount, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())', {
        actor.name, actor.id, actor.rank, action, comment or '', amount or 0
    })
end

function QBTablet.FactionService.startAutoFunding()
    CreateThread(function()
        while true do
            Wait(Config.AutoFactionIncome.everyMs)
            QBTablet.State.faction.balance = (QBTablet.State.faction.balance or 0) + Config.AutoFactionIncome.amount
            QBTablet.FactionService.log({ name = 'Urząd Miasta', id = 0, rank = '-' }, 'AUTO_DEPOSIT', Config.AutoFactionIncome.comment, Config.AutoFactionIncome.amount)
        end
    end)
end

QBCore.Functions.CreateCallback('qb-tablet:server:factionDashboard', function(source, cb)
    local Player = QBTablet.QBCore.Functions.GetPlayer(source)
    if not isFaction(Player) then return cb({ ok = false, message = Lang:t('ui.not_in_faction') }) end

    local members = {}
    for _, id in pairs(QBTablet.QBCore.Functions.GetPlayers()) do
        local p = QBTablet.QBCore.Functions.GetPlayer(id)
        if isFaction(p) then
            local cid = p.PlayerData.citizenid
            members[#members + 1] = {
                citizenid = cid,
                source = p.PlayerData.source,
                name = fullName(p),
                rank = (p.PlayerData.job.grade and p.PlayerData.job.grade.name) or 'Brak',
                role = (p.PlayerData.job and p.PlayerData.job.label) or 'LSPD',
                online = true,
                warns = QBTablet.State.faction.warnings[cid] or 0,
                todayHours = 0,
                hiredBy = 'System'
            }
        end
    end

    cb({
        ok = true,
        me = actorOf(Player),
        balance = QBTablet.State.faction.balance,
        members = members,
        logs = QBTablet.State.faction.logs,
        blacklist = QBTablet.State.faction.blacklist,
        ranks = QBTablet.State.faction.ranks,
        warrants = QBTablet.State.faction.warrants,
        fines = QBTablet.State.faction.fines,
        arrests = QBTablet.State.faction.arrests,
        transport = Config.TransportCatalog,
        permissions = QBTablet.FactionService.getPlayerPermissions(Player)
    })
end)

QBCore.Functions.CreateCallback('qb-tablet:server:factionAction', function(source, cb, payload)
    local Player = QBTablet.QBCore.Functions.GetPlayer(source)
    if not isFaction(Player) then return cb({ ok = false, message = 'Brak dostępu' }) end
    local action = payload and payload.action
    local actor = actorOf(Player)

    if action == 'deposit' then
        local amount = tonumber(payload.amount) or 0
        if amount <= 0 then return cb({ ok = false, message = 'Błędna kwota' }) end
        QBTablet.State.faction.balance = QBTablet.State.faction.balance + amount
        QBTablet.FactionService.log(actor, 'DEPOSIT', payload.comment, amount)
        return cb({ ok = true, balance = QBTablet.State.faction.balance })
    elseif action == 'withdraw' then
        local amount = tonumber(payload.amount) or 0
        if amount <= 0 or amount > QBTablet.State.faction.balance then return cb({ ok = false, message = 'Brak środków' }) end
        QBTablet.State.faction.balance = QBTablet.State.faction.balance - amount
        QBTablet.FactionService.log(actor, 'WITHDRAW', payload.comment, amount)
        return cb({ ok = true, balance = QBTablet.State.faction.balance })
    elseif action == 'member_warn_add' then
        local cid = payload.citizenid
        local warns = (QBTablet.State.faction.warnings[cid] or 0) + 1
        QBTablet.State.faction.warnings[cid] = warns
        QBTablet.FactionService.log(actor, 'WARN_ADD', payload.reason, 0)
        if warns >= Config.WarnLimit then
            QBTablet.State.faction.warnings[cid] = 0
            local target = QBTablet.QBCore.Functions.GetPlayerByCitizenId(cid)
            if target then target.Functions.SetJob('unemployed', 0) end
            QBTablet.FactionService.log(actor, 'AUTO_FIRE_WARN_LIMIT', payload.reason or '3 WARN', 0)
            return cb({ ok = true, fired = true, warns = Config.WarnLimit })
        end
        return cb({ ok = true, warns = warns })
    elseif action == 'member_warn_remove' then
        local cid = payload.citizenid
        local warns = math.max((QBTablet.State.faction.warnings[cid] or 0) - 1, 0)
        QBTablet.State.faction.warnings[cid] = warns
        QBTablet.FactionService.log(actor, 'WARN_REMOVE', payload.reason, 0)
        return cb({ ok = true, warns = warns })
    elseif action == 'member_fire' then
        local target = QBTablet.QBCore.Functions.GetPlayerByCitizenId(payload.citizenid)
        if target then target.Functions.SetJob('unemployed', 0) end
        QBTablet.FactionService.log(actor, 'FIRE', payload.reason, 0)
        if payload.addToBlacklist then
            QBTablet.State.faction.blacklist[#QBTablet.State.faction.blacklist + 1] = {
                by = actor.name,
                bySource = actor.id,
                targetName = payload.targetName,
                citizenid = payload.citizenid,
                reason = payload.reason,
                date = os.date('%Y-%m-%d %H:%M:%S')
            }
            QBTablet.FactionService.log(actor, 'BLACKLIST_ADD', payload.reason, 0)
        end
        QBTablet.TabletService.savePersistentState()
        return cb({ ok = true })
    elseif action == 'member_promote' or action == 'member_demote' then
        local target = QBTablet.QBCore.Functions.GetPlayerByCitizenId(payload.citizenid)
        if not target then return cb({ ok = false, message = 'Gracz offline' }) end
        local level = tonumber(payload.gradeLevel)
        if level == nil then return cb({ ok = false, message = 'Brak rangi' }) end
        target.Functions.SetJob(target.PlayerData.job.name, level)
        QBTablet.FactionService.log(actor, action == 'member_promote' and 'PROMOTE' or 'DEMOTE', payload.reason, 0)
        return cb({ ok = true })
    elseif action == 'member_bonus' then
        local amount = tonumber(payload.amount) or 0
        if amount <= 0 or amount > QBTablet.State.faction.balance then return cb({ ok = false, message = 'Brak środków' }) end
        QBTablet.State.faction.balance = QBTablet.State.faction.balance - amount
        QBTablet.FactionService.log(actor, 'BONUS', payload.reason, amount)
        return cb({ ok = true, balance = QBTablet.State.faction.balance })
    elseif action == 'blacklist_remove' then
        for i, row in ipairs(QBTablet.State.faction.blacklist) do
            if row.citizenid == payload.citizenid then table.remove(QBTablet.State.faction.blacklist, i) break end
        end
        QBTablet.FactionService.log(actor, 'BLACKLIST_REMOVE', payload.reason or '', 0)
        QBTablet.TabletService.savePersistentState()
        return cb({ ok = true })
    elseif action == 'db_add_warrant' then
        QBTablet.State.faction.warrants[#QBTablet.State.faction.warrants + 1] = {
            citizenid = payload.citizenid, stars = payload.stars, reason = payload.reason, by = actor.name, date = os.date('%Y-%m-%d %H:%M:%S')
        }
        QBTablet.FactionService.log(actor, 'WARRANT', payload.reason, payload.stars)
        QBTablet.TabletService.savePersistentState()
        return cb({ ok = true })
    elseif action == 'db_add_fine' then
        QBTablet.State.faction.fines[#QBTablet.State.faction.fines + 1] = {
            name = payload.name, amount = tonumber(payload.amount) or 0, reason = payload.reason, by = actor.name, date = os.date('%Y-%m-%d %H:%M:%S')
        }
        QBTablet.FactionService.log(actor, 'FINE', payload.reason, tonumber(payload.amount) or 0)
        QBTablet.TabletService.savePersistentState()
        return cb({ ok = true })
    elseif action == 'db_add_arrest' then
        QBTablet.State.faction.arrests[#QBTablet.State.faction.arrests + 1] = {
            citizenid = payload.citizenid, months = tonumber(payload.months) or 0, fine = tonumber(payload.fine) or 0, by = actor.name, date = os.date('%Y-%m-%d %H:%M:%S')
        }
        QBTablet.State.faction.balance = QBTablet.State.faction.balance + 5000
        QBTablet.FactionService.log(actor, 'ARREST', ('miesiące:%s'):format(payload.months or 0), 5000)
        QBTablet.TabletService.savePersistentState()
        return cb({ ok = true, balance = QBTablet.State.faction.balance })
    elseif action == 'spawn_transport' then
        local vehicle = nil
        for _, row in ipairs(Config.TransportCatalog) do
            if row.key == payload.key then vehicle = row break end
        end
        if not vehicle then return cb({ ok = false, message = 'Nie znaleziono transportu' }) end
        TriggerClientEvent('qb-tablet:client:transportBlip', source, {
            x = vehicle.coords.x, y = vehicle.coords.y, z = vehicle.coords.z
        })
        QBTablet.FactionService.log(actor, 'TRANSPORT_REQUEST', vehicle.label, 0)
        return cb({ ok = true, vehicle = vehicle })
    end

    cb({ ok = false, message = 'Nieobsługiwana akcja' })
end)
