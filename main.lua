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

---------------------------------------------------------
-- ESP TAB
---------------------------------------------------------
local EspTab = Window:CreateTab("ESP", 4483362458)

EspTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Callback = function(Value)
      print("ESP Enabled:", Value)
      -- TODO: Insert ESP script
   end
})

EspTab:CreateToggle({
   Name = "Show Players",
   CurrentValue = false,
   Callback = function(Value)
      print("Show Players:", Value)
   end
})

EspTab:CreateToggle({
   Name = "Show Items",
   CurrentValue = false,
   Callback = function(Value)
      print("Show Items:", Value)
   end
})

---------------------------------------------------------
-- TELEPORT TAB
---------------------------------------------------------
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

TeleportTab:CreateButton({
   Name = "Teleport to Machine",
   Callback = function()
      print("Teleport to Machine")
      -- TODO: Insert teleport logic
   end
})

TeleportTab:CreateButton({
   Name = "Teleport to Elevator",
   Callback = function()
      print("Teleport to Elevator")
   end
})

---------------------------------------------------------
-- AUTO FARM TAB
---------------------------------------------------------
local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)

AutoFarmTab:CreateToggle({
   Name = "Auto Farm",
   CurrentValue = false,
   Callback = function(Value)
      print("Auto Farm:", Value)
   end
})

AutoFarmTab:CreateToggle({
   Name = "Auto Collect Items",
   CurrentValue = false,
   Callback = function(Value)
      print("Auto Collect:", Value)
   end
})

---------------------------------------------------------
-- PLAYER TAB
---------------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 200},
   Increment = 1,
   Suffix = " speed",
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
      -- TODO: Add godmode code
   end
})

PlayerTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Callback = function(Value)
      print("Noclip:", Value)
      -- TODO: Add noclip code
   end
})

PlayerTab:CreateToggle({
   Name = "Infinite Stamina",
   CurrentValue = false,
   Callback = function(Value)
      print("Infinite Stamina:", Value)
   end
})

PlayerTab:CreateToggle({
   Name = "Auto Skillcheck",
   CurrentValue = false,
   Callback = function(Value)
      print("Auto Skillcheck:", Value)
   end
})

---------------------------------------------------------
-- CREDITS TAB
---------------------------------------------------------
local CreditsTab = Window:CreateTab("Credits", 4483362458)

CreditsTab:CreateParagraph({Title = "Created by", Content = "Ali_hhjjj"})
CreditsTab:CreateParagraph({Title = "Tester/Helper", Content = "GOODJOBS3"})
CreditsTab:CreateParagraph({Title = "Special Thanks", Content = "Olivia (Creator of Riddance Hub) for her Rayfield window"})
