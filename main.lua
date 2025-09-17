-- Twilight Zone GUI (Rayfield Version)
-- Creator: Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special Thanks: Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving idea to use Rayfield

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Twilight Zone",
   LoadingTitle = "Twilight Zone Loader",
   LoadingSubtitle = "by Ali_hhjjj",
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

-- // Utility
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function teleportTo(part)
    if not part then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
    end
end

-- FIXED Machine Finder
local function gatherMachineParts()
    local parts = {}
    local machinesFolder = Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")

    if machinesFolder then
        for _, machine in ipairs(machinesFolder:GetChildren()) do
            if machine:IsA("Model") and tonumber(machine.Name) then
                local front = machine:FindFirstChild("Front")
                if front and front:IsA("BasePart") then
                    table.insert(parts, front)
                end
            end
        end
    end

    return parts
end

local function teleportToRandomMachine()
    local machines = gatherMachineParts()
    if #machines > 0 then
        teleportTo(machines[math.random(1, #machines)])
    end
end

local function teleportToElevator()
    local elev = Workspace:FindFirstChild("Elevator")
    if elev then
        local spawn = elev:FindFirstChild("ElevatorSpawn") or elev:FindFirstChild("Front")
        if spawn then teleportTo(spawn) end
    end
end

-- ESP
local espEnabled = {Machines = false, Spirits = false}
local espMap = {}

local function createHighlight(obj, color)
    if not obj or espMap[obj] then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor, hl.OutlineColor = color, color
    hl.FillTransparency = 0.5
    hl.Parent = obj
    espMap[obj] = hl
end

local function clearESP()
    for _, hl in pairs(espMap) do
        if hl then hl:Destroy() end
    end
    espMap = {}
end

task.spawn(function()
    while task.wait(1) do
        if not espEnabled.Machines and not espEnabled.Spirits then
            clearESP()
        else
            if espEnabled.Machines then
                for _, front in ipairs(gatherMachineParts()) do
                    if front.Parent and not espMap[front.Parent] then
                        createHighlight(front.Parent, Color3.fromRGB(0,255,0))
                    end
                end
            end
            if espEnabled.Spirits then
                local spiritsFolder = Workspace:FindFirstChild("Spirits")
                if spiritsFolder then
                    for _, spirit in ipairs(spiritsFolder:GetChildren()) do
                        if not espMap[spirit] then
                            createHighlight(spirit, Color3.fromRGB(200,0,200))
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Teleport Flags
local autoMachine, autoElevator = false, false

task.spawn(function()
    while task.wait(3) do
        if autoMachine then teleportToRandomMachine() end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if autoElevator then teleportToElevator() end
    end
end)

-- // Tabs
local EspTab = Window:CreateTab("ESP")
EspTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(val) espEnabled.Machines = val if not val then clearESP() end end
})
EspTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(val) espEnabled.Spirits = val if not val then clearESP() end end
})

local TeleTab = Window:CreateTab("Teleport")
TeleTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = teleportToRandomMachine
})
TeleTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = teleportToElevator
})

local AutoTab = Window:CreateTab("Auto Farm")
AutoTab:CreateToggle({
    Name = "Auto Teleport to Machines",
    CurrentValue = false,
    Callback = function(val) autoMachine = val end
})
AutoTab:CreateToggle({
    Name = "Auto Teleport to Elevator",
    CurrentValue = false,
    Callback = function(val) autoElevator = val end
})

local PlayerTab = Window:CreateTab("Player")
PlayerTab:CreateLabel("Godmode: Always On")
PlayerTab:CreateLabel("Auto SkillCheck: Always On")
PlayerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Callback = function(val) -- add stamina code here if needed end
})

local CreditsTab = Window:CreateTab("Credits")
CreditsTab:CreateLabel("Created by: Ali_hhjjj")
CreditsTab:CreateLabel("Tester/Helper: GoodJOBS3")
CreditsTab:CreateLabel("Special Thanks: Olivia (Riddance Hub) & Shelly (Manager) - Idea to use Rayfield")
