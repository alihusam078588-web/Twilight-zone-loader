-- main.lua
-- Twilight Zone GUI (Rayfield Version)

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone GUI",
    LoadingTitle = "Twilight Zone Loader",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TZLoader", -- folder name for configs
        FileName = "tz_config"
    },
    Discord = {
        Enabled = false,
        Invite = "", -- optional
        RememberJoins = false
    },
    KeySystem = false, -- no key system for now
})

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

-- Test Button
MainTab:CreateButton({
    Name = "Test Button",
    Callback = function()
        print("[TZ Loader] Test Button clicked!")
    end,
})

-- Test Toggle
MainTab:CreateToggle({
    Name = "Test Toggle",
    CurrentValue = false,
    Flag = "TestToggle",
    Callback = function(Value)
        print("[TZ Loader] Test Toggle set to:", Value)
    end,
})

-- Other Tab
local OtherTab = Window:CreateTab("Other", 4483362458)

-- Example Button in Other Tab
OtherTab:CreateButton({
    Name = "Other Button",
    Callback = function()
        print("[TZ Loader] Other Button clicked!")
    end,
})

-- Example Toggle in Other Tab
OtherTab:CreateToggle({
    Name = "Other Toggle",
    CurrentValue = false,
    Flag = "OtherToggle",
    Callback = function(Value)
        print("[TZ Loader] Other Toggle set to:", Value)
    end,
})

print("[TZ Loader] ✅ Twilight Zone Rayfield GUI loaded successfully!")
