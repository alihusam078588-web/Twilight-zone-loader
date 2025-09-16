-- Twilight Zone Loader
local scriptUrl = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local success, result = pcall(function()
    return loadstring(game:HttpGet(scriptUrl))()
end)

if not success then
    warn("[Twilight Zone Loader] Failed to load script:", result)
else
    print("[Twilight Zone Loader] Loaded successfully!")
end
