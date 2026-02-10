-- Safe fallbacks for environment-specific helpers
if type(fireproximityprompt) ~= "function" then
    -- provide a best-effort fallback that uses ProximityPrompt API if present
    function fireproximityprompt(prompt, ...)
        if not prompt then return end
        if type(prompt.InputHoldBegin) == "function" then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end)
        else
            -- nothing we can do; keep silent to avoid errors
        end
    end
end

-- Guard VirtualInputManager usage
local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
if not ok or not vim then
    -- create a safe stub so code that references it won't error
    vim = nil
end
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
MainTab:Select()

MainTab:Section({
    Title = "Machine Teleport",
    Desc = "some Machines features",
})
--// Teleport Tab
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "lucide:map-pin", -- works in most builds
})

local TeleportSection = TeleportTab:Section({
    Title = "Teleport Options",
    Box = false,
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 20,
    Opened = true,
})

--// Player Tab
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "solar:user-bold",
})
PlayerTab:Select()

PlayerTab:Section({
    Title = "Player Controls",
    Desc = "Movement and physics features",
})



-- Merged Auto Farm Module for Dolly's Factory
-- Paste into a LocalScript after Window, MainTab, TeleportSection, PlayerTab exist

--// WindUI Setup (assumes already loaded earlier in your environment)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

assert(MainTab, "MainTab is nil. Run this after creating your UI.")
assert(PlayerTab, "PlayerTab is nil. Run this after creating your UI.")
assert(TeleportSection, "TeleportSection is nil. Run this after creating your UI.")

-- Single global state
local lastPosition = nil

-- Thread flags and handles
local autoFarm = false
local autoFarmThread = nil

local autoTrainPartsEnabled = false
local autoTrainThread = nil

local autoKodaEnabled = false
local autoKodaThread = nil

local autoHide = false
local autoHideThread = nil

local autoTeleMach = false
local autoTeleMachThread = nil
local noclipConnection = nil

-- Coil control
local coilEnabled = false
local coilThread = nil
local coilGroupDelay = 0.6
local coilPerCoilDelay = 0.2
local coilTimeout = 6
local coilLastFired = {} -- map coil -> last tick

-- FullBright backup
local _FB_backup = nil
local fullBrightEnabled = false

-- Skip samples option and prioritize samples
local skipSamplesForCompleted = true
local prioritizeSamples = false

-- Hide duration default 3
local hideDuration = 3

-- Aggro / visualizer
local aggroRadius = 40
local showAggroVisualizer = false
local aggroSpherePart = nil

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

--// Vars
local Enabled = false
local Multiplier = 1
local MaxVel = 85

--// Velocity Bypass Loop
RunService.RenderStepped:Connect(function()
    if not Enabled then return end

    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local dir = hum.MoveDirection
    if dir.Magnitude > 0 then
        local vel = dir * (Multiplier * 16)
        hrp.AssemblyLinearVelocity = Vector3.new(
            math.clamp(vel.X, -MaxVel, MaxVel),
            hrp.AssemblyLinearVelocity.Y,
            math.clamp(vel.Z, -MaxVel, MaxVel)
        )
    end
end)

--// PlayerTab Elements
PlayerTab:Slider({
    Title = "custom speed",
    Desc = "Max 6",
    Step = 0.1,
    IsTooltip = true,
    Value = {
        Min = 1,
        Max = 6,
        Default = 1
    },
    Callback = function(v)
        Multiplier = v  -- changes speed multiplier
    end
})

PlayerTab:Toggle({
    Title = "Enable walkspeed",
    Desc = "Change your speed",
    Value = false,
    Callback = function(state)
        Enabled = state  -- turns velocity bypass on/off
    end
})
-- Debug helper
local function dbg(msg)
    print("[TZHub] " .. tostring(msg))
end

-- Utility: check if Reject (enemy) is nearby
local function isRejectNearby(radius)
    radius = radius or aggroRadius
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, e in ipairs(enemies:GetChildren()) do
        if e.Name:lower():find("reject") then
            local root = e:FindFirstChildWhichIsA("BasePart") or e:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - hrp.Position).Magnitude <= radius then
                return true
            end
        end
    end
    return false
end

-- Default HasAllRejects check (callable override)
local function defaultHasAllRejectsCheck(plr)
    local attr = plr.GetAttribute and plr.GetAttribute(plr, "HasAllRejects")
    return attr == true
end
local HasAllRejectsCheck = defaultHasAllRejectsCheck

-- Safe fire proximity prompt wrapper
local function safeFirePrompt(prompt)
    if not prompt then return end
    pcall(function() fireproximityprompt(prompt, 0) end)
end

-- Fire all prompts under an object
local function firePrompts(obj)
    if not obj then return end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            safeFirePrompt(v)
        end
    end
end

-- FullBright functions
local function enableFullBright()
    if fullBrightEnabled then return end
    local Lighting = game:GetService("Lighting")
    _FB_backup = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        GlobalShadows = Lighting.GlobalShadows,
    }
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(255,255,255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    Lighting.GlobalShadows = false
    fullBrightEnabled = true
    dbg("FullBright enabled")
end

local function disableFullBright()
    if not fullBrightEnabled then return end
    local Lighting = game:GetService("Lighting")
    if _FB_backup then
        Lighting.Brightness = _FB_backup.Brightness
        Lighting.Ambient = _FB_backup.Ambient
        Lighting.OutdoorAmbient = _FB_backup.OutdoorAmbient
        Lighting.ClockTime = _FB_backup.ClockTime
        Lighting.GlobalShadows = _FB_backup.GlobalShadows
    end
    _FB_backup = nil
    fullBrightEnabled = false
    dbg("FullBright disabled")
end

-- Collect Stuffing
local function collectStuffing(hrp)
    local stuffingFolder = workspace:FindFirstChild("Pickup") and workspace.Pickup:FindFirstChild("Stuffing")
    if not stuffingFolder then return end
    for _, item in ipairs(stuffingFolder:GetChildren()) do
        if not autoFarm then break end
        if item:IsA("Model") or item:IsA("BasePart") then
            local ok, cf, size = pcall(function() return item:GetBoundingBox() end)
            if not ok or not cf then continue end
            while autoFarm and item.Parent == stuffingFolder do
                hrp.CFrame = cf - Vector3.new(0, size.Y/2 + 2, 0)
                firePrompts(item)
                task.wait(0.2)
            end
        end
    end
end

-- Farm Machines (normal proximity approach)
local function farmMachines(hrp)
    local interacts = workspace:FindFirstChild("Interacts")
    if not interacts then return end
    for _, machine in ipairs(interacts:GetChildren()) do
        if not autoFarm then break end
        if machine.Name == "ItemCollection" then continue end
        local interaction = machine:FindFirstChild("Interaction")
        local prompt = interaction and interaction:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            local ok, cf, size = pcall(function() return machine:GetBoundingBox() end)
            if not ok or not cf then continue end
            local target = cf + Vector3.new(0, size.Y/2 + 2, 0)
            while autoFarm and prompt.Parent and machine:FindFirstChild("VFX") and #machine.VFX:GetChildren() > 0 do
                if isRejectNearby() then
                    dbg("Abort machine loop: Reject nearby")
                    break
                end
                hrp.CFrame = target
                safeFirePrompt(prompt)
                task.wait(0.3)
            end
        end
    end
end

-- Replacement: autoTrainPartsOnce (collect one-by-one until GUI shows completion, then teleport to TrainSafeZone)
local function readTrainPartsAmount()
    local ok, amountLabel = pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return nil end
        local gameUI = gui:FindFirstChild("GameUI")
        if not gameUI then return nil end
        local hud = gameUI:FindFirstChild("HUD")
        if not hud then return nil end
        local tracker = hud:FindFirstChild("ObjectiveTracker")
        if not tracker then return nil end
        local objectives = tracker:FindFirstChild("Objectives")
        if not objectives then return nil end
        local train = objectives:FindFirstChild("ItemCollectionTrainParts")
        if not train then return nil end
        return train:FindFirstChild("Amount")
    end)
    if not ok or not amountLabel then return nil end
    return amountLabel
end

local function parseAmountText(text)
    if not text or type(text) ~= "string" then return nil, nil end
    local a, b = string.match(text, "(%d+)%s*/%s*(%d+)")
    if not a or not b then return nil, nil end
    return tonumber(a), tonumber(b)
end

local function getDeliveryPoint()
    -- prefer workspace.Map.DeliveryPoint if present, otherwise search for a part named "Delivery"
    local dp = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("DeliveryPoint")
    if dp then return dp end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.find(obj.Name:lower(), "delivery") then
            return obj
        end
    end
    return nil
end

