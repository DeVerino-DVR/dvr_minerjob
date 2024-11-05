fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

shared_scripts { 
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts { 
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

lua54 'yes'

dependency 'ox_lib'
dependency 'ox_target'
dependency 'rsg-core'