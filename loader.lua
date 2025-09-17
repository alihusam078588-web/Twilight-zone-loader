-- Twilight Zone Loader
-- Loads main.lua from your GitHub repo

local function LoadScript(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("[TZ Loader] ❌ HTTP request failed:", response)
        return
    end

    local func, err = loadstring(response)
    if not func then
        warn("[TZ Loader] ❌ Failed to compile:", err)
        return
    end

    local ok, runtimeErr = pcall(func)
    if not ok then
        warn("[TZ Loader] ❌ Runtime error:", runtimeErr)
    else
        print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully! (by alihusam078588-web)")
    end
end

-- 🔗 Your GitHub raw link
LoadScript("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua")
