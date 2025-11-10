local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart"}
    for _,n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then return f end
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

task.spawn(function()
    while true do
        pcall(function()
            if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then
                for _, folder in ipairs(Workspace.Floor.Spirits:GetChildren()) do
                    for _, v in ipairs(folder:GetChildren()) do
                        if v.Name == "HitPlayer" then v:Destroy() end
                    end
                end
            end
        end)
    task.wait(0.5)
    end
end)

local function findMachinesFolders()
    local folders = {}
    if Workspace:FindFirstChild("Machines") then
        table.insert(folders, Workspace.Machines)
    end
    if Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
                table.insert(folders, obj)
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
            table.insert(folders, obj)
        end
    end
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
    local folders = findMachinesFolders()
    for _, machinesFolder in ipairs(folders) do
        for _, machine in ipairs(machinesFolder:GetChildren()) do
            if machine:IsA("Model") and not isFuseLike(machine.Name) then
                local rep = findRepresentativePart(machine) or machine
                if rep then table.insert(parts, rep) end
            end
        end
    end
    if #parts == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not isFuseLike(obj.Name) then
                if tostring(obj.Name):lower():find("machine") then
                    local rep = findRepresentativePart(obj) or obj
                    table.insert(parts, rep)
                end
            end
        end
    end
    if #parts == 0 and Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            if obj:IsA("Model") and not isFuseLike(obj.Name) then
                local rep = findRepresentativePart(obj)
                if rep and (tostring(obj.Name):lower():find("machine") or rep.Name:lower():find("machine") ) then
                    table.insert(parts, rep)
                end
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
    table.sort(parts, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)
    return parts[1]
