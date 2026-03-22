local DATA_FILE = 'tablet_state.json'

QBTablet = QBTablet or {}
QBTablet.TabletService = {}

local function fullName(Player)
    local ci = Player.PlayerData.charinfo or {}
    return (ci.firstname or 'Unknown') .. ' ' .. (ci.lastname or '')
end

local function isFaction(Player)
    local job = (Player.PlayerData.job and Player.PlayerData.job.name) or ''
    return Config.FactionJobs[job] == true
end

function QBTablet.TabletService.loadPersistentState()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if raw and raw ~= '' then
        local decoded = json.decode(raw)
        if decoded then QBTablet.State = decoded end
    end
end

function QBTablet.TabletService.savePersistentState()
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, json.encode(QBTablet.State), -1)
end

QBTablet.QBCore.Functions.CreateCallback('qb-tablet:server:getBootstrap', function(source, cb)
    local Player = QBTablet.QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ configured = false }) end
    local tmd = Player.PlayerData.metadata.tablet or {}
    cb({
        configured = tmd.configured == true,
        language = tmd.language or Config.DefaultLanguage,
        identity = {
            name = fullName(Player),
            rankLabel = (Player.PlayerData.job and Player.PlayerData.job.grade and Player.PlayerData.job.grade.name) or 'Brak',
            jobLabel = (Player.PlayerData.job and Player.PlayerData.job.label) or 'Cywil',
            source = source,
            citizenid = Player.PlayerData.citizenid
        },
        hasFaction = isFaction(Player),
        family = tmd.family,
        transportCatalog = Config.TransportCatalog,
        permissions = QBTablet.FactionService.getPlayerPermissions(Player)
    })
end)

QBTablet.QBCore.Functions.CreateCallback('qb-tablet:server:setup', function(source, cb, payload)
    local Player = QBTablet.QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ ok = false, message = 'No player' }) end
    if type(payload) ~= 'table' or not payload.pin or not payload.language then return cb({ ok = false, message = 'Bad payload' }) end

    local md = Player.PlayerData.metadata.tablet or {}
    md.configured = true
    md.language = payload.language
    md.pin = tostring(payload.pin)
    md.family = md.family
    Player.Functions.SetMetaData('tablet', md)

    cb({ ok = true })
end)

QBTablet.QBCore.Functions.CreateCallback('qb-tablet:server:unlock', function(source, cb, payload)
    local Player = QBTablet.QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ ok = false }) end
    local md = Player.PlayerData.metadata.tablet or {}
    cb({ ok = tostring(md.pin or '') == tostring(payload.pin or '') })
end)

QBTablet.QBCore.Functions.CreateCallback('qb-tablet:server:createFamily', function(source, cb, payload)
    local Player = QBTablet.QBCore.Functions.GetPlayer(source)
    if not Player then return cb({ ok = false }) end
    local name = (payload and payload.name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then return cb({ ok = false, message = 'Podaj nazwę rodziny' }) end

    local cid = Player.PlayerData.citizenid
    QBTablet.State.families[cid] = { name = name, owner = cid, createdAt = os.time() }

    local md = Player.PlayerData.metadata.tablet or {}
    md.family = name
    Player.Functions.SetMetaData('tablet', md)

    QBTablet.TabletService.savePersistentState()

    QBTablet.DB.execute('INSERT INTO tablet_families (citizenid, family_name, created_at) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE family_name = VALUES(family_name)', { cid, name })

    cb({ ok = true, family = name })
end)
