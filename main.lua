-- Twilight Zone Hub (Delta iOS Safe Edition)
-- Creator: Ali_hhjjj | Helper: GoodJOBS3

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub (Delta Edition)",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "Delta iOS Safe",
    ConfigurationSaving = { Enabled = true, FolderName = "TZ_Hub", FileName = "TZ_Config" }
})

-- ========= UTIL =========
local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

local function findPart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function gatherMachines()
    local list = {}
    local floor = Workspace:FindFirstChild("Floor")
    local machinesFolder = (floor and floor:FindFirstChild("Machines")) or Workspace:FindFirstChild("Machines")
    if not machinesFolder then return list end
    for _, child in ipairs(machinesFolder:GetChildren()) do
        if child:IsA("Model") and not isFuseLike(child.Name) then
            table.insert(list, {
                model = child,
                part = findPart(child),
                prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
            })
        end
    end
    return list
end

local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and part then
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
    end
end

-- ========= ESP =========
local espEnabledMachines, espEnabledSpirits = false, false
local espMap = {}

local function createHighlight(obj, color)
    if not obj or espMap[obj] then return end
    local h = Instance.new("Highlight")
    h.Name = "TZ_HL"
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.55
    h.Parent = game:GetService("CoreGui")
    espMap[obj] = h
end

local function clearHighlights()
    for _, v in pairs(espMap) do v:Destroy() end
    espMap = {}
end

task.spawn(function()
    while true do
        if espEnabledMachines then
            for _, e in ipairs(gatherMachines()) do
                if e.model and not espMap[e.model] then
                    createHighlight(e.model, Color3.fromRGB(0,255,0))
                end
            end
        end
        if espEnabledSpirits then
            local floor = Workspace:FindFirstChild("Floor")
            local spirits = (floor and floor:FindFirstChild("Spirits")) or Workspace:FindFirstChild("Spirits")
            if spirits then
                for _, s in ipairs(spirits:GetChildren()) do
                    if not espMap[s] then
                        createHighlight(s, Color3.fromRGB(200,0,200))
                    end
                end
            end
        end
        if not espEnabledMachines and not espEnabledSpirits then
            clearHighlights()
        end
        task.wait(1)
    end
end)

-- ========= GODMODE (local only) =========
local function destroyHitPlayer(char)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name == "HitPlayer" then
            p:Destroy()
        end
    end
end

local function protectCharacter(char)
    destroyHitPlayer(char)
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.Name == "HitPlayer" then
            d:Destroy()
        end
    end)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.HealthChanged:Connect(function(h)
            if h < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
    end
end

if LocalPlayer.Character then protectCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(protectCharacter)

-- ========= INFINITE STAMINA (Delta-safe) =========
local AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
local staminaEnabled = false

task.spawn(function()
    while true do
        if staminaEnabled and AddStamina then
            AddStamina:FireServer(50) -- keep spamming stamina
        end
        task.wait(0.2)
    end
end)

-- ========= AUTO SKILLCHECK =========
task.spawn(function()
    local function hookRemote(r)
        if r:IsA("RemoteFunction") then
            r.OnClientInvoke = function() return 2 end
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if tostring(v.Name):lower():find("skill") then
            hookRemote(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(d)
        if tostring(d.Name):lower():find("skill") then
            hookRemote(d)
        end
    end)
end)

-- ========= AUTO TELEPORT =========
local autoTeleport = false
task.spawn(function()
    while true do
        if autoTeleport then
            local machines = gatherMachines()
            if #machines > 0 then
                local pick = machines[math.random(1, #machines)]
                if pick.part then
                    teleportToPart(pick.part)
                    if pick.prompt then
                        pcall(function() fireproximityprompt(pick.prompt, 1, true) end)
                    end
                end
            end
        end
        task.wait(1.5)
    end
end)

-- ========= AUTO ELEVATOR =========
local autoElevator = false
task.spawn(function()
    while true do
        if autoElevator then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local msg = elevator:FindFirstChild("Message", true)
                if msg and msg.Enabled then
                    local spawn = elevator:FindFirstChildWhichIsA("BasePart", true)
                    if spawn then teleportToPart(spawn, 2) end
                end
            end
        end
        task.wait(1)
    end
end)

-- ========= GUI =========
local tabESP = Window:CreateTab("ESP")
tabESP:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Callback = function(v) espEnabledMachines = v end })
tabESP:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espEnabledSpirits = v end })

local tabTP = Window:CreateTab("Teleport")
tabTP:CreateToggle({ Name = "Auto Teleport to Machines (Aura)", CurrentValue = false, Callback = function(v) autoTeleport = v end })
tabTP:CreateToggle({ Name = "Auto Elevator", CurrentValue = false, Callback = function(v) autoElevator = v end })

local tabPlayer = Window:CreateTab("Player")
tabPlayer:CreateSlider({ Name = "WalkSpeed", Range = {8,250}, Increment = 1, CurrentValue = 16, Callback = function(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end})
tabPlayer:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaEnabled = v end })
tabPlayer:CreateLabel("Godmode: Enabled (Local Only)")
tabPlayer:CreateLabel("Auto SkillCheck: Enabled")

local tabCredits = Window:CreateTab("Credits")
tabCredits:CreateLabel("Created by: Ali_hhjjj")
tabCredits:CreateLabel("Helper: GoodJOBS3")

Rayfield:LoadConfiguration()
