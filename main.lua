-- Twilight Zone Main Script
-- Loads WindUI from your GitHub repo and builds the GUI

-- Load WindUI library from your repo
local Library = nil
local success, err = pcall(function()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua"))()
end)

if not success or not Library then
    warn("⚠️ Failed to load WindUI library. Check your internet connection or the URL.", err)
    return
end

-- Create the main window
local Window = Library:CreateWindow("Twilight Zone GUI")

-- Example tabs & buttons (you can add more)
local Tab1 = Window:CreateTab("Main")
Tab1:CreateButton("Test Button", function()
    print("✅ Test Button clicked!")
end)

local Tab2 = Window:CreateTab("Other")
Tab2:CreateToggle("Test Toggle", false, function(state)
    print("✅ Toggle state:", state)
end)

print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
