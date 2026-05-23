--// WindUI Setup
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--// Window
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
    Icon = "solar:compass-big-bold", -- matches your main window icon
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient theme
        Color3.fromHex("DC143C"), -- Crimson start
        Color3.fromHex("8B0000")  -- Darker Crimson end
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})
--// Main Tab
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "solar:home-bold",
})
-- =============================================
-- TZ HUB – Dolly's Factory Auto Farm (Fixed)
-- Author: Ali_hhjjj
-- =============================================

local Players          = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local player           = Players.LocalPlayer

-- ── Character / HRP ──────────────────────────
local function getHRP()
    local char = workspace:WaitForChild("Characters"):WaitForChild(tostring(player.UserId))
    return char:WaitForChild("HumanoidRootPart")
end

local HRP
task.spawn(function()
    while true do
        pcall(function() HRP = getHRP() end)
        task.wait(1)
    end
end)

-- ── Workspace refs ────────────────────────────
local StuffingFolder = workspace:WaitForChild("Pickup"):WaitForChild("Stuffing")
local TimerUI        = player:WaitForChild("PlayerGui")
                           :WaitForChild("GameUI")
                           :WaitForChild("HUD")
                           :WaitForChild("Timer")
local SafeZone = workspace:WaitForChild("Persistent")
                          :WaitForChild("Zones")
                          :WaitForChild("TrainSafeZone")

-- ── Settings ──────────────────────────────────
local offset            = -4
local Enabled           = false
local rejectEscapeEnabled = false
local rejectDistance    = 25
local rejectWaitTime    = 5
local hideWaitTime      = 0.2

-- ── State ─────────────────────────────────────
local avoidingReject = false

-- ── Helpers ───────────────────────────────────
local function Freeze(state)
    local char = workspace:FindFirstChild("Characters")
                 and workspace.Characters:FindFirstChild(tostring(player.UserId))
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = state and 0 or 16
        hum.JumpPower = state and 0 or 50
    end
end

local function FirePrompts(obj)
    for _, v in pairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(v, 0) end)
        end
    end
end

local function GetPart(obj)
    if obj:IsA("BasePart") or obj:IsA("MeshPart") then return obj end
    return obj:FindFirstChildWhichIsA("MeshPart", true)
        or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function WaitIfAvoiding()
    while avoidingReject do task.wait(0.1) end
end