local function autoTrainPartsOnce(hrp)
    local interacts = workspace:FindFirstChild("Interacts")
    if not interacts then
        dbg("autoTrainParts: Interacts not found")
        return
    end
    local collectionFolder = interacts:FindFirstChild("ItemCollection")
    if not collectionFolder then
        dbg("autoTrainParts: ItemCollection not found")
        return
    end

    local function getAmountLabel()
        return readTrainPartsAmount()
    end

    local function getAmounts()
        local lbl = getAmountLabel()
        if not lbl then return nil, nil end
        return parseAmountText(lbl.Text)
    end

    -- Wait for GUI to appear and be parseable
    local waitStart = tick()
    while autoTrainPartsEnabled do
        local cur, tot = getAmounts()
        if cur and tot then break end
        if (tick() - waitStart) > 8 then
            dbg("autoTrainParts: GUI not found after wait; aborting")
            return
        end
        task.wait(0.4)
    end

    local cur, tot = getAmounts()
    if not cur or not tot then
        dbg("autoTrainParts: unable to read amounts; aborting")
        return
    end

    if cur >= tot then
        dbg("autoTrainParts: already complete " .. tostring(cur) .. "/" .. tostring(tot))
        local safeZone = workspace:FindFirstChild("Persistent")
            and workspace.Persistent:FindFirstChild("Zones")
            and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")
        if safeZone then pcall(function() hrp.CFrame = safeZone.CFrame + Vector3.new(0, 5, 0) end) end
        return
    end

    local function resolveDeliveryPoint()
        local dp = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("DeliveryPoint")
        if dp then return dp end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and string.find(obj.Name:lower(), "delivery") then
                return obj
            end
        end
        return nil
    end

    local deliveryPoint = resolveDeliveryPoint()

    while autoTrainPartsEnabled do
        if isRejectNearby() then
            dbg("autoTrainParts: Reject nearby — pausing")
            task.wait(1)
            local curNow, totNow = getAmounts()
            if curNow and totNow and curNow >= totNow then break end
            continue
        end

        if skipSamplesForCompleted and HasAllRejectsCheck(player) then
            dbg("autoTrainParts: Player completed rejects — aborting")
            autoTrainPartsEnabled = false
            return
        end

        local curNow, totNow = getAmounts()
        if not curNow or not totNow then
            local waited = 0
            while autoTrainPartsEnabled and waited < 6 and not getAmountLabel() do
                task.wait(0.5); waited = waited + 0.5
            end
            curNow, totNow = getAmounts()
            if not curNow or not totNow then
                dbg("autoTrainParts: GUI lost mid-run; aborting")
                autoTrainPartsEnabled = false
                return
            end
        end

        if curNow >= totNow then
            dbg("autoTrainParts: completed during run: " .. tostring(curNow) .. "/" .. tostring(totNow))
            break
        end

        collectionFolder = workspace:FindFirstChild("Interacts") and workspace.Interacts:FindFirstChild("ItemCollection")
        if not collectionFolder then
            dbg("autoTrainParts: ItemCollection disappeared; waiting briefly")
            task.wait(0.6)
            continue
        end

        local items = collectionFolder:GetChildren()
        if #items == 0 then
            dbg("autoTrainParts: no items in ItemCollection; teleporting to DeliveryPoint and waiting")
            deliveryPoint = resolveDeliveryPoint()
            if deliveryPoint then pcall(function() hrp.CFrame = deliveryPoint.CFrame + Vector3.new(0, 5, 0) end) end

            local waited = 0
            local newFound = false
            while autoTrainPartsEnabled and waited < 12 do
                local folderNow = workspace:FindFirstChild("Interacts") and workspace.Interacts:FindFirstChild("ItemCollection")
                if folderNow and #folderNow:GetChildren() > 0 then
                    newFound = true
                    break
                end
                local curCheck, totCheck = getAmounts()
                if curCheck and totCheck and curCheck >= totCheck then
                    newFound = false
                    break
                end
                task.wait(0.6); waited = waited + 0.6
            end

            if not newFound then
                local finalCur, finalTot = getAmounts()
                if finalCur and finalTot and finalCur >= finalTot then
                    dbg("autoTrainParts: completed after waiting: " .. tostring(finalCur) .. "/" .. tostring(finalTot))
                    break
                else
                    task.wait(0.4)
                    continue
                end
            end
        end

        local collectedThisPass = false
        items = collectionFolder:GetChildren()
        for idx = 1, #items do
            if not autoTrainPartsEnabled then break end

            local amtLabelCheck = getAmountLabel()
            if not amtLabelCheck then task.wait(0.05); continue end
            local curCheck, totCheck = parseAmountText(amtLabelCheck.Text)
            if curCheck and totCheck and curCheck >= totCheck then
                dbg("autoTrainParts: completed while iterating items")
                collectedThisPass = true
                break
            end

            local item = collectionFolder:GetChildren()[idx]
            if not item or not item.Parent then task.wait(0.05); continue end

            if isRejectNearby() then
                dbg("autoTrainParts: Reject detected before teleport; breaking item loop")
                break
            end

            local ok, cf, size = pcall(function() return item:GetBoundingBox() end)
            if ok and cf then
                pcall(function() hrp.CFrame = cf - Vector3.new(0, (size.Y / 2) + 2, 0) end)
            else
                if item:IsA("BasePart") and item.CFrame then
                    pcall(function() hrp.CFrame = item.CFrame - Vector3.new(0, item.Size.Y/2 + 2, 0) end)
                else
                    task.wait(0.05)
                    continue
                end
            end

            task.wait(0.12)

            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                safeFirePrompt(prompt)
            else
                firePrompts(item)
            end

            deliveryPoint = resolveDeliveryPoint()
            if deliveryPoint and deliveryPoint:IsA("BasePart") then
                pcall(function() hrp.CFrame = deliveryPoint.CFrame + Vector3.new(0, 5, 0) end)
            end

            local startTick = tick()
            local maxWait = 4.0
            repeat
                task.wait(0.12)
                local amtLabelAfter = getAmountLabel()
                if not amtLabelAfter then break end
                local curAfter, totAfter = parseAmountText(amtLabelAfter.Text)
                if curAfter and totAfter and curAfter > curCheck then
                    dbg("autoTrainParts: collected one -> " .. tostring(curAfter) .. "/" .. tostring(totAfter))
                    collectedThisPass = true
                    break
                end
            until (tick() - startTick) >= maxWait

            task.wait(0.12)

            if collectedThisPass then break end
        end

        local amtLabelFinal = getAmountLabel()
        if amtLabelFinal then
            local curFinal, totFinal = parseAmountText(amtLabelFinal.Text)
            if curFinal and totFinal and curFinal >= totFinal then
                dbg("autoTrainParts: collection complete: " .. tostring(curFinal) .. "/" .. tostring(totFinal))
                local safeZone = workspace:FindFirstChild("Persistent")
                    and workspace.Persistent:FindFirstChild("Zones")
                    and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")
                if safeZone then pcall(function() hrp.CFrame = safeZone.CFrame + Vector3.new(0, 5, 0) end) end
                break
            end
        end

        if not collectedThisPass then
            task.wait(0.6)
        end
    end

    -- ensure flag cleared so autoFarm can continue
    autoTrainPartsEnabled = false
    dbg("autoTrainParts: loop ended")
end

-- Worker wrapper that runs the one-shot collector in its own thread
local function autoTrainPartsWorker(hrp)
    local ok, err = pcall(function() autoTrainPartsOnce(hrp) end)
    if not ok then dbg("autoTrainPartsWorker error: " .. tostring(err)) end
    autoTrainPartsEnabled = false
    autoTrainThread = nil
    dbg("autoTrainPartsWorker: finished")
end

function startAutoTrainParts()
    if autoTrainPartsEnabled then return end
    autoTrainPartsEnabled = true
    if autoTrainThread then return end
    autoTrainThread = task.spawn(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char and char:WaitForChild("HumanoidRootPart")
        if not hrp then
            autoTrainPartsEnabled = false
            autoTrainThread = nil
            return
        end
        autoTrainPartsWorker(hrp)
    end)
    dbg("autoTrainParts: started (worker)")
end



-- Auto Train SafeZone
local function autoTrainSafeZone(hrp)
    local interacts = workspace:FindFirstChild("Interacts")
    if not interacts or not hrp then return end
    for _, machine in ipairs(interacts:GetChildren()) do
        if machine.Name == "ItemCollection" then continue end
        local vfx = machine:FindFirstChild("VFX")
        if vfx and #vfx:GetChildren() > 0 then
            return
        end
    end
    local safeZone = workspace:FindFirstChild("Persistent")
        and workspace.Persistent:FindFirstChild("Zones")
        and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")
    if safeZone then hrp.CFrame = safeZone.CFrame + Vector3.new(0, 5, 0) end
end

-- Coil helpers
local function canFireCoil(coil)
    local last = coilLastFired[coil]
    if not last then return true end
    return (tick() - last) >= coilPerCoilDelay
end

local function markFired(coil)
    coilLastFired[coil] = tick()
end

local function fireCoilSafely(hrp, coil)
    if not coil or not coil:IsA("BasePart") then return end
    local prompt = coil:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return end
    if not canFireCoil(coil) then return end
    hrp.CFrame = coil.CFrame + Vector3.new(0, 5, 0)
    safeFirePrompt(prompt)
    markFired(coil)
end

local function fireAllCoilsControlled(hrp)
    local coilFolder = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Interact")
        and workspace.Map.Interact:FindFirstChild("TeslaCoil")
        and workspace.Map.Interact.TeslaCoil:FindFirstChild("CoilActivators")
    if not coilFolder then return end

    local groups = {"Middle Coils","Platform 2","Platform 3","Platform 4"}
    for _, groupName in ipairs(groups) do
        if not coilEnabled then return end
        local group = coilFolder:FindFirstChild(groupName)
        if group then
            for _, coil in ipairs(group:GetDescendants()) do
                if not coilEnabled then return end
                if coil:IsA("BasePart") then
                    if canFireCoil(coil) then
                        local startTick = tick()
                        -- attempt to fire with timeout to avoid blocking trains
                        fireCoilSafely(hrp, coil)
                        while coilEnabled and coil:FindFirstChildOfClass("ProximityPrompt") and coil.Parent and (tick() - startTick) < coilTimeout do
                            task.wait(coilPerCoilDelay)
                        end
                        task.wait(coilPerCoilDelay)
                    end
                end
            end
            task.wait(coilGroupDelay)
        end
    end

    local safeZone = workspace.Persistent and workspace.Persistent:FindFirstChild("Zones") and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")
    if safeZone then hrp.CFrame = safeZone.CFrame + Vector3.new(0, 5, 0) end
end

-- Auto Koda handlers
local function handleMachinesWithKoda(hrp)
    local interacts = workspace:FindFirstChild("Interacts")
    if not interacts or not hrp then return end
    for _, machine in ipairs(interacts:GetChildren()) do
        if machine.Name == "ItemCollection" then continue end
        local vfx = machine:FindFirstChild("VFX")
        if vfx and #vfx:GetChildren() > 0 then
            local interaction = machine:FindFirstChild("Interaction")
            local prompt = interaction and interaction:FindFirstChild("ProximityPrompt")
            if not prompt then continue end

            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Seated) end) end

            local ok, cf, size = pcall(function() return machine:GetBoundingBox() end)
            if not ok or not cf then continue end
            local targetCFrame = cf - Vector3.new(0, size.Y/2 + 0.1, 0)
            hrp.CFrame = targetCFrame

            while autoKodaEnabled and prompt and prompt.Parent and vfx and #vfx:GetChildren() > 0 do
                if isRejectNearby() then break end
                safeFirePrompt(prompt)
                task.wait(0.2)
                hrp.CFrame = targetCFrame
            end
        end
    end
    autoTrainSafeZone(hrp)
end

local function handleMachinesNormally(hrp)
    local interacts = workspace:FindFirstChild("Interacts")
    if not interacts or not hrp then return end
    for _, machine in ipairs(interacts:GetChildren()) do
        if machine.Name == "ItemCollection" then continue end
        local vfx = machine:FindFirstChild("VFX")
        if vfx and #vfx:GetChildren() > 0 then
            local interaction = machine:FindFirstChild("Interaction")
            local prompt = interaction and interaction:FindFirstChild("ProximityPrompt")
            if not prompt then continue end
            local ok, cf, size = pcall(function() return machine:GetBoundingBox() end)
            if not ok or not cf then continue end
            local targetCFrame = cf - Vector3.new(0, size.Y/2 + 1, 0)
            hrp.CFrame = targetCFrame
            while autoFarm and prompt and prompt.Parent and vfx and #vfx:GetChildren() > 0 do
                if isRejectNearby() then break end
                safeFirePrompt(prompt)
                task.wait(0.2)
                hrp.CFrame = targetCFrame
            end
        end
    end
    autoTrainSafeZone(hrp)
end

-- autokoda loop
local function autokodaLoop()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    while autoKodaEnabled do
        task.wait(0.1)
        local koda = workspace:FindFirstChild("Enemies") and workspace.Enemies:FindFirstChild("RejectKoda")
        if koda then
            handleMachinesWithKoda(hrp)
        else
            task.wait(0.5)
        end
    end
    autoKodaThread = nil
end

local function autoFarmLoop()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local lastInteractSnapshot = nil

    local function snapshotInteracts()
        local interacts = workspace:FindFirstChild("Interacts")
        if not interacts then return nil end
        local t = {}
        for _, child in ipairs(interacts:GetChildren()) do
            table.insert(t, child.Name)
        end
        table.sort(t)
        return table.concat(t, ",")
    end

    while autoFarm do
        task.wait(0.12)

        -- detect zone / map change by snapshotting Interacts children
        local currentSnapshot = snapshotInteracts()
        if lastInteractSnapshot ~= nil and currentSnapshot ~= lastInteractSnapshot then
            dbg("autoFarm: zone change detected — resetting state")
            -- reset train parts automation so it will re-evaluate new zone
            autoTrainPartsEnabled = false
            -- small cooldown to allow map to settle
            task.wait(0.6)
            autoTrainPartsEnabled = true
        end
        lastInteractSnapshot = currentSnapshot

        if isRejectNearby() then
            dbg("Reject nearby — autoFarm pausing this tick")
            task.wait(0.6)
            continue
        end

        if prioritizeSamples then
            pcall(function() collectStuffing(hrp) end)
            task.wait(0.15)
        end

        local tesla = workspace:FindFirstChild("Map")
            and workspace.Map:FindFirstChild("Interact")
            and workspace.Map.Interact:FindFirstChild("TeslaCoil")
        if tesla and coilEnabled then
            pcall(function() fireAllCoilsControlled(hrp) end)
        else
            if not prioritizeSamples then pcall(function() collectStuffing(hrp) end) end
            if not isRejectNearby() then
                pcall(function() farmMachines(hrp) end)
                -- ensure autoTrainParts restarts if zone changed or items reappeared
                if autoTrainPartsEnabled and not autoTrainThread then
    autoTrainThread = task.spawn(function() autoTrainPartsWorker(hrp) end)
