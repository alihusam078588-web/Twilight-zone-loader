-- Twilight Zone Hub
-- Creator: Ali_hhjjj | Tester: GoodJOBS3
-- Special Thanks: Olivia & Shelly

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Load Rayfield
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then
    warn("[TZ] Failed to load Rayfield.")
    return
end

-- Window
local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = { Enabled = true, FolderName = "TZ_Hub", FileName = "TZ_Config" }
})

-- ===== GODMODE (self only) =====
local function cleanCharacter(char)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "HitPlayer" then
            v:Destroy()
        end
    end
end

local function protectPlayer(p)
    if not p then return end
    if p.Character then cleanCharacter(p.Character) end
    p.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        cleanCharacter(char)
        char.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and d.Name == "HitPlayer" then
                d:Destroy()
            end
        end)
    end)
end

protectPlayer(LocalPlayer)

-- ===== Infinite Stamina =====
local AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
local staminaEnabled = false
task.spawn(function()
    while true do
        if staminaEnabled then
            pcall(function()
                firesignal(AddStamina.OnClientEvent, 999)
            end)
        end
        task.wait(0.3)
    end
end)

-- ===== Auto SkillCheck =====
task.spawn(function()
    local function attach(remote)
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote.OnClientInvoke = function() return 2 end
            elseif remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function() end)
            end
        end)
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if tostring(v.Name):lower():find("skill") then
            attach(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(d)
        if tostring(d.Name):lower():find("skill") then
            attach(d)
        end
    end)
end)

-- ===== ESP =====
local espOn = {machines=false, spirits=false}
local espMap = {}
local function createESP(target, color)
    if espMap[target] then return end
    local h = Instance.new("Highlight")
    h.Adornee = target
    h.FillColor = color
    h.FillTransparency = 0.5
    h.OutlineColor = color
    h.Parent = game:GetService("CoreGui")
    espMap[target] = h
end
local function clearESP()
    for _,h in pairs(espMap) do pcall(function() h:Destroy() end) end
    espMap = {}
end
task.spawn(function()
    while true do
        if espOn.machines or espOn.spirits then
            if espOn.machines then
                local floor = Workspace:FindFirstChild("Floor")
                local machines = floor and floor:FindFirstChild("Machines")
                if machines then
                    for _,m in ipairs(machines:GetChildren()) do
                        if not m.Name:lower():find("fuse") then
                            createESP(m, Color3.fromRGB(0,200,0))
                        end
                    end
                end
            end
            if espOn.spirits then
                local floor = Workspace:FindFirstChild("Floor")
                local spirits = floor and floor:FindFirstChild("Spirits")
                if spirits then
                    for _,s in ipairs(spirits:GetChildren()) do
                        createESP(s, Color3.fromRGB(200,0,200))
                    end
                end
            end
        else
            clearESP()
        end
        task.wait(1)
    end
end)

-- ===== Teleport =====
local function teleportToElevator()
    local elev = Workspace:FindFirstChild("Elevator")
    if elev then
        local part = elev:FindFirstChildWhichIsA("BasePart", true)
        if part and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
        end
    end
end

local function teleportToMachine()
    local floor = Workspace:FindFirstChild("Floor")
    local machines = floor and floor:FindFirstChild("Machines")
    if machines then
        for _,m in ipairs(machines:GetChildren()) do
            if not m.Name:lower():find("fuse") then
                local part = m:FindFirstChildWhichIsA("BasePart", true)
                if part and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0,3,0)
                    local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        for i=1,5 do task.spawn(function() fireproximityprompt(prompt) end) end
                    end
                    break
                end
            end
        end
    end
end

-- ===== Auto Farm (Aura Spam) =====
local autoFarm = false
task.spawn(function()
    while true do
        if autoFarm then
            teleportToMachine()
        end
        task.wait(1)
    end
end)

-- ===== GUI Tabs =====
local tabESP = Window:CreateTab("ESP")
tabESP:CreateToggle({Name="ESP Machines",CurrentValue=false,Callback=function(v) espOn.machines=v if not v then clearESP() end end})
tabESP:CreateToggle({Name="ESP Spirits",CurrentValue=false,Callback=function(v) espOn.spirits=v if not v then clearESP() end end})

local tabTP = Window:CreateTab("Teleport")
tabTP:CreateButton({Name="Teleport to Elevator",Callback=teleportToElevator})
tabTP:CreateButton({Name="Teleport to Machine",Callback=teleportToMachine})

local tabAuto = Window:CreateTab("Auto Farm")
tabAuto:CreateToggle({Name="Auto Teleport + Spam Aura",CurrentValue=false,Callback=function(v) autoFarm=v end})

local tabPlayer = Window:CreateTab("Player")
tabPlayer:CreateToggle({Name="Infinite Stamina",CurrentValue=false,Callback=function(v) staminaEnabled=v end})
tabPlayer:CreateLabel("Godmode: ENABLED (self only)")
tabPlayer:CreateLabel("Auto SkillCheck: ENABLED")

local tabCredits = Window:CreateTab("Credits")
tabCredits:CreateLabel("Created by: Ali_hhjjj")
tabCredits:CreateLabel("Tester/Helper: GoodJOBS3")
tabCredits:CreateLabel("Special Thanks: Olivia & Shelly")

Rayfield:LoadConfiguration()
