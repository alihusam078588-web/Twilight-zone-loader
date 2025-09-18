-- Twilight Zone Hub
-- Creator: Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special Thanks: Olivia & Shelly (Rayfield idea)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = { Enabled = true, FolderName = "TZ_Hub", FileName = "TZ_Config" }
})

----------------------------------------------------
-- UTIL
local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

local function findRepPart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

----------------------------------------------------
-- TELEPORT
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    local char = LocalPlayer.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
    char.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
end

local function teleportToRandomMachine()
    local folder = Workspace.Floor:FindFirstChild("Machines")
    if not folder then return end
    local machines = {}
    for _,m in ipairs(folder:GetChildren()) do
        if not isFuseLike(m.Name) then
            local part = findRepPart(m)
            if part then table.insert(machines, {model = m, part = part}) end
        end
    end
    if #machines > 0 then
        local pick = machines[math.random(1, #machines)]
        teleportToPart(pick.part)
        local prompt = pick.model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
        end
    end
end

local function teleportToElevator()
    local elev = Workspace:FindFirstChild("Elevator")
    if not elev then return end
    local spawn = elev:FindFirstChild("ElevatorSpawn") or elev:FindFirstChildWhichIsA("BasePart", true)
    if spawn then teleportToPart(spawn, 2) end
end

----------------------------------------------------
-- ESP
local espMachines, espSpirits = false, false
local function createHighlight(obj, color)
    if obj and not obj:FindFirstChild("TZ_HL") then
        local hl = Instance.new("Highlight")
        hl.Name = "TZ_HL"
        hl.Adornee = obj
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.5
        hl.Parent = obj
    end
end

local function clearHighlights()
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Highlight") and v.Name == "TZ_HL" then v:Destroy() end
    end
end

task.spawn(function()
    while true do
        if espMachines then
            local folder = Workspace.Floor:FindFirstChild("Machines")
            if folder then
                for _,m in ipairs(folder:GetChildren()) do
                    if not isFuseLike(m.Name) then
                        createHighlight(m, Color3.fromRGB(0,255,0))
                    end
                end
            end
        end
        if espSpirits then
            local folder = Workspace.Floor:FindFirstChild("Spirits")
            if folder then
                for _,s in ipairs(folder:GetChildren()) do
                    createHighlight(s, Color3.fromRGB(200,0,200))
                end
            end
        end
        if not espMachines and not espSpirits then
            clearHighlights()
        end
        task.wait(1)
    end
end)

----------------------------------------------------
-- GODMODE (only you)
local function protectChar(char)
    for _,v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "HitPlayer" then
            v:Destroy()
        end
    end
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.Name == "HitPlayer" then
            d:Destroy()
        end
    end)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.HealthChanged:Connect(function(val)
            if val < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
    end
end

if LocalPlayer.Character then protectChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(protectChar)

----------------------------------------------------
-- INFINITE STAMINA (only you)
local staminaFlag = false
local staminaRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")

task.spawn(function()
    while true do
        if staminaFlag and staminaRemote then
            pcall(function()
                firesignal(staminaRemote.OnClientEvent, 100)
            end)
        end
        task.wait(0.2)
    end
end)

----------------------------------------------------
-- AUTO SKILLCHECK
task.spawn(function()
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteFunction") and tostring(v.Name):lower():find("skill") then
            v.OnClientInvoke = function() return 2 end
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteFunction") and tostring(v.Name):lower():find("skill") then
            v.OnClientInvoke = function() return 2 end
        end
    end)
end)

----------------------------------------------------
-- GUI
local tabESP = Window:CreateTab("ESP")
tabESP:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachines = v end })
tabESP:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpirits = v end })

local tabTP = Window:CreateTab("Teleport")
tabTP:CreateButton({ Name = "Teleport to Random Machine", Callback = teleportToRandomMachine })
tabTP:CreateButton({ Name = "Teleport to Elevator", Callback = teleportToElevator })

local tabPlayer = Window:CreateTab("Player")
tabPlayer:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end })
tabPlayer:CreateLabel("Godmode: ENABLED (only you)")
tabPlayer:CreateLabel("Auto SkillCheck: ENABLED")

local tabCredits = Window:CreateTab("Credits")
tabCredits:CreateLabel("Created by: Ali_hhjjj")
tabCredits:CreateLabel("Tester/Helper: GoodJOBS3")
tabCredits:CreateLabel("Special Thanks: Olivia & Shelly")

Rayfield:LoadConfiguration()
