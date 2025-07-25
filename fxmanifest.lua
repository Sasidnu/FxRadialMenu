fx_version 'cerulean'
game 'gta5'
author 'Don-RedEye & Gemini'
description 'FxRadialMenu - Final Version'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_script 'config.lua'

client_scripts {
    'client/client.lua',
    'client/clothing.lua' -- clothing.lua integrate කරන්න
}
-- Remove trunk.lua and stretcher.lua references