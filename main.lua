-- Twilight Zone - ESP + Auto Teleport (aura-only, fusebox ignored)
-- Creator: Ali_hhjjj
-- Thanks to Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving Idea to use Rayfield

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "TZ_AuraFix_v2"
if PlayerGui:FindFirstChild(GUI_NAME) then
    pcall(function() PlayerGui[GUI_NAME]:Destroy() end)
end

-- helper print
local function safePrint(...) pcall(print,"[TZ]",...) end

-- === HELPERS ===
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart","Torso"}
    for _,n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then return f end
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

local function getMachineModels()
    local out = {}
    local container = nil
    if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines") then
        container = Workspace.Floor.Machines
    else
        container = Workspace:FindFirstChild("Machines") or Workspace
    end
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA("Model") and not isFuseLike(child.Name) then
            table.insert(out, child)
        end
    end
    return out
end

-- aura heuristic
local function hasMachineAura(model)
    if not model then return false end
    if model:FindFirstChild("MachineSound") and model.MachineSound:IsA("Sound") then return true end
    if model:FindFirstChildWhichIsA("Sound", true) then return true end
    if model:FindFirstChildWhichIsA("ParticleEmitter", true) then return true end
    local front = model:FindFirstChild("Front") or findRepresentativePart(model)
    if front and front:FindFirstChildWhichIsA("ProximityPrompt", true) then return true end
    if model:FindFirstChild("Aura") or model:FindFirstChild("HasAura") or model:FindFirstChild("Active") then return true end
    return false
end

-- === TELEPORTS ===
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 4
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = part.CFrame + Vector3.new(0,yOffset,0)
    end)
    return true
end

local function teleportToRandomMachine_manual()
    local models = getMachineModels()
    if #models == 0 then return false end
    local pick = models[math.random(1,#models)]
    local front = pick:FindFirstChild("Front") or findRepresentativePart(pick)
    if front then return teleportToPart(front, 4) end
    return false
end

local function teleportToRandomAuraMachine_auto()
    local models = getMachineModels()
    local auraList = {}
    for _,m in ipairs(models) do
        if hasMachineAura(m) then
            local front = m:FindFirstChild("Front") or findRepresentativePart(m)
            if front then table.insert(auraList, {model=m, part=front}) end
        end
    end
    if #auraList == 0 then return false end
    local pick = auraList[math.random(1,#auraList)]
    local ok = teleportToPart(pick.part, 4)
    if ok then
        for i=1,10 do
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            task.wait(0.09)
        end
    end
    return ok
end

local function teleportToElevator()
    local candidates = {}
    if Workspace:FindFirstChild("Floor") then
        for _,child in ipairs(Workspace.Floor:GetChildren()) do
            if tostring(child.Name):lower():find("elevator") then
                table.insert(candidates, child)
            end
        end
    end
    for _,child in ipairs(Workspace:GetChildren()) do
        if tostring(child.Name):lower():find("elevator") then
            table.insert(candidates, child)
        end
    end

    for _,elevator in ipairs(candidates) do
        local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
        if spawn then
            return teleportToPart(spawn, 3)
        end
    end
    return false
end

-- === ESP ===
local espMachinesOn = false
local espSpiritsOn = false
local espMap = {}

local function makeHighlightForModel(model, color3)
    if not model or espMap[model] then return end
    local H = Instance.new("Highlight")
    H.Name = "TZ_HL"
    H.Adornee = model
    H.FillColor = color3
    H.OutlineColor = color3
    H.FillTransparency = 0.55
    H.Parent = model
    espMap[model] = H
end

local function clearHighlights()
    for m,hl in pairs(espMap) do
        pcall(function() hl:Destroy() end)
    end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            for _,m in ipairs(getMachineModels()) do
                if not espMap[m] then
                    makeHighlightForModel(m, Color3.fromRGB(0,200,0))
                end
            end
        end
        if espSpiritsOn then
            local containers = {}
            if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then
                table.insert(containers, Workspace.Floor.Spirits)
            end
            if Workspace:FindFirstChild("Spirits") then
                table.insert(containers, Workspace.Spirits)
            end
            for _,cont in ipairs(containers) do
                for _,s in ipairs(cont:GetChildren()) do
                    if not espMap[s] then
                        makeHighlightForModel(s, Color3.fromRGB(200,0,200))
                    end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then
            clearHighlights()
        end
        task.wait(1)
    end
end)

-- === AUTO TELEPORT LOOP ===
local autoTeleportFlag = false
local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local ok = teleportToRandomAuraMachine_auto()
            if not ok and autoElevatorFlag then
                teleportToElevator()
            end
            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- === GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 380, 0, 400)
frame.Position = UDim2.new(0.05,0,0.12,0)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.Active = true
frame.Draggable = true
local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-12,0,32)
title.Position = UDim2.new(0,6,0,6)
title.BackgroundTransparency = 1
title.Text = "Twilight Zone (Aura AutoTP, Fuse Ignored)"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(230,230,230)

local y = 50
local function addToggle(label, initial, cb)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-12,0,34)
    btn.Position = UDim2.new(0,6,0,y)
    btn.BackgroundColor3 = initial and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = label..": "..(initial and "ON" or "OFF")
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,6)
    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
        btn.Text = label..": "..(state and "ON" or "OFF")
        pcall(cb,state)
    end)
    y = y + 40
end

local function addButton(label, cb)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-12,0,34)
    btn.Position = UDim2.new(0,6,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = label
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
    y = y + 40
end

-- toggles & buttons
addToggle("ESP Machines", false, function(v) espMachinesOn=v if not v then clearHighlights() end end)
addToggle("ESP Spirits", false, function(v) espSpiritsOn=v if not v then clearHighlights() end end)
addButton("Teleport Random Machine", teleportToRandomMachine_manual)
addButton("Teleport Elevator", teleportToElevator)
addToggle("Auto Teleport (Aura only)", false, function(v) autoTeleportFlag=v end)
addToggle("Auto Elevator (if no Aura)", false, function(v) autoElevatorFlag=v end)

-- credits
local credit = Instance.new("TextLabel", frame)
credit.Size = UDim2.new(1,-12,0,60)
credit.Position = UDim2.new(0,6,1,-66)
credit.BackgroundTransparency = 1
credit.Font = Enum.Font.SourceSans
credit.TextSize = 12
credit.TextColor3 = Color3.fromRGB(200,200,200)
credit.Text = "Creator: Ali_hhjjj\nThanks: Olivia (Riddance) & Shelly (Riddance manager) for Rayfield idea"

safePrint("TZ script (v2) loaded.")