end
                pcall(function() autoTrainSafeZone(hrp) end)
            else
                dbg("Skipped machine actions due to Reject proximity")
            end

            local mini = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("PlushieMinigame")
            if mini then
                pcall(function()
                    local frame = mini.Root and mini.Root.Frame
                    if frame and frame:FindFirstChild("SkillCheck") and frame:FindFirstChild("Target") then
                        local moving = frame.SkillCheck:FindFirstChild("Miss")
                        local perfect = frame.Target:FindFirstChild("Perfect")
                        if moving and perfect then
                            local perfectCenter = perfect.AbsolutePosition + (perfect.AbsoluteSize / 2)
                            local x = math.clamp(perfectCenter.X, moving.AbsolutePosition.X, moving.AbsolutePosition.X + moving.AbsoluteSize.X)
                            local y = math.clamp(perfectCenter.Y, moving.AbsolutePosition.Y, moving.AbsolutePosition.Y + moving.AbsoluteSize.Y)
                            local dist = (Vector2.new(x, y) - perfectCenter).Magnitude
                            if dist <= 6 then
                                local VirtualInputManager = game:GetService("VirtualInputManager")
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                task.defer(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
                            end
                        end
                    end
                end)
            end
        end
    end
    autoFarmThread = nil
    dbg("autoFarm loop ended")
end

-- Start/stop functions for Auto Farm
local function startAutoFarm()
    if autoFarm then return end
    autoFarm = true
    if autoFarmThread then return end
    autoFarmThread = task.spawn(autoFarmLoop)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if hrp then lastPosition = hrp.CFrame end
end

local function stopAutoFarm()
    autoFarm = false
    autoFarmThread = nil
    if lastPosition then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.CFrame = lastPosition end) end
        lastPosition = nil
    end
end

-- Auto Hide start/stop (pauses farming while hiding)
local function startAutoHide()
    if autoHide then return end
    autoHide = true
    if autoHideThread then return end
    autoHideThread = task.spawn(function()
        while autoHide do
            task.wait(0.5)
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local gui = player:FindFirstChild("PlayerGui")
            local detectedIcon = gui and gui:FindFirstChild("GameUI") and gui.GameUI:FindFirstChild("HUD") and gui.GameUI.HUD:FindFirstChild("DetectedFrame") and gui.GameUI.HUD.DetectedFrame:FindFirstChild("DetectedIcon")
            if detectedIcon and detectedIcon.Visible then
                local prevAutoFarm = autoFarm
                local prevAutoTrain = autoTrainPartsEnabled
                autoFarm = false
                autoTrainPartsEnabled = false

                local originalCFrame = hrp.CFrame
                local safeZone = workspace.Persistent and workspace.Persistent:FindFirstChild("Zones") and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")
                if safeZone then
                    hrp.CFrame = safeZone.CFrame + Vector3.new(0, 5, 0)
                    task.wait(hideDuration)
                    hrp.CFrame = originalCFrame
                else
                    task.wait(hideDuration)
                end

                autoFarm = prevAutoFarm
                autoTrainPartsEnabled = prevAutoTrain
            end
        end
        autoHideThread = nil
    end)
end

local function stopAutoHide()
    autoHide = false
    autoHideThread = nil
end

-- Auto Teleport to machine (noclip) start/stop
local function startAutoTeleMach()
    if autoTeleMach then return end
    autoTeleMach = true
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
    if autoTeleMachThread then return end
    autoTeleMachThread = task.spawn(function()
        while autoTeleMach do
            task.wait(0.2)
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            local interacts = workspace:FindFirstChild("Interacts")
            if not interacts then continue end
            for _, machine in ipairs(interacts:GetChildren()) do
                if not autoTeleMach then break end
                if machine.Name == "ItemCollection" then continue end
                local vfx = machine:FindFirstChild("VFX")
                if not vfx or #vfx:GetChildren() == 0 then continue end
                local ok, cf, size = pcall(function() return machine:GetBoundingBox() end)
                if not ok or not cf then continue end
                local targetCFrame = cf - Vector3.new(0, size.Y/2 + 0.5, 0)

                -- safety: check rejects before teleporting
                if isRejectNearby() then
                    dbg("Skipping teleport under machine due to Reject proximity")
                    task.wait(0.6)
                    continue
                end

                hrp.CFrame = targetCFrame
                task.wait(0.01)
                local prompt = machine:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    while autoTeleMach and prompt.Parent and machine:FindFirstChild("VFX") and #machine.VFX:GetChildren() > 0 do
                        hrp.CFrame = targetCFrame
                        safeFirePrompt(prompt)
                        task.wait(0.01)
                    end
                else
                    repeat
                        hrp.CFrame = targetCFrame
                        task.wait(0.01)
                        vfx = machine:FindFirstChild("VFX")
                    until not autoTeleMach or not vfx or #vfx:GetChildren() == 0
                end
                task.wait(0.05)
            end
        end
        autoTeleMachThread = nil
    end)
end

local function stopAutoTeleMach()
    autoTeleMach = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    autoTeleMachThread = nil
    local char = player.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end



-- Auto Koda start/stop
local function startAutoKoda()
    if autoKodaEnabled then return end
    autoKodaEnabled = true
    if autoKodaThread then return end
    autoKodaThread = task.spawn(autokodaLoop)
end

local function stopAutoKoda()
    autoKodaEnabled = false
    autoKodaThread = nil
end

-- Aggro visualizer helpers
local function createAggroSphere(radius)
    if aggroSpherePart and aggroSpherePart.Parent then aggroSpherePart:Destroy() end
    local part = Instance.new("Part")
    part.Name = "TZHub_AggroSphere"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.6
    part.Size = Vector3.new(radius*2, 1, radius*2)
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(255, 80, 80)
    part.CastShadow = false
    part.Parent = workspace
    aggroSpherePart = part
end

local function updateAggroSphere()
    if not aggroSpherePart then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local r = aggroRadius
    aggroSpherePart.Size = Vector3.new(r*2, 1, r*2)
    aggroSpherePart.CFrame = CFrame.new(hrp.Position - Vector3.new(0, hrp.Size and hrp.Size.Y/2 or 2, 0))
end

local function showAggroVisualizerFunc()
    if showAggroVisualizer then return end
    showAggroVisualizer = true
    createAggroSphere(aggroRadius)
    task.spawn(function()
        while showAggroVisualizer do
            updateAggroSphere()
            task.wait(0.06)
        end
        if aggroSpherePart then pcall(function() aggroSpherePart:Destroy() end) end
        aggroSpherePart = nil
    end)
end

local function hideAggroVisualizerFunc()
    showAggroVisualizer = false
end

-- UI wiring (MainTab / TeleportSection / PlayerTab)
MainTab:Toggle({
    Title = "Auto Farm",
    Flag = "autofarm_toggle",
    Value = false,
    Callback = function(state) if state then startAutoFarm() else stopAutoFarm() end end
})

-- Auto pickup toggles for MainTab
-- Paste this where MainTab and WindUI are available

-- Config
local TELEPORT_OFFSET_Y = 3
local FIRE_DELAY = 0.14
local SCAN_DELAY = 0.12
local PROMPT_COOLDOWN = 0.6

-- State
local _autoMiscEnabled = false
local _autoMiscThread = nil
local _autoEventEnabled = false
local _autoEventThread = nil

-- Services / helpers
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function safeGetHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function safeFirePrompt(prompt)
    if not prompt then return end
    pcall(function()
        if type(prompt.InputHoldBegin) == "function" then
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        else
            pcall(function() fireproximityprompt(prompt, 0) end)
        end
    end)
end

local function teleportToPart(part)
    if not part or not part:IsA("BasePart") then return false end
    local hrp = safeGetHRP()
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = part.CFrame + Vector3.new(0, TELEPORT_OFFSET_Y, 0)
    end)
    return true
end

local function findNearestBasePartFromPrompt(prompt)
    if not prompt or not prompt.Parent then return nil end
    if prompt.Parent:IsA("BasePart") then return prompt.Parent end
    local ancestor = prompt.Parent
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("BasePart") then return ancestor end
        ancestor = ancestor.Parent
    end
    for _, d in ipairs(prompt:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function isInventoryFull()
    local ok, full = pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return false end
        local gameUI = gui:FindFirstChild("GameUI")
        if not gameUI then return false end
        local hud = gameUI:FindFirstChild("HUD")
        if not hud then return false end
        local br = hud:FindFirstChild("BottomRight")
        if not br then return false end
        local tools = br:FindFirstChild("Tools")
        if not tools then return false end

        local function slotHasImage(idx)
            local btn = tools:FindFirstChild("AbilityButton_" .. tostring(idx))
            if not btn then return false end
            local icon = btn:FindFirstChild("AbilityIcon")
            if not icon then return false end
            local img = icon.Image
            return (img ~= nil and img ~= "")
        end

        local s1 = slotHasImage(1)
        local s2 = slotHasImage(2)
        local s3 = slotHasImage(3)
        return (s1 and s2 and s3)
    end)
    return ok and full
end

local function notify(title, content, icon)
    pcall(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({ Title = title, Content = content, Icon = icon or "zap", Duration = 3 })
        else
            print("[Notify]", title, content)
        end
    end)
end

local function runPickupLoop(folderGetter, enabledRef, threadRef, label)
    if threadRef[1] then return end
    threadRef[1] = task.spawn(function()
        local lastFired = setmetatable({}, { __mode = "k" })
        local savedPos = nil

        while enabledRef[1] do
            -- inventory check
            if isInventoryFull() then
                -- teleport back if we saved a position
                if savedPos and safeGetHRP() then
                    pcall(function() safeGetHRP().CFrame = savedPos end)
                end
                notify(label, "Inventory full — stopped and returned to previous position", "close")
                enabledRef[1] = false
                break
            end

            local folder = nil
            pcall(function() folder = folderGetter() end)
            if folder and folder.Parent then
                for _, obj in ipairs(folder:GetDescendants()) do
                    if not enabledRef[1] then break end
                    if obj and obj:IsA("ProximityPrompt") then
                        local now = tick()
                        local last = lastFired[obj] or 0
                        if (now - last) >= PROMPT_COOLDOWN then
                            local part = findNearestBasePartFromPrompt(obj)
                            if part then
                                -- save current position before teleporting
                                if not savedPos then
                                    local hrp = safeGetHRP()
                                    if hrp then savedPos = hrp.CFrame end
                                end

                                local ok = teleportToPart(part)
                                if ok then
                                    task.wait(FIRE_DELAY)
                                    safeFirePrompt(obj)
                                    lastFired[obj] = tick()
                                    task.wait(0.04)
                                end
                            else
                                -- no part found, try firing in place
                                safeFirePrompt(obj)
                                lastFired[obj] = tick()
                                task.wait(0.04)
                            end
                        end
                    end
                end
            end

            task.wait(SCAN_DELAY)
        end

        -- cleanup on exit: restore saved position if still valid and inventory full wasn't the reason
        if savedPos and safeGetHRP() and not isInventoryFull() then
            pcall(function() safeGetHRP().CFrame = savedPos end)
        end

        threadRef[1] = nil
    end)
end

-- Start/stop helpers for Misc
local function getPickupMiscFolder()
    local pickup = workspace:FindFirstChild("Pickup")
    return pickup and pickup:FindFirstChild("Misc")
