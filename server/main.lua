local QBCore = exports['qb-core']:GetCoreObject()

local DATA_FILE = 'tablet_data.json'
local State = {
    families = {},
    faction = {
        balance = 0,
        logs = {},
        warnings = {},
        blacklist = {},
        ranks = Config.DefaultRankPermissions,
    }
}

local function loadState()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if raw and raw ~= '' then
        local decoded = json.decode(raw)
        if decoded then State = decoded end
    end
end

local function saveState()
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, json.encode(State), -1)
end

local function playerFullName(Player)
    local ci = Player.PlayerData.charinfo or {}
    return (ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or '')
end

local function getIdentifier(Player)
    return Player.PlayerData.citizenid
end

local function isFactionMember(Player)
    local job = (Player.PlayerData.job and Player.PlayerData.job.name) or ''
    return Config.FactionJobs[job] == true
end

local function pushFactionLog(actor, action, comment, amount)
    State.faction.logs[#State.faction.logs + 1] = {
        who = actor.name,
        rank = actor.rank,
        action = action,
        comment = comment,
        amount = amount or 0,
        at = os.date('%Y-%m-%d %H:%M:%S')
    }
    saveState()
end

CreateThread(function()
    loadState()
    while true do
        Wait(Config.FactionAutoIncomeMs)
        State.faction.balance = (State.faction.balance or 0) + Config.FactionAutoIncomeAmount
        pushFactionLog({ name = 'Urząd Miasta', rank = '-' }, 'wpłata', 'Automatyczny przelew', Config.FactionAutoIncomeAmount)
    end
end)

QBCore.Functions.CreateCallback('qb-tablet:server:getBootstrap', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    local metadata = Player.PlayerData.metadata.tablet or {}
    cb({
        configured = metadata.configured == true,
        language = metadata.language or Config.DefaultLanguage,
        identity = {
            name = playerFullName(Player),
            rank = (Player.PlayerData.job and Player.PlayerData.job.label) or 'Cywil',
            grade = (Player.PlayerData.job and Player.PlayerData.job.grade and Player.PlayerData.job.grade.name) or 'Brak'
        },
        hasFaction = isFactionMember(Player),
        family = metadata.family,
        transport = Config.TransportPoints,
    })
end)

QBCore.Functions.CreateCallback('qb-tablet:server:completeSetup', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false, 'No player') end
    if type(data) ~= 'table' or not data.language or not data.pin then
        return cb(false, 'Invalid setup')
    end

    Player.Functions.SetMetaData('tablet', {
        configured = true,
        language = data.language,
        pin = tostring(data.pin),
        family = (Player.PlayerData.metadata.tablet and Player.PlayerData.metadata.tablet.family) or nil,
    })
    cb(true)
end)

QBCore.Functions.CreateCallback('qb-tablet:server:unlock', function(source, cb, pin)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end
    local metadata = Player.PlayerData.metadata.tablet or {}
    cb(tostring(metadata.pin or '') == tostring(pin or ''))
end)

QBCore.Functions.CreateCallback('qb-tablet:server:createFamily', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ ok = false }) end
    if not data or not data.name or data.name == '' then return cb({ ok = false, message = 'Brak nazwy' }) end

    local metadata = Player.PlayerData.metadata.tablet or {}
    metadata.family = data.name
    Player.Functions.SetMetaData('tablet', metadata)
    State.families[getIdentifier(Player)] = {
        name = data.name,
        createdAt = os.time(),
    }
    saveState()
    cb({ ok = true, family = data.name })
end)

