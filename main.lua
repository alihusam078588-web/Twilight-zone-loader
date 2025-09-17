-- Twilight Zone using Rayfield UI

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone Loader",
    LoadingSubtitle = "by Ali",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "TwilightZone",
       FileName = "TZ_Config"
    },
    Discord = {
       Enabled = false,
       Invite = "",
       RememberJoins = false
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local OtherTab = Window:CreateTab("Other", 4483362458)

MainTab:CreateButton({
    Name = "Test Button",
    Callback = function()
        print("✅ Test Button pressed!")
    end,
})

OtherTab:CreateToggle({
    Name = "Test Toggle",
    CurrentValue = false,
    Flag = "TestToggle",
    Callback = function(Value)
        print("🔘 Test Toggle is now:", Value)
    end,
})
