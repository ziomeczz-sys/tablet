Config = {}

Config.TabletCommand = 'tablet'
Config.DefaultLanguage = 'pl'
Config.SupportedLanguages = { 'pl', 'en' }
Config.FactionJobs = {
    police = true,
    lspd = true,
}

Config.LeaderCommand = 'lealspd'
Config.GlobalNewsCommand = 'gnews'

Config.FactionAutoIncomeMs = 30 * 60 * 1000
Config.FactionAutoIncomeAmount = 15000

Config.WarnLimit = 3

Config.TransportPoints = {
    {
        label = 'Radiowóz #1',
        model = 'police',
        coords = vector4(441.6, -984.2, 25.7, 90.0)
    },
    {
        label = 'SUV #2',
        model = 'fbi2',
        coords = vector4(452.1, -1018.3, 28.5, 1.0)
    }
}

Config.DefaultRankPermissions = {
    recruit = {
        label = 'Kadet',
        salaryPerHour = 400,
        permissions = {
            canHire = false,
            canFire = false,
            canWarn = false,
            canStorage = true,
            canDeposit = true,
            canWithdraw = false,
            canBonus = false,
            canPromote = false,
            canManageRanks = false,
            canLicenses = false,
            canGNews = false,
            canFunding = false,
            canJail = false,
            canManageBlacklist = false,
            canDatabase = true,
        }
    }
}
