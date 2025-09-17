-- loader.lua
local ok, res = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua")
end)
if not ok or not res or res == "" then
    warn("Failed to fetch main.lua from GitHub. Check your raw URL / connectivity.")
    return
end
loadstring(res)()
