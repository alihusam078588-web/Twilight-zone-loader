-- Twilight Zone Script
-- Creator: Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special Thanks: Olivia (creator of Riddance Hub) & Shelly (Riddance Manager) for idea to use Rayfield

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

----------------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------
-- UTIL
----------------------------------------------------------------------

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

local function gatherMachineParts()
    local parts = {}
    local candidates = {
        (Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")) or nil,
        Workspace:FindFirstChild("Machines") or nil,
        Workspace:FindFirstChild("CurrentRoom") or nil,
        Workspace
    }
    for _, folder in ipairs(candidates) do
        if folder and folder.GetChildren then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    if not isFuseLike(child.Name) then
                        local rep = findRepresentativePart(child)
                        if rep then table.insert(parts, rep) end
                    end
                elseif child:IsA("BasePart") then
                    if not isFuseLike(child.Name) then table.insert(parts, child) end
                end
            end
        end
    end
    return parts
end

local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
    return true
end

----------------------------------------------------------------------
-- FEATURES
----------------------------------------------------------------------

-- Godmode (always-on)
task.spawn(function()
    while true do
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v and v.Name == "HitPlayer" then v:Destroy() end
        end
        task.wait(0.5)
    end
end)

-- Auto SkillCheck (always-on)
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

-- ESP
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

local function createHighlightFor(target, color)
    if not target or not target.Parent or espMap[target] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "TZ_HL"
    hl.Adornee = target
    hl.FillColor, hl.OutlineColor = color, color
    hl.FillTransparency = 0.55
    hl.Parent = target
    espMap[target] = hl
end

local function clearAllHighlights()
    for _, hl in pairs(espMap) do pcall(function() hl:Destroy() end) end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            for _, p in ipairs(gatherMachineParts()) do
                if p and p.Parent and not espMap[p] then
                    if p.Parent:IsA("Model") then
                        createHighlightFor(p.Parent, Color3.fromRGB(0,200,0))
                    else
                        createHighlightFor(p, Color3.fromRGB(0,200,0))
                    end
                end
            end
        end
        if espSpiritsOn then
            local containers = {}
            if Workspace:FindFirstChild("Spirits") then table.insert(containers, Workspace.Spirits) end
            if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then table.insert(containers, Workspace.Floor.Spirits) end
            for _, c in ipairs(containers) do
                for _, s in ipairs(c:GetChildren()) do
                    if s and not espMap[s] then createHighlightFor(s, Color3.fromRGB(200,0,200)) end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then clearAllHighlights() end
        task.wait(0.9)
    end
end)

-- Infinite Stamina
local staminaFlag = false
local AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
task.spawn(function()
    while true do
        if staminaFlag then
            pcall(function() firesignal(AddStamina.OnClientEvent, 45) end)
        end
        task.wait(0.2)
    end
end)

-- Auto Elevator
local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoElevatorFlag then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg and msg.Enabled then
                    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
                    if spawn then teleportToPart(spawn, 2) end
                    repeat task.wait(1) until not msg.Enabled
                end
            end
        end
        task.wait(1)
    end
end)

-- Auto Teleport + Machine Aura
local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then
                local p = parts[math.random(1,#parts)]
                teleportToPart(p)
                -- Machine aura (spam E)
                for _, d in ipairs(p.Parent:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(d) end)
                    end
                end
            end
        end
        task.wait(3)
    end
end)

----------------------------------------------------------------------
-- RAYFIELD UI
----------------------------------------------------------------------

-- ESP Tab
local ESPTab = Window:CreateTab("ESP")
ESPTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(v) espMachinesOn = v end
})
ESPTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(v) espSpiritsOn = v end
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("Teleport")
TeleportTab:CreateButton({
    Name = "Teleport: Random Machine (with Aura)",
    Callback = function()
        local parts = gatherMachineParts()
        if #parts > 0 then
            local p = parts[math.random(1,#parts)]
            teleportToPart(p)
            for _, d in ipairs(p.Parent:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    pcall(function() fireproximityprompt(d) end)
                end
            end
        end
    end
})
TeleportTab:CreateButton({
    Name = "Teleport: Elevator",
    Callback = function()
        local elevator = Workspace:FindFirstChild("Elevator")
        if elevator then
            local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
            if spawn then teleportToPart(spawn, 2) end
        end
    end
})

-- Auto Farm Tab
local AutoFarmTab = Window:CreateTab("Auto Farm")
AutoFarmTab:CreateToggle({
    Name = "Auto Teleport (with Machine Aura)",
    CurrentValue = false,
    Callback = function(v) autoTeleportFlag = v end
})
AutoFarmTab:CreateToggle({
    Name = "Auto Elevator (when all machines done)",
    CurrentValue = false,
    Callback = function(v) autoElevatorFlag = v end
})

-- Player Tab
local PlayerTab = Window:CreateTab("Player")
PlayerTab:CreateSlider({
    Name = "Custom Speed",
    Range = {16,100},
    Increment = 1,
    Suffix = "WalkSpeed",
    CurrentValue = 16,
    Callback = function(v)
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
})
PlayerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Callback = function(v) staminaFlag = v end
})
PlayerTab:CreateParagraph({Title = "Godmode", Content = "Always ON"})
PlayerTab:CreateParagraph({Title = "Auto SkillCheck", Content = "Always ON"})

----------------------------------------------------------------------
-- END
----------------------------------------------------------------------

Rayfield:Notify({
    Title = "Twilight Zone",
    Content = "Loaded successfully with Rayfield UI",
    Duration = 6
})
