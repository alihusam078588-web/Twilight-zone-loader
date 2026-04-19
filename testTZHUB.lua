--// WindUI Setup
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local MachineRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlushieMachineCompleted")

--// Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Safe access to the Machine Controller
local MachineMinigame = require(player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Interface"):WaitForChild("UIController"):WaitForChild("GameUI"):WaitForChild("MachineMinigame"))
local MachineController = MachineMinigame.MachineController

--// Window Setup
local Window = WindUI:CreateWindow({
    Title = "TZ HUB || Dolly's Factory",
    Folder = "TZHub",
    Icon = "solar:compass-big-bold",
    Theme = "Crimson",
    NewElements = true,
    HideSearchBar = false,
})

Window:EditOpenButton({
    Title = "TZ HUB || Dolly's Factory",
    Icon = "solar:compass-big-bold",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("DC143C"), Color3.fromHex("8B0000")),
    Enabled = true,
    Draggable = true,
})

local MainTab = Window:Tab({ Title = "Main", Icon = "solar:home-bold" })

-- =========================
-- SETTINGS & FOLDERS
-- =========================
local Interacts      = workspace:WaitForChild("Interacts", 10)
local StuffingFolder = workspace:WaitForChild("Pickup"):WaitForChild("Stuffing", 10)
local TimerUI        = player:WaitForChild("PlayerGui"):WaitForChild("GameUI"):WaitForChild("HUD"):WaitForChild("Timer", 10)
local SafeZone       = workspace:WaitForChild("Persistent"):WaitForChild("Zones"):WaitForChild("TrainSafeZone", 10)

local offset  = -5
local Enabled = false
local rejectEscapeEnabled = false
local rejectDistance      = 25
local rejectWaitTime      = 5
local avoidingReject = false
local hideWaitTime = 0.2 
local HRP

-- =========================
-- HELPERS
-- =========================
local function getHRP()
    local characters = workspace:FindFirstChild("Characters")
    if not characters then return nil end
    local char = characters:FindFirstChild(tostring(player.UserId))
    return char and char:FindFirstChild("HumanoidRootPart")
end

task.spawn(function()
    while true do
        local foundHRP = getHRP()
        if foundHRP then HRP = foundHRP end
        task.wait(1)
    end
end)

local function Freeze(state)
    local char = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(tostring(player.UserId))
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = state and 0 or 16
        hum.JumpPower = state and 0 or 50
    end
end

local function TPUnder(part)
    if HRP and part then
        HRP.CFrame = part.CFrame * CFrame.new(0, offset, 0)
    end
end

local function FirePrompts(obj)
    if not obj then return end
    for _, v in pairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(v, 0) end)
        end
    end
end

local function GetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") or obj:IsA("MeshPart") then return obj end
    return obj:FindFirstChildWhichIsA("MeshPart", true) or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function WaitIfAvoiding()
    while avoidingReject do task.wait(0.1) end
end

-- =========================
-- CORE LOGIC
-- =========================
local function StartRejectWatcher()
    task.spawn(function()
        while Enabled do
            task.wait(0.3)
            if not rejectEscapeEnabled or avoidingReject or not HRP then continue end

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name:lower():find("reject") then
                    local enemyHrp = v:FindFirstChild("HumanoidRootPart")
                    if enemyHrp and (HRP.Position - enemyHrp.Position).Magnitude <= rejectDistance then
                        avoidingReject = true
                        local returnCFrame = HRP.CFrame
                        HRP.CFrame = SafeZone:GetPivot() * CFrame.new(0, 3, 0)
                        task.wait(rejectWaitTime)
                        if Enabled and HRP then HRP.CFrame = returnCFrame end
                        avoidingReject = false
                        break
                    end
                end
            end
        end
    end)
end

local function GetAllMachines()
    local golden = {}
    local normal = {}
    for _, machine in pairs(CollectionService:GetTagged("PlushieMachine")) do
        local progress = machine:GetAttribute("Progress") or 0
        if progress < 1 then
            if machine:HasTag("ToughMachine") then
                table.insert(golden, machine)
            else
                table.insert(normal, machine)
            end
        end
    end
    -- Golden machines go first
    for _, m in ipairs(normal) do table.insert(golden, m) end
    return golden
end