QBCore.Functions.CreateCallback('qb-tablet:server:getFactionData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not isFactionMember(Player) then return cb({ ok = false, message = Lang:t('ui.not_in_faction') }) end

    local members = {}
    for _, id in pairs(QBCore.Functions.GetPlayers()) do
        local Target = QBCore.Functions.GetPlayer(id)
        if Target and isFactionMember(Target) then
            members[#members + 1] = {
                citizenid = Target.PlayerData.citizenid,
                source = Target.PlayerData.source,
                name = playerFullName(Target),
                rank = (Target.PlayerData.job.grade and Target.PlayerData.job.grade.name) or 'Brak',
                job = Target.PlayerData.job.name,
                online = true,
                warns = State.faction.warnings[Target.PlayerData.citizenid] or 0,
            }
        end
    end

    cb({
        ok = true,
        balance = State.faction.balance,
        members = members,
        blacklist = State.faction.blacklist,
        logs = State.faction.logs,
        ranks = State.faction.ranks,
    })
end)

QBCore.Functions.CreateCallback('qb-tablet:server:factionAction', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not isFactionMember(Player) then return cb({ ok = false }) end
    if type(data) ~= 'table' then return cb({ ok = false }) end

    local actor = {
        name = playerFullName(Player),
        rank = (Player.PlayerData.job.grade and Player.PlayerData.job.grade.name) or 'Brak'
    }

    if data.type == 'deposit' then
        local amount = tonumber(data.amount) or 0
        if amount <= 0 then return cb({ ok = false, message = 'Błędna kwota' }) end
        State.faction.balance = State.faction.balance + amount
        pushFactionLog(actor, 'wpłata', data.comment or '', amount)
        return cb({ ok = true, balance = State.faction.balance })
    elseif data.type == 'withdraw' then
        local amount = tonumber(data.amount) or 0
        if amount <= 0 or amount > State.faction.balance then return cb({ ok = false, message = 'Brak środków' }) end
        State.faction.balance = State.faction.balance - amount
        pushFactionLog(actor, 'wypłata', data.comment or '', amount)
        return cb({ ok = true, balance = State.faction.balance })
    elseif data.type == 'warn' then
        local cid = data.citizenid
        if not cid then return cb({ ok = false }) end
        local warns = (State.faction.warnings[cid] or 0) + 1
        if warns >= Config.WarnLimit then
            State.faction.warnings[cid] = 0
            local offline = QBCore.Functions.GetPlayerByCitizenId(cid)
            if offline then
                offline.Functions.SetJob('unemployed', 0)
            end
            pushFactionLog(actor, 'zwolnienie', 'Limit WARN', 0)
            return cb({ ok = true, removed = true })
        else
            State.faction.warnings[cid] = warns
            pushFactionLog(actor, 'warn', data.reason or '', 0)
            saveState()
            return cb({ ok = true, warns = warns })
        end
    elseif data.type == 'blacklist_add' then
        State.faction.blacklist[#State.faction.blacklist + 1] = {
            by = actor.name,
            target = data.targetName,
            citizenid = data.citizenid,
            reason = data.reason,
            at = os.date('%Y-%m-%d %H:%M:%S')
        }
        saveState()
        return cb({ ok = true })
    elseif data.type == 'blacklist_remove' then
        for i, v in ipairs(State.faction.blacklist) do
            if v.citizenid == data.citizenid then
                table.remove(State.faction.blacklist, i)
                break
            end
        end
        saveState()
        return cb({ ok = true })
    end

    cb({ ok = false, message = 'Unsupported action' })
end)

RegisterCommand(Config.LeaderCommand, function(source, args)
    local src = source
    if src ~= 0 then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or Player.PlayerData.job.name ~= 'police' then
            TriggerClientEvent('qb-tablet:client:notify', src, 'Brak uprawnień', 'error')
            return
        end
    end

    local targetId = tonumber(args[1])
    if not targetId then return end
    local Target = QBCore.Functions.GetPlayer(targetId)
    if not Target then return end

    Target.Functions.SetJob('police', 2)
    TriggerClientEvent('qb-tablet:client:notify', targetId, 'Nadano rangę Leader LSPD', 'success')
end)

RegisterCommand(Config.GlobalNewsCommand, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not isFactionMember(Player) then return end
    local text = table.concat(args, ' ')
    if text == '' then return end
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 52, 152, 219 },
        multiline = true,
        args = { '[LSPD NEWS]', text }
    })
end)