end

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
    return teleportToPart(parts[math.random(1,#parts)])
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

local espMachinesOn, espSpiritsOn = false, false
local espMap = {} 

local function createHighlightForModel(model, color)
    if not model or not model.Parent or espMap[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "TZ_HL"
    hl.Adornee = model
    hl.FillColor, hl.OutlineColor = color, color
    hl.FillTransparency = 0.55
    hl.Parent = workspace 
    espMap[model] = hl
end

local function clearAllHighlights()
    for model, hl in pairs(espMap) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    espMap = {}
end

local function cleanupDeadHighlights()
    for model, hl in pairs(espMap) do
        if not model or not model.Parent then
            pcall(function()
                if hl then hl:Destroy() end
            end)
            espMap[model] = nil
        end
    end
end

task.spawn(function()
    while true do
        cleanupDeadHighlights()
        if espMachinesOn then
            local parts = gatherMachineParts()
            for _, rep in ipairs(parts) do
                local model = rep and rep:IsA("BasePart") and rep.Parent or rep
                if model and model:IsA("Model") and not espMap[model] then
                    createHighlightForModel(model, Color3.fromRGB(0,200,0))
                end
            end
        end
        if espSpiritsOn then
            local foundSpiritFolders = {}
            if Workspace:FindFirstChild("Floor") then
                for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
                    if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then
                        table.insert(foundSpiritFolders, obj)
                    end
                end
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then
                    table.insert(foundSpiritFolders, obj)
                end
            end
            local seen = {}
            for _, folder in ipairs(foundSpiritFolders) do
                if folder and not seen[folder] then
                    seen[folder] = true
                    for _, spirit in ipairs(folder:GetChildren()) do
                        if spirit:IsA("Model") and not espMap[spirit] then
                            createHighlightForModel(spirit, Color3.fromRGB(200,0,200))
                        end
                    end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then clearAllHighlights() end
        task.wait(1)
    end
end)

do
    local function tryAttachSkillCheck(remote)
        if not remote then return end
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...) return 2 end
        elseif remote:IsA("RemoteEvent") then
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
            tryAttachSkillCheck(desc)
        end
    end)
end

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

local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoElevatorFlag then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg and msg.Enabled then
                    teleportToElevator()
                    repeat task.wait(1) until not msg.Enabled
                end
            end
        end
        task.wait(1)
    end
end)

local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then teleportToPart(parts[math.random(1,#parts)]) end
        end
        task.wait(3)
    end
end)

-- Auto Collect Logic
local hrp 
local hoverHeight = 10
local hoverEnabled = false
local autoCollectCandyFlag = false
local autoTeleportSpiritsFlag = false
local autoCollectBooksFlag = false
local autoCollectStarsFlag = false

local function getCharacterAndHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp_local = char and char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    return char, hrp_local
end

LocalPlayer.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

task.spawn(function()
    while true do
        if hoverEnabled and hrp then
            hrp.Velocity = Vector3.new(0,0,0)
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            hrp.CFrame = CFrame.new(hrp.Position.X, hoverHeight, hrp.Position.Z)
        end
        task.wait(0.05)
    end
end)

-- Safe Collection Function (No Fling)
local function collectWithPrompt(itemModel)
    if not itemModel or not itemModel.Parent then return end
    
    -- Recursively find the ProximityPrompt
    local prompt = itemModel:FindFirstChildOfClass("ProximityPrompt", true)
    
    if prompt and prompt:IsA("ProximityPrompt") then
        pcall(function()
            -- Attempt to set hold duration very low (0.01) if necessary, then trigger
            if prompt.HoldDuration > 0 then
                prompt.HoldDuration = 0.01 
            end
            prompt:InputHoldTime(0) -- Triggers the prompt instantly for collection
        end)
        -- Wait for the server to process collection and destroy the item
        task.wait(0.05)
    end
end


-- Candy Collector: Returns the model containing the prompt
local function getAllCandyModels()
    local models = {}
    if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Items") then
        for _, container in ipairs(Workspace.Floor.Items.Currencies:GetChildren()) do
            if container:FindFirstChild("CandyCorns") then
                table.insert(models, container.CandyCorns)
            end
        end
    end
    return models
end

local function autoCollectCandys()
    task.spawn(function()
        while autoCollectCandyFlag do
            local candies = getAllCandyModels()
            for _, model in ipairs(candies) do
                if not autoCollectCandyFlag then break end
                collectWithPrompt(model)
            end
            task.wait(1) 
        end
    end)
end

-- Research Book Collector: Returns the item model containing the prompt
local function getAllResearchBooks()
    local models = {}
    if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Items") then
        local target = Workspace.Floor.Items 
        for _, obj in ipairs(target:GetDescendants()) do
            local name = obj.Name:lower()
            -- Search for capsules, books, research, or prom (Prom is likely a container name)
            if obj:IsA("Model") and (name:find("capsule") or name:find("book") or name:find("research") or name:find("prom")) then
                -- Ensure the model has a ProximityPrompt or a part that contains one
                if obj:FindFirstChildOfClass("ProximityPrompt", true) then
                    table.insert(models, obj)
                end
            end
        end
    end
    return models
end

local function startAutoCollectBooks()
    task.spawn(function()
        while autoCollectBooksFlag do
            local items = getAllResearchBooks()
            for _, itemModel in ipairs(items) do
                if not autoCollectBooksFlag then break end
                collectWithPrompt(itemModel)
            end
            task.wait(1) 
        end
    end)
end

-- Star Collector: Returns the item model containing the prompt
local function getAllStars()
    local models = {}
    if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Items") and Workspace.Floor.Items:FindFirstChild("Currencies") then
        local currencies = Workspace.Floor.Items.Currencies
        for _, container in ipairs(currencies:GetChildren()) do
            local name = container.Name:lower()
            if name:find("star") and container:IsA("Model") then
                 if container:FindFirstChildOfClass("ProximityPrompt", true) then
                    table.insert(models, container)
                end
            end
        end
    end
    return models
end

local function startAutoCollectStars()
    task.spawn(function()
        while autoCollectStarsFlag do
            local items = getAllStars()
            for _, itemModel in ipairs(items) do
                if not autoCollectStarsFlag then break end
                collectWithPrompt(itemModel)
            end
            task.wait(1) 
        end
    end)
end

local function spiritEncountered()
    local gui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("main")
    if gui and gui:FindFirstChild("Top") then
        local eye = gui.Top:FindFirstChild("EyeIcon")
        if eye then return eye.Visible end
    end
    return false
end

local function getAllSpirits()
    local parts = {}
    if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then
        for _, folder in ipairs(Workspace.Floor.Spirits:GetChildren()) do
            for _, spirit in ipairs(folder:GetChildren()) do
                if spirit:IsA("Model") then
                    local part = spirit:FindFirstChild("HumanoidRootPart") or spirit:FindFirstChildWhichIsA("BasePart", true)
                    if part then table.insert(parts, part) end
                end
            end
        end
    end
    return parts
end

local function autoBypassSpirits()
    task.spawn(function()
        local _, hrp_local = getCharacterAndHRP()
        if not hrp_local then 
            autoTeleportSpiritsFlag = false 
            hoverEnabled = false
            return 
        end
        
        local originalPos = hrp_local.CFrame
        local spirits = getAllSpirits()
        
        if #spirits == 0 then 
            autoTeleportSpiritsFlag = false 
            hoverEnabled = false
            return 
        end
        
        for _, part in ipairs(spirits) do
            if not autoTeleportSpiritsFlag then break end
            hrp_local.CFrame = CFrame.new(part.Position.X, hoverHeight, part.Position.Z)
            task.wait(0.5)
            
            local elapsed = 0
            while elapsed < 3 do
                if spiritEncountered() then break end
                task.wait(0.2)
                elapsed = elapsed + 0.2
            end
        end
        
        if hrp_local.Parent then
            hrp_local.CFrame = originalPos
        end
        
        hoverEnabled = false
        autoTeleportSpiritsFlag = false
    end)
end


local Rayfield
local success, errorMessage = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not Rayfield or not success then
    warn("Failed to load Rayfield UI library: " .. (errorMessage or "Unknown error"))
    game.StarterGui:SetCore("SendNotification", {
        Title = "Script Error ❌",
        Text = "Failed to load the UI library. Check your executor or connection.",
        Duration = 8
    })
    return 
end

local Window = Rayfield:CreateWindow({
   Name = "Twilight Zone Hub",
   LoadingTitle = "Twilight Zone Loader",
   LoadingSubtitle = "by Ali_hhjjj",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false }
})

local TabMain = Window:CreateTab("Main")
local TabESP = Window:CreateTab("ESP")
local TabCollect = Window:CreateTab("Auto Collect") 
local TabCredits = Window:CreateTab("Credits")

TabESP:CreateToggle({Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachinesOn = v; if not v then clearAllHighlights() end end})
TabESP:CreateToggle({Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpiritsOn = v; if not v then clearAllHighlights() end end})

TabMain:CreateButton({Name = "Teleport: Nearest Machine", Callback = teleportToNearestMachine})
TabMain:CreateButton({Name = "Teleport: Random Machine", Callback = teleportToRandomMachine})
TabMain:CreateButton({Name = "Teleport: Elevator", Callback = teleportToElevator})
TabMain:CreateToggle({Name = "Auto Teleport Machines", CurrentValue = false, Callback = function(v) autoTeleportFlag = v end})
TabMain:CreateToggle({Name = "Auto Elevator", CurrentValue = false, Callback = function(v) autoElevatorFlag = v end})
TabMain:CreateToggle({Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end})

local antiLagFlag = false
TabMain:CreateToggle({
    Name = "Anti Lag",
    CurrentValue = false,
    Flag = "AntiLagToggle",
    Callback = function(state)
        antiLagFlag = state
        if antiLagFlag then
            task.spawn(function()
                while antiLagFlag do
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Decal") or obj:IsA("Texture") then
                            pcall(function() obj:Destroy() end)
                        end
                        if obj:IsA("ParticleEmitter") then
                            pcall(function() obj.Enabled = false end)
                        end
                        if obj:IsA("Sound") then
                            pcall(function() obj:Stop() end)
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end
})

-- Auto Collect Toggles (Now all safe/no-fling)
TabCollect:CreateToggle({
    Name = "Auto Collect Candys",
    CurrentValue = false,
    Flag = "AutoCollectCandyHalloween",
    Callback = function(state)
        autoCollectCandyFlag = state
        if state then
            autoCollectCandys()
        end
    end
})

TabCollect:CreateToggle({
    Name = "Auto Collect Research Books",
    CurrentValue = false,
    Flag = "AutoCollectBooks",
    Callback = function(state)
        autoCollectBooksFlag = state
        if state then
            startAutoCollectBooks()
        end
    end
})

TabCollect:CreateToggle({
    Name = "Auto Collect Stars",
    CurrentValue = false,
    Flag = "AutoCollectStars",
    Callback = function(state)
        autoCollectStarsFlag = state
        if state then
            startAutoCollectStars()
        end
    end
})

TabCollect:CreateToggle({
    Name = "Auto Bypass Spirits (Hover)",
    CurrentValue = false,
    Flag = "AutoTeleportSpiritsHalloween",
    Callback = function(state)
        autoTeleportSpiritsFlag = state
        hoverEnabled = state
        if state then
            autoBypassSpirits()
        end
    end
})

-- Player Tab
local PlayerTab = Window:CreateTab("Player", 4483362458)
local Player = game.Players.LocalPlayer
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
    end,
})

Player.CharacterAdded:Connect(function(char)
    Humanoid = char:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = walkspeed
end)

local noclip = false
local noclipConnection

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclip then return end
        local character = Player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local character = Player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
end

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
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

Player.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    if noclip then
        enableNoclip()
    else
        disableNoclip()
    end
end)

Players.LocalPlayer.CharacterRemoving:Connect(function()
    disableNoclip()
end)

TabCredits:CreateLabel("Created by Ali_hhjjj")
TabCredits:CreateLabel("Tester: GoodJOBS3")
TabCredits:CreateLabel("Thanks to Olivia (creator of Riddance Hub)")


game.StarterGui:SetCore("SendNotification", {
    Title = "TZ Script",
    Text = "Godmode and Auto Skillcheck is ACTIVE!",
    Duration = 8
})
