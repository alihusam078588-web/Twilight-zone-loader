-- Twilight Zone Loader
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"))()
end)

if not success then
    warn("[Twilight Zone Loader] Failed to load main.lua:", err)
end
