-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // Util
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart"}
    for _,n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then return f end
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    
[span_0](start_span)return model:FindFirstChildWhichIsA("BasePart", true)[span_0](end_span)
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

-- // Godmode (remove HitPlayer)
task.spawn(function()
    while true do
        pcall(function()
            if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then
                for _, folder in ipairs(Workspace.Floor.Spirits:GetChildren()) do
               
      [span_1](start_span)for _, v in ipairs(folder:GetChildren()) do[span_1](end_span)
                        if v.Name == "HitPlayer" then v:Destroy() end
                    end
                end
            end
        end)
    
    [span_2](start_span)task.wait(0.5)[span_2](end_span)
    end
end)

-- // Gather machines (robust search)
local function findMachinesFolders()
    local folders = {}

    -- direct top-level
    if Workspace:FindFirstChild("Machines") then
        table.insert(folders, Workspace.Machines)
    end

    -- under Floor (common)
    if Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
       
             [span_3](start_span)table.insert(folders, obj)[span_3](end_span)
            end
        end
    end

    -- search entire workspace for any folder/model literally named "Machines"
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
            table.insert(folders, obj)
        end
    end

   
  -- dedupe
    local seen = {}
    local unique = {}
    for _, f in ipairs(folders) do
        if f and not seen[f] then
            seen[f] = true
            table.insert(unique, f)
        end
    end
    return unique
end

local function gatherMachineParts()
    local parts = {}

    -- first, collect from any 
[span_4](start_span)found "Machines" folders[span_4](end_span)
    local folders = findMachinesFolders()
    for _, machinesFolder in ipairs(folders) do
        for _, machine in ipairs(machinesFolder:GetChildren()) do
            if machine:IsA("Model") and not isFuseLike(machine.Name) then
                local rep = findRepresentativePart(machine) or machine
                if rep then table.insert(parts, rep) end
          
    [span_5](start_span)end[span_5](end_span)
        end
    end

    -- fallback: find models named like "*machine*" anywhere (helpful for unusual maps)
    if #parts == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not isFuseLike(obj.Name) then
                if tostring(obj.Name):lower():find("machine") then
               
      [span_6](start_span)local rep = findRepresentativePart(obj) or obj[span_6](end_span)
                    table.insert(parts, rep)
                end
            end
        end
    end

    -- final fallback: any models under Floor that look like machines (robust attempt)
    if #parts == 0 and Workspace:FindFirstChild("Floor") then
   
      [span_7](start_span)for _, obj in ipairs(Workspace.Floor:GetDescendants()) do[span_7](end_span)
            if obj:IsA("Model") and not isFuseLike(obj.Name) then
                local rep = findRepresentativePart(obj)
                if rep and (tostring(obj.Name):lower():find("machine") or rep.Name:lower():find("machine") ) then
                    table.insert(parts, rep)
          
       [span_8](start_span)end[span_8](end_span)
            end
        end
    end

    return parts
end

local function findNearestMachinePart()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local parts = gatherMachineParts()
    if #parts == 0 then return nil end
    table.sort(parts, function(a,b) return (a.Position - hrp.Position).Magnitude < 
(b.Position - hrp.Position)[span_9](start_span).Magnitude end)[span_9](end_span)
    return parts[1]
end

-- // Teleports
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0) end)
    return true
end

