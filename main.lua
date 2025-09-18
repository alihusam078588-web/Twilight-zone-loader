-- Twilight Zone Script (Rayfield Edition)
-- Features: ESP Machines/Spirits, Teleports, Auto Teleport, Auto Elevator,
-- Auto SkillCheck, Godmode (self only), Infinite Stamina (self only)
-- Created by Ali_hhjjj | Tester: GoodJOBS3

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // Rayfield Loader
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Script",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TZ_Config",
        FileName = "TZ_AIO"
    }
})

-- // Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local CreditsTab = Window:CreateTab("Credits", 4483362458)

-- // Utils
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","HumanoidRootPart","PrimaryPart"}
    for _,n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then return f end
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse")
end

-- // GODMODE (Self Only)
task.spawn(function()
    while task.wait(0.5) do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v and v.Name == "HitPlayer" and v:IsA("BasePart") then
                if v:IsDescendantOf(Workspace.Floor) then
                    v:Destroy()
                end
            end
        end
    end
end)

-- // Infinite Stamina (Self Only)
local staminaFlag = false
local AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")

task.spawn(function()
    while task.wait(0.25) do
        if staminaFlag then
            pcall(function()
                firesignal(AddStamina.OnClientEvent, 45)
            end)
            pcall(function()
                AddStamina:FireServer(45)
            end)
            local stats = LocalPlayer:FindFirstChild("Data")
            if stats and stats:FindFirstChild("Stamina") then
                stats.Stamina.Value = 150
            end
        end
    end
end)

-- // ESP
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
    while task.wait(1) do
        if espMachinesOn then
            local folder = Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    if m:IsA("Model") and not isFuseLike(m.Name) then
                        createHighlightFor(m, Color3.fromRGB(0,200,0))
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
                    createHighlightFor(s, Color3.fromRGB(200,0,200))
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then
            clearAllHighlights()
        end
    end
end)

-- // Teleports
local function teleportToPart(part)
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
    return true
end

local function teleportToRandomMachine()
    local folder = Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")
    if not folder then return end
    local machines = folder:GetChildren()
    if #machines == 0 then return end
    local m = machines[math.random(1,#machines)]
    local rep = findRepresentativePart(m)
    if rep then teleportToPart(rep) end
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or findRepresentativePart(elevator)
    if spawn then teleportToPart(spawn) end
end

-- // Auto Teleport + Auto Elevator
local autoTeleportFlag, autoElevatorFlag = false, false

task.spawn(function()
    while task.wait(3) do
        if autoTeleportFlag then teleportToRandomMachine() end
    end
end)

task.spawn(function()
    while task.wait(1) do
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
    end
end)

-- // Auto SkillCheck
do
    local function attach(remote)
        if not remote then return end
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...) return 2 end
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            attach(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then
            attach(desc)
        end
    end)
end

-- // GUI Setup
MainTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(v) espMachinesOn = v end
})

MainTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(v) espSpiritsOn = v end
})

TeleportTab:CreateButton({
    Name = "Teleport Random Machine",
    Callback = teleportToRandomMachine
})

TeleportTab:CreateButton({
    Name = "Teleport Elevator",
    Callback = teleportToElevator
})

TeleportTab:CreateToggle({
    Name = "Auto Teleport Machines",
    CurrentValue = false,
    Callback = function(v) autoTeleportFlag = v end
})

TeleportTab:CreateToggle({
    Name = "Auto Elevator",
    CurrentValue = false,
    Callback = function(v) autoElevatorFlag = v end
})

MiscTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Callback = function(v) staminaFlag = v end
})

CreditsTab:CreateLabel("Created by Ali_hhjjj")
CreditsTab:CreateLabel("Tester/Helper: GoodJOBS3")
