-- Twilight Zone Rayfield GUI
-- by Ali_hhjjj

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "Twilight Zone",
   LoadingTitle = "Twilight Zone Loader",
   LoadingSubtitle = "Rayfield Edition",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "TZConfig",
      FileName = "TwilightZone"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = false
   },
   KeySystem = false,
})

-- === ESP TAB ===
local ESPTab = Window:CreateTab("ESP")

ESPTab:CreateToggle({
   Name = "ESP Machines",
   CurrentValue = false,
   Flag = "ESPMachines",
   Callback = function(Value)
      _G.ESP_Machines = Value
      while _G.ESP_Machines do
         task.wait(1)
         for _, machine in pairs(workspace:GetChildren()) do
            if machine.Name == "Machine" and not machine:FindFirstChild("ESPHighlight") then
               local h = Instance.new("Highlight", machine)
               h.Name = "ESPHighlight"
               h.FillColor = Color3.fromRGB(0,255,0)
               h.OutlineColor = Color3.fromRGB(0,0,0)
            end
         end
      end
      if not Value then
         for _, machine in pairs(workspace:GetChildren()) do
            if machine:FindFirstChild("ESPHighlight") then
               machine.ESPHighlight:Destroy()
            end
         end
      end
   end,
})

ESPTab:CreateToggle({
   Name = "ESP Spirits",
   CurrentValue = false,
   Flag = "ESpSpirits",
   Callback = function(Value)
      _G.ESP_Spirits = Value
      while _G.ESP_Spirits do
         task.wait(1)
         for _, spirit in pairs(workspace:GetChildren()) do
            if spirit.Name == "Spirit" and not spirit:FindFirstChild("ESPHighlight") then
               local h = Instance.new("Highlight", spirit)
               h.Name = "ESPHighlight"
               h.FillColor = Color3.fromRGB(255,0,0)
               h.OutlineColor = Color3.fromRGB(0,0,0)
            end
         end
      end
      if not Value then
         for _, spirit in pairs(workspace:GetChildren()) do
            if spirit:FindFirstChild("ESPHighlight") then
               spirit.ESPHighlight:Destroy()
            end
         end
      end
   end,
})

-- === TELEPORT TAB ===
local TeleportTab = Window:CreateTab("Teleport")

TeleportTab:CreateButton({
   Name = "Teleport to Nearest Machine",
   Callback = function()
      local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
      local nearest, dist = nil, math.huge
      for _, machine in pairs(workspace:GetChildren()) do
         if machine.Name == "Machine" and machine:FindFirstChild("PrimaryPart") then
            local d = (hrp.Position - machine.PrimaryPart.Position).Magnitude
            if d < dist then
               dist = d
               nearest = machine
            end
         end
      end
      if nearest then
         hrp.CFrame = nearest.PrimaryPart.CFrame + Vector3.new(0,5,0)
      end
   end,
})

TeleportTab:CreateButton({
   Name = "Teleport to Elevator",
   Callback = function()
      local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
      local elevator = workspace:FindFirstChild("Elevator")
      if elevator and elevator:FindFirstChild("PrimaryPart") then
         hrp.CFrame = elevator.PrimaryPart.CFrame + Vector3.new(0,5,0)
      end
   end,
})

-- === AUTO FARM TAB ===
local AutoFarmTab = Window:CreateTab("Auto Farm")

AutoFarmTab:CreateToggle({
   Name = "Auto Teleport to Machines",
   CurrentValue = false,
   Flag = "AutoMachines",
   Callback = function(Value)
      _G.AutoMachines = Value
      while _G.AutoMachines do
         task.wait(2)
         local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
         for _, machine in pairs(workspace:GetChildren()) do
            if machine.Name == "Machine" and machine:FindFirstChild("PrimaryPart") then
               hrp.CFrame = machine.PrimaryPart.CFrame + Vector3.new(0,5,0)
               task.wait(5)
            end
         end
      end
   end,
})

AutoFarmTab:CreateToggle({
   Name = "Auto Elevator (after machines)",
   CurrentValue = false,
   Flag = "AutoElevator",
   Callback = function(Value)
      _G.AutoElevator = Value
      while _G.AutoElevator do
         task.wait(3)
         -- pretend check: all machines disabled
         local allDone = true
         for _, machine in pairs(workspace:GetChildren()) do
            if machine.Name == "Machine" then
               allDone = false
            end
         end
         if allDone then
            local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
            local elevator = workspace:FindFirstChild("Elevator")
            if elevator and elevator:FindFirstChild("PrimaryPart") then
               hrp.CFrame = elevator.PrimaryPart.CFrame + Vector3.new(0,5,0)
            end
         end
      end
   end,
})

-- === PLAYER TAB ===
local PlayerTab = Window:CreateTab("Player")

PlayerTab:CreateToggle({
   Name = "Infinite Stamina",
   CurrentValue = false,
   Flag = "InfStamina",
   Callback = function(Value)
      _G.InfStamina = Value
      local plr = game.Players.LocalPlayer
      while _G.InfStamina do
         task.wait(0.5)
         if plr:FindFirstChild("PlayerData") then
            plr.PlayerData.Stamina.Value = plr.PlayerData.Stamina.MaxValue
         end
      end
   end,
})

PlayerTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
      _G.Noclip = Value
      local char = game.Players.LocalPlayer.Character
      while _G.Noclip do
         task.wait()
         for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
               v.CanCollide = false
            end
         end
      end
   end,
})

PlayerTab:CreateSlider({
   Name = "WalkSpeed",
   Range = {16, 100},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeed",
   Callback = function(Value)
      game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
   end,
})

PlayerTab:CreateLabel("Godmode (always enabled)")
PlayerTab:CreateLabel("Auto SkillCheck (always active)")

-- === CREDITS TAB ===
local CreditsTab = Window:CreateTab("Credits")

CreditsTab:CreateLabel("Created by: Ali_hhjjj")
CreditsTab:CreateLabel("Tester/Helper: GOODJOBS3")
CreditsTab:CreateLabel("Special Thanks: Olivia (Riddance Hub)")
