-- main.lua
-- Twilight Zone Rayfield GUI

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone GUI",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TwilightZone",
        FileName = "TwilightConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "", -- your Discord invite here (optional)
        RememberJoins = true
    },
    KeySystem = false, -- set true if you want a key system
    KeySettings = {
        Title = "Twilight Zone | Key System",
        Subtitle = "Authentication",
        Note = "Ask Ali_hhjjj for access",
        FileName = "TwilightKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"MySecretKey"}
    }
})

----------------------------------------------------
-- Tabs
----------------------------------------------------
local MainTab = Window:CreateTab("Main", 4483362458) -- you can change the icon id
local MiscTab = Window:CreateTab("Misc", 4483362458)
local CreditsTab = Window:CreateTab("Credits", 4483362458)

----------------------------------------------------
-- Main Tab Elements
----------------------------------------------------
MainTab:CreateButton({
    Name = "Test Button",
    Callback = function()
        Rayfield:Notify({
            Title = "Button Clicked!",
            Content = "You pressed the Test Button.",
            Duration = 4,
            Image = 4483362458,
        })
    end
})

MainTab:CreateToggle({
    Name = "Test Toggle",
    CurrentValue = false,
    Flag = "TestToggle",
    Callback = function(Value)
        print("Test Toggle:", Value)
    end,
})

----------------------------------------------------
-- Misc Tab Elements
----------------------------------------------------
MiscTab:CreateSlider({
    Name = "Walkspeed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkspeedSlider",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end,
})

----------------------------------------------------
-- Credits Tab
----------------------------------------------------
CreditsTab:CreateParagraph({Title = "Credits", Content = "Made by Ali_hhjjj\nHelper: GoodJOBS3\nSpecial Thanks: Olivia"})

print("[TZ] ✅ Rayfield GUI Loaded!")
