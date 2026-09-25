fx_version "cerulean"
game "gta5"

author "kongcheng"
description "Standalone carry player script"
version "1.2.1"
dependency "ox_lib"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
}

client_scripts {
    "client.lua"
}

server_scripts {
    "server.lua"
}
