-- main.lua

-- Load WindUI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua"))()

-- Create main window
local Window = Library:CreateWindow("Twilight Zone GUI")

-- Create "Main" tab
local MainTab = Window:CreateTab("Main")

MainTab:CreateButton("Test Button", function()
    print("[TZ Loader] Test Button clicked!")
end)

-- Create "Other" tab
local OtherTab = Window:CreateTab("Other")

OtherTab:CreateToggle("Test Toggle", false, function(state)
    print("[TZ Loader] Test Toggle set to:", state)
end)

print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