local function HandleMachine(machine)
    if not HRP or not machine then return end
    local isGolden = machine:HasTag("ToughMachine")
    
    local function getProgress() return machine:GetAttribute("Progress") or 0 end
    if getProgress() >= 1 then return end

    -- Use specific Golden Pivot logic if it's a ToughMachine
    local targetPivot = machine:FindFirstChild("Player1Pivot") or machine:FindFirstChild("Player2Pivot")
    local fallback = machine:FindFirstChild("Cylinder.270", true) or machine:FindFirstChildWhichIsA("BasePart", true)
    
    local done = false
    local connection
    
    -- Listen for the completion remote to break the loop instantly
    connection = MachineRemote.OnClientEvent:Connect(function()
        done = true
    end)

    while Enabled and not done and getProgress() < 1 do
        WaitIfAvoiding()
        
        local targetCFrame
        if isGolden and targetPivot then
            targetCFrame = targetPivot.CFrame
        else
            -- Normal machine logic using Controller
            local ok, side = pcall(function() return MachineController:_getClosestLever(player, machine) end)
            if ok and (side == 1 or side == 2) then
                local pivot = machine:FindFirstChild("Player" .. tostring(side) .. "Pivot")
                targetCFrame = pivot and pivot.CFrame or fallback.CFrame * CFrame.new(0, -4, 0)
            else
                targetCFrame = fallback.CFrame * CFrame.new(0, -4, 0)
            end
        end

        HRP.CFrame = targetCFrame
        FirePrompts(machine)
        Freeze(true)
        task.wait(0.01)
        
        if not machine.Parent then break end
    end
    
    if connection then connection:Disconnect() end
    Freeze(false)
end

local function CollectTrainParts()
    local delivery = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("DeliveryPoint")
    local folder = Interacts and Interacts:FindFirstChild("ItemCollection")
    if not delivery or not folder or not HRP then return false end

    WaitIfAvoiding()
    local target = nil
    for _, obj in ipairs(folder:GetChildren()) do
        if obj.Name == "Train Part" and obj:IsA("BasePart") then target = obj break end
    end

    if not target then return false end

    HRP.CFrame = target.CFrame * CFrame.new(0, -4, 0)
    FirePrompts(target)
    task.wait(0.1)
    
    if target:FindFirstChild("AlignOrientation") then
        HRP.CFrame = delivery.CFrame * CFrame.new(0, 3, 0)
        task.wait(0.2)
    end
    return true
end

-- =========================
-- RUNNER
-- =========================
local function run()
    StartRejectWatcher()
    
    -- Independent Stuffing Collector Loop
    task.spawn(function()
        while Enabled do
            WaitIfAvoiding()
            for _, v in pairs(StuffingFolder:GetChildren()) do
                if not Enabled then break end
                local part = GetPart(v)
                if part then
                    repeat
                        WaitIfAvoiding()
                        TPUnder(part)
                        FirePrompts(v)
                        task.wait(0.01)
                    until not v.Parent or not Enabled
                end
            end
            task.wait(1)
        end
    end)

    -- Main Farm Loop
    while Enabled do
        WaitIfAvoiding()
        
        -- Priority 1: Train Parts
        local foundPart = CollectTrainParts()
        
        -- Priority 2: Machines (Golden first)
        if not foundPart then
            local machines = GetAllMachines()
            if #machines > 0 then
                HandleMachine(machines[1]) -- Handle one at a time to check for parts/rejects in between
            else
                -- Idle in safe zone if nothing to do
                if SafeZone then HRP.CFrame = SafeZone.CFrame * CFrame.new(0, 3, 0) end
            end
        end
        task.wait(0.1)
    end
end

-- =========================
-- UI COMPONENTS
-- =========================
local thread
MainTab:Toggle({
    Title = "Auto Farm",
    Desc = "Test 8 from fede the crab",
    Flag = "Autofarm_toggle",
    Callback = function(state)
        Enabled = state
        if state then
            if not thread then
                thread = task.spawn(function()
                    run()
                    thread = nil
                end)
            end
        else
            Freeze(false)
        end
    end
})

MainTab:Toggle({
    Title = "Reject Escape",
    Flag = "rejectEscape_toggle",
    Callback = function(state) rejectEscapeEnabled = state end
})

MainTab:Slider({
    Title = "Detection Distance",
    Step = 1,
    Value = {Min = 5, Max = 100, Default = 25},
    Callback = function(val) rejectDistance = val end
})