end

local function startAutoMisc()
    if _autoMiscEnabled then return end
    _autoMiscEnabled = true
    runPickupLoop(getPickupMiscFolder, { _autoMiscEnabled }, { _autoMiscThread }, "Auto pickup misc items")
    notify("Auto pickup misc items", "Started", "zap")
end

local function stopAutoMisc()
    _autoMiscEnabled = false
    notify("Auto pickup misc items", "Stopped", "close")
end

-- Start/stop helpers for Event
local function getPickupEventFolder()
    local pickup = workspace:FindFirstChild("Pickup")
    return pickup and pickup:FindFirstChild("Event")
end

local function startAutoEvent()
    if _autoEventEnabled then return end
    _autoEventEnabled = true
    runPickupLoop(getPickupEventFolder, { _autoEventEnabled }, { _autoEventThread }, "Auto pickup event items")
    notify("Auto pickup event items", "Started", "zap")
end

local function stopAutoEvent()
    _autoEventEnabled = false
    notify("Auto pickup event items", "Stopped", "close")
end

-- UI toggles on MainTab (names requested)
MainTab:Toggle({
    Title = "Auto pickup misc items",
    Value = false,
    Callback = function(state)
        if state then startAutoMisc() else stopAutoMisc() end
    end
})

MainTab:Toggle({
    Title = "Auto pickup event items",
    Value = false,
    Callback = function(state)
        if state then startAutoEvent() else stopAutoEvent() end
    end
})



--// Blackout UI (PlayerGui)
local BlackoutGui = Instance.new("ScreenGui")
BlackoutGui.Name = "BlackoutMode"
BlackoutGui.IgnoreGuiInset = true
BlackoutGui.ResetOnSpawn = false
BlackoutGui.Parent = player:WaitForChild("PlayerGui")

local BlackFrame = Instance.new("Frame")
BlackFrame.Size = UDim2.fromScale(1, 1)
BlackFrame.Position = UDim2.fromScale(0, 0)
BlackFrame.BackgroundColor3 = Color3.new(0,0,0)
BlackFrame.BackgroundTransparency = 1 -- initially off
BlackFrame.BorderSizePixel = 0
BlackFrame.ZIndex = 1 -- low, WindUI stays on top
BlackFrame.Parent = BlackoutGui

--// Toggle in MainTab
MainTab:Toggle({
    Title = "Blackout Mode",
    Desc = "Make everything black except the UI",
    Value = false,
    Callback = function(state)
        BlackFrame.BackgroundTransparency = state and 0 or 1
    end
})

-- Auto Collect Train Parts (fixed, robust, MainTab toggle)
-- Paste this after your UI (MainTab) is created. It will use existing globals if present.

-- Local state
local _autoCollectEnabled = false
local _autoCollectThread = nil
local _dbg = dbg or function(...) print("[AutoCollect]", ...) end

-- Safe resolvers (non-blocking)
local function resolveItemFolder()
    local interacts = workspace:FindFirstChild("Interacts")
    if not interacts then return nil end
    return interacts:FindFirstChild("ItemCollection")
end

local function resolveDeliveryPoint()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("DeliveryPoint")
end

local function resolveSafeZone()
    return workspace:FindFirstChild("Persistent")
        and workspace.Persistent:FindFirstChild("Zones")
        and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")
end

local function safeGetHRP()
    local plr = game:GetService("Players").LocalPlayer
    if not plr then return nil end
    local char = plr.Character or plr.CharacterAdded:Wait()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Safe teleport helper
local function _teleportToPart(part)
    if not part or not part:IsA("BasePart") then return false end
    local hrp = safeGetHRP()
    if not hrp then return false end
    pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0) end)
    task.wait(0.18)
    return true
end

-- Safe prompt fire (InputHold preferred)
local function _safeFirePrompt(prompt)
    if not prompt then return end
    pcall(function()
        if type(prompt.InputHoldBegin) == "function" then
            prompt:InputHoldBegin()
            task.wait(0.06)
            prompt:InputHoldEnd()
        else
            pcall(function() fireproximityprompt(prompt, 0) end)
        end
    end)
end

-- Wait until both an item and a delivery point exist (or until disabled)
local function _waitForWork(timeout)
    timeout = timeout or 30
    local start = tick()
    while _autoCollectEnabled and (tick() - start) < timeout do
        local folder = resolveItemFolder()
        local dp = resolveDeliveryPoint()
        local hasItem = folder and #folder:GetChildren() > 0
        local hasDelivery = dp and dp.Parent
        if hasItem and hasDelivery then
            return true
        end
        _dbg("Waiting for work (items:", tostring(hasItem), "delivery:", tostring(hasDelivery) .. ")")
        -- refresh references and wait a bit
        task.wait(0.6)
    end
    return false
end

-- Collect current items once (teleport to each item, collect, teleport to delivery)
local function _collectOnce()
    local folder = resolveItemFolder()
    local dp = resolveDeliveryPoint()
    if not folder or not dp then return false end

    local children = folder:GetChildren()
    if #children == 0 then return false end

    local foundAny = false
    for _, item in ipairs(children) do
        if not _autoCollectEnabled then break end
        if not item or not item.Parent then continue end
        if item:IsA("BasePart") then
            local prompt = item:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                foundAny = true

                -- teleport to item (use bounding box if model)
                local ok, cf, size = pcall(function() return item:GetBoundingBox() end)
                if ok and cf then
                    pcall(function() safeGetHRP().CFrame = cf - Vector3.new(0, (size.Y/2) + 2, 0) end)
                    task.wait(0.12)
                else
                    _teleportToPart(item)
                end

                -- collect
                _safeFirePrompt(prompt)
                task.wait(0.28)

                -- teleport to delivery point to deposit (if exists)
                dp = resolveDeliveryPoint()
                if dp and dp:IsA("BasePart") then
                    pcall(function() safeGetHRP().CFrame = dp.CFrame + Vector3.new(0, 5, 0) end)
                    task.wait(0.35)
                end

                -- wait briefly for GUI to update
                local startTick = tick()
                local collected = false
                while _autoCollectEnabled and (tick() - startTick) < 4 do
                    local amtLabel = readTrainPartsAmount()
                    if amtLabel then
                        local cur, tot = parseAmountText(amtLabel.Text)
                        if cur and tot and cur > 0 then
                            collected = true
                            break
                        end
                    end
                    task.wait(0.12)
                end

                task.wait(0.12)
            end
        end
    end

    return foundAny
end

-- Main loop: wait for work, collect until none left, ensure teleport to delivery, then wait for new work
local function _autoCollectLoop()
    while _autoCollectEnabled do
        -- ensure both folder and delivery exist (wait up to 30s)
        if not _waitForWork(30) then
            _dbg("AutoCollect: timed out waiting for work or disabled")
            break
        end

        -- perform collection passes until no items remain
        local passCount = 0
        while _autoCollectEnabled do
            passCount = passCount + 1
            local ok, found = pcall(_collectOnce)
            if not ok then
                _dbg("AutoCollect: error during collectOnce, retrying", found)
                task.wait(0.6)
                continue
            end

            if not found then
                -- No items found this pass. Ensure we teleport to DeliveryPoint (if present),
                -- then wait for new items to spawn instead of returning.
                local dp = resolveDeliveryPoint()
                if dp and dp:IsA("BasePart") then
                    _dbg("AutoCollect: no items left — teleporting to DeliveryPoint")
                    pcall(function() safeGetHRP().CFrame = dp.CFrame + Vector3.new(0, 5, 0) end)
                else
                    _dbg("AutoCollect: no DeliveryPoint found when items finished")
                end

                -- Wait for new items to appear (with a reasonable timeout). If new items appear, continue loop.
                local waited = 0
                local newItemsAppeared = false
                while _autoCollectEnabled and waited < 20 do
                    local folder = resolveItemFolder()
                    if folder and #folder:GetChildren() > 0 then
                        newItemsAppeared = true
                        break
                    end
                    task.wait(0.6)
                    waited = waited + 0.6
                end

                if newItemsAppeared then
                    _dbg("AutoCollect: new items detected — resuming collection")
                    task.wait(0.2)
                    break -- break inner while to start collecting new items
                else
                    _dbg("AutoCollect: no new items after wait — returning to idle and will wait again")
                    break -- exit inner loop and go back to outer waitForWork
                end
            end

            -- small delay between passes
            task.wait(0.25)
        end

        -- short cooldown before checking for work again
        task.wait(0.6)
    end

    _autoCollectThread = nil
    _dbg("AutoCollect: loop ended")
end

-- Public start/stop
local function startAutoCollect()
    if _autoCollectEnabled then return end
    _autoCollectEnabled = true
    if _autoCollectThread then return end
    _autoCollectThread = task.spawn(_autoCollectLoop)
    _dbg("Auto Collect Train Parts started")
end

local function stopAutoCollect()
    _autoCollectEnabled = false
    _autoCollectThread = nil
    _dbg("Auto Collect Train Parts stopped")
end

-- Attach toggle to MainTab (uses existing MainTab)
if MainTab then
    MainTab:Toggle({
        Title = "Auto Collect Train Parts",
        Value = false,
        Callback = function(state)
            if state then startAutoCollect() else stopAutoCollect() end
        end
    })
else
    -- fallback: expose functions globally
    _G.startAutoCollect = startAutoCollect
    _G.stopAutoCollect = stopAutoCollect
    _dbg("Auto Collect Train Parts: MainTab not found; use _G.startAutoCollect/_G.stopAutoCollect")
end

MainTab:Toggle({
    Title = "Skip Samples If Completed",
    Flag = "skip_samples_toggle",
    Value = skipSamplesForCompleted,
    Callback = function(state) skipSamplesForCompleted = state end
})

MainTab:Toggle({
    Title = "Prioritize Samples",
    Flag = "prioritize_samples",
    Desc = "This will make the auto farm on slow mod meaning the teleport will be slow It may affect other toggles and break them",
    Value = prioritizeSamples,
    Callback = function(state) prioritizeSamples = state end
})

-- Auto Activate Tesla Coils toggle (attach to MainTab)
-- Paste this after your MainTab, getCoilFolder, getSafeZone and tp definitions.

local _autoCoilsEnabled = false
local _autoCoilsThread = nil
local _firedPrompts = FiredPrompts or {}
local _zoneActive = ZoneActive or false

local function _safeTeleportToPart(part)
    if not part or not part:IsA("BasePart") then return end
    local ok, err = pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = part.CFrame + Vector3.new(0, 3, 0) end
    end)
    if ok then task.wait(0.18) end
end

local function _safeFirePrompt(prompt)
    if not prompt then return end
    pcall(function()
        if type(prompt.InputHoldBegin) == "function" then
            prompt:InputHoldBegin()
            task.wait(0.06)
            prompt:InputHoldEnd()
        else
            pcall(function() fireproximityprompt(prompt, 0) end)
        end
    end)
end

local function _cleanFiredPrompts()
    for prompt, _ in pairs(_firedPrompts) do
        if not prompt or not prompt.Parent then
            _firedPrompts[prompt] = nil
        end
    end
end

local function _fireAllCoilsOnce()
    local coilRoot = getCoilFolder()
    if not coilRoot then return false end

    local activatedAny = false
    for _, folder in ipairs(coilRoot:GetChildren()) do
        if not _autoCoilsEnabled then break end
        if not folder:IsA("Folder") then continue end

        for _, obj in ipairs(folder:GetDescendants()) do
            if not _autoCoilsEnabled then break end
            if not obj or not obj.Parent then continue end

            if obj:IsA("ProximityPrompt") and not _firedPrompts[obj] then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    _firedPrompts[obj] = true
                    activatedAny = true

                    -- teleport and fire
                    _safeTeleportToPart(part)
                    _safeFirePrompt(obj)

                    task.wait(0.35)
                end
            end
        end
    end

    return activatedAny
