local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local function notify(msg)
    StarterGui:SetCore("SendNotification", {
        Title = "TZ Loader",
        Text = msg,
        Duration = 8
    })
end

-- Check if LobbySpawn exists
if Workspace:FindFirstChild("LobbySpawn") then
    notify("Please use the script only in game, not in lobby!")
end
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
        if f and f:IsA("BasePart") then
            return f
        end
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
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
                        if v.Name == "HitPlayer" then
                            v:Destroy()
                        end
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
                if rep and (tostring(obj.Name):lower():find("machine") or rep.Name:lower():find("machine")) then
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
    table.sort(parts, function(a,b)
        return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
    end)
    return parts[1]
end

-- // Teleports
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
    end)
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

-- // ESP
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
        pcall(function()
            if hl then hl:Destroy() end
        end)
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
                    createHighlightForModel(model, Color3.fromRGB(0, 200, 0))
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
                        if spirit:IsA("Model") then
                            local part = spirit:FindFirstChild("HumanoidRootPart") or spirit:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                createHighlightForModel(spirit, Color3.fromRGB(200, 0, 200))
                            end
                        end
                    end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then
            clearAllHighlights()
        end
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

-- // Infinite Stamina
local staminaFlag = false
local AddStamina
pcall(function()
    AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
end)
task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
            pcall(function()
                firesignal(AddStamina.OnClientEvent, 45)
            end)
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
                    repeat
                        task.wait(1)
                    until not msg.Enabled
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
            if #parts > 0 then
                teleportToPart(parts[math.random(1, #parts)])
            end
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
    Discord = { Enabled = false },
})

local TabMain = Window:CreateTab("Main")
local TabESP = Window:CreateTab("ESP")
local TabAutoCollect = Window:CreateTab("Auto collect")
local TabCredits = Window:CreateTab("Credits")

-- Main Tab
TabMain:CreateButton({ Name = "Teleport: Nearest Machine", Callback = teleportToNearestMachine })
TabMain:CreateButton({ Name = "Teleport: Random Machine", Callback = teleportToRandomMachine })
TabMain:CreateButton({ Name = "Teleport: Elevator", Callback = teleportToElevator })
TabMain:CreateToggle({ Name = "Auto Teleport Machines", CurrentValue = false, Callback = function(v) autoTeleportFlag = v end })
TabMain:CreateToggle({ Name = "Auto Elevator", CurrentValue = false, Callback = function(v) autoElevatorFlag = v end })
TabMain:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end })
TabMain:CreateToggle({ Name = "Anti Lag", CurrentValue = false, Callback = function(state)
    if state then
        task.spawn(function()
            while state do
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Decal") or obj:IsA("Texture") then
                        pcall(function() obj:Destroy() end)
                    elseif obj:IsA("ParticleEmitter") then
                        pcall(function() obj.Enabled = false end)
                    elseif obj:IsA("Sound") then
                        pcall(function() obj:Stop() end)
                    end
                end
                task.wait(2)
            end
        end)
    end
end })

-- ESP Tab
TabESP:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachinesOn = v if not v then clearAllHighlights() end end })
TabESP:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpiritsOn = v if not v then clearAllHighlights() end end })

-- Auto Collect Tab (new)
do
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hoverHeight = 10
    LocalPlayer.CharacterAdded:Connect(function(char)
        hrp = char:WaitForChild("HumanoidRootPart")
    end)
    

    local function getAllSpirits()
        local parts = {}
        if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then
            for _, folder in ipairs(Workspace.Floor.Spirits:GetChildren()) do
                for _, spirit in ipairs(folder:GetChildren()) do
                    if spirit:IsA("Model") then
                        local part = spirit:FindFirstChild("HumanoidRootPart") or spirit:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            table.insert(parts, part)
                        end
                    end
                end
            end
        end
        return parts
    end



    local function spiritEncountered()
        local gui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("main")
        if gui and gui:FindFirstChild("Top") then
            local eye = gui.Top:FindFirstChild("EyeIcon")
            if eye then
                return eye.Visible
            end
        end
        return false
    end


    -- Auto teleport to spirits toggle
    local autoTeleportSpiritsFlag = false
    TabAutoCollect:CreateToggle({
        Name = "Auto Teleport to Spirits",
        CurrentValue = false,
        Callback = function(state)
            autoTeleportSpiritsFlag = state
            hoverEnabled = state
            if state then
                task.spawn(function()
                    if not hrp then return end
                    local originalPos = hrp.CFrame
                    local spirits = getAllSpirits()
                    if #spirits == 0 then return end
                    for _, part in ipairs(spirits) do
                        if not autoTeleportSpiritsFlag then break end
                        teleportTo(part)
                        task.wait(0.5)
                        local elapsed = 0
                        while elapsed < 3 do
                            if spiritEncountered() then break end
                            task.wait(0.2)
                            elapsed = elapsed + 0.2
                        end
                    end
                    hrp.CFrame = originalPos
                    hoverEnabled = false
                    autoTeleportSpiritsFlag = false
                end)
            end
        end
    })
end

