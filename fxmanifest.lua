fx_version 'cerulean'
game 'gta5'

name 'qb-tablet-ios'
author 'codex'
description 'QBCore tablet with iOS style lock/setup and faction/family apps'
version '0.1.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'shared/locales/*.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
