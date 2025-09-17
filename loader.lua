local url = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local ok, err = pcall(function()
    loadstring(game:HttpGet(url))()
end)

if ok then
    print("[TZ Loader] ✅ Successfully loaded main.lua")
else
    warn("[TZ Loader] ❌ Failed to load main.lua:", err)
end
