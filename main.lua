-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Create your main window
local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone Loader",
    LoadingSubtitle = "by Ali",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "TwilightZone", -- Where configs will save
       FileName = "TZ_Config"
    },
    Discord = {
       Enabled = false,
       Invite = "", -- your discord invite
       RememberJoins = false
    },
    KeySystem = false, -- turn on if you want key system
})

-- Create Tabs
local MainTab = Window:CreateTab("Main", 4483362458) -- Roblox asset ID for icon
local OtherTab = Window:CreateTab("Other", 4483362458)

-- Add a button
MainTab:CreateButton({
    Name = "Test Button",
    Callback = function()
        print("Button pressed!")
    end,
})

-- Add a toggle
OtherTab:CreateToggle({
    Name = "Test Toggle",
    CurrentValue = false,
    Flag = "TestToggle",
    Callback = function(Value)
        print("Toggle set to:", Value)
    end,
})
