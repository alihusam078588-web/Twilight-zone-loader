-- Twilight Zone GUI using official WindUI

-- Load WindUI from FootageSUS GitHub
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/Source.lua"))()

-- Create a window
local window = WindUI:CreateWindow({
    Title = "Twilight Zone",
    SubTitle = "by Ali_hhjjj",
    Theme = "Dark",
})

-- Tabs
local mainTab = window:CreateTab("Main")
local settingsTab = window:CreateTab("Settings")

-- Button Example
mainTab:CreateButton({
    Name = "Test Button",
    Callback = function()
        print("✅ Test Button clicked!")
    end,
})

-- Toggle Example
mainTab:CreateToggle({
    Name = "Test Toggle",
    Default = false,
    Callback = function(state)
        print("Toggle state:", state)
    end,
})
