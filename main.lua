-- Twilight Zone GUI (Full Fixed Version)
-- Credits: Ali_hhjjj
-- Tester/Helper: GoodJOBS3
-- Special thanks: Olivia (creator of Riddance Hub, WindUI)

----------------------------------------------------
-- Load WindUI Library
----------------------------------------------------
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/FootageSUS/WindUI/main/library.lua"))()
end)

if not ok or not WindUI then
    warn("⚠️ Failed to load WindUI library. Check your internet connection or the URL.")
    return
end

-- Theme + transparency
WindUI.Theme = "Dark"
WindUI.Transparency = 0.15

-- Localization
WindUI.Locale = {
    ["en"] = {
        welcome = "Welcome to Twilight Zone!",
    },
    ["ar"] = {
        welcome = "مرحباً بك في Twilight Zone!",
    }
}

----------------------------------------------------
-- Create Window
----------------------------------------------------
local Window = WindUI:CreateWindow({
    Name = "Twilight Zone",
    Themeable = {
        Info = "Made by Ali_hhjjj"
    }
})

----------------------------------------------------
-- Tabs
----------------------------------------------------
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
        -- TODO: Add autofarm logic here
    end,
})

----------------------------------------------------
-- Teleport Tab
----------------------------------------------------
teleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        print("Teleporting to Elevator...")
        -- TODO: Add teleport-to-elevator logic here
    end,
})

teleportTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = function()
        print("Teleporting to random machine...")
        -- TODO: Add teleport-to-random-machine logic here
    end,
})

teleportTab:CreateToggle({
    Name = "Auto Teleport to Machines",
    CurrentValue = false,
    Flag = "AutoTPMachines",
    Callback = function(Value)
        print("Auto Teleport to Machines:", Value)
        -- TODO: Add auto-teleport machines logic here
    end,
})

teleportTab:CreateToggle({
    Name = "Auto Teleport to Elevator when done",
    CurrentValue = false,
    Flag = "AutoTPElevator",
    Callback = function(Value)
        print("Auto Teleport to Elevator:", Value)
        -- TODO: Add auto-teleport elevator logic here
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
        -- TODO: Add ESP for machines here
    end,
})

espTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Flag = "ESPSpirits",
    Callback = function(Value)
        print("ESP Spirits:", Value)
        -- TODO: Add ESP for spirits here
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
        -- TODO: Add infinite stamina logic here
    end,
})

----------------------------------------------------
-- Credits Tab
----------------------------------------------------
creditsTab:CreateLabel("Made by Ali_hhjjj")
creditsTab:CreateLabel("Tester/Helper: GoodJOBS3")
creditsTab:CreateLabel("Special thanks: Olivia (Riddance Hub, WindUI)")

----------------------------------------------------
-- Welcome Popup
----------------------------------------------------
WindUI:Popup({
    Title = "Welcome",
    Description = WindUI:GetLocale("welcome"),
    Buttons = {
        {
            Name = "Close",
            Callback = function()
                print("Welcome popup closed.")
            end
        }
    }
})

print("✅ Twilight Zone GUI Loaded Successfully!")
