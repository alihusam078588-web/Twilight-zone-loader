-- TZ All-in-One (clean, unobfuscated)
-- GUI + ESP (machines/spirits) + Teleport (random machine / elevator)
-- + Auto Teleport (with aura) + Auto Elevator (watch message)
-- + Godmode (always) + AutoSkill (always) + Infinite Stamina (toggle)
-- Credits: Created by Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special thanks: Olivia (creator of Riddance Hub WindUI)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "TZ_AllInOne_vFinal"
if PlayerGui:FindFirstChild(GUI_NAME) then
    pcall(function() PlayerGui[GUI_NAME]:Destroy() end)
end

local function tzLog(...) pcall(print, "[TZ]", ...) end

-- ---------- UTIL ----------
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart"}
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

-- ---------- GODMODE (remove HitPlayer) ----------
task.spawn(function()
    while true do
        pcall(function()
            for _,v in ipairs(Workspace:GetDescendants()) do
                if v and v.Name and tostring(v.Name):match("^HitPlayer") then
                    pcall(function() v:Destroy() end)
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- ---------- MACHINE GATHER ----------
local function gatherMachineParts()
    local parts = {}
    local candidates = {
        (Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")) or nil,
        Workspace:FindFirstChild("Machines") or nil,
        Workspace:FindFirstChild("CurrentRoom") or nil,
        Workspace
    }
    for _, folder in ipairs(candidates) do
        if folder and folder.GetChildren then
            for _, child in ipairs(folder:GetChildren()) do
                if child and not isFuseLike(child.Name) then
                    if child:IsA("Model") then
                        local rep = findRepresentativePart(child)
                        if rep then table.insert(parts, rep) end
                    elseif child:IsA("BasePart") then
                        table.insert(parts, child)
                    end
                end
            end
        end
    end
    return parts
end

-- ---------- TELEPORT ----------
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0) end)
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
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- ---------- ESP ----------
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

local function createHighlightFor(target, color)
    if not target or not target.Parent then return end
    if espMap[target] then return end
    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "TZ_HL"
        h.Adornee = target
        h.FillColor, h.OutlineColor = color, color
        h.FillTransparency = 0.55
        h.Parent = target
        return h
    end)
    if ok and hl then espMap[target] = hl end
end

local function clearAllHighlights()
    for _, hl in pairs(espMap) do pcall(function() hl:Destroy() end) end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            for _, p in ipairs(gatherMachineParts()) do
                if p and p.Parent and not espMap[p] then
                    if p.Parent:IsA("Model") then
                        createHighlightFor(p.Parent, Color3.fromRGB(0,200,0))
                    else
                        createHighlightFor(p, Color3.fromRGB(0,200,0))
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
                    if s and not espMap[s] then createHighlightFor(s, Color3.fromRGB(200,0,200)) end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then clearAllHighlights() end
        task.wait(0.9)
    end
end)

-- ---------- AutoSkill (always-on) ----------
do
    local function tryAttachSkillCheck(remote)
        if not remote then return end
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote.OnClientInvoke = function(...) return 2 end
            elseif remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function(...) end)
            end
        end)
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            tryAttachSkillCheck(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then
            tryAttachSkillCheck(desc)
        end
    end)
end

-- ---------- Infinite Stamina (toggle) ----------
local staminaFlag = false
local AddStamina
pcall(function()
    AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
end)

task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
            pcall(function() firesignal(AddStamina.OnClientEvent, 45) end)
        end
        task.wait(0.25)
    end
end)

-- ---------- Auto Elevator (watch message) ----------
local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoElevatorFlag then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg then
                    local ok, enabled = pcall(function() return msg.Enabled end)
                    if ok and enabled then
                        pcall(teleportToElevator)
                        repeat task.wait(1) ok, enabled = pcall(function() return msg.Enabled end) until not ok or not enabled
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- ---------- Auto Teleport to Machine (with Aura) + auto-elevator when done ----------
local autoTeleportToMachineFlag = false
local auraDelay = 0.2
local auraRepeat = 8

local function findProximityPromptInModel(model)
    if not model then return nil end
    for _,d in ipairs(model:GetDescendants()) do
        if d and d:IsA("ProximityPrompt") then return d end
    end
    return nil
end

task.spawn(function()
    while true do
        if autoTeleportToMachineFlag then
            local parts = gatherMachineParts()
            if #parts == 0 then
                tzLog("AutoTeleport: no machines found, teleporting to elevator...")
                pcall(teleportToElevator)
                task.wait(1.2)
            else
                local target = parts[math.random(1,#parts)]
                if teleportToPart(target) then
                    task.wait(0.2)
                    -- machine aura: find ProximityPrompt in the model or the part, and fire it multiple times
                    local model = (target.Parent and target.Parent:IsA("Model")) and target.Parent or target
                    local prompt = findProximityPromptInModel(model) or findProximityPromptInModel(target)
                    if prompt then
                        for i=1, auraRepeat do
                            if not autoTeleportToMachineFlag then break end
                            pcall(function() fireproximityprompt(prompt) end)
                            task.wait(auraDelay)
                        end
                    else
                        -- fallback: try to send E key (may not work on all exploits)
                        for i=1, 4 do
                            if not autoTeleportToMachineFlag then break end
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                task.wait(0.05)
                                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                            end)
                            task.wait(0.15)
                        end
                    end
                    task.wait(0.2)
                end
            end
        end
        task.wait(2)
    end
end)

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name, screenGui.ResetOnSpawn = GUI_NAME, false

-- compact toggle button
local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size, toggleBtn.Position = UDim2.new(0,42,0,42), UDim2.new(0.03,0,0.18,0)
toggleBtn.Text, toggleBtn.TextScaled, toggleBtn.Font = "☰", true, Enum.Font.SourceSansBold
toggleBtn.BackgroundColor3, toggleBtn.TextColor3 = Color3.fromRGB(40,40,40), Color3.fromRGB(255,255,255)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1,0)
toggleBtn.Active, toggleBtn.Draggable = true, true

