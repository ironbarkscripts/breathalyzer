fx_version 'cerulean'
game 'gta5'

author      'Ironbark Scripts'
description 'kg-alcolizer — server-authoritative breathalyser'
version     '2.2.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/alcolizer.png',
}

shared_scripts {
    'shared/config.lua',
    'shared/bridge.lua',
}

client_scripts {
    '@ox_lib/init.lua',
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
}

data_file 'DLC_ITYP_REQUEST' 'stream/prop_inhaler_01.ytyp'

dependencies {
    'ox_lib',
}
