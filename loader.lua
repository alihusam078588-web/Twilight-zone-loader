-- Twilight Zone Loader
local success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078/Twilight-zone-loader/main/windui.lua"))()
end)

if not success or not Library then
    warn("[TZ Loader] ❌ Failed to load WindUI library!")
    return
end

print("[TZ Loader] ✅ Successfully loaded Twilight Zone GUI!")

-- Create main window
local Window = Library:CreateWindow({
    Title = "Twilight Zone GUI",
    Center = true,
    AutoShow = true,
})

-- Main tab
local MainTab = Window:AddTab("Main")

MainTab:AddButton({
    Title = "Test Button",
    Callback = function()
        print("[TZ Loader] Test Button clicked!")
    end
})

MainTab:AddToggle({
    Title = "Test Toggle",
    Default = false,
    Callback = function(state)
        print("[TZ Loader] Test Toggle set to:", state)
    end
})
