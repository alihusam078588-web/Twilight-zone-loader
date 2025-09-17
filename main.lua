-- Twilight Zone GUI
-- Creator: Ali_hhjjj
-- Thanks to Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving Idea to use Rayfield

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "Twilight Zone",
   LoadingTitle = "Twilight Zone GUI",
   LoadingSubtitle = "by Ali_hhjjj",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "TwilightZoneCFG",
      FileName = "TwilightZone"
   },
   Discord = {
      Enabled = false,
   }
})

---------------------------------------------------------------------
-- Player Tab
---------------------------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateToggle({
   Name = "Godmode",
   CurrentValue = false,
   Flag = "Godmode",
   Callback = function(Value)
      if Value then
         local player = game.Players.LocalPlayer
         local char = player.Character or player.CharacterAdded:Wait()
         if char:FindFirstChild("Humanoid") then
            char.Humanoid.MaxHealth = math.huge
            char.Humanoid.Health = math.huge
         end
      end
   end
})

PlayerTab:CreateToggle({
   Name = "Auto Skillcheck",
   CurrentValue = false,
   Flag = "Skillcheck",
   Callback = function(Value)
      getgenv().AutoSkillcheck = Value
      while getgenv().AutoSkillcheck do
         game:GetService("VirtualInputManager"):SendKeyEvent(true, "E", false, game)
         game:GetService("VirtualInputManager"):SendKeyEvent(false, "E", false, game)
         task.wait(0.1)
      end
   end
})

---------------------------------------------------------------------
-- Teleport Tab
---------------------------------------------------------------------
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

TeleportTab:CreateButton({
   Name = "Teleport to Elevator",
   Callback = function()
      local player = game.Players.LocalPlayer
      local char = player.Character or player.CharacterAdded:Wait()
      local hrp = char:WaitForChild("HumanoidRootPart")
      local elevator = workspace.Floor:FindFirstChild("Elevator")
      if elevator then
         hrp.CFrame = elevator.CFrame + Vector3.new(0,5,0)
      end
   end
})

TeleportTab:CreateButton({
   Name = "Teleport to Random Machine",
   Callback = function()
      local machines = workspace.Floor.Machines:GetChildren()
      local choices = {}
      for _,m in ipairs(machines) do
         if m:FindFirstChild("Front") then
            table.insert(choices,m.Front)
         end
      end
      if #choices > 0 then
         local pick = choices[math.random(1,#choices)]
         local player = game.Players.LocalPlayer
         local hrp = player.Character.HumanoidRootPart
         hrp.CFrame = pick.CFrame + Vector3.new(0,3,0)
      end
   end
})

TeleportTab:CreateToggle({
   Name = "Auto Teleport Machines (with Aura)",
   CurrentValue = false,
   Flag = "AutoTPMachine",
   Callback = function(Value)
      getgenv().AutoTPMachine = Value
      while getgenv().AutoTPMachine do
         local machines = workspace.Floor.Machines:GetChildren()
         local choices = {}
         for _,m in ipairs(machines) do
            if m:FindFirstChild("Front") then
               table.insert(choices,m.Front)
            end
         end
         if #choices > 0 then
            local pick = choices[math.random(1,#choices)]
            local player = game.Players.LocalPlayer
            local hrp = player.Character.HumanoidRootPart
            hrp.CFrame = pick.CFrame + Vector3.new(0,3,0)
            
            -- Spam "E" (Aura effect)
            for i=1,15 do
               game:GetService("VirtualInputManager"):SendKeyEvent(true,"E",false,game)
               game:GetService("VirtualInputManager"):SendKeyEvent(false,"E",false,game)
               task.wait(0.1)
            end
         end
         task.wait(3)
      end
   end
})

---------------------------------------------------------------------
-- ESP Tab
---------------------------------------------------------------------
local ESPTab = Window:CreateTab("ESP", 4483362458)

local function highlight(obj,color)
   if not obj:FindFirstChild("ESP_Highlight") then
      local hl = Instance.new("Highlight")
      hl.Name = "ESP_Highlight"
      hl.FillColor = color
      hl.OutlineColor = color
      hl.Adornee = obj
      hl.Parent = obj
   end
end

ESPTab:CreateToggle({
   Name = "ESP Machines",
   CurrentValue = false,
   Flag = "ESPMachines",
   Callback = function(Value)
      if Value then
         for _,m in ipairs(workspace.Floor.Machines:GetChildren()) do
            if m:FindFirstChild("Front") then
               highlight(m,"Green")
            end
         end
      else
         for _,m in ipairs(workspace.Floor.Machines:GetChildren()) do
            if m:FindFirstChild("ESP_Highlight") then
               m.ESP_Highlight:Destroy()
            end
         end
      end
   end
})

ESPTab:CreateToggle({
   Name = "ESP Spirits",
   CurrentValue = false,
   Flag = "ESPSpirits",
   Callback = function(Value)
      if Value then
         for _,s in ipairs(workspace.Floor.Spirits:GetChildren()) do
            highlight(s,"Red")
         end
      else
         for _,s in ipairs(workspace.Floor.Spirits:GetChildren()) do
            if s:FindFirstChild("ESP_Highlight") then
               s.ESP_Highlight:Destroy()
            end
         end
      end
   end
})

---------------------------------------------------------------------
-- Credits Tab
---------------------------------------------------------------------
local Credits = Window:CreateTab("Credits", 4483362458)

Credits:CreateLabel("Creator: Ali_hhjjj")
Credits:CreateLabel("Tester / Helper: You")
Credits:CreateLabel("Special Thanks:")
Credits:CreateLabel("Olivia (creator of Riddance Hub)")
Credits:CreateLabel("Shelly (Riddance manager)")
Credits:CreateLabel("For giving Idea to use Rayfield")
