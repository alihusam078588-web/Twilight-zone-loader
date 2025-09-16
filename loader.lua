-- Twilight Zone Loader (place this in loader.lua or paste into your executor)
local RAW_MAIN_URL = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"

local function log(...)
    pcall(print, "[TZ Loader]", ...)
end

local ok, body = pcall(function()
    return game:HttpGet(RAW_MAIN_URL)
end)

if not ok or not body or body == "" then
    log("Failed to download main.lua. Check your RAW_MAIN_URL and internet.")
    return
end

local fn, err = loadstring(body)
if not fn then
    log("loadstring error:", err)
    return
end

local ok2, err2 = pcall(fn)
if not ok2 then
    log("Error executing main.lua:", err2)
    return
end

log("Successfully loaded Twilight Zone main script.")