end

local function _autoCoilsLoop()
    while _autoCoilsEnabled do
        local coilRoot = getCoilFolder()

        -- zone not ready
        if not coilRoot or #coilRoot:GetChildren() == 0 then
            if _zoneActive then
                -- zone ended: clear state
                _firedPrompts = {}
                _zoneActive = false
            end
            task.wait(0.6)
            continue
        end

        -- zone active
        _zoneActive = true

        local ok, activated = pcall(_fireAllCoilsOnce)
        if not ok then
            dbg("AutoCoils: error during pass")
            task.wait(0.6)
            continue
        end

        if not activated then
            local safe = getSafeZone()
            if safe and safe:IsA("BasePart") then
                _safeTeleportToPart(safe)
            end

            -- cleanup stale entries and wait for new prompts
            _cleanFiredPrompts()
            task.wait(1.2)
        end

        task.wait(0.25)
    end

    _autoCoilsThread = nil
end

local function startAutoCoils()
    if _autoCoilsEnabled then return end
    _autoCoilsEnabled = true
    if _autoCoilsThread then return end
    _autoCoilsThread = task.spawn(_autoCoilsLoop)
    dbg("Auto Activate Tesla Coils started")
end

local function stopAutoCoils()
    _autoCoilsEnabled = false
    _autoCoilsThread = nil
    dbg("Auto Activate Tesla Coils stopped")
end

-- Replace existing toggle or add new toggle on MainTab
MainTab:Toggle({
    Title = "Auto Tesla Coils",
    Value = false,
    Callback = function(state)
        if state then
            -- reset state for a fresh run
            _firedPrompts = {}
            _zoneActive = false
            startAutoCoils()
        else
            stopAutoCoils()
        end
    end
})


MainTab:Toggle({
    Title = "Auto Koda",
    Desc = "Teleport under machine to avoid Koda",
    Flag = "autokoda_toggle",
    Value = false,
    Callback = function(state) if state then startAutoKoda() else stopAutoKoda() end end
})

MainTab:Slider({
    Title = "Auto Hide Duration",
    Flag = "auto_hide_duration",
    Step = 1,
    Value = { Min = 1, Max = 30, Default = hideDuration },
    Callback = function(value) hideDuration = value end
})
MainTab:Toggle({
    Title = "Auto Hide",
    Flag = "auto_hide_toggle",
    Value = false,
    Callback = function(state) if state then startAutoHide() else stopAutoHide() end end
})

TeleportSection:Toggle({
    Title = "Auto teleport to machine",
    Flag = "autotelemach_noclip_toggle",
    Value = false,
    Callback = function(state) if state then startAutoTeleMach() else stopAutoTeleMach() end end
})

MainTab:Toggle({
    Title = "FullBright",
    Flag = "fullbright_toggle",
    Value = false,
    Callback = function(state) if state then enableFullBright() else disableFullBright() end end
})

MainTab:Toggle({
    Title = "Show Reject Aggro Range",
    Flag = "show_aggro_range",
    Value = false,
    Callback = function(state) if state then showAggroVisualizerFunc() else hideAggroVisualizerFunc() end end
})
MainTab:Slider({
    Title = "Aggro Radius",
    Flag = "aggro_radius",
    Step = 1,
    Value = { Min = 10, Max = 120, Default = aggroRadius },
    Callback = function(v) aggroRadius = v if aggroSpherePart then createAggroSphere(aggroRadius) end end
})



dbg("Auto Farm module loaded and UI wired.")



-- Inputs
local targetPlayerName = ""
local targetObjectPath = ""

TeleportSection:Input({
    Title = "Player Name",
    Placeholder = "Enter player name",
    Callback = function(value)
        targetPlayerName = value
    end
})

TeleportSection:Input({
    Title = "Object Path (optional)",
    Placeholder = "e.g. Workspace.Part",
    Callback = function(value)
        targetObjectPath = value
    end
})

-- Single Teleport to Player
TeleportSection:Button({
    Title = "Teleport to Player",
    Icon = "solar:arrow-right-bold",
    Callback = function()
        local plr = game:GetService("Players"):FindFirstChild(targetPlayerName)
        local char = game.Players.LocalPlayer.Character
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            WindUI:Notify({
                Title = "Teleport",
                Content = "Teleported to " .. targetPlayerName,
                Icon = "solar:location-bold",
                Duration = 4,
            })
        end
    end
})

-- Single Teleport to Object
TeleportSection:Button({
    Title = "Teleport to Object",
    Icon = "solar:arrow-right-bold",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        local target
        if targetObjectPath ~= "" then
            local success, result = pcall(function()
                return loadstring("return " .. targetObjectPath)()
            end)
            if success and result then
                target = result
            end
        end
        if target and char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 3, 0)
            WindUI:Notify({
                Title = "Teleport",
                Content = "Teleported to object: " .. targetObjectPath,
                Icon = "solar:location-bold",
                Duration = 4,
            })
        end
    end
})

-- Loop Teleport Toggle
local loopTeleportEnabled = false
TeleportSection:Toggle({
    Title = "Loop Teleport",
    Flag = "loop_teleport_toggle",
    Value = false,
    Callback = function(state)
        loopTeleportEnabled = state
        if state then
            task.spawn(function()
                while loopTeleportEnabled do
                    local char = game.Players.LocalPlayer.Character
                    if targetPlayerName ~= "" then
                        local plr = game:GetService("Players"):FindFirstChild(targetPlayerName)
                        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        end
                    elseif targetObjectPath ~= "" then
                        local success, result = pcall(function()
                            return loadstring("return " .. targetObjectPath)()
                        end)
                        if success and result and char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = result.CFrame + Vector3.new(0, 3, 0)
                        end
                    end
                    task.wait(1) -- teleport every second
                end
            end)
        end
    end
})
--// Teleport Function (to machines that still have VFX children)
local function teleportAboveMachine()
    local machines = workspace.Interacts:GetChildren()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local targetMachine

    -- find the first machine that has VFX children (meaning incomplete)
    for _, machine in ipairs(machines) do
        if machine.Name ~= "ItemCollection" then
            local vfx = machine:FindFirstChild("VFX")
            if vfx and #vfx:GetChildren() > 0 then
                targetMachine = machine
                break
            end
        end
    end

    if targetMachine then
        local targetCFrame
        if targetMachine:IsA("Model") then
            local cf, size = targetMachine:GetBoundingBox()
            targetCFrame = cf + Vector3.new(0, size.Y/2 + 10, 0)
        elseif targetMachine:IsA("BasePart") then
            targetCFrame = targetMachine.CFrame + Vector3.new(0, targetMachine.Size.Y/2 + 10, 0)
        end

        if targetCFrame then
            hrp.CFrame = targetCFrame
            WindUI:Notify({
                Title = "Teleport",
                Content = "Teleported above incomplete Machine.",
                Icon = "solar:cursor-square-bold",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Machine has no valid position.",
                Icon = "solar:info-square-bold",
                Duration = 3,
            })
        end
    else
        WindUI:Notify({
            Title = "Teleport Blocked",
            Content = "All Machines are completed (no VFX children).",
            Icon = "solar:info-square-bold",
            Duration = 3,
        })
    end
end

--// Button
TeleportSection:Button({
    Title = "Teleport to Machine",
    Flag = "Telemach_button",
    Icon = "solar:cursor-square-bold",
    Callback = function()
        teleportAboveMachine()
    end
})





--// Noclip Toggle
local noclipEnabled = false
local noclipConnection

PlayerTab:Toggle({
    Title = "Noclip",
    Flag = "noclip_toggle",
    Value = false,
    Callback = function(state)
        noclipEnabled = state
        if noclipEnabled then
            -- Start noclip loop
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            -- Stop noclip loop
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            -- Reset collisions back to normal
            for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
})

-- Robust Fly Module for PC Mobile Gamepad
-- Drop this into your script where PlayerTab is available

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Config
local flySpeed = 50
local decelTime = 0.18 -- smooth stop time

-- Internal state
local flyEnabled = false
local flyBV = nil
local flyLoop = nil

-- Utility: safe pcall wrapper
local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then return nil end
    return res
end

-- Create BodyVelocity attached to HRP
local function createBV(hrp)
    if not hrp then return nil end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "TZHub_FlyBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1250
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp
    return bv
end

-- Compute desired velocity using Humanoid.MoveDirection and camera pitch
local function computeVelocity(humanoid, hrp, speed)
    local moveDir = humanoid and humanoid.MoveDirection or Vector3.new(0,0,0)
    if moveDir.Magnitude <= 0.01 then
        return Vector3.new(0,0,0)
    end

    local cam = workspace.CurrentCamera
    if not cam then
        local horiz = Vector3.new(moveDir.X, 0, moveDir.Z)
        if horiz.Magnitude <= 0.01 then return Vector3.new(0,0,0) end
        return horiz.Unit * speed
    end

    -- horizontal from MoveDirection, vertical from camera look Y scaled by forward alignment
    local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z)
    local horizVel = Vector3.new(0,0,0)
    if horizontal.Magnitude > 0.01 then
        horizVel = horizontal.Unit * speed
    end

    local camLook = cam.CFrame.LookVector
    local camForwardXZ = Vector3.new(camLook.X, 0, camLook.Z)
    local forwardAmount = 0
    if camForwardXZ.Magnitude > 0.01 and horizontal.Magnitude > 0.01 then
        forwardAmount = math.clamp(horizontal.Unit:Dot(camForwardXZ.Unit), -1, 1)
    end

    local vertical = camLook.Y * forwardAmount * speed
    return Vector3.new(horizVel.X, vertical, horizVel.Z)
end

