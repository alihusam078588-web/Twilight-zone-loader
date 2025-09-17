-- Twilight Zone GUI (main.lua)
-- Using WindUI

-- Load WindUI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua"))()

-- Create the main window
local Window = Library:CreateWindow({
    Title = "Twilight Zone GUI",
    Center = true,
    AutoShow = true,
})

-- Create a main tab
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "rbxassetid://10734950020" -- optional
})

-- Create a section
local MainSection = MainTab:CreateSection("Main Features")

-- Add buttons
MainSection:CreateButton({
    Name = "Fly",
    Callback = function()
        print("Fly enabled!")
        -- put fly script here
    end
})

MainSection:CreateButton({
    Name = "Noclip",
    Callback = function()
        print("Noclip enabled!")
        -- put noclip script here
    end
})

-- Add a toggle
MainSection:CreateToggle({
    Name = "ESP",
    Default = false,
    Callback = function(state)
        print("ESP:", state)
        -- put ESP toggle code here
    end
})

-- Add a slider
MainSection:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

-- Credits tab
local CreditsTab = Window:CreateTab({
    Name = "Credits",
    Icon = "rbxassetid://6034509993"
})

local CreditsSection = CreditsTab:CreateSection("Made By")
CreditsSection:CreateLabel("Ali_hhjjj")
