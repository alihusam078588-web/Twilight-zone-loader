-- Twilight Zone Loader
local url = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local success, err = pcall(function()
    loadstring(game:HttpGet(url))()
end)

if not success then
    warn("[TZ Loader] ❌ Runtime error:", err)
else
    print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
end
