-- Twilight Zone (Rayfield Edition)
-- Creator: Ali_hhjjj | Tester/Helper: GOODJOBS3
-- Special Thanks: Thanks to Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving Idea to use Rayfield

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone Loader",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    }
})

-- // UTILITIES
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox")
end

local function gatherMachineParts()
    local parts = {}
    local containers = {Workspace, Workspace:FindFirstChild("Machines"), Workspace:FindFirstChild("Floor")}
    for _, folder in ipairs(containers) do
        if folder and folder.GetChildren then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    if not isFuseLike(child.Name) then
                        local rep = findRepresentativePart(child)
                        if rep then table.insert(parts, rep) end
                    end
                elseif child:IsA("BasePart") and not isFuseLike(child.Name) then
                    table.insert(parts, child)
                end
            end
        end
    end
    return parts
end

local function teleportToPart(part, yOffset)
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    hrp.CFrame = part.CFrame + Vector3.new(0, yOffset or 5, 0)
    return true
end

local function teleportToRandomMachine()
    local parts = gatherMachineParts()
    if #parts == 0 then return false end
    return teleportToPart(parts[math.random(1,#parts)])
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChildWhichIsA("BasePart")
    return spawn and teleportToPart(spawn, 2)
end

-- // ESP
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}
local function clearAllHighlights()
    for _, hl in pairs(espMap) do pcall(function() hl:Destroy() end) end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            for _, p in ipairs(gatherMachineParts()) do
                if p and not espMap[p] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "TZ_HL"
                    hl.Adornee = p:IsA("BasePart") and p or p.Parent
                    hl.FillColor = Color3.fromRGB(0, 200, 0)
                    hl.OutlineColor = Color3.fromRGB(0, 200, 0)
                    hl.Parent = p
                    espMap[p] = hl
                end
            end
        end
        if espSpiritsOn and Workspace:FindFirstChild("Spirits") then
            for _, s in ipairs(Workspace.Spirits:GetChildren()) do
                if s and not espMap[s] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "TZ_HL"
                    hl.Adornee = s
                    hl.FillColor = Color3.fromRGB(200, 0, 200)
                    hl.OutlineColor = Color3.fromRGB(200, 0, 200)
                    hl.Parent = s
                    espMap[s] = hl
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then
            clearAllHighlights()
        end
        task.wait(1)
    end
end)

-- // ALWAYS-ON GODMODE
task.spawn(function()
    while true do
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name == "HitPlayer" then v:Destroy() end
        end
        task.wait(0.5)
    end
end)

-- // AUTO SKILLCHECK
for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteFunction") and v.Name:lower():find("skill") then
        v.OnClientInvoke = function() return 2 end
    end
end

-- // AUTO FEATURES
local autoTeleportFlag, autoElevatorFlag = false, false

task.spawn(function()
    while true do
        if autoTeleportFlag then teleportToRandomMachine() end
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        if autoElevatorFlag then teleportToElevator() end
        task.wait(2)
    end
end)

-- // TABS
local EspTab = Window:CreateTab("ESP", 4483362458)
EspTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(Value) espMachinesOn = Value end
})
EspTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(Value) espSpiritsOn = Value end
})

local TeleportTab = Window:CreateTab("Teleport", 4483362458)
TeleportTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = teleportToRandomMachine
})
TeleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = teleportToElevator
})

local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
AutoFarmTab:CreateToggle({
    Name = "Auto Teleport to Machine",
    CurrentValue = false,
    Callback = function(Value) autoTeleportFlag = Value end
})
AutoFarmTab:CreateToggle({
    Name = "Auto Teleport to Elevator",
    CurrentValue = false,
    Callback = function(Value) autoElevatorFlag = Value end
})

local PlayerTab = Window:CreateTab("Player", 4483362458)
PlayerTab:CreateLabel("Godmode: ENABLED")
PlayerTab:CreateLabel("Auto Skillcheck: ENABLED")

local CreditsTab = Window:CreateTab("Credits", 4483362458)
CreditsTab:CreateLabel("Creator: Ali_hhjjj")
CreditsTab:CreateLabel("Tester/Helper: GOODJOBS3")
CreditsTab:CreateLabel("Special Thanks: Olivia (creator of Riddance Hub) & Shelly (Riddance manager)")
