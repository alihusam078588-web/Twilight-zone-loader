-- Twilight Zone Master Loader
-- This loads WindUI first, then main.lua

local username = "alihusam078588-web"
local repo = "Twilight-zone-loader"
local branch = "main"

-- Helper function to fetch from GitHub
local function fetchFile(file)
    local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", username, repo, branch, file)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        warn("[TZ Loader] Failed to load:", file, "Error:", result)
        return nil
    end
    return result
end

-- Load WindUI first
local windui = fetchFile("windui.lua")
if windui then
    loadstring(windui)()
    print("[TZ Loader] ✅ WindUI loaded successfully!")
else
    warn("[TZ Loader] ⚠️ WindUI not found, GUI may not work!")
end

-- Load main.lua
local main = fetchFile("main.lua")
if main then
    loadstring(main)()
    print("[TZ Loader] ✅ main.lua loaded successfully!")
else
    warn("[TZ Loader] ❌ Failed to load main.lua!")
end