local frame = Instance.new("Frame", screenGui)
frame.Size, frame.Position = UDim2.new(0,220,0,420), UDim2.new(0.12,0,0.18,0)
frame.BackgroundColor3 = Color3.fromRGB(12,12,12)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
frame.Active, frame.Draggable = true, true

local title = Instance.new("TextLabel", frame)
title.Size, title.Position = UDim2.new(1,-10,0,26), UDim2.new(0,6,0,6)
title.BackgroundTransparency, title.Text = 1, "Twilight Zone Script"
title.Font, title.TextSize, title.TextColor3 = Enum.Font.SourceSansBold, 16, Color3.fromRGB(220,220,220)

local y = 44
local function addToggleBtn(label, initial, onToggle)
    local b = Instance.new("TextButton", frame)
    b.Size, b.Position = UDim2.new(1,-12,0,30), UDim2.new(0,6,0,y)
    b.BackgroundColor3 = initial and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
    b.Font, b.TextSize, b.TextColor3 = Enum.Font.SourceSans, 14, Color3.fromRGB(255,255,255)
    b.Text = label .. ": " .. (initial and "ON" or "OFF")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    y = y + 36
    local state = initial
    b.MouseButton1Click:Connect(function()
        state = not state
        b.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
        b.Text = label .. ": " .. (state and "ON" or "OFF")
        onToggle(state)
    end)
    return b
end

local function addActionBtn(label, callback)
    local b = Instance.new("TextButton", frame)
    b.Size, b.Position = UDim2.new(1,-12,0,30), UDim2.new(0,6,0,y)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.Font, b.TextSize, b.TextColor3 = Enum.Font.SourceSans, 14, Color3.fromRGB(255,255,255)
    b.Text = label
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    y = y + 36
    b.MouseButton1Click:Connect(callback)
    return b
end

-- ESP toggles
local btnESP_Machines = addToggleBtn("ESP Machines", false, function(s) espMachinesOn = s; if not s then clearAllHighlights() end end)
local btnESP_Spirits  = addToggleBtn("ESP Spirits", false, function(s) espSpiritsOn = s; if not s then clearAllHighlights() end end)

-- Teleport buttons / toggles
local btnTeleportRandom  = addActionBtn("Teleport: Random Machine", function() pcall(teleportToRandomMachine) end)
local btnTeleportElev = addActionBtn("Teleport: Elevator", function() pcall(teleportToElevator) end)

local autoTPBtn = addToggleBtn("Auto Teleport To Machine", false, function(s) autoTeleportToMachineFlag = s end)
local autoElevWhenDoneToggle = addToggleBtn("Auto Teleport To Elevator (when done)", true, function(s)
    -- This toggle only affects behavior description; actual auto-elevator on no-machines is always executed
    -- kept for user preference / notification only
    tzLog("Auto teleport-to-elevator toggle:", s and "ENABLED" or "DISABLED (note: script still goes to elevator when no machines remain)")
end)

-- Auto Elevator watch message (optional)
local autoElevBtn = addToggleBtn("Auto Elevator (watch message)", false, function(s) autoElevatorFlag = s end)

-- Infinite stamina toggle
local staminaBtn = addToggleBtn("Infinite Stamina", false, function(s) staminaFlag = s end)

-- status labels / credits
local godLabel = Instance.new("TextLabel", frame)
godLabel.Size, godLabel.Position = UDim2.new(1,-12,0,18), UDim2.new(0,6,1,-120)
godLabel.BackgroundTransparency, godLabel.Text = 1, "Godmode: ENABLED"
godLabel.Font, godLabel.TextSize, godLabel.TextColor3 = Enum.Font.SourceSansBold, 13, Color3.fromRGB(0,255,0)

local skillLabel = Instance.new("TextLabel", frame)
skillLabel.Size, skillLabel.Position = UDim2.new(1,-12,0,18), UDim2.new(0,6,1,-100)
skillLabel.BackgroundTransparency, skillLabel.Text = 1, "Auto SkillCheck: ACTIVE"
skillLabel.Font, skillLabel.TextSize, skillLabel.TextColor3 = Enum.Font.SourceSansBold, 13, Color3.fromRGB(0,255,0)

local creditsLabel = Instance.new("TextLabel", frame)
creditsLabel.Size, creditsLabel.Position = UDim2.new(1,-12,0,40), UDim2.new(0,6,1,-72)
creditsLabel.BackgroundTransparency, creditsLabel.Text = 1, "Credits: Ali_hhjjj | Tester: GoodJOBS3 | Special thanks: Olivia"
creditsLabel.Font, creditsLabel.TextSize, creditsLabel.TextColor3 = Enum.Font.SourceSans, 12, Color3.fromRGB(160,160,255)

toggleBtn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

tzLog("TZ All-in-One loaded (ESP+TP+Aura+AutoSkill+Stamina+Godmode).")
