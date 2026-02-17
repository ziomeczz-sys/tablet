local QBCore = exports['qb-core']:GetCoreObject()

QBTablet = QBTablet or {}
QBTablet.QBCore = QBCore
QBTablet.State = {
    faction = {
        balance = 0,
        logs = {},
        warnings = {},
        blacklist = {},
        ranks = Config.DefaultRanks,
        warrants = {},
        fines = {},
        arrests = {}
    },
    families = {}
}

CreateThread(function()
    QBTablet.DB.init()
    QBTablet.TabletService.loadPersistentState()
    QBTablet.FactionService.loadRanksFromDb()
    QBTablet.FactionService.startAutoFunding()
end)
