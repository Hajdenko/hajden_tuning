fx_version('cerulean')
games({ 'gta5' })
lua54('yes')

author('hajdenkoo')
description('Simple Tuning System by hajdenkoo')
version('1.0.1')

shared_scripts({
    '@ox_lib/init.lua',
    'config.lua'
});

server_scripts({
    'server/*.lua',
    'sv_config.lua'
});

client_scripts({
    'client/*.lua'
});
