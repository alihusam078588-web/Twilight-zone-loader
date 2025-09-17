-- Twilight Zone Loader
-- Safely loads main.lua from GitHub repo

local url = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

-- Try fetching script
local success, response = pcall(function()
    return game:HttpGet(url)
end)

if not success then
    warn("[TZ Loader] ❌ Failed to fetch main.lua:", response)
    return
end

-- Try executing script
local execSuccess, execError = pcall(function()
    loadstring(response)()
end)

if not execSuccess then
    warn("[TZ Loader] ❌ Error while running main.lua:", execError)
else
    print("[TZ Loader] ✅ Successfully loaded Twilight Zone GUI!")
end
