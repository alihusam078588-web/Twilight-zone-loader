-- Twilight Zone Loader
-- Created by Ali_hhjjj + ChatGPT

local scriptUrl = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/script.lua"
local success, response = pcall(function()
    return game:HttpGet(scriptUrl)
end)

if success then
    loadstring(response)()
else
    warn("Failed to load Twilight Zone script. Error:", response)
end
