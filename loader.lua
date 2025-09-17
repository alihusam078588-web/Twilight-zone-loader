local ok, res = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua")
end)

if not ok or not res or res == "" then
    warn("[TZ Loader] Failed to load main.lua")
    return
end

loadstring(res)()
