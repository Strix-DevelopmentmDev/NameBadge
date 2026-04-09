fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'strix_badge'
author 'Strix Development'
description 'Optimized synced prop name badge system'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'oxmysql'
}