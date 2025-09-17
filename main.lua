-- Twilight Zone Loader - Rayfield-like UI
-- Author: Ali_hhjjj
-- Helper: GoodJOBS3
-- Special thanks: Olivia

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // Rayfield UI Loader
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "Twilight Zone GUI",
   LoadingTitle = "Twilight Zone Loader",
   LoadingSubtitle = "by Ali_hhjjj",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "TZLoader",
      FileName = "TZConfig"
   },
   KeySystem = false,
})

-- // Player Tab
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateToggle({
   Name = "Godmode",
   CurrentValue = true,
   Flag = "Godmode",
   Callback = function(Value)
      -- Always on godmode
      if Value then
         LocalPlayer.Character.Humanoid.Health = math.huge
         LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            LocalPlayer.Character.Humanoid.Health = math.huge
         end)
      end
   end,
})

PlayerTab:CreateToggle({
   Name = "Auto Skillcheck",
   CurrentValue = true,
   Flag = "AutoSkillcheck",
   Callback = function(Value)
      -- Always auto skillcheck
      if Value then
         print("Auto Skillcheck Enabled")
         -- Hook your skillcheck event here
      end
   end,
})

PlayerTab:CreateSlider({
   Name = "Custom Speed",
   Range = {16, 100},
   Increment = 1,
   Suffix = "WalkSpeed",
   CurrentValue = 16,
   Flag = "WalkSpeed",
   Callback = function(Value)
      LocalPlayer.Character.Humanoid.WalkSpeed = Value
   end,
})

PlayerTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
      if Value then
         RunService.Stepped:Connect(function()
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
               if part:IsA("BasePart") then
                  part.CanCollide = false
               end
            end
         end)
      end
   end,
})

-- // Auto Farm Tab
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateToggle({
   Name = "Auto Teleport to Machine",
   CurrentValue = false,
   Flag = "AutoTPMachine",
   Callback = function(Value)
      if Value then
         print("Auto TP Machine Enabled")
         -- loop teleport logic here
      end
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Teleport to Elevator (after machines)",
   CurrentValue = false,
   Flag = "AutoTPElevator",
   Callback = function(Value)
      if Value then
         print("Auto TP Elevator Enabled")
         -- teleport to elevator logic
      end
   end,
})

-- // Teleport Tab
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

TeleportTab:CreateButton({
   Name = "Teleport to Random Machine (with aura spam E)",
   Callback = function()
      print("TP to random machine + spam E")
      -- teleport to random machine + fire proximity prompt
   end,
})

TeleportTab:CreateButton({
   Name = "Teleport to Elevator",
   Callback = function()
      print("TP to Elevator")
      -- teleport to elevator position
   end,
})

-- // ESP Tab
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({
   Name = "ESP Machines",
   CurrentValue = false,
   Flag = "ESPMachines",
   Callback = function(Value)
      print("ESP Machines:", Value)
   end,
})

ESPTab:CreateToggle({
   Name = "ESP Spirits",
   CurrentValue = false,
   Flag = "ESPSpirits",
   Callback = function(Value)
      print("ESP Spirits:", Value)
   end,
})

-- // Credits Tab
local CreditsTab = Window:CreateTab("Credits", 4483362458)

CreditsTab:CreateLabel("TZ Rayfield-like GUI")
CreditsTab:CreateLabel("Made by: Ali_hhjjj")
CreditsTab:CreateLabel("Helper: GoodJOBS3")
CreditsTab:CreateLabel("Special thanks: Olivia")

Rayfield:LoadConfiguration()
