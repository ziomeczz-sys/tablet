QBTablet = QBTablet or {}
QBTablet.DB = {}

local function hasOxmysql()
    return GetResourceState('oxmysql') == 'started'
end

function QBTablet.DB.init()
    if not hasOxmysql() then
        print('[qb-tablet] oxmysql not started, using json fallback state only.')
        return
    end
    print('[qb-tablet] oxmysql detected. SQL file: sql/tablet.sql')
end

function QBTablet.DB.fetchAll(query, params, cb)
    if not hasOxmysql() then return cb({}) end
    exports.oxmysql:fetch(query, params or {}, cb)
end

function QBTablet.DB.execute(query, params, cb)
    if not hasOxmysql() then if cb then cb(0) end return end
    exports.oxmysql:execute(query, params or {}, cb)
end
