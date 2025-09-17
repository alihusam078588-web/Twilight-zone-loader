-- Twilight Zone Loader
-- Loads WindUI and main.lua from your GitHub repo

local function safeLoad(url, description)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        local ok, err = pcall(function()
            loadstring(result)()
        end)
        if not ok then
            warn("[TZ Loader] ❌ Failed to run " .. description .. ": " .. err)
        else
            print("[TZ Loader] ✅ Successfully loaded " .. description .. "!")
        end
    else
        warn("[TZ Loader] ❌ Failed to load " .. description .. "!")
    end
end

-- Load WindUI library first
safeLoad("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua", "WindUI library")

-- Load your main GUI
safeLoad("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua", "Twilight Zone GUI")

print("[TZ Loader] 🚀 Loader finished by Ali_hhjjj")
