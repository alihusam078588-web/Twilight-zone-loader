-- Twilight Zone Loader
-- Loads main.lua from GitHub repo

local url = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local success, err = pcall(function()
    loadstring(game:HttpGet(url))()
end)

if not success then
    warn("[TZ Loader] ❌ Failed to load main.lua:", err)
else
    print("[TZ Loader] ✅ Successfully loaded Twilight Zone Rayfield GUI!")
end
