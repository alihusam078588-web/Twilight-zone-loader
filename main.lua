-- main.lua

-- Require WindUI (it’s already loaded by loader.lua)
local Library = Library or require(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua"))

-- Create a main window
local window = Library:CreateWindow("Twilight Zone")

-- Add a tab
local mainTab = window:CreateTab("Main")

-- Add a button
mainTab:CreateButton("Click Me", function()
    print("✅ Button was clicked!")
end)

-- Add a toggle
mainTab:CreateToggle("Toggle Me", false, function(state)
    print("🔘 Toggle is now:", state)
end)
