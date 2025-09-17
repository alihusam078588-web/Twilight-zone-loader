-- Twilight Zone All-in-One (Rayfield Edition)
-- GUI + ESP + Teleport + AutoFarm + Player
-- Created by Ali_hhjjj | Tester/Helper: GoodJOBS3 | Special Thanks: Olivia (Riddance Hub)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Rayfield Loader
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Riddance Hub | Twilight Zone",
    LoadingSubtitle = "Created by Ali_hhjjj",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

-- Tabs
local EspTab = Window:CreateTab("ESP", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local AutoFarmTab = Window:CreateTab("Auto Farm", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)

-- ========= UTIL =========
local function findRepPart(model)
    if model:IsA("BasePart") then return model end
    for _,n in ipairs({"HumanoidRootPart","Head","PrimaryPart","Front"}) do
        local p = model:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function gatherMachines()
    local results = {}
    local folders = {
        Workspace:FindFirstChild("Machines"),
        Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines"),
        Workspace:FindFirstChild("CurrentRoom"),
        Workspace
    }
    for _,f in ipairs(folders) do
        if f then
            for _,c in ipairs(f:GetChildren()) do
                if c:IsA("Model") then
                    local p = findRepPart(c)
                    if p then table.insert(results,p) end
                elseif c:IsA("BasePart") then
                    table.insert(results,c)
                end
            end
        end
    end
    return results
end

local function teleportTo(part)
    if not part then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
    end
end

-- ========= ESP =========
local espMachines, espSpirits = false,false
local espMap = {}

local function makeHL(obj,color)
    if not obj or espMap[obj] then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.5
    hl.Parent = obj
    espMap[obj] = hl
end

local function clearHL()
    for _,hl in pairs(espMap) do hl:Destroy() end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachines then
            for _,m in ipairs(gatherMachines()) do
                if m.Parent and not espMap[m.Parent] then
                    makeHL(m.Parent,Color3.fromRGB(0,255,0))
                end
            end
        end
        if espSpirits and Workspace:FindFirstChild("Spirits") then
            for _,s in ipairs(Workspace.Spirits:GetChildren()) do
                if not espMap[s] then
                    makeHL(s,Color3.fromRGB(200,0,200))
                end
            end
        end
        if not espMachines and not espSpirits then clearHL() end
        task.wait(1)
    end
end)

-- ========= GODMODE + SkillCheck (Always ON) =========
task.spawn(function()
    while true do
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v.Name == "HitPlayer" then v:Destroy() end
        end
        task.wait(0.5)
    end
end)

for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteFunction") and v.Name:lower():find("skill") then
        v.OnClientInvoke = function() return 2 end
    end
end

-- ========= Infinite Stamina =========
local staminaFlag = false
local StaminaRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")

task.spawn(function()
    while true do
        if staminaFlag then
            pcall(function() firesignal(StaminaRemote.OnClientEvent, 50) end)
        end
        task.wait(0.3)
    end
end)

-- ========= AutoFarm =========
local autoTP, autoElev = false,false
local auraEnabled = false

task.spawn(function()
    while true do
        if autoTP then
            local machines = gatherMachines()
            if #machines > 0 then
                local m = machines[math.random(1,#machines)]
                teleportTo(m)
                if auraEnabled then
                    local prompt = m:FindFirstChildWhichIsA("ProximityPrompt",true)
                    if prompt then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end
            else
                -- no machines left, auto teleport to elevator
                local elevator = Workspace:FindFirstChild("Elevator")
                if elevator then teleportTo(findRepPart(elevator)) end
            end
        end
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        if autoElev then
            local machines = gatherMachines()
            if #machines == 0 then
                local elevator = Workspace:FindFirstChild("Elevator")
                if elevator then teleportTo(findRepPart(elevator)) end
            end
        end
        task.wait(3)
    end
end)

-- ========= Noclip =========
local noclip = false
game:GetService("RunService").Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end
end)

-- ========= ESP Tab =========
EspTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(v) espMachines = v end,
})

EspTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(v) espSpirits = v end,
})

-- ========= Teleport Tab =========
TeleportTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = function()
        local machines = gatherMachines()
        if #machines>0 then teleportTo(machines[math.random(1,#machines)]) end
    end,
})

TeleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        local elevator = Workspace:FindFirstChild("Elevator")
        if elevator then teleportTo(findRepPart(elevator)) end
    end,
})

-- ========= Auto Farm Tab =========
AutoFarmTab:CreateToggle({
    Name = "Auto Teleport to Machines (with Aura)",
    CurrentValue = false,
    Callback = function(v) autoTP = v; auraEnabled = v end,
})

AutoFarmTab:CreateToggle({
    Name = "Auto Teleport to Elevator (when machines done)",
    CurrentValue = false,
    Callback = function(v) autoElev = v end,
})

-- ========= Player Tab =========
PlayerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Callback = function(v) staminaFlag = v end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) noclip = v end,
})

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16,100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(v)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end,
})

PlayerTab:CreateLabel("Godmode: Always ON")
PlayerTab:CreateLabel("Auto SkillCheck: Always ON")
PlayerTab:CreateLabel("Tester/Helper: GoodJOBS3")
PlayerTab:CreateLabel("Created by Ali_hhjjj")
PlayerTab:CreateLabel("Special Thanks: Thanks Olivia (creater of Riddance Hub) and Shelly (riddance manager) for giving idea to use Rayfield")
