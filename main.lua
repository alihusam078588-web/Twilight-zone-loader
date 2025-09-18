-- Twilight Zone Hub
-- Creator: Ali_hhjjj
-- Tester/Helper: GoodJOBS3
-- Special Thanks: Olivia (Riddance Hub Creator) & Shelly (Riddance Manager)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Rayfield
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then
    warn("[TZ] Rayfield failed to load.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = { Enabled = true, FolderName = "TZ_Hub", FileName = "TZ_Config" }
})

-- === Utility ===
local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local front = model:FindFirstChild("Front")
    if front and front:IsA("BasePart") then return front end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function gatherMachineEntries()
    local list = {}
    local floor = Workspace:FindFirstChild("Floor")
    local machinesFolder = floor and floor:FindFirstChild("Machines")
    if not machinesFolder then return list end
    for _, child in ipairs(machinesFolder:GetChildren()) do
        if child:IsA("Model") and not isFuseLike(child.Name) then
            local rep = findRepresentativePart(child)
            local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
            table.insert(list, { model = child, part = rep, prompt = prompt })
        end
    end
    return list
end

-- === Teleport ===
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
    return true
end

local function teleportToRandomMachine(noAura)
    local entries = gatherMachineEntries()
    if #entries == 0 then return false end
    local pick = entries[math.random(1,#entries)]
    if pick.part then
        teleportToPart(pick.part)
        if not noAura and pick.prompt then
            if type(fireproximityprompt) == "function" then
                fireproximityprompt(pick.prompt)
            end
        end
        return true
    end
    return false
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChildWhichIsA("BasePart", true)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- === ESP ===
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

local function createHighlightFor(target, color)
    if not target or espMap[target] then return end
    local h = Instance.new("Highlight")
    h.Name = "TZ_HL"
    h.Adornee = target
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.55
    h.Parent = target
    espMap[target] = h
end

local function clearAllHighlights()
    for _,v in pairs(espMap) do v:Destroy() end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            for _, e in ipairs(gatherMachineEntries()) do
                local t = e.model or e.part
                if t and not espMap[t] then createHighlightFor(t, Color3.fromRGB(0,200,0)) end
            end
        end
        if espSpiritsOn then
            local floor = Workspace:FindFirstChild("Floor")
            local cont = floor and floor:FindFirstChild("Spirits")
            if cont then
                for _, s in ipairs(cont:GetChildren()) do
                    if s and not espMap[s] then createHighlightFor(s, Color3.fromRGB(200,0,200)) end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then clearAllHighlights() end
        task.wait(1)
    end
end)

-- === Godmode (only self) ===
local function protectLocalHumanoid(hum)
    if not hum then return end
    hum.Health = hum.MaxHealth
    hum.HealthChanged:Connect(function(new)
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end)
end

if LocalPlayer.Character then
    local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then protectLocalHumanoid(h) end
end
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then protectLocalHumanoid(hum) end
end)

-- === Infinite Stamina (self only) ===
local AddStamina = ReplicatedStorage.Remotes.Gameplay:FindFirstChild("AddStamina")
local staminaFlag = false
task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
            firesignal(AddStamina.OnClientEvent, 999)
        end
        task.wait(0.25)
    end
end)

-- === Auto SkillCheck ===
for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteFunction") and v.Name:lower():find("skill") then
        v.OnClientInvoke = function() return 2 end
    end
end

-- === Auto Farm ===
local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            teleportToRandomMachine()
        end
        task.wait(1)
    end
end)

local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoElevatorFlag then
            teleportToElevator()
        end
        task.wait(1)
    end
end)

-- === GUI ===
local tabESP = Window:CreateTab("ESP")
tabESP:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachinesOn = v if not v then clearAllHighlights() end end })
tabESP:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpiritsOn = v if not v then clearAllHighlights() end end })

local tabTP = Window:CreateTab("Teleport")
tabTP:CreateButton({ Name = "Teleport to Random Machine", Callback = function() teleportToRandomMachine(true) end })
tabTP:CreateButton({ Name = "Teleport to Elevator", Callback = teleportToElevator })

local tabAuto = Window:CreateTab("Auto Farm")
tabAuto:CreateToggle({ Name = "Auto Teleport Machines", CurrentValue = false, Callback = function(v) autoTeleportFlag = v end })
tabAuto:CreateToggle({ Name = "Auto Elevator", CurrentValue = false, Callback = function(v) autoElevatorFlag = v end })

local tabPlayer = Window:CreateTab("Player")
tabPlayer:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end })
tabPlayer:CreateLabel("Godmode: ENABLED (self only)")
tabPlayer:CreateLabel("Auto SkillCheck: ENABLED")

local tabCredits = Window:CreateTab("Credits")
tabCredits:CreateLabel("Created by: Ali_hhjjj")
tabCredits:CreateLabel("Tester/Helper: GoodJOBS3")
tabCredits:CreateLabel("Special Thanks: Olivia & Shelly")

Rayfield:LoadConfiguration()