-- ── Reject Escape ─────────────────────────────
local function StartRejectWatcher()
    task.spawn(function()
        while Enabled do
            task.wait(0.3)
            if not rejectEscapeEnabled or avoidingReject or not HRP then continue end

            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name:lower():find("reject") then
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                    if hrp and (HRP.Position - hrp.Position).Magnitude <= rejectDistance then
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

local function BurstTeleportToSafeZone()
    task.spawn(function()
        local part = SafeZone:IsA("BasePart") and SafeZone
                     or SafeZone:FindFirstChildWhichIsA("BasePart")
        if not part or not HRP then return end
        local deadline = tick() + hideWaitTime
        while Enabled and tick() < deadline do
            HRP.CFrame = part.CFrame * CFrame.new(0, 3, 0)
            task.wait(0.001)
        end
    end)
end

-- ── RejectMeistro scan (integrated into watcher) ──
--   Removed the separate ScanRejectMeistro function that had a race condition.
--   StartRejectWatcher already handles all reject models including RejectMeistro.

-- ── Train Part collection ─────────────────────
local function CollectTrainParts()
    local delivery = workspace:FindFirstChild("Map")
                     and workspace.Map:FindFirstChild("DeliveryPoint")
    local folder   = workspace:FindFirstChild("Interacts")
                     and workspace.Interacts:FindFirstChild("ItemCollection")

    if not delivery or not folder or not HRP then return false end

    WaitIfAvoiding()

    local target
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("MeshPart") and obj.Name == "Train Part" then
            target = obj
            break
        end
    end

    if not target then
        HRP.CFrame = SafeZone.CFrame * CFrame.new(0, 3, 0)
        return false
    end

    HRP.CFrame = target.CFrame * CFrame.new(0, offset, 0)

    for _, v in ipairs(target:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(v, 0) end)
        end
    end

    -- Deliver if the part was picked up (it disappears from the folder)
    task.wait(0.05)
    if not target.Parent then
        HRP.CFrame = delivery.CFrame * CFrame.new(0, 3, 0)
        task.wait(0.1)
        FirePrompts(delivery)
    end

    return true
end

-- ── Tesla Coils ───────────────────────────────
local function FindCoilRoot()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end

    -- Search broadly instead of hardcoded path
    for _, obj in pairs(map:GetDescendants()) do
        if obj.Name == "CoilActivators" then return obj end
    end

    -- Fallback: search for individual Coil objects inside TeslaCoil
    local tesla = map:FindFirstChild("TeslaCoil", true)
    return tesla
end

local function DoCoils()
    local coilRoot = FindCoilRoot()
    if not coilRoot then return false end

    local function getActiveCoils()
        local list = {}
        for _, obj in ipairs(coilRoot:GetDescendants()) do
            if obj.Name == "Coil" then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled and prompt.Parent then
                    local part = obj:IsA("BasePart") and obj
                                 or obj:FindFirstChildWhichIsA("MeshPart", true)
                                 or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        table.insert(list, { obj = obj, part = part, prompt = prompt })
                    end
                end
            end
        end
        return list
    end

    while Enabled do
        WaitIfAvoiding()
        local coils = getActiveCoils()

        if #coils == 0 then
            -- No active coils – coil phase might be over
            WaitIfAvoiding()
            if HRP then HRP.CFrame = SafeZone.CFrame * CFrame.new(0, 3, 0) end
            task.wait(0.3)

            -- If the coil container is gone, the coil phase ended
            if not coilRoot or not coilRoot.Parent then return false end
            continue
        end

        for _, coil in ipairs(coils) do
            if not Enabled then break end
            WaitIfAvoiding()
            if not coil.obj.Parent then continue end

            local deadline = tick() + 2
            while Enabled and coil.obj.Parent and coil.prompt.Parent and tick() < deadline do
                WaitIfAvoiding()
                if HRP then HRP.CFrame = coil.part.CFrame * CFrame.new(0, 3, 0) end
                pcall(function()
                    fireproximityprompt(coil.prompt, coil.prompt.HoldDuration or 0)
                end)
                task.wait(0.01)
            end

            task.wait(0.05)
        end

        task.wait(0.05)
    end

    return true
end

-- ── Machine handler ───────────────────────────
local function GetMaxProgress(machine)
    return CollectionService:HasTag(machine, "ToughMachine") and 2 or 1
end

-- BUG FIX: re-fetch machines every loop iteration so completed machines
-- are excluded. Old code built the list once and kept stale entries.
local function GetAllMachines()
    local tough, normal = {}, {}

    for _, machine in pairs(CollectionService:GetTagged("PlushieMachine")) do
        if not machine:IsDescendantOf(workspace) then continue end
        local progress = machine:GetAttribute("Progress") or 0
        local max      = GetMaxProgress(machine)
        if progress < max then
            if CollectionService:HasTag(machine, "ToughMachine") then
                table.insert(tough, machine)
            else
                table.insert(normal, machine)
            end
        end
    end

    -- Sort each group by distance to HRP for efficiency
    local function sortByDist(list)
        if not HRP then return end
        table.sort(list, function(a, b)
            local pa = a:GetPivot().Position
            local pb = b:GetPivot().Position
            return (pa - HRP.Position).Magnitude < (pb - HRP.Position).Magnitude
        end)
    end

    sortByDist(tough)
    sortByDist(normal)

    -- Prioritise normal machines (faster), then tough ones
    local all = {}
    for _, m in ipairs(normal) do table.insert(all, m) end
    for _, m in ipairs(tough)  do table.insert(all, m) end
    return all
end

local function GetMachinePart(machine)
    -- Try well-known part names first
    local candidates = {
        "Golden_Machine", "Cylinder.270", "Base", "Pump",
        "MachineBody", "Body", "Main"
    }
    for _, name in ipairs(candidates) do
        local part = machine:FindFirstChild(name, true)
        if part and (part:IsA("BasePart") or part:IsA("MeshPart")) then
            return part
        end
    end
    -- Fallback: first BasePart
    return machine:FindFirstChildWhichIsA("BasePart", true)
end

local function GetMachineSlotCFrame(machine, part)
    -- Try Player1Pivot / Player2Pivot (proper slot positions)
    for _, slot in ipairs({ "Player1Pivot", "Player2Pivot" }) do
        local pivot = machine:FindFirstChild(slot, true)
        if pivot then
            local ok, cf = pcall(function() return pivot:GetPivot() end)
            if ok then return cf * CFrame.new(0, offset, 0) end
        end
    end
    -- Fallback to part CFrame
    return part.CFrame * CFrame.new(0, offset, 0)
end

local function HandleMachine(machine)
    if not HRP or not machine or not machine:IsDescendantOf(workspace) then return end

    local function getProgress()
        return machine:GetAttribute("Progress") or 0
    end

    local max  = GetMaxProgress(machine)
    if getProgress() >= max then return end

    local part = GetMachinePart(machine)
    if not part then return end

    local targetCFrame = GetMachineSlotCFrame(machine, part)

    while Enabled and machine:IsDescendantOf(workspace) and getProgress() < max do
        WaitIfAvoiding()

        local deadline = tick() + 0.25

        while Enabled and getProgress() < max and tick() < deadline do
            if HRP then HRP.CFrame = targetCFrame end
            FirePrompts(machine)
            if machine.Parent then FirePrompts(machine.Parent) end
            Freeze(true)
            task.wait(0.001)
            if not machine:IsDescendantOf(workspace) then break end
        end

        task.wait(0.001)
    end

    -- Always unfreeze when done with this machine
    Freeze(false)
end

-- ── Timer watcher (teleport to safe zone during round transition) ──
local function StartTimerWatcher()
    task.spawn(function()
        local wasVisible = false
        while Enabled do
            WaitIfAvoiding()
            if TimerUI.Visible then
                if not wasVisible then
                    for i = 1, 3 do
                        if HRP then HRP.CFrame = SafeZone.CFrame * CFrame.new(0, 3, 0) end
                        task.wait(0.05)
                    end
                end
                wasVisible = true
            else
                wasVisible = false
            end
            task.wait(0.1)
        end
    end)
end

-- ── Main loop (single, no duplicate) ─────────
local function run()
    -- BUG FIX: removed the separate ScanRejectMeistro + immediate RejectFound check
    -- (race condition – the scan is async so RejectFound was always false here).
    -- StartRejectWatcher handles all reject models including RejectMeistro.
    StartRejectWatcher()
    StartTimerWatcher()

    while Enabled do
        WaitIfAvoiding()

        -- 1. Collect stuffing
        local stuffItems = StuffingFolder:GetChildren()
        if #stuffItems > 0 then
            local originCFrame = HRP and HRP.CFrame

            for _, v in ipairs(stuffItems) do
                if not Enabled then break end
                WaitIfAvoiding()
                local part = GetPart(v)
                if not part then continue end

                repeat
                    WaitIfAvoiding()
                    if HRP then HRP.CFrame = part.CFrame * CFrame.new(0, offset, 0) end
                    FirePrompts(v)
                    task.wait(0.001)
                until not v.Parent or not Enabled
            end

            if Enabled and HRP and originCFrame then
                HRP.CFrame = originCFrame
            end

            -- Loop back to check stuffing again before doing machines
            task.wait(0.001)
            continue
        end

        -- 2. Train parts
        if CollectTrainParts() then
            task.wait(0.05)
            continue
        end

        -- 3. Tesla coils (blocking while active)
        local didCoil = DoCoils()

        -- 4. Machines (only when no coil phase)
        if not didCoil then
            local machines = GetAllMachines()
            if #machines > 0 then
                for _, machine in ipairs(machines) do
                    if not Enabled then break end
                    WaitIfAvoiding()
                    HandleMachine(machine)
                end
            else
                -- Nothing to do – wait at safe zone
                if HRP then HRP.CFrame = SafeZone.CFrame * CFrame.new(0, 3, 0) end
            end
        end

        task.wait(0.001)
    end

    -- Cleanup
    Freeze(false)
    avoidingReject = false
end

-- ── UI bindings ───────────────────────────────
local thread

MainTab:Toggle({
    Title    = "Auto Farm",
    Desc     = "hi",
    Flag     = "Autofarm_toggle",
    Icon     = "",
    Value    = false,
    Callback = function(state)
        Enabled = state
        if not Enabled then
            avoidingReject = false
            Freeze(false) -- safety unfreeze on disable
        end
        if Enabled and not thread then
            thread = task.spawn(function()
                run()
                thread = nil
            end)
        end
    end
})

MainTab:Toggle({
    Title    = "Reject Escape",
    Flag     = "rejectEscape_toggle",
    Desc     = "Teleports to safe zone when a Reject gets too close",
    Icon     = "shield",
    Value    = false,
    Callback = function(state)
        rejectEscapeEnabled = state
    end
})

MainTab:Slider({
    Title    = "Reject Detection Distance",
    Desc     = "Studs before Reject Escape triggers",
    Icon     = "",
    Step     = 1,
    Value    = { Min = 5, Max = 100, Default = 25 },
    Callback = function(val)
        rejectDistance = val
    end
})

MainTab:Slider({
    Title    = "Safe Zone Wait Time",
    Flag     = "safezonewait_slider",
    Desc     = "Seconds to stay in safe zone before returning",
    Icon     = "",
    Step     = 1,
    Value    = { Min = 1, Max = 100, Default = 5 },
    Callback = function(val)
        rejectWaitTime = val
    end
})

MainTab:Slider({
    Title    = "Reject Hide Delay",
    Desc     = "Time spent hiding when RejectMeistro appears",
    Step     = 0.1,
    Value    = { Min = 0.1, Max = 5, Default = 0.2 },
    Callback = function(value)
        hideWaitTime = value
    end
})
