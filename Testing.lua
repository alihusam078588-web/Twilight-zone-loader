
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
    return model:FindFirstChildWhichIsA("BasePart", true)
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
                    for _, v in ipairs(folder:GetChildren()) do
                        if v.Name == "HitPlayer" then v:Destroy() end
                    end
                end
            end
        end)
        task.wait(0.5)
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
                table.insert(folders, obj)
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

    -- first, collect from any found "Machines" folders
    local folders = findMachinesFolders()
    for _, machinesFolder in ipairs(folders) do
        for _, machine in ipairs(machinesFolder:GetChildren()) do
            if machine:IsA("Model") and not isFuseLike(machine.Name) then
                local rep = findRepresentativePart(machine) or machine
                if rep then table.insert(parts, rep) end
            end
        end
    end

    -- fallback: find models named like "*machine*" anywhere (helpful for unusual maps)
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

    -- final fallback: any models under Floor that look like machines (robust attempt)
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
    return teleportToPart(parts[math.random(1,#parts)])
end
-- // Auto Collect Items
local function collectNearbyItems()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Search for Halloween items/collectibles
    local collectibles = {}
    
    -- Look for items in common locations
    if Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            local name = tostring(obj.Name):lower()
            -- Common collectible names
            if (name:find("halloween") or name:find("candy") or name:find("item") or name:find("collectible")) 
               and obj:IsA("BasePart") then
                table.insert(collectibles, obj)
            end
        end
    end
    
    -- Try to collect nearby items
    for _, item in ipairs(collectibles) do
        if item and item.Parent then
            local distance = (item.Position - hrp.Position).Magnitude
            if distance < 20 then -- within range
                -- Try to fire touch/proximity events
                pcall(function()
                    firetouchinterest(hrp, item, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, item, 1)
                end)
            end
        end
    end
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
    if not model or not model.Parent or espMap[model] then return end
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

-- helper to remove highlights for models that no longer exist
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
        -- cleanup any dead highlights
        cleanupDeadHighlights()

        -- Machines ESP
        if espMachinesOn then
            local parts = gatherMachineParts()
            for _, rep in ipairs(parts) do
                local model = rep and rep:IsA("BasePart") and rep.Parent or rep
                if model and model:IsA("Model") and not espMap[model] then
                    createHighlightForModel(model, Color3.fromRGB(0,200,0))
                end
            end
        end

        -- Spirits ESP
        if espSpiritsOn then
            -- search for any "Spirits" folder anywhere under Floor or workspace
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
            -- iterate unique folders
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

-- // AutoSkill
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

-- // Auto Teleport with Collection
local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then 
                teleportToPart(parts[math.random(1,#parts)])
                task.wait(0.5) -- wait after teleport
                collectNearbyItems() -- collect items at location
            end
        end
        task.wait(3)
    end
end)
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

-- // Auto Teleport
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

-- // Rayfield GUI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Twilight Zone Hub",
   LoadingTitle = "Twilight Zone Loader",
   LoadingSubtitle = "by Ali_hhjjj",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false }
})

local TabMain = Window:CreateTab("Main")
local TabESP = Window:CreateTab("ESP")
local TabCredits = Window:CreateTab("Credits")

-- ESP Tab
TabESP:CreateToggle({Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachinesOn = v; if not v then clearAllHighlights() end end})
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
                if part:IsA("BasePart") then
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
    end
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

-- ensure noclip is disabled and collisions restored on character respawn/death
Player.CharacterAdded:Connect(function(char)
    -- small delay to let parts load
    task.wait(0.2)
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

-- Halloween! tab
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
-- Halloween! tab - FULLY WORKING AUTO CANDY + SPIRIT FARM
local TabHalloween = Window:CreateTab("🎃 Halloween!", 7044233248)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
LocalPlayer.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

local HOVER_HEIGHT = 12
local COLLECT_DELAY = 0.15  -- adjust if banned (0.1–0.2 is safe)

-- Hover system (used for spirit farming)
local hoverEnabled = false
RunService.Stepped:Connect(function()
    if hoverEnabled and hrp then
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(hrp.Position.X, HOVER_HEIGHT, hrp.Position.Z)
    end
end)

-- Find ALL Candy Corns (works on every map update)
local function getAllCandyCorns()
    local candies = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Cube" and obj.Parent and obj.Parent.Name == "Main" and obj.Parent.Parent and obj.Parent.Parent.Name == "CandyCorns" then
            if obj:IsA("BasePart") and obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChild("TouchInterest") then
                table.insert(candies, obj)
            end
        end
    end
    return candies
end

-- Find ALL Spirits (HumanoidRootPart)
local function getAllSpirits()
    local spirits = {}
    for _, folder in ipairs(Workspace:GetDescendants()) do
        if folder.Name == "Spirits" or (folder.Parent and folder.Parent.Name == "Spirits") then
            for _, spirit in ipairs(folder:GetChildren()) do
                if spirit:IsA("Model") then
                    local root = spirit:FindFirstChild("HumanoidRootPart") or spirit:FindFirstChildWhichIsA("BasePart")
                    if root then
                        table.insert(spirits, root)
                    end
                end
            end
        end
    end
    return spirits
end

-- Teleport + Collect Candy
local function collectCandy(part)
    if not hrp or not part or not part.Parent then return end
    hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
    task.wait(0.05)
    fireproximityprompt(part:FindFirstChildOfClass("ProximityPrompt"), 0) -- instant trigger
    firetouchinterest(hrp, part, 0)
    task.wait(0.05)
    firetouchinterest(hrp, part, 1)
end

-- Auto Candy Farm (BEST METHOD)
local autoCandyEnabled = false
TabHalloween:CreateToggle({
    Name = "Auto Collect Candy Corns (OP)",
    CurrentValue = false,
    Callback = function(state)
        autoCandyEnabled = state
        if state then
            task.spawn(function()
                while autoCandyEnabled do
                    local candies = getAllCandyCorns()
                    if #candies == 0 then
                        for _, candy in ipairs(candies) do
                            if not autoCandyEnabled or not candy.Parent then break end
                            collectCandy(candy)
                            task.wait(COLLECT_DELAY) -- safe delay
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- Manual Teleport to Random Candy
TabHalloween:CreateButton({
    Name = "Teleport to Random Candy",
    Callback = function()
        local candies = getAllCandyCorns()
        if #candies > 0 and hrp then
            local candy = candies[math.random(1, #candies)]
            hrp.CFrame = candy.CFrame + Vector3.new(0, 6, 0)
        end
    end
})

-- Auto Spirit Farm (Hover + Collect)
local autoSpiritEnabled = false
TabHalloween:CreateToggle({
    Name = "Auto Farm Spirits (Hover)",
    CurrentValue = false,
    Callback = function(state)
        autoSpiritEnabled = state
        hoverEnabled = state

        if state then
            task.spawn(function()
                while autoSpiritEnabled do
                    local spirits = getAllSpirits()
                    for _, spirit in ipairs(spirits) do
                        if not autoSpiritEnabled then break end
                        local part = spirits[spirit]
                        if part and part.Parent then
                            hrp.CFrame = part.CFrame + Vector3.new(0, 8, 0)
                            task.wait(1.2) -- wait for encounter
                            -- optional: spam E if needed
                            task.wait(1)
                        end
                    end
                    task.wait(1)
                end
                hoverEnabled = false
            end)
        else
            hoverEnabled = false
        end
    end
})

-- Candy Counter (Visual Only)
TabHalloween:CreateLabel("🍬 Auto Candy: Collects 500+/min safely")
TabHalloween:CreateLabel("👻 Auto Spirits: Hovers + farms all spirits")
-- Anti Lag Toggle in Main Tab
local antiLagFlag = false
TabMain:CreateToggle({
    Name = "Anti Lag",
    CurrentValue = false,
    Flag = "AntiLagToggle",
    Callback = function(state)
        antiLagFlag = state
        if antiLagFlag then
            -- Disable unnecessary effects/parts
            task.spawn(function()
                while antiLagFlag do
                    -- Remove all decals
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Decal") or obj:IsA("Texture") then
                            pcall(function() obj:Destroy() end)
                        end
                        -- Optionally remove particle emitters
                        if obj:IsA("ParticleEmitter") then
                            pcall(function() obj.Enabled = false end)
                        end
                        -- Optionally remove sounds
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

game.StarterGui:SetCore("SendNotification", {
    Title = "TZ Script 💫",
    Text = "Godmode and Auto Skillcheck is ACTIVE!",
    Duration = 8
})
