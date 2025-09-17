-- Twilight Zone GUI (Rayfield)

-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "by Ali",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "TwilightZone",
       FileName = "TZHub"
    },
    Discord = {
       Enabled = false,
       Invite = "", -- optional
       RememberJoins = true
    },
    KeySystem = false
})

-- Example Tab
local MainTab = Window:CreateTab("Main", 4483362458)

-- Example Button
MainTab:CreateButton({
   Name = "Test Button",
   Callback = function()
      print("✅ Test Button Pressed!")
   end
})

-- Example Toggle
MainTab:CreateToggle({
   Name = "Test Toggle",
   CurrentValue = false,
   Callback = function(Value)
      print("🔘 Toggle set to:", Value)
   end
})

-- Example Slider
MainTab:CreateSlider({
   Name = "Test Slider",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = 50,
   Callback = function(Value)
      print("📊 Slider value:", Value)
   end,
})
