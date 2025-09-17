-- Twilight Zone GUI (Rayfield Version)
-- Creator: Ali_hhjjj | Tester/Helper: GOODJOBS3
-- Special Thanks: Olivia (Riddance creator) & Shelly (Riddance manager) for giving the idea to use Rayfield

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone Loader",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "TZ_Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = false
    },
    KeySystem = false
})

-- ===== VARIABLES =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local staminaFlag = false
local autoTeleportFlag = false
local autoElevatorFlag = false
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

-- ===== UTIL =====
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","Head","HumanoidRootPart","PrimaryPart"}
    for _,n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then return f end
    end
    if model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function gatherMachineParts()
    local parts = {}
    local candidates = {
        Workspace:FindFirstChild("Machines"),
        Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines"),
        Workspace
    }
    for _, folder in ipairs(candidates) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local rep = findRepresentativePart(child)
                    if rep then table.insert(parts, rep) end
                elseif child:IsA("BasePart") then
                    table.insert(parts, child)
                end
            end
        end
    end
    return parts
end

local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0) end
end

local function teleportToRandomMachine()
    local parts = gatherMachineParts()
    if #parts > 0 then teleportToPart(parts[math.random(1,#parts)]) end
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if elevator then
        local spawn = elevator:FindFirstChild("ElevatorSpawn") or findRepresentativePart(elevator)
        if spawn then teleportToPart(spawn, 2) end
    end
end

-- ===== ESP =====
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
            for _, p in ipairs(gatherMachineParts()) do
                if p and not espMap[p] then
                    createHighlightFor(p, Color3.fromRGB(0,200,0))
                end
            end
        end
        if espSpiritsOn and Workspace:FindFirstChild("Spirits") then
            for _, s in ipairs(Workspace.Spirits:GetChildren()) do
                if s and not espMap[s] then
                    createHighlightFor(s, Color3.fromRGB(200,0,200))
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then
            clearAllHighlights()
        end
    end
end)

-- ===== GODMODE (always on) =====
task.spawn(function()
    while task.wait(0.5) do
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v and v.Name == "HitPlayer" then v:Destroy() end
        end
    end
end)

-- ===== AUTO SKILLCHECK (always on) =====
do
    local function tryAttach(remote)
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function() return 2 end
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteFunction") and tostring(v.Name):lower():find("skill") then
            tryAttach(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if desc:IsA("RemoteFunction") and tostring(desc.Name):lower():find("skill") then
            tryAttach(desc)
        end
    end)
end

-- ===== INFINITE STAMINA =====
local AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
task.spawn(function()
    while task.wait(0.2) do
        if staminaFlag then
            pcall(function() firesignal(AddStamina.OnClientEvent, 45) end)
        end
    end
end)

-- ===== AUTO TELEPORT =====
task.spawn(function()
    while task.wait(3) do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then
                local target = parts[math.random(1,#parts)]
                teleportToPart(target)
                -- Machine Aura (spam E) while auto teleport is ON
                task.spawn(function()
                    for _,v in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                        if v:IsA("TextButton") and v.Text == "E" then
                            pcall(function() firesignal(v.MouseButton1Click) end)
                        end
                    end
                end)
            end
        end
    end
end)

-- ===== AUTO ELEVATOR =====
task.spawn(function()
    while task.wait(1) do
        if autoElevatorFlag then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg and msg.Enabled then
                    teleportToElevator()
                end
            end
        end
    end
end)

-- ===== TABS =====
local TabESP = Window:CreateTab("ESP", 4483362458)
TabESP:CreateToggle({Name="ESP Machines",CurrentValue=false,Callback=function(v) espMachinesOn=v; if not v then clearAllHighlights() end end})
TabESP:CreateToggle({Name="ESP Spirits",CurrentValue=false,Callback=function(v) espSpiritsOn=v; if not v then clearAllHighlights() end end})

local TabTP = Window:CreateTab("Teleport", 4483362458)
TabTP:CreateButton({Name="Teleport to Random Machine",Callback=teleportToRandomMachine})
TabTP:CreateButton({Name="Teleport to Elevator",Callback=teleportToElevator})

local TabAuto = Window:CreateTab("Auto Farm", 4483362458)
TabAuto:CreateToggle({Name="Auto Teleport to Machine (with Aura)",CurrentValue=false,Callback=function(v) autoTeleportFlag=v end})
TabAuto:CreateToggle({Name="Auto Teleport to Elevator",CurrentValue=false,Callback=function(v) autoElevatorFlag=v end})

local TabPlayer = Window:CreateTab("Player", 4483362458)
TabPlayer:CreateToggle({Name="Infinite Stamina",CurrentValue=false,Callback=function(v) staminaFlag=v end})
TabPlayer:CreateLabel("Godmode: ENABLED")
TabPlayer:CreateLabel("Auto SkillCheck: ACTIVE")

local TabCredits = Window:CreateTab("Credits", 4483362458)
TabCredits:CreateLabel("Creator: Ali_hhjjj")
TabCredits:CreateLabel("Tester/Helper: GOODJOBS3")
TabCredits:CreateLabel("Special Thanks: Olivia (creator of riddance hub) & Shelly (Riddance manager) for idea to use Rayfield")