-- Smoothly decelerate and cleanup
local function smoothStop(hrp)
    if not hrp then return end
    -- lerp AssemblyLinearVelocity to zero
    local startVel = hrp.AssemblyLinearVelocity
    local t0 = tick()
    while tick() - t0 < decelTime do
        local alpha = (tick() - t0) / decelTime
        local newVel = startVel:Lerp(Vector3.new(0,0,0), alpha)
        safe(function() hrp.AssemblyLinearVelocity = newVel end)
        task.wait()
    end
    safe(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
end

-- Start fly loop
local function startFly()
    if flyEnabled then return end
    flyEnabled = true

    flyLoop = task.spawn(function()
        while flyEnabled do
            task.wait() -- responsive loop

            local char = player and player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then
                task.wait(0.2)
                continue
            end

            if not flyBV or not flyBV.Parent then
                if flyBV then safe(function() flyBV:Destroy() end) end
                flyBV = createBV(hrp)
            end

            local desired = computeVelocity(hum, hrp, flySpeed)
            if desired.Magnitude > 0.01 then
                flyBV.Velocity = desired
            else
                flyBV.Velocity = Vector3.new(0,0,0)
            end
        end
    end)
end

-- Stop fly loop safely
local function stopFly()
    if not flyEnabled and not flyBV then return end
    flyEnabled = false

    -- capture HRP to operate on
    local char = player and player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- if BV exists, smoothly lerp its velocity to zero then destroy
    if flyBV and flyBV.Parent then
        local startVel = flyBV.Velocity
        local t0 = tick()
        while tick() - t0 < decelTime do
            local alpha = (tick() - t0) / decelTime
            local newVel = startVel:Lerp(Vector3.new(0,0,0), alpha)
            if flyBV and flyBV.Parent then
                flyBV.Velocity = newVel
            elseif hrp then
                hrp.AssemblyLinearVelocity = newVel
            end
            task.wait()
        end
        safe(function() if flyBV and flyBV.Parent then flyBV:Destroy() end end)
        flyBV = nil
    else
        -- no BV: still ensure assembly velocity is smoothed
        if hrp then smoothStop(hrp) end
    end

    -- final safety clears
    if hrp then
        safe(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
    end
end

-- UI wiring helper
local function ensurePlayerTabAndWire(PlayerTab)
    if not PlayerTab then
        warn("Fly UI not created: PlayerTab is nil")
        return false
    end

    -- Toggle
    PlayerTab:Toggle({
        Title = "Fly",
        Value = false,
        Callback = function(state)
            if state then
                startFly()
            else
                stopFly()
            end
        end
    })

    -- Slider
    PlayerTab:Slider({
        Title = "Fly Speed",
        Flag = "fly_slider",
        Step = 1,
        Value = {
            Min = 10,
            Max = 300,
            Default = flySpeed,
        },
        Callback = function(value)
            flySpeed = value
        end
    })

    return true
end

-- Attempt to wire UI now. If PlayerTab is not global, caller must pass it in.
-- If your script has a variable PlayerTab, call ensurePlayerTabAndWire(PlayerTab) after PlayerTab is created.
if _G and _G.PlayerTab then
    ensurePlayerTabAndWire(_G.PlayerTab)
else
    -- try to find PlayerTab global name used earlier in your script
    if PlayerTab then
        ensurePlayerTabAndWire(PlayerTab)
    else
        -- print instruction so you can wire it manually
        print("Fly module loaded. Call ensurePlayerTabAndWire(PlayerTab) after PlayerTab is created.")
    end
end
--// Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local JumpPower = 50
local JumpEnabled = false

--// Jump Button GUI
local JumpGui = Instance.new("ScreenGui")
JumpGui.Name = "WindUI_JumpGui"
JumpGui.ResetOnSpawn = false
JumpGui.Parent = game:GetService("CoreGui")

local JumpButton = Instance.new("TextButton")
JumpButton.Parent = JumpGui
JumpButton.Size = UDim2.new(0, 120, 0, 50)
JumpButton.Position = UDim2.new(0.82, 0, 0.7, 0)
JumpButton.Text = "JUMP"
JumpButton.TextScaled = true
JumpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
JumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpButton.BorderSizePixel = 0
JumpButton.Visible = false
JumpButton.Active = true
JumpButton.Draggable = true

--// Jump Logic
local function Jump()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.JumpPower = JumpPower
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

JumpButton.MouseButton1Click:Connect(Jump)

--// Add to Player Tab
PlayerTab:Toggle({
    Title = "Enable Jump Button",
     Flag = "jump_button",
    Desc = "Show or hide jump button",
    Value = false,
    Callback = function(state)
        JumpEnabled = state
        JumpButton.Visible = state
    end
})

PlayerTab:Slider({
    Title = "Jump Height",
    Desc = "Change jump power",
    Flag = "jumph_slider",
    Step = 5,
    Value = {
        Min = 20,
        Max = 300,
        Default = 50,
    },
    Callback = function(value)
        JumpPower = value
    end
})


--// Auto Teleport to Elevator
local autoElevator = false

TeleportSection:Toggle({
    Title = "Auto teleport to train",
    Flag = "auto_elevator_toggle",
    Value = false,
    Callback = function(state)
        autoElevator = state
        if autoElevator then
            task.spawn(function()
                while autoElevator do
                    task.wait(1)

                    local interacts = workspace:FindFirstChild("Interacts")
                    if not interacts then
                        -- Machines folder deleted -> stop teleport loop
                        autoElevator = false
                        break
                    end

                    local machines = interacts:GetChildren()
                    local allCleared = true

                    for _, machine in pairs(machines) do
                        local vfx = machine:FindFirstChild("VFX")
                        if vfx and #vfx:GetChildren() > 0 then
                            allCleared = false
                            break
                        end
                    end

                    if allCleared and #machines > 0 then
                        local player = game.Players.LocalPlayer
                        local char = player.Character or player.CharacterAdded:Wait()
                        local hrp = char:WaitForChild("HumanoidRootPart")

                        local elevator = workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")
                        if elevator and elevator:IsA("BasePart") then
                            hrp.CFrame = elevator.CFrame + Vector3.new(0, 5, 0)
                        end
                    end
                end
            end)
        end
    end
})
--// Teleport to Item Button (no notify)
MainTab:Button({
    Title = "Teleport to item",
    Flag = "teleport_item_button",
    Icon = "solar:cursor-square-bold",
    Callback = function()
        local stuffingFolder = workspace:FindFirstChild("Pickup") and workspace.Pickup:FindFirstChild("Stuffing")
        if stuffingFolder then
            local items = stuffingFolder:GetChildren()
            if #items > 0 then
                local item = items[1]
                local player = game.Players.LocalPlayer
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")

                if item:IsA("Model") then
                    local cf, size = item:GetBoundingBox()
                    hrp.CFrame = cf + Vector3.new(0, size.Y/2 + 5, 0)
                elseif item:IsA("BasePart") then
                    hrp.CFrame = item.CFrame + Vector3.new(0, item.Size.Y/2 + 5, 0)
                end

                -- Fire its ProximityPrompt if exists
                local prompt = item:FindFirstChild("Main") and item.Main:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt, 0) -- bypass Hold
                end
            end
        end
    end
})


--// Teleport to Weapons Button
TeleportSection:Button({
    Title = "Teleport to weapons",
    Flag = "teleport_weapons_button",
    Icon = "solar:cursor-square-bold",
    Callback = function()
        local vfxFolder = workspace:FindFirstChild("VFX")
        if vfxFolder then
            local items = vfxFolder:GetChildren()
            if #items > 0 then
                local item = items[1]
                local player = game.Players.LocalPlayer
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")

                -- Teleport slightly above item
                if item:IsA("Model") then
                    local cf, size = item:GetBoundingBox()
                    hrp.CFrame = cf + Vector3.new(0, size.Y/2 + 3, 0)
                elseif item:IsA("BasePart") then
                    hrp.CFrame = item.CFrame + Vector3.new(0, item.Size.Y/2 + 3, 0)
                end

                -- Fire any ProximityPrompt inside
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    fireproximityprompt(prompt, 0) -- bypass Hold instantly
                end
            end
        end
    end
})

local autoWeapons = false

TeleportSection:Toggle({
    Title = "Auto teleport to weapons",
    Flag = "auto_weapons_toggle",
    Value = false,
    Callback = function(state)
        autoWeapons = state
        if autoWeapons then
            task.spawn(function()
                while autoWeapons do
                    task.wait(0.5)

                    local vfxFolder = workspace:FindFirstChild("VFX")
                    if vfxFolder then
                        for _, item in pairs(vfxFolder:GetChildren()) do
                            local player = game.Players.LocalPlayer
                            local char = player.Character or player.CharacterAdded:Wait()
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            if not hrp then continue end

                            -- Teleport slightly above item
                            if item:IsA("Model") then
                                local cf, size = item:GetBoundingBox()
                                hrp.CFrame = cf + Vector3.new(0, size.Y/2 + 3, 0)
                            elseif item:IsA("BasePart") then
                                hrp.CFrame = item.CFrame + Vector3.new(0, item.Size.Y/2 + 3, 0)
                            end

                            -- Loop firing prompts until item disappears
                            while autoWeapons and item.Parent == vfxFolder do
                                for _, prompt in ipairs(item:GetDescendants()) do
                                    if prompt:IsA("ProximityPrompt") then
                                        pcall(function()
                                            fireproximityprompt(prompt, 0)
                                        end)
                                    end
                                end
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end)
        end
    end
})
-- Perfect Hold Skillcheck Toggle with two sliders
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- tunables (defaults)
local waitInside = 0.3     -- time to stay inside Perfect (seconds)
local cooldown = 0.6       -- delay between hits (seconds)

local enterTime = 0
local lastHit = 0
local skillConn = nil
local enabled = false

local function pressSpace()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local function overlap(posA, sizeA, posB, sizeB)
    return posA.X < posB.X + sizeB.X
       and posA.X + sizeA.X > posB.X
       and posA.Y < posB.Y + sizeB.Y
       and posA.Y + sizeA.Y > posB.Y
end

local function startSkillcheck()
    if skillConn and skillConn.Connected then return end
    enterTime = 0
    lastHit = 0
    skillConn = RunService.RenderStepped:Connect(function()
        local mini = pg:FindFirstChild("Main") and pg.Main:FindFirstChild("PlushieMinigame")
        if not mini then
            enterTime = 0
            return
        end

        local frame = mini.Root.Frame
        local bar = frame.SkillCheck:FindFirstChild("Miss")
        local perfect = frame.Target:FindFirstChild("Perfect")
        if not bar or not perfect then
            enterTime = 0
            return
        end

        -- cooldown protection
        if tick() - lastHit < cooldown then
            enterTime = 0
            return
        end

        local inside = overlap(
            bar.AbsolutePosition,
            bar.AbsoluteSize,
            perfect.AbsolutePosition,
            perfect.AbsoluteSize
        )

        if inside then
            if enterTime == 0 then
                enterTime = tick()
            end

            if tick() - enterTime >= waitInside then
                lastHit = tick()
                enterTime = 0
                pressSpace()
            end
        else
            enterTime = 0
        end
    end)
end

local function stopSkillcheck()
    if skillConn then
        if skillConn.Connected then skillConn:Disconnect() end
        skillConn = nil
    end
    enterTime = 0
    lastHit = 0
end

-- Toggle in MainTab
MainTab:Toggle({
    Title = "Auto Skillcheck",
    Flag = "perfect_hold_skillcheck",
    Value = false,
    Callback = function(state)
        enabled = state
        if enabled then
            startSkillcheck()
        else
            stopSkillcheck()
        end
    end
})

-- Slider: Wait inside Perfect (seconds)
MainTab:Slider({
    Title = "Skillcheck Duration",
    Desc = "How long the bar must remain inside the Perfect zone before pressing (seconds).",
    Step = 0.01,
    Value = {
        Min = 0.05,
        Max = 1.0,
        Default = waitInside,
    },
    Callback = function(val)
        waitInside = val
    end
})

-- Slider: Cooldown between hits (seconds)
MainTab:Slider({
    Title = "Perfect Hit Cooldown",
    Desc = "Minimum delay between successful hits (seconds).",
    Step = 0.01,
    Value = {
        Min = 0.1,
        Max = 2.0,
        Default = cooldown,
    },
    Callback = function(val)
        cooldown = val
    end
})

--// Visual Tab
local VisualTab = Window:Tab({
    Title = "Visual",
    Icon = "solar:eye-bold",
})

local VisualSection = VisualTab:Section({
    Title = "Visual Enhancements",
    Box = false,
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 17,
    Opened = true,
})

-- === FullBright toggle ===
local fullBrightEnabled = false
local function enableFullBright()
    if fullBrightEnabled then return end
    local Lighting = game:GetService("Lighting")
    _FB_backup = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        GlobalShadows = Lighting.GlobalShadows,
    }
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(255,255,255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    Lighting.GlobalShadows = false
    fullBrightEnabled = true
    dbg("FullBright enabled")
end

local function disableFullBright()
    if not fullBrightEnabled then return end
    local Lighting = game:GetService("Lighting")
    if _FB_backup then
        Lighting.Brightness = _FB_backup.Brightness
        Lighting.Ambient = _FB_backup.Ambient
        Lighting.OutdoorAmbient = _FB_backup.OutdoorAmbient
        Lighting.ClockTime = _FB_backup.ClockTime
        Lighting.GlobalShadows = _FB_backup.GlobalShadows
    end
    _FB_backup = nil
    fullBrightEnabled = false
    dbg("FullBright disabled")
end


-- Shared ESP color
local espColor = Color3.fromRGB(0, 255, 0)
local espEnabled = false

-- Function to apply highlights
local function applyHighlights()
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local existing = plr.Character:FindFirstChild("ESPHighlight")
            if not existing then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESPHighlight"
                highlight.FillColor = espColor
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = plr.Character
            else
                existing.FillColor = espColor
            end
        end
    end
end

-- ESP Toggle
VisualSection:Toggle({
    Title = "Highlight Players",
    Flag = "esp_toggle",
    Value = false,
    Callback = function(state)
        espEnabled = state
        if state then
            task.spawn(function()
                while espEnabled do
                    applyHighlights()
                    task.wait(1) -- update every second
                end
                -- cleanup when disabled
                for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
                    if plr.Character and plr.Character:FindFirstChild("ESPHighlight") then
                        plr.Character.ESPHighlight:Destroy()
                    end
                end
            end)
        end
    end
})



-- Colorpicker linked to ESP
VisualSection:Colorpicker({
    Title = "Character Color",
    Desc = "Change highlight color for ESP",
    Default = espColor,
    Callback = function(color)
        espColor = color
        -- update all highlights instantly
        for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("ESPHighlight") then
                plr.Character.ESPHighlight.FillColor = espColor
            end
        end
    end
})
--// Highlight Machine Toggle
local autoHighlight = false

VisualSection:Toggle({
    Title = "Highlight Machines",
    Desc = "even the game will break it 😭",
    Flag = "highlight_machine_toggle",
    Value = false,
    Callback = function(state)
        autoHighlight = state
        if autoHighlight then
            task.spawn(function()
                while autoHighlight do
                    task.wait(1)

                    local interacts = workspace:FindFirstChild("Interacts")
                    if interacts then
                        for _, machine in pairs(interacts:GetChildren()) do
                            if machine:IsA("Model") or machine:IsA("BasePart") then
                                -- Remove existing highlight
                                local oldHighlight = machine:FindFirstChildOfClass("Highlight")
                                if oldHighlight then
                                    oldHighlight:Destroy()
                                end

                                -- Add our highlight
                                local highlight = Instance.new("Highlight")
                                highlight.Name = "AutoHighlight"
                                highlight.FillColor = Color3.fromRGB(0, 255, 0) -- bright green
                                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                highlight.FillTransparency = 0.5
                                highlight.OutlineTransparency = 0
                                highlight.Parent = machine
                            end
                        end
                    end
                end
            end)
        else
            -- Toggle OFF: remove all our highlights
            local interacts = workspace:FindFirstChild("Interacts")
            if interacts then
                for _, machine in pairs(interacts:GetChildren()) do
                    local oldHighlight = machine:FindFirstChild("AutoHighlight")
                    if oldHighlight then
                        oldHighlight:Destroy()
                    end
                end
            end
        end
    end
})
-- Enemy Highlight Toggle (fixed)
-- Adds/removes a named Highlight ("RejectHighlight") on models under workspace.Enemies.
-- Handles enemies added after toggle is enabled and cleans up on disable.

local enemyHighlightEnabled = false
local enemyHighlightConnections = {} -- store connections to disconnect later

local function makeHighlightForEnemy(enemy)
    if not enemy or not enemy.Parent then return end
    -- avoid duplicating
    if enemy:FindFirstChild("RejectHighlight") then return end

    local success, adornee = pcall(function()
        -- Prefer a BasePart or PrimaryPart as the adornee
        if enemy:IsA("BasePart") then
            return enemy
        end
        if enemy.PrimaryPart and enemy.PrimaryPart:IsA("BasePart") then
            return enemy.PrimaryPart
        end
        local part = enemy:FindFirstChildWhichIsA("BasePart", true)
        return part or enemy
    end)

    if not success or not adornee then return end

    local hl = Instance.new("Highlight")
    hl.Name = "RejectHighlight"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Adornee = adornee
    hl.Parent = enemy
end

local function removeHighlightFromEnemy(enemy)
    if not enemy then return end
    local child = enemy:FindFirstChild("RejectHighlight")
    if child and child:IsA("Highlight") then
        child:Destroy()
    end
end

local function enableRejectHighlight()
    if enemyHighlightEnabled then return end
    enemyHighlightEnabled = true

    -- Apply to existing enemies safely
    if workspace:FindFirstChild("Enemies") then
        for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
            pcall(makeHighlightForEnemy, enemy)
        end
    end

    -- Connect to future children added to workspace.Enemies
    if workspace:FindFirstChild("Enemies") then
        local connAdded = workspace.Enemies.ChildAdded:Connect(function(child)
            pcall(makeHighlightForEnemy, child)
        end)
        table.insert(enemyHighlightConnections, connAdded)

        -- Also handle when an enemy is removed (cleanup)
        local connRemoved = workspace.Enemies.ChildRemoved:Connect(function(child)
            pcall(removeHighlightFromEnemy, child)
        end)
        table.insert(enemyHighlightConnections, connRemoved)
    else
        -- If Enemies folder doesn't exist yet, watch workspace for it to appear
        local conn = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Enemies" and child:IsA("Folder") then
                -- apply to any existing children and attach connections
                for _, enemy in ipairs(child:GetChildren()) do
                    pcall(makeHighlightForEnemy, enemy)
                end
                local c1 = child.ChildAdded:Connect(function(ch) pcall(makeHighlightForEnemy, ch) end)
                local c2 = child.ChildRemoved:Connect(function(ch) pcall(removeHighlightFromEnemy, ch) end)
                table.insert(enemyHighlightConnections, c1)
                table.insert(enemyHighlightConnections, c2)
            end
        end)
        table.insert(enemyHighlightConnections, conn)
    end
