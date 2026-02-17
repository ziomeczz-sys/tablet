Config = {}

Config.TabletCommand = 'tablet'
Config.LeaderCommand = 'lealspd'
Config.GlobalNewsCommand = 'gnews'

Config.DefaultLanguage = 'pl'
Config.SupportedLanguages = { 'pl', 'en' }
Config.FactionJobs = { police = true, lspd = true }
Config.WarnLimit = 3

Config.AutoFactionIncome = {
    everyMs = 30 * 60 * 1000,
    amount = 15000,
    comment = 'Przelew z urzędu'
}

Config.TransportCatalog = {
    { key = 'patrol_1', label = 'Vapid Stanier Patrol', model = 'police', coords = vector4(441.6, -984.2, 25.7, 90.0) },
    { key = 'patrol_2', label = 'Buffalo S Patrol', model = 'police2', coords = vector4(452.1, -1018.3, 28.5, 1.0) },
    { key = 'suv_1', label = 'FIB SUV', model = 'fbi2', coords = vector4(462.0, -1026.0, 28.1, 2.0) }
}

Config.PermissionKeys = {
    'canHire', 'canFire', 'canWarn', 'canStorage', 'canDeposit', 'canWithdraw',
    'canBonus', 'canPromote', 'canManageRanks', 'canLicenses', 'canGNews',
    'canFunding', 'canJail', 'canManageBlacklist', 'canDatabase'
}

Config.DefaultRanks = {
    [0] = {
        id = 'cadet', label = 'Kadet', salaryPerHour = 400,
        permissions = {
            canHire = false, canFire = false, canWarn = false, canStorage = false,
            canDeposit = true, canWithdraw = false, canBonus = false, canPromote = false,
            canManageRanks = false, canLicenses = false, canGNews = false, canFunding = false,
            canJail = false, canManageBlacklist = false, canDatabase = true
        }
    },
    [1] = {
        id = 'officer', label = 'Officer', salaryPerHour = 700,
        permissions = {
            canHire = false, canFire = false, canWarn = true, canStorage = true,
            canDeposit = true, canWithdraw = false, canBonus = false, canPromote = false,
            canManageRanks = false, canLicenses = true, canGNews = true, canFunding = false,
            canJail = true, canManageBlacklist = false, canDatabase = true
        }
    },
    [2] = {
        id = 'leader', label = 'Leader', salaryPerHour = 1500,
        permissions = {
            canHire = true, canFire = true, canWarn = true, canStorage = true,
            canDeposit = true, canWithdraw = true, canBonus = true, canPromote = true,
            canManageRanks = true, canLicenses = true, canGNews = true, canFunding = true,
            canJail = true, canManageBlacklist = true, canDatabase = true
        }
    }
}
