-- Twilight Zone Hub (Rayfield GUI)
-- Creator: Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special Thanks: Olivia (Riddance Hub Creator) & Shelly (Riddance Manager)

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Rayfield Loader
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Window
local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TZ_Hub",
        FileName = "TZ_Config"
    }
})

-- ===== UTILITIES =====
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","HumanoidRootPart","PrimaryPart"}
    for _,n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then return f end
    end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox")
end

local function gatherMachines()
    local parts = {}
    local folder = Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if not isFuseLike(child.Name) then
                local rep = findRepresentativePart(child)
                local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
                if rep then table.insert(parts, {part = rep, prompt = prompt}) end
            end
        end
    end
    return parts
end

local function teleportTo(part)
    if not part then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
    end
end

local function teleportToRandomMachine()
    local machines = gatherMachines()
    if #machines > 0 then
        local pick = machines[math.random(1,#machines)]
        teleportTo(pick.part)
        if pick.prompt and typeof(fireproximityprompt) == "function" then
            fireproximityprompt(pick.prompt)
        end
    end
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if elevator then
        local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("TeleportExit") or findRepresentativePart(elevator)
        if spawn then teleportTo(spawn) end
    end
end

-- ===== ESP =====
local espMachines, espSpirits = false, false
local function createHighlight(obj, color)
    if not obj:FindFirstChild("TZ_HL") then
        local hl = Instance.new("Highlight")
        hl.Name = "TZ_HL"
        hl.Adornee = obj
        hl.FillColor = color
        hl.FillTransparency = 0.5
        hl.Parent = obj
    end
end

task.spawn(function()
    while true do
        if espMachines then
            for _, entry in ipairs(gatherMachines()) do
                createHighlight(entry.part.Parent, Color3.fromRGB(0,255,0))
            end
        end
        if espSpirits and Workspace.Floor:FindFirstChild("Spirits") then
            for _, s in ipairs(Workspace.Floor.Spirits:GetChildren()) do
                createHighlight(s, Color3.fromRGB(200,0,200))
            end
        end
        task.wait(1)
    end
end)

-- ===== GODMODE (local only) =====
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.Name == "HitPlayer" then
                    v:Destroy()
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
        task.wait(1)
    end
end)

-- ===== Auto SkillCheck =====
for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteFunction") and v.Name:lower():find("skill") then
        v.OnClientInvoke = function() return 2 end
    end
end

-- ===== Infinite Stamina =====
local staminaFlag = false
local AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
task.spawn(function()
    while true do
        if staminaFlag then
            pcall(function() firesignal(AddStamina.OnClientEvent, 45) end)
        end
        task.wait(0.25)
    end
end)

-- ===== Auto Teleport Machines =====
local autoTP = false
task.spawn(function()
    while true do
        if autoTP then teleportToRandomMachine() end
        task.wait(2.5)
    end
end)

-- ===== Auto Elevator =====
local autoElevator = false
task.spawn(function()
    while true do
        if autoElevator then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg and msg.Enabled then
                    teleportToElevator()
                end
            end
        end
        task.wait(1)
    end
end)

-- ===== GUI =====
-- ESP Tab
local ESPTab = Window:CreateTab("ESP")
ESPTab:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachines = v end })
ESPTab:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpirits = v end })

-- Teleport Tab
local TP = Window:CreateTab("Teleport")
TP:CreateButton({ Name = "Teleport Random Machine", Callback = teleportToRandomMachine })
TP:CreateButton({ Name = "Teleport Elevator", Callback = teleportToElevator })

-- Auto Farm Tab
local Auto = Window:CreateTab("Auto Farm")
Auto:CreateToggle({ Name = "Auto Teleport to Machines (with aura)", CurrentValue = false, Callback = function(v) autoTP = v end })
Auto:CreateToggle({ Name = "Auto Elevator", CurrentValue = false, Callback = function(v) autoElevator = v end })

-- Player Tab
local PlayerTab = Window:CreateTab("Player")
PlayerTab:CreateSlider({
    Name = "Custom WalkSpeed",
    Range = {16,100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
})
PlayerTab:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end })
PlayerTab:CreateLabel("Godmode: ENABLED (local only)")
PlayerTab:CreateLabel("Auto SkillCheck: ENABLED")

-- Credits
local Credits = Window:CreateTab("Credits")
Credits:CreateLabel("Created by: Ali_hhjjj")
Credits:CreateLabel("Tester/Helper: GoodJOBS3")
Credits:CreateLabel("Special Thanks: Olivia & Shelly")

Rayfield:LoadConfiguration()
