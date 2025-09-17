-- Twilight Zone GUI Main Script
-- Credits: Ali_hhjjj
-- Tester/Helper: GoodJOBS3
-- Special thanks: Olivia (creator of Riddance Hub, WindUI)

-- Load WindUI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/FootageSUS/WindUI/main/library.lua"))()

-- Create Window
local Window = Library:CreateWindow({
    Name = "Twilight Zone",
    Themeable = {
        Info = "Made by Ali_hhjjj"
    }
})

-- Tabs
local farmTab = Window:CreateTab("Auto Farm")
local teleportTab = Window:CreateTab("Teleport")
local espTab = Window:CreateTab("ESP")
local miscTab = Window:CreateTab("Misc")
local creditsTab = Window:CreateTab("Credits")

----------------------------------------------------
-- Auto Farm Tab
----------------------------------------------------
farmTab:CreateToggle({
    Name = "Auto Farm Machines",
    CurrentValue = false,
    Flag = "AutoFarmMachines",
    Callback = function(Value)
        print("Auto Farm Machines:", Value)
        -- TODO: Add your autofarm logic here
    end,
})

----------------------------------------------------
-- Teleport Tab
----------------------------------------------------
teleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        print("Teleporting to Elevator...")
        -- TODO: Add teleport-to-elevator logic
    end,
})

teleportTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = function()
        print("Teleporting to random machine...")
        -- TODO: Add teleport-to-random-machine logic
    end,
})

teleportTab:CreateToggle({
    Name = "Auto Teleport to Machines",
    CurrentValue = false,
    Flag = "AutoTPMachines",
    Callback = function(Value)
        print("Auto Teleport to Machines:", Value)
        -- TODO: Add auto teleport machine logic
    end,
})

teleportTab:CreateToggle({
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
espTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Flag = "ESPMachines",
    Callback = function(Value)
        print("ESP Machines:", Value)
        -- TODO: Add ESP for machines
    end,
})

espTab:CreateToggle({
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
miscTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfiniteStamina",
    Callback = function(Value)
        print("Infinite Stamina:", Value)
        -- TODO: Add stamina logic here
    end,
})

----------------------------------------------------
-- Credits Tab
----------------------------------------------------
creditsTab:CreateLabel("Made by Ali_hhjjj")
creditsTab:CreateLabel("Tester/Helper: GoodJOBS3")
creditsTab:CreateLabel("Special thanks: Olivia (Riddance Hub, WindUI)")

print("Twilight Zone main script loaded!")
