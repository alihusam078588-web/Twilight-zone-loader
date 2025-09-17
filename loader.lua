-- Twilight Zone Loader
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam07858-web/Twilight-zone-loader/main/main.lua"))()
end)

if success then
    print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
else
    warn("[TZ Loader] ❌ Failed to load:", err)
end
