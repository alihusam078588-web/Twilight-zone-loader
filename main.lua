-- main.lua
-- Twilight Zone Rayfield GUI
-- Made by Ali_hhjjj | Helper: GoodJOBS3 | Special thanks: Olivia

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
    KeySystem = false
})

----------------------------------------------------
-- Tabs
----------------------------------------------------
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local CreditsTab = Window:CreateTab("Credits", 4483362458)

----------------------------------------------------
-- Auto Farm Tab
----------------------------------------------------
FarmTab:CreateToggle({
    Name = "Auto Farm Machines",
    CurrentValue = false,
    Flag = "AutoFarmMachines",
    Callback = function(Value)
        print("Auto Farm Machines:", Value)
        -- TODO: Add auto farm logic here
    end,
})

----------------------------------------------------
-- Teleport Tab
----------------------------------------------------
TeleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        print("Teleporting to Elevator...")
        -- TODO: Add teleport-to-elevator logic
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = function()
        print("Teleporting to random machine...")
        -- TODO: Add teleport-to-random-machine logic
    end,
})

TeleportTab:CreateToggle({
    Name = "Auto Teleport to Machines",
    CurrentValue = false,
    Flag = "AutoTPMachines",
    Callback = function(Value)
        print("Auto Teleport to Machines:", Value)
        -- TODO: Add auto teleport machine logic
    end,
})

TeleportTab:CreateToggle({
    Name = "Auto Teleport to Elevator when done",
    CurrentValue = false,
    Flag = "AutoTPElevator",
    Callback = function(Value)
        print("Auto Teleport to Elevator:", Value)
        -- TODO: Add auto teleport elevator logic
    end,
})

----------------------------------------------------
-- ESP Tab
----------------------------------------------------
ESPTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Flag = "ESPMachines",
    Callback = function(Value)
        print("ESP Machines:", Value)
        -- TODO: Add ESP for machines
    end,
})

ESPTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Flag = "ESPSpirits",
    Callback = function(Value)
        print("ESP Spirits:", Value)
        -- TODO: Add ESP for spirits
    end,
})

----------------------------------------------------
-- Misc Tab
----------------------------------------------------
MiscTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfiniteStamina",
    Callback = function(Value)
        print("Infinite Stamina:", Value)
        -- TODO: Add stamina logic here
    end,
})

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
CreditsTab:CreateParagraph({
    Title = "Credits",
    Content = "Made by Ali_hhjjj\nHelper: GoodJOBS3\nSpecial thanks: Olivia"
})

print("[TZ] ✅ Twilight Zone Rayfield GUI Loaded!")