-- Credits Tab
TabCredits:CreateLabel("Created by Ali_hhjjj")
TabCredits:CreateLabel("Tester: GoodJOBS3")
TabCredits:CreateLabel("Thanks to Olivia (creator of Riddance Hub) and shelly (Riddance manager) for Rayfield idea")

-- Notification (same as before)
game.StarterGui:SetCore("SendNotification", {
    Title = "TZ Script",
    Text = "Godmode and Auto Skillcheck is ACTIVE!",
    Duration = 8
})

TabAutoCollect:CreateButton({
    Name = "Collect Currency",
    Callback = function()
        local items = workspace.Floor.Items.Currencies:GetChildren()
        for i = 1, #items do
            local item = items[i]
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = item:GetPivot()
                    task.wait(0.3)
                    fireproximityprompt(prompt)
                end
                break
            end
        end
    end
})


TabAutoCollect:CreateButton({
    Name = "Collect Capsule",
    Callback = function()
        local items = workspace.Floor.Items.Capsules:GetChildren()
        for i = 1, #items do
            local item = items[i]
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = item:GetPivot()
                    task.wait(0.3)
                    fireproximityprompt(prompt)
                end
                break
            end
        end
    end
})

local autoCurrency = false

TabAutoCollect:CreateToggle({
    Name = "Auto Collect Currency",
    CurrentValue = false,
    Callback = function(state)
        autoCurrency = state
        if state then
            task.spawn(function()
                while autoCurrency do
                    local items = workspace.Floor.Items.Currencies:GetChildren()
                    for i = 1, #items do
                        if not autoCurrency then break end
                        local item = items[i]
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if prompt and hrp then
                            hrp.CFrame = item:GetPivot()
                            task.wait(0.25)
                            fireproximityprompt(prompt)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

local autoCapsule = false

TabAutoCollect:CreateToggle({
    Name = "Auto Collect Capsule",
    CurrentValue = false,
    Callback = function(state)
        autoCapsule = state
        if state then
            task.spawn(function()
                while autoCapsule do
                    local items = workspace.Floor.Items.Capsules:GetChildren()
                    for i = 1, #items do
                        if not autoCapsule then break end
                        local item = items[i]
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if prompt and hrp then
                            hrp.CFrame = item:GetPivot()
                            task.wait(0.25)
                            fireproximityprompt(prompt)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local OWNER_NAME = "Ali_hhjjj"


local function notifyOwner()
    StarterGui:SetCore("SendNotification", {
        Title = "TZ Owner",
        Text = "The owner joined your server",
        Duration = 8
    })
end


for _, plr in pairs(Players:GetPlayers()) do
    if plr.Name == OWNER_NAME then
        notifyOwner()
    end
end


Players.PlayerAdded:Connect(function(plr)
    if plr.Name == OWNER_NAME then
        notifyOwner()
    end
end)
local autoFarmFlag = false

local function hasAvailableMachinePrompt(machinesFolder)
    if not machinesFolder then return false end
    for _, machine in ipairs(machinesFolder:GetChildren()) do
        local front = machine:FindFirstChild("Front")
        if front then
            local prompt = front:FindFirstChildWhichIsA("ProximityPrompt", true) or front:FindFirstChild("ProximityPrompt")
            if prompt and (not prompt.Enabled or prompt.Enabled == nil) == false then
                -- prompt exists and appears enabled (some games set Enabled = true/false)
                return true
            end
        end
    end
    return false
end

TabMain:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(state)
        autoFarmFlag = state

        task.spawn(function()
            while autoFarmFlag do
                task.wait(0.4)

                local floor = workspace:FindFirstChild("Floor")
                if not floor then
                    task.wait(1)
                    continue
                end

                local machinesFolder = floor:FindFirstChild("Machines")
                if not machinesFolder then
                    task.wait(1)
                    continue
                end

                local anyTriggered = false

                for _, machine in ipairs(machinesFolder:GetChildren()) do
                    if not autoFarmFlag then break end

                    local front = machine:FindFirstChild("Front")
                    if not front then continue end

                    local prompt = front:FindFirstChildWhichIsA("ProximityPrompt", true) or front:FindFirstChild("ProximityPrompt")
                    if not prompt then continue end

                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end

                    -- Teleport in front of the machine
                    hrp.CFrame = front.CFrame + front.CFrame.LookVector * -2
                    task.wait(0.2)

                    -- Trigger the machine
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)

                    anyTriggered = true
                    task.wait(0.4)
                end

                -- Auto elevator use if elevator prompt exists (original behaviour)
                local elevator = floor:FindFirstChild("Elevator")
                if elevator then
                    local prompt = elevator:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                    end
                end

                -- If we didn't trigger any machines this pass, teleport to elevator in a loop
                if not anyTriggered then
                    -- keep teleporting to elevator until a new machine prompt appears or autoFarmFlag becomes false
                    local attempts = 0
                    while autoFarmFlag and not hasAvailableMachinePrompt(machinesFolder) and attempts < 30 do
                        pcall(function()
                            teleportToElevator()
                        end)
                        attempts = attempts + 1
                        task.wait(2) -- wait between teleports; you can lower this if you want faster looping
                    end
                end
            end
        end)
    end
})
TabMain:CreateLabel("this auto farm only teleport to machines and elevator it does not work with traps")