end

local function disableRejectHighlight()
    if not enemyHighlightEnabled then return end
    enemyHighlightEnabled = false

    -- Disconnect all stored connections
    for _, conn in ipairs(enemyHighlightConnections) do
        pcall(function() conn:Disconnect() end)
    end
    enemyHighlightConnections = {}

    -- Remove highlights named "RejectHighlight" from all enemies
    if workspace:FindFirstChild("Enemies") then
        for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
            pcall(removeHighlightFromEnemy, enemy)
        end
    end
end

-- Hook into your VisualSection toggle
VisualSection:Toggle({
    Title = "Reject Highlight",
    Desc = "You know highlight the Rejects right?",
    Flag = "enemy_highlight_toggle",
    Value = false,
    Callback = function(state)
        if state then
            enableRejectHighlight()
        else
            disableRejectHighlight()
        end
    end
})
--// Custom Highlight Section
local CustomHighlightSection = VisualTab:Section({
    Title = "Custom Highlight",
    Box = false,
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 17,
    Opened = true,
})

-- Input: Name of Object
local objectName = ""
CustomHighlightSection:Input({
    Title = "Name of Object",
    Placeholder = "e.g. HumanoidRootPart",
    Callback = function(value)
        objectName = value
    end
})

-- Input: Object Path (optional)
local objectPath = ""
CustomHighlightSection:Input({
    Title = "Object Path (optional)",
    Placeholder = "e.g. Workspace.Part",
    Callback = function(value)
        objectPath = value
    end
})

-- Toggle: Highlight Object
CustomHighlightSection:Toggle({
    Title = "Highlight Object",
    Flag = "custom_highlight_toggle",
    Value = false,
    Callback = function(state)
        if state then
            local target
            -- If path provided, try to find object by path
            if objectPath ~= "" then
                local success, result = pcall(function()
                    return loadstring("return " .. objectPath)()
                end)
                if success and result then
                    target = result
                end
            end
            -- If no path, try to find by name in Workspace
            if not target and objectName ~= "" then
                target = workspace:FindFirstChild(objectName, true)
            end

            if target then
                if not target:FindFirstChild("CustomHighlight") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "CustomHighlight"
                    highlight.FillColor = Color3.fromRGB(255, 215, 0) -- gold default
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.Parent = target
                end
            else
                WindUI:Notify({
                    Title = "Highlight Error",
                    Content = "Object not found: " .. (objectPath ~= "" and objectPath or objectName),
                    Icon = "solar:info-circle-bold",
                    Duration = 4,
                })
            end
        else
            -- Remove highlight when toggle is off
            local target
            if objectPath ~= "" then
                local success, result = pcall(function()
                    return loadstring("return " .. objectPath)()
                end)
                if success and result then
                    target = result
                end
            end
            if not target and objectName ~= "" then
                target = workspace:FindFirstChild(objectName, true)
            end
            if target and target:FindFirstChild("CustomHighlight") then
                target.CustomHighlight:Destroy()
            end
        end
    end
})

--// Feedback Tab
local FeedbackTab= Window:Tab({
    Title = "Feedback",
    Icon = "mail-check", -- optional
    Locked = false,
})
FeedbackTab:Select()

FeedbackTab:Section({
    Title = "Send Feedback",
    Desc = "Submit feedback directly to Discord webhook",
    Icon = "solar:edit-bold",              -- ✏️ section icon
    IconColor = Color3.fromRGB(255, 0, 0), -- 🔴 red section icon
})

local feedbackText = ""
local lastSent = 0
local player = game.Players.LocalPlayer

FeedbackTab:Input({
    Title = "Your Feedback",
    Placeholder = "Type your feedback here...",
    Icon = "solar:pen-bold",               -- 🖊 input icon
    IconColor = Color3.fromRGB(255, 0, 0), -- 🔴 red input icon
    Callback = function(value)
        feedbackText = value
    end,
})

