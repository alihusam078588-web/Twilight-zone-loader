-- Twilight Zone Loader
-- Author: Ali_hhjjj
-- Repo: alihusam078588-web/Twilight-zone-loader

local url = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local success, response = pcall(function()
    return game:HttpGet(url)
end)

if success then
    local func, loadErr = loadstring(response)
    if func then
        print("[TZ Loader] ✅ Successfully loaded Twilight Zone GUI!")
        func()
    else
        warn("[TZ Loader] ❌ Failed to compile main.lua:", loadErr)
    end
else
    warn("[TZ Loader] ❌ Runtime error: " .. tostring(response))
end