local function teleportToRandomMachine()
    local parts = gatherMachineParts()
    if #parts == 0 then return false end
   
  [span_10](start_span)return teleportToPart(parts[math.random(1,#parts)])[span_10](end_span)
end

local function teleportToNearestMachine()
    local p = findNearestMachinePart()
    if not p then return false end
    return teleportToPart(p)
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- // ESP
local espMachinesOn, espSpiritsOn = false, false
local espMap = {} -- key = target model, value = Highlight instance

local function createHighlightForModel(model, color)
    
[span_11](start_span)if not model or not model.Parent or espMap[model] then return end[span_11](end_span)
    local hl = Instance.new("Highlight")
    hl.Name = "TZ_HL"
    hl.Adornee = model
    hl.FillColor, hl.OutlineColor = color, color
    hl.FillTransparency = 0.55
    hl.Parent = workspace -- placing highlight in workspace is fine
    espMap[model] = hl
end

local function clearAllHighlights()
    for model, hl in pairs(espMap) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    espMap = {}
end

-- helper to 
[span_12](start_span)remove highlights for models that no longer exist[span_12](end_span)
local function cleanupDeadHighlights()
    for model, hl in pairs(espMap) do
        if not model or not model.Parent then
            pcall(function()
                if hl then hl:Destroy() end
            end)
            espMap[model] = nil
        end
  
   [span_13](start_span)end[span_13](end_span)
end

task.spawn(function()
    while true do
        -- cleanup any dead highlights
        cleanupDeadHighlights()

        -- Machines ESP
        if espMachinesOn then
            local parts = gatherMachineParts()
            for _, rep in ipairs(parts) do
                local model = rep 
[span_14](start_span)and rep:IsA("BasePart") and rep.Parent or rep[span_14](end_span)
                if model and model:IsA("Model") and not espMap[model] then
                    createHighlightForModel(model, Color3.fromRGB(0,200,0))
                end
            end
        end

        -- Spirits ESP
     
    [span_15](start_span)if espSpiritsOn then[span_15](end_span)
            -- search for any "Spirits" folder anywhere under Floor or workspace
            local foundSpiritFolders = {}
            if Workspace:FindFirstChild("Floor") then
                for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
                    if (obj:IsA("Folder") or 
[span_16](start_span)obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then[span_16](end_span)
                        table.insert(foundSpiritFolders, obj)
                    end
                end
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
     
            [span_17](start_span)if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then[span_17](end_span)
                    table.insert(foundSpiritFolders, obj)
                end
            end
            -- iterate unique folders
            local seen = {}
  
           [span_18](start_span)for _, folder in ipairs(foundSpiritFolders) do[span_18](end_span)
                if folder and not seen[folder] then
                    seen[folder] = true
                    for _, spirit in ipairs(folder:GetChildren()) do
                 
        [span_19](start_span)if spirit:IsA("Model") and not espMap[spirit] then[span_19](end_span)
                            createHighlightForModel(spirit, Color3.fromRGB(200,0,200))
                        end
                    end
               
  [span_20](start_span)end[span_20](end_span)
            end
        end

        if not espMachinesOn and not espSpiritsOn then clearAllHighlights() end
        task.wait(1)
    end
end)

-- // AutoSkill
do
    local function tryAttachSkillCheck(remote)
        if not remote then return end
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...) return 2 end
   
      [span_21](start_span)elseif remote:IsA("RemoteEvent") then[span_21](end_span)
            remote.OnClientEvent:Connect(function(...) end)
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            tryAttachSkillCheck(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then
   
          [span_22](start_span)tryAttachSkillCheck(desc)[span_22](end_span)
        end
    end)
end

-- // Infinite Stamina
local staminaFlag = false
local AddStamina
pcall(function()
    AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
end)

task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
            pcall(function() firesignal(AddStamina.OnClientEvent, 45) end)
        end
        task.wait(0.2)
    end
end)

-- // Auto Elevator
local autoElevatorFlag = false
task.spawn(function()
    while true do
 
        [span_23](start_span)if autoElevatorFlag then[span_23](end_span)
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg and msg.Enabled 
[span_24](start_span)then[span_24](end_span)
                    teleportToElevator()
                    repeat task.wait(1) until not msg.Enabled
                end
            end
        end
        task.wait(1)
    end
end)

-- // Auto Teleport
local autoTeleportFlag = false
task.spawn(function()
  
   [span_25](start_span)while true do[span_25](end_span)
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then teleportToPart(parts[math.random(1,#parts)]) end
        end
        task.wait(3)
    end
end)

-- // Rayfield GUI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Twilight Zone Hub",
   LoadingTitle = "Twilight Zone Loader",
   LoadingSubtitle = "by Ali_hhjjj",
   ConfigurationSaving 
[span_26](start_span)= { Enabled = false },[span_26](end_span)
   Discord = { Enabled = false }
})

local TabMain = Window:CreateTab("Main")
local TabESP = Window:CreateTab("ESP")
local TabCredits = Window:CreateTab("Credits")

-- ESP Tab
TabESP:CreateToggle({Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachinesOn = v;
[span_27](start_span)if not v then clearAllHighlights() end end})[span_27](end_span)
TabESP:CreateToggle({Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpiritsOn = v; if not v then clearAllHighlights() end end})

-- Main Tab
TabMain:CreateButton({Name = "Teleport: Nearest Machine", Callback = teleportToNearestMachine})
TabMain:CreateButton({Name = "Teleport: Random Machine", Callback = teleportToRandomMachine})
TabMain:CreateButton({Name = "Teleport: Elevator", Callback = teleportToElevator})
TabMain:CreateToggle({Name = "Auto Teleport Machines", CurrentValue = false, Callback = function(v) autoTeleportFlag = v end})
TabMain:CreateToggle({Name = "Auto Elevator", CurrentValue = false, Callback = function(v) autoElevatorFlag = v end})
TabMain:CreateToggle({Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end})


-- [[ PLAYER TAB ]] --

local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

-- Custom Speed
local 
[span_28](start_span)Player = game.Players.LocalPlayer[span_28](end_span)
local Humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
local walkspeed = 16

PlayerTab:CreateSlider({
    Name = "Custom Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = walkspeed,
    Flag = "SpeedValue",
    Callback = function(Value)
        walkspeed = Value
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
    
[span_29](start_span)end,[span_29](end_span)
})

-- Update when respawn
Player.CharacterAdded:Connect(function(char)
    Humanoid = char:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = walkspeed
end)

-- Noclip (fixed: single connection, restores collisions)
local noclip = false
local noclipConnection

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclip then return end
        local character = Player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
        
         [span_30](start_span)if part:IsA("BasePart") then[span_30](end_span)
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
  
   [span_31](start_span)end[span_31](end_span)
    -- restore collisions
    local character = Player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

PlayerTab:CreateToggle({
    Name = "Noclip",
    
[span_32](start_span)CurrentValue = false,[span_32](end_span)
    Flag = "NoclipToggle",
    Callback = function(Value)
        noclip = Value
        if noclip then
            enableNoclip()
        else
            disableNoclip()
        end
    end,
})

-- ensure noclip is disabled and collisions restored on character respawn/death
Player.CharacterAdded:Connect(function(char)
    -- small delay to let parts load
  
   [span_33](start_span)task.wait(0.2)[span_33](end_span)
    if noclip then
        -- if noclip active, re-enable (ensures connection is active for new character)
        enableNoclip()
    else
        -- make sure collisions are restored
        disableNoclip()
    end
end)

-- if player leaves/reset, attempt restore
Players.LocalPlayer.CharacterRemoving:Connect(function()
    disableNoclip()
end)

-- Credits Tab
TabCredits:CreateLabel("Created by Ali_hhjjj")
TabCredits:CreateLabel("Tester: GoodJOBS3")
TabCredits:CreateLabel("Thanks to Olivia (creator of Riddance Hub)")

-- Halloween!
[span_34](start_span)tab[span_34](end_span)
local TabHalloween = Window:CreateTab("🎃 Halloween!")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
local hoverHeight = 10

LocalPlayer.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

local hoverEnabled = false
task.spawn(function()
    while true do
        if hoverEnabled and hrp then
            hrp.Velocity = Vector3.new(0,0,0)
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            hrp.CFrame = CFrame.new(hrp.Position.X, hoverHeight, hrp.Position.Z)
     
    [span_35](start_span)end[span_35](end_span)
        task.wait(0.05)
    end
end)

-- **MODIFIED:** Now collects "CandyCorns" AND "Promitr" parts (assuming similar structure)
local function getAllCandyParts()
    local parts = {}
    if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Items") and Workspace.Floor.Items:FindFirstChild("Currencies") then
        local Currencies = Workspace.Floor.Items.Currencies
        for _, container in ipairs(Currencies:GetChildren()) do
            -- Look for CandyCorns
            if container:FindFirstChild("CandyCorns") then
                local main = container.CandyCorns:FindFirstChild("Main")
                if main then
    
                 [span_36](start_span)local cube = main:FindFirstChild("Cube")[span_36](end_span)
                    if cube then table.insert(parts, cube) end
                end
            end
            -- ADDED: Look for Promitr parts (assuming a similar structure)
            if container:FindFirstChild("Promitr") then
                local main = container.Promitr:FindFirstChild("Main")
                if main then
                    local cube = main:FindFirstChild("Cube")
                    if cube then table.insert(parts, cube) end
                end
            end
        end
    end
    return parts
end

local function getAllSpirits()
    local parts = {}
  
   [span_37](start_span)if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then[span_37](end_span)
        for _, folder in ipairs(Workspace.Floor.Spirits:GetChildren()) do
            for _, spirit in ipairs(folder:GetChildren()) do
                if spirit:IsA("Model") then
                    local part = spirit:FindFirstChild("HumanoidRootPart") or spirit:FindFirstChildWhichIsA("BasePart", true)
                    
[span_38](start_span)if part then table.insert(parts, part) end[span_38](end_span)
                end
            end
        end
    end
    return parts
end

local function teleportToPartHalloween(part)
    if hrp and part then
        hrp.CFrame = CFrame.new(part.Position.X, hoverHeight, part.Position.Z)
    end
end

local function spiritEncountered()
    local gui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("main")
    if gui and gui:FindFirstChild("Top") then
       
 [span_39](start_span)local eye = gui.Top:FindFirstChild("EyeIcon")[span_39](end_span)
        if eye then return eye.Visible end
    end
    return false
end

-- **MODIFIED:** Updated button name and logic for return to original position
TabHalloween:CreateButton({
    Name = "Teleport: Random Collectible", -- Name updated
    Callback = function()
        local partsToCollect = getAllCandyParts()
        if #partsToCollect == 0 or not hrp then return end
        local originalPos = hrp.CFrame
        local randomPart = partsToCollect[math.random(1,#partsToCollect)]
        teleportToPartHalloween(randomPart)
  
       [span_40](start_span)task.wait(1.5)[span_40](end_span)
        hrp.CFrame = originalPos -- Return to original position
    end
})

-- **MODIFIED:** Updated toggle name and logic for Auto Collect/Return
local autoTeleportCandyFlag = false
TabHalloween:CreateToggle({
    Name = "Auto Collect Candies/Promitrs", -- Name updated for Promitr
    CurrentValue = false,
    Flag = "AutoTeleportCandyHalloween",
    Callback = function(state)
        autoTeleportCandyFlag = state
        if state then
            task.spawn(function()
                if not hrp then return end
                local originalPos = hrp.CFrame -- Save original position
                
                while autoTeleportCandyFlag 
[span_41](start_span)do[span_41](end_span)
                    local partsToCollect = getAllCandyParts()
                    
                    if #partsToCollect > 0 then
                        for _, cube in ipairs(partsToCollect) do
                            if not autoTeleportCandyFlag then break end
                       
                            [span_42](start_span)teleportToPartHalloween(cube)[span_42](end_span)
                            task.wait(0.2)
                        end
                    end
                    
                    -- Return to original position after a sweep (only if still active)
                    if autoTeleportCandyFlag and hrp then
                        hrp.CFrame = originalPos
                    end
                    
                    task.wait(1) -- Wait before checking for new items (was 0.5)
                end
                
                -- Final return to original position if the loop is exited by disabling the flag
                if hrp then hrp.CFrame = originalPos end
            end)
       
  [span_43](start_span)end[span_43](end_span)
    end
})

local autoTeleportSpiritsFlag = false
TabHalloween:CreateToggle({
    Name = "Auto Teleport to Spirits",
    CurrentValue = false,
    Flag = "AutoTeleportSpiritsHalloween",
    Callback = function(state)
        autoTeleportSpiritsFlag = state
        hoverEnabled = state
        if state then
            task.spawn(function()
                if not hrp then return end
  
               [span_44](start_span)local originalPos = hrp.CFrame[span_44](end_span)
                local spirits = getAllSpirits()
                if #spirits == 0 then return end
                for _, part in ipairs(spirits) do
                    if 
[span_45](start_span)not autoTeleportSpiritsFlag then break end[span_45](end_span)
                    teleportToPartHalloween(part)
                    task.wait(0.5)
                    local elapsed = 0
                    while elapsed < 3 do
         
                       [span_46](start_span)if spiritEncountered() then break end[span_46](end_span)
                        task.wait(0.2)
                        elapsed = elapsed + 0.2
                    end
         
        [span_47](start_span)end[span_47](end_span)
                hrp.CFrame = originalPos
                hoverEnabled = false
                autoTeleportSpiritsFlag = false
            end)
        end
    end
})
-- Anti Lag Toggle in Main Tab
local antiLagFlag = false
TabMain:CreateToggle({
    Name = 
[span_48](start_span)"Anti Lag",[span_48](end_span)
    CurrentValue = false,
    Flag = "AntiLagToggle",
    Callback = function(state)
        antiLagFlag = state
        if antiLagFlag then
            -- Disable unnecessary effects/parts
            task.spawn(function()
                while antiLagFlag do
                
     -- Remove all decals
                    [span_49](start_span)for _, obj in ipairs(workspace:GetDescendants()) do[span_49](end_span)
                        if obj:IsA("Decal") or obj:IsA("Texture") then
                            pcall(function() obj:Destroy() end)
          
               [span_50](start_span)end[span_50](end_span)
                        -- Optionally remove particle emitters
                        if obj:IsA("ParticleEmitter") then
                            pcall(function() obj.Enabled = false 
[span_51](start_span)end)[span_51](end_span)
                        end
                        -- Optionally remove sounds
                        if obj:IsA("Sound") then
                       
      [span_52](start_span)pcall(function() obj:Stop() end)[span_52](end_span)
                        end
                    end
                    task.wait(2)
                end
            end)
 
        [span_53](start_span)end[span_53](end_span)
    end
})

game.StarterGui:SetCore("SendNotification", {
    Title = "TZ Script 💫",
    Text = "Godmode and Auto Skillcheck is ACTIVE!",
    Duration = 8
})