FeedbackTab:Button({
    Title = "Send Feedback",
    Color = Color3.fromRGB(200, 0, 0),     -- 🔴 red button
    Icon = "solar:send-bold",              -- 📤 send icon
    IconColor = Color3.fromRGB(255, 255, 255), -- ⚪ white icon for contrast
    Callback = function()
        local now = tick()

        -- Cooldown check (10 seconds)
        if now - lastSent < 10 then
            WindUI:Notify({
                Title = "Cooldown",
                Content = "Please wait 10 seconds before sending again.",
                Icon = "alert-triangle",
                Duration = 3,
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        -- Empty check
        if feedbackText == "" then
            WindUI:Notify({
                Title = "Feedback",
                Content = "Please enter some text before sending.",
                Icon = "alert-triangle",
                Duration = 3,
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        -- Block mass mentions
        local lowerText = feedbackText:lower()
        if string.find(lowerText, "@everyone") or string.find(lowerText, "@here") then
            WindUI:Notify({
                Title = "Feedback Error",
                Content = "Mass mentions (@everyone / @here) are not allowed.",
                Icon = "alert-triangle",
                Duration = 4,
                Color = Color3.fromRGB(255, 0, 0),
            })
            return
        end

        local HttpService = game:GetService("HttpService")
        local webhookURL = "https://discord.com/api/webhooks/1467864734257909991/g_6k7MEaAe6YWHkjgAIBOBYaqBQBxNeEGwN2B8Qc4Jdh6eeGyX02nazIPsdGkGs2Qnep"

        local payload = HttpService:JSONEncode({
            content = "**Feedback Submitted**\n"
                .. "Username: " .. player.Name .. "\n"
                .. "Message: \"" .. feedbackText .. "\""
        })

        local req = request or syn and syn.request or http_request
        if req then
            local success, err = pcall(function()
                req({
                    Url = webhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = payload
                })
            end)

            if success then
                WindUI:Notify({
                    Title = "Feedback",
                    Content = "Feedback sent successfully!",
                    Icon = "check",
                    Duration = 3,
                    Color = Color3.fromRGB(0, 200, 0), -- ✅ green success
                })
                feedbackText = ""
                lastSent = tick()
            else
                WindUI:Notify({
                    Title = "Feedback Error",
                    Content = tostring(err),
                    Icon = "alert-triangle",
                    Duration = 4,
                    Color = Color3.fromRGB(255, 0, 0),
                })
            end
        else
            WindUI:Notify({
                Title = "Feedback Error",
                Content = "Your executor does not support HTTP requests.",
                Icon = "alert-triangle",
                Duration = 4,
                Color = Color3.fromRGB(255, 0, 0),
            })
        end
    end,
})
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "solar:folder-with-files-bold",
    IconColor = Color3.fromRGB(255, 180, 0),
    Border = true,
})

local ConfigManager = Window.ConfigManager
local ConfigName = "default"
local myConfig = ConfigManager:CreateConfig(ConfigName)

local ConfigNameInput = SettingsTab:Input({
    Title = "Config Name",
    Icon = "file-cog",
    Callback = function(value)
        ConfigName = value
        myConfig = ConfigManager:CreateConfig(ConfigName)
    end,
})

local function refreshDropdown(dd)
    dd:Refresh(ConfigManager:AllConfigs())
end

local AllConfigsDropdown = SettingsTab:Dropdown({
    Title = "All Configs",
    Values = ConfigManager:AllConfigs(),
    Value = ConfigName,
    Callback = function(value)
        ConfigName = value
        ConfigNameInput:Set(value)
        myConfig = ConfigManager:CreateConfig(ConfigName)
    end,
})

SettingsTab:Button({
    Title = "Save Config",
    Callback = function()
        if myConfig:Save() then
            WindUI:Notify({
                Title = "Settings",
                Content = "Saved '"..ConfigName.."'",
                Icon = "check"
            })
        end
        refreshDropdown(AllConfigsDropdown)
    end,
})

SettingsTab:Button({
    Title = "Load Config",
    Callback = function()
        if myConfig:Load() then
            WindUI:Notify({
                Title = "Settings",
                Content = "Loaded '"..ConfigName.."'",
                Icon = "refresh-cw"
            })
        else
            WindUI:Notify({
                Title = "Settings",
                Content = "Failed to load '"..ConfigName.."'",
                Icon = "alert-triangle"
            })
        end
    end,
})

SettingsTab:Button({
    Title = "Delete Config",
    Color = Color3.fromRGB(255, 80, 80),
    Callback = function()
        if myConfig:Delete() then
            WindUI:Notify({
                Title = "Settings",
                Content = "Deleted '"..ConfigName.."'",
                Icon = "trash"
            })
        end
        refreshDropdown(AllConfigsDropdown)
    end,
})
--// Community Tab
local CommunityTab = Window:Tab({
    Title = "Community",
    Icon = "solar:users-group-rounded-bold",
})

--// Discord Paragraph
local DiscordParagraph = CommunityTab:Paragraph({
    Title = "My Discord",
    Desc = "Join our community and stay connected!\n\nInvite: https://discord.gg/kq6qEp5a3",
    Color = "Red", -- can be "Red", "Orange", "Green", "Blue", "White", "Grey"
    Image = "solar:megaphone-bold", -- optional icon
    ImageSize = 30,
    Thumbnail = "", -- optional thumbnail (rbxassetid://...)
    ThumbnailSize = 80,
    Locked = false,
    Buttons = {
        {
            Icon = "link",
            Title = "Copy Invite",
            Callback = function()
                if setclipboard then
                    setclipboard("https://discord.gg/hJ3rbfEyc")
                    WindUI:Notify({
                        Title = "Community",
                        Content = "Discord invite copied to clipboard!",
                        Icon = "solar:clipboard-bold",
                        Duration = 4,
                    })
                else
                    WindUI:Notify({
                        Title = "Community",
                        Content = "Clipboard not supported.\nInvite: https://discord.gg/hJ3rbfEyc",
                        Icon = "solar:info-square-bold",
                        Duration = 6,
                    })
                end
            end,
        }
    }
})

--// Live Theme Editor in Settings Tab
local currentTheme = {
    Name = "Live Theme",
    Accent = Color3.fromRGB(200, 50, 50),
    Background = Color3.fromRGB(20, 20, 20),
    Outline = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(255, 255, 255),
    Placeholder = Color3.fromRGB(120, 120, 120),
    Button = Color3.fromRGB(50, 50, 50),
    Icon = Color3.fromRGB(160, 160, 160),
}

--// Section inside Settings Tab
local ThemeSection = SettingsTab:Section({
    Title = "Your Theme!",
    Box = false,
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 17, -- optional
    Opened = true,
})

-- Accent Colorpicker
ThemeSection:Colorpicker({
    Title = "Accent Color",
    Desc = "Pick accent color for highlights",
    Default = currentTheme.Accent,
    Callback = function(color)
        currentTheme.Accent = color
        WindUI:AddTheme(currentTheme)
        WindUI:SetTheme("Live Theme")
    end
})

-- Background Colorpicker
ThemeSection:Colorpicker({
    Title = "Background Color",
    Desc = "Pick background color",
    Default = currentTheme.Background,
    Callback = function(color)
        currentTheme.Background = color
        WindUI:AddTheme(currentTheme)
        WindUI:SetTheme("Live Theme")
    end
})

-- Text Colorpicker
ThemeSection:Colorpicker({
    Title = "Text Color",
    Desc = "Pick text color",
    Default = currentTheme.Text,
    Callback = function(color)
        currentTheme.Text = color
        WindUI:AddTheme(currentTheme)
        WindUI:SetTheme("Live Theme")
    end
})

-- Reset Theme Button
ThemeSection:Button({
    Title = "Reset Theme",
    Desc = "Revert back to the default theme",
    Icon = "solar:refresh-bold",
    Callback = function()
        WindUI:SetTheme("Crimson") -- change "Crimson" if your default is different
        WindUI:Notify({
            Title = "Theme Reset",
            Content = "Theme has been reset to default (Crimson).",
            Icon = "solar:palette-bold",
            Duration = 4,
        })
    end
})

-- Auto Use Ability (add to your script where MainTab exists)
-- Toggle will repeatedly activate the HUD AbilityButton when allowed.
-- Behavior:
--  - Checks PlayerGui.GameUI.HUD.BottomRight.AbilityButton.CooldownTime.ContentText
--  - If ContentText == "1" it waits 2 seconds then activates the AbilityButton
--  - After activating, if ContentText is not "1" the loop stops (ability on cooldown)
--  - Uses safe pcall wrappers and restores state on stop

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local _autoAbilityEnabled = false
local _autoAbilityThread = nil

local function notify(title, content, icon)
    pcall(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({ Title = title, Content = content, Icon = icon or "zap", Duration = 3 })
        else
            print("[Notify]", title, content)
        end
    end)
end

local function getAbilityButton()
    local ok, btn = pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then return nil end
        local gameUI = gui:FindFirstChild("GameUI")
        if not gameUI then return nil end
        local hud = gameUI:FindFirstChild("HUD")
        if not hud then return nil end
        local br = hud:FindFirstChild("BottomRight")
        if not br then return nil end
        return br:FindFirstChild("AbilityButton")
    end)
    if ok then return btn end
    return nil
end

local function getCooldownContentText(button)
    if not button then return nil end
    local ok, content = pcall(function()
        local cd = button:FindFirstChild("CooldownTime")
        if not cd then return nil end
        return tostring(cd.ContentText or cd.Text or "")
    end)
    if ok then return content end
    return nil
end

local function safeActivateButton(button)
    if not button then return false end
    local ok = pcall(function()
        -- Prefer Activate if available (fires Activated)
        if typeof(button.Activate) == "function" then
            button:Activate()
        else
            -- fallback: simulate a click by firing MouseButton1Click if present
            if button:IsA("GuiButton") and typeof(button.MouseButton1Click) == "RBXScriptSignal" then
                button.MouseButton1Click:Fire()
            end
        end
    end)
    return ok
end

local function runAutoAbilityLoop(enabledRef, threadRef)
    if threadRef[1] then return end
    threadRef[1] = task.spawn(function()
        while enabledRef[1] do
            local btn = getAbilityButton()
            if not btn then
                task.wait(0.5)
                continue
            end

            local content = getCooldownContentText(btn)
            -- only proceed when ContentText explicitly equals "1"
            if content == "1" then
                -- wait 2 seconds before using ability
                local waited = 0
                while enabledRef[1] and waited < 2 do
                    task.wait(0.1)
                    waited = waited + 0.1
                end
                if not enabledRef[1] then break end

                -- activate ability
                safeActivateButton(btn)
                task.wait(0.12) -- small delay to allow GUI to update

                -- check cooldown after using ability
                local after = getCooldownContentText(btn)
                if after ~= "1" then
                    -- ability is on cooldown; stop looping as requested
                    notify("Auto Ability", "Ability went on cooldown — stopping", "close")
                    enabledRef[1] = false
                    break
                end

                -- if still "1", loop continues and will wait 2s then activate again
            else
                -- if ContentText is not "1" we stop as per spec
                notify("Auto Ability", "Ability not ready (cooldown) — stopping", "close")
                enabledRef[1] = false
                break
            end

            task.wait(0.12)
        end

        threadRef[1] = nil
    end)
end

local function startAutoAbility()
    if _autoAbilityEnabled then return end
    _autoAbilityEnabled = true
    runAutoAbilityLoop({ _autoAbilityEnabled }, { _autoAbilityThread })
    notify("Auto Ability", "Started", "zap")
end

local function stopAutoAbility()
    _autoAbilityEnabled = false
    notify("Auto Ability", "Stopped", "close")
end

-- Add toggle to MainTab
MainTab:Toggle({
    Title = "Auto use ability",
    Desc = "it will freeze you for 5 seconds if you are on mobile",
    Value = false,
    Callback = function(state)
        if state then startAutoAbility() else stopAutoAbility() end
    end
})

-- Auto Collect Stuffing Toggle (Maintab)

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local AutoStuffing = false
local StuffingThread

local function getPart(item)
    if item:IsA("BasePart") then
        return item
    elseif item:IsA("Model") then
        return item:FindFirstChildWhichIsA("BasePart")
    end
end

local function getPrompt(obj)
    return obj:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function tp(cf)
    hrp.CFrame = cf
end

local function startAutoStuffing()
    if StuffingThread then return end

    StuffingThread = task.spawn(function()
        while AutoStuffing do
            local pickup = workspace:FindFirstChild("Pickup")
            local folder = pickup and pickup:FindFirstChild("Stuffing")

            if not folder then
                task.wait(0.25)
                continue
            end

            for _, item in ipairs(folder:GetChildren()) do
                if not AutoStuffing then break end

                local part = getPart(item)
                local prompt = part and getPrompt(item)

                if part and prompt and part.Parent then
                    local originalCF = hrp.CFrame
                    local attempts = 0

                    while AutoStuffing and part.Parent and attempts < 8 do
                        attempts += 1

                        tp(part.CFrame * CFrame.new(0, -2.5, 0))
                        task.wait(0.04)

                        tp(part.CFrame)
                        fireproximityprompt(prompt)
                        task.wait(0.04)
                    end

                    -- return to exact position
                    tp(originalCF)
                    task.wait(0.05)
                end
            end

            task.wait(0.12)
        end
        StuffingThread = nil
    end)
end

-- WindUI Toggle (Maintab)
MainSection:Toggle({
    Title = "Auto Collect Stuffing",
    Desc = "Teleport and collect stuffing automatically",
    Callback = function(state)
        AutoStuffing = state
        if state then
            startAutoStuffing()
        end
    end
})

WindUI:Notify({
    Title = "Announcement",
    Content = "fixed bugs and added new toggles in main tab and player tab",
    Icon = "solar:megaphone-bold",
    Duration = 6, -- seconds the notify stays visible
})
