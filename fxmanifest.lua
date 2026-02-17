fx_version 'cerulean'
game 'gta5'

name 'qb-tablet-pro'
author 'codex'
description 'Professional QBCore iPad-style faction tablet'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'shared/constants.lua',
    'shared/locales/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua'
}

server_scripts {
    'server/main.lua',
    'server/db.lua',
    'server/tablet_service.lua',
    'server/faction_service.lua',
    'server/commands.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles/*.css',
    'html/js/*.js',
    'sql/tablet.sql'
}
