-- main.lua

-- Load WindUI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-hhjjj/WindUI/main/library.lua"))()

-- Create main window
local Window = Library:CreateWindow("Twilight Zone GUI")

-- Create "Main" tab
local MainTab = Window:CreateTab("Main")

-- Add a button directly inside Main tab
MainTab:CreateButton("Test Button", function()
    print("[TZ Loader] Test Button clicked!")
end)

-- Create "Other" tab
local OtherTab = Window:CreateTab("Other")

-- Add a toggle directly inside Other tab
OtherTab:CreateToggle("Test Toggle", false, function(state)
    print("[TZ Loader] Test Toggle set to:", state)
end)

print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
