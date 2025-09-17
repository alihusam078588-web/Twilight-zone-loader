-- loader.lua
-- Twilight Zone Loader by alihusam078

local function safeLoad(url, name)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("[TZ Loader] ❌ Failed to load " .. name .. "!")
        return nil
    end

    local fn, err = loadstring(result)
    if not fn then
        warn("[TZ Loader] ❌ Error compiling " .. name .. ": " .. tostring(err))
        return nil
    end

    print("[TZ Loader] ✅ Successfully loaded " .. name .. "!")
    return fn()
end

-- Load WindUI library (your repo)
local Library = safeLoad(
    "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua",
    "WindUI library"
)

if not Library then return end

-- Load main script (your repo)
safeLoad(
    "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua",
    "Twilight Zone GUI"
)
