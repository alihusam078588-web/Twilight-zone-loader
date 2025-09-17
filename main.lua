-- Twilight Zone GUI (Rayfield)
-- Author: Ali_hhjjj | Tester: GOODJOBS3 | Thanks: Olivia (Riddance Hub)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone GUI",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = false,
    }
})

----------------------------------------------------
-- ESP Tab
----------------------------------------------------
local espTab = Window:CreateTab("ESP")

espTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(Value)
        print("ESP Machines:", Value)
        -- TODO: Add ESP Machine logic
    end,
})

espTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(Value)
        print("ESP Spirits:", Value)
        -- TODO: Add ESP Spirit logic
    end,
})

----------------------------------------------------
-- Teleport Tab
----------------------------------------------------
local teleportTab = Window:CreateTab("Teleport")

teleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        print("Teleporting to Elevator...")
        -- TODO: Add elevator teleport logic
    end,
})

teleportTab:CreateButton({
    Name = "Teleport to Machine",
    Callback = function()
        print("Teleporting to Machine...")
        -- TODO: Add machine teleport logic
    end,
})

----------------------------------------------------
-- Credits Tab
----------------------------------------------------
local creditsTab = Window:CreateTab("Credits")
creditsTab:CreateParagraph({Title = "Creator", Content = "Ali_hhjjj"})
creditsTab:CreateParagraph({Title = "Tester/Helper", Content = "GOODJOBS3"})
creditsTab:CreateParagraph({Title = "Special Thanks", Content = "Olivia (Riddance Hub)"})

print("[Twilight Zone] ✅ GUI Loaded (ESP + Teleport only)")
