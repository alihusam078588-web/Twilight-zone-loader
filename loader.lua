-- Twilight Zone Loader
-- Loads main.lua from your GitHub repo

local url = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local success, result = pcall(function()
    local src = game:HttpGet(url)
    loadstring(src)()
end)

if not success then
    warn("[TZ Loader] ❌ Runtime error:", result)
else
    print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully from alihusam078588-web/Twilight-zone-loader!")
end
