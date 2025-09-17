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

-------------------------------------------------
-- MAIN TAB
-------------------------------------------------
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "rbxassetid://10734950020"
})

local MainSection = MainTab:CreateSection("Player")

-- Fly button
MainSection:CreateButton({
    Name = "Enable Fly",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/fly.lua"))()
    end
})

-- Noclip button
MainSection:CreateButton({
    Name = "Enable Noclip",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/noclip.lua"))()
    end
})

-- WalkSpeed slider
MainSection:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})

-------------------------------------------------
-- VISUAL TAB
-------------------------------------------------
local VisualTab = Window:CreateTab({
    Name = "Visual",
    Icon = "rbxassetid://6034509993"
})

local VisualSection = VisualTab:CreateSection("ESP")

-- ESP Toggle
VisualSection:CreateToggle({
    Name = "ESP",
    Default = false,
    Callback = function(state)
        if state then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/esp.lua"))()
        else
            print("ESP disabled (no disable script yet).")
        end
    end
})

-------------------------------------------------
-- AUTO TAB
-------------------------------------------------
local AutoTab = Window:CreateTab({
    Name = "AutoFarm",
    Icon = "rbxassetid://6034509990"
})

local AutoSection = AutoTab:CreateSection("Farming")

-- AutoFarm Toggle
AutoSection:CreateToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(state)
        if state then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/autofarm.lua"))()
        else
            print("AutoFarm stopped (needs disable code).")
        end
    end
})

-------------------------------------------------
-- CREDITS TAB
-------------------------------------------------
local CreditsTab = Window:CreateTab({
    Name = "Credits",
    Icon = "rbxassetid://6034509992"
})

local CreditsSection = CreditsTab:CreateSection("Made By")
CreditsSection:CreateLabel("Ali_hhjjj & ChatGPT")

print("[TZ Loader] 🚀 Twilight Zone GUI Loaded Successfully!")
