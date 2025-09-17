-- Twilight Zone Loader (Fixed)
local url = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local success, response = pcall(function()
    return game:HttpGet(url, true)
end)

if success then
    local func, loadErr = loadstring(response)
    if func then
        print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
        func()
    else
        warn("[TZ Loader] ❌ Failed to compile main.lua:", loadErr)
    end
else
    warn("[TZ Loader] ❌ Failed to download main.lua:", response)
end
