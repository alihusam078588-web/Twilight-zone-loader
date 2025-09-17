-- Twilight Zone Main Script
-- Rayfield GUI with ESP, Teleport, Auto Farm, Player, and Credits

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
       Enabled = false
    }
})

------------------------------------------------
-- ESP Tab
------------------------------------------------
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(Value)
        print("ESP Machines:", Value)
        -- TODO: Add real ESP machine logic
    end
})

ESPTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(Value)
        print("ESP Spirits:", Value)
        -- TODO: Add real ESP spirits logic
    end
})

------------------------------------------------
-- Teleport Tab
------------------------------------------------
local TeleTab = Window:CreateTab("Teleport", 4483362458)

TeleTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        print("Teleport to elevator")
        -- TODO: Add teleport-to-elevator logic
    end
})

TeleTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = function()
        print("Teleport to random machine")
        -- TODO: Add teleport-to-random-machine logic
    end
})

------------------------------------------------
-- Auto Farm Tab
------------------------------------------------
local AutoTab = Window:CreateTab("Auto Farm", 4483362458)

AutoTab:CreateToggle({
    Name = "Auto Teleport to Machine",
    CurrentValue = false,
    Callback = function(Value)
        print("Auto teleport to machine:", Value)
        -- TODO: Add real auto machine farm logic
    end
})

AutoTab:CreateToggle({
    Name = "Auto Teleport to Elevator (after machines done)",
    CurrentValue = false,
    Callback = function(Value)
        print("Auto teleport to elevator:", Value)
        -- TODO: Add logic for auto elevator teleport
    end
})

------------------------------------------------
-- Player Tab
------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
})

PlayerTab:CreateToggle({
    Name = "Godmode",
    CurrentValue = false,
    Callback = function(Value)
        print("Godmode:", Value)
        -- TODO: Add real godmode logic
    end
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        print("Noclip:", Value)
        -- TODO: Add real noclip logic
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Callback = function(Value)
        print("Infinite stamina:", Value)
        -- TODO: Add stamina logic
    end
})

PlayerTab:CreateToggle({
    Name = "Auto Skillcheck",
    CurrentValue = false,
    Callback = function(Value)
        print("Auto skillcheck:", Value)
        -- TODO: Add skillcheck logic
    end
})

------------------------------------------------
-- Credits Tab
------------------------------------------------
local CreditsTab = Window:CreateTab("Credits", 4483362458)

CreditsTab:CreateParagraph({Title = "Created by", Content = "Ali_hhjjj"})
CreditsTab:CreateParagraph({Title = "Tester/Helper", Content = "GOODJOBS3"})
CreditsTab:CreateParagraph({Title = "Special Thanks", Content = "Olivia (creator of Riddance Hub)"})

------------------------------------------------
-- Notify
------------------------------------------------
Rayfield:Notify({
    Title = "Twilight Zone",
    Content = "Loaded successfully!",
    Duration = 5,
    Image = 4483362458
})
