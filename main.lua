
-- TZ All-in-One (clean, unobfuscated)
-- GUI + ESP (machines/spirits) + Teleport (machine/elevator) + Auto Teleport (with aura) + Auto Elevator (Message) + Godmode + AutoSkill + Infinite Stamina
-- Created by Ali_hhjjj | Tester/Helper: GoodJOBS3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- remove previous GUI if exists
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
                if v and v.Name == "HitPlayer" then v:Destroy() end
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
                if child:IsA("Model") then
                    if not isFuseLike(child.Name) then
                        local rep = findRepresentativePart(child)
                        if rep then table.insert(parts, rep) end
                    end
                elseif child:IsA("BasePart") then
                    if not isFuseLike(child.Name) then table.insert(parts, child) end
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

-- ---------- AutoSkill ----------
do
    local function tryAttachSkillCheck(remote)
        if not remote then return end
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...) return 2 end
        elseif remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...) end)
        end
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

-- ---------- Infinite Stamina (toggle using firesignal) ----------
local staminaFlag = false
local AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")

task.spawn(function()
    while true do
        if staminaFlag then
            pcall(function() firesignal(AddStamina.OnClientEvent, 45) end)
        end
        task.wait(0.2)
    end
end)

-- ---------- Auto Elevator ----------
local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoElevatorFlag then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg and msg.Enabled then
                    teleportToElevator()
                    repeat task.wait(1) until not msg.Enabled
                end
            end
        end
        task.wait(1)
    end
end)

-- ---------- Auto Teleport with Aura + Auto Elevator on completion ----------
local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then
                local target = parts[math.random(1,#parts)]
                if teleportToPart(target) then
                    -- spam E (machine aura)
                    for i=1,6 do
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.1)
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        task.wait(0.1)
                    end
                end
            else
                -- no machines left, go to elevator automatically
                teleportToElevator()
            end
        end
        task.wait(2)
    end
end)

-- ---------- GUI ----------
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name, screenGui.ResetOnSpawn = GUI_NAME, false

local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size, toggleBtn.Position = UDim2.new(0,48,0,48), UDim2.new(0.03,0,0.18,0)
toggleBtn.Text, toggleBtn.TextScaled, toggleBtn.Font = "☰", true, Enum.Font.SourceSansBold
toggleBtn.BackgroundColor3, toggleBtn.TextColor3 = Color3.fromRGB(45,45,45), Color3.fromRGB(255,255,255)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1,0)
toggleBtn.Active = true
toggleBtn.Draggable = true

local frame = Instance.new("Frame", screenGui)
frame.Size, frame.Position = UDim2.new(0,260,0,520), UDim2.new(0.12,0,0.18,0)
frame.BackgroundColor3 = Color3.fromRGB(12,12,12)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
frame.Active, frame.Draggable = true, true

local title = Instance.new("TextLabel", frame)
title.Size, title.Position = UDim2.new(1,-12,0,30), UDim2.new(0,6,0,6)
title.BackgroundTransparency, title.Text = 1, "Twilight Zone Script"
title.Font, title.TextSize, title.TextColor3 = Enum.Font.SourceSansBold, 18, Color3.fromRGB(220,220,220)

local divider = Instance.new("Frame", frame)
divider.Size, divider.Position = UDim2.new(1,-12,0,2), UDim2.new(0,6,0,40)
divider.BackgroundColor3 = Color3.fromRGB(30,30,30)

local y = 48
local function addToggleBtn(label, initial, onToggle)
    local b = Instance.new("TextButton", frame)
    b.Size, b.Position = UDim2.new(1,-16,0,36), UDim2.new(0,8,0,y)
    b.BackgroundColor3 = initial and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
    b.Font, b.TextSize, b.TextColor3 = Enum.Font.SourceSans, 16, Color3.fromRGB(255,255,255)
    b.Text = label .. ": " .. (initial and "ON" or "OFF")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    y = y + 44
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
    b.Size, b.Position = UDim2.new(1,-16,0,36), UDim2.new(0,8,0,y)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.Font, b.TextSize, b.TextColor3 = Enum.Font.SourceSans, 16, Color3.fromRGB(255,255,255)
    b.Text = label
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    y = y + 44
    b.MouseButton1Click:Connect(callback)
    return b
end

local btnESP_Machines = addToggleBtn("ESP Machines", false, function(s) espMachinesOn = s; if not s then clearAllHighlights() end end)
local btnESP_Spirits  = addToggleBtn("ESP Spirits", false, function(s) espSpiritsOn = s; if not s then clearAllHighlights() end end)
local btnTeleportRandom  = addActionBtn("Teleport: Random Machine", teleportToRandomMachine)
local autoTPBtn = addToggleBtn("Auto Teleport (with aura)", false, function(s) autoTeleportFlag = s end)
local btnTeleportElev = addActionBtn("Teleport to Elevator", teleportToElevator)
local autoElevBtn = addToggleBtn("Auto Elevator (watch message)", false, function(s) autoElevatorFlag = s end)
local staminaBtn = addToggleBtn("Infinite Stamina", false, function(s) staminaFlag = s end)

local godLabel = Instance.new("TextLabel", frame)
godLabel.Size, godLabel.Position = UDim2.new(1,-12,0,18), UDim2.new(0,6,1,-120)
godLabel.BackgroundTransparency, godLabel.Text = 1, "Godmode: ENABLED"
godLabel.Font, godLabel.TextSize, godLabel.TextColor3 = Enum.Font.SourceSansBold, 14, Color3.fromRGB(0,255,0)

local skillLabel = Instance.new("TextLabel", frame)
skillLabel.Size, skillLabel.Position = UDim2.new(1,-12,0,18), UDim2.new(0,6,1,-96)
skillLabel.BackgroundTransparency, skillLabel.Text = 1, "Auto SkillCheck: ACTIVE"
skillLabel.Font, skillLabel.TextSize, skillLabel.TextColor3 = Enum.Font.SourceSansBold, 14, Color3.fromRGB(0,255,0)

local testerLabel = Instance.new("TextLabel", frame)
testerLabel.Size, testerLabel.Position = UDim2.new(1,-12,0,18), UDim2.new(0,6,1,-72)
testerLabel.BackgroundTransparency, testerLabel.Text = 1, "Tester/Helper: GoodJOBS3"
testerLabel.Font, testerLabel.TextSize, testerLabel.TextColor3 = Enum.Font.SourceSans, 12, Color3.fromRGB(140,200,255)

local footerLabel = Instance.new("TextLabel", frame)
footerLabel.Size, footerLabel.Position = UDim2.new(1,-12,0,18), UDim2.new(0,6,1,-48)
footerLabel.BackgroundTransparency, footerLabel.Text = 1, "Created by Ali_hhjjj"
footerLabel.Font, footerLabel.TextSize, footerLabel.TextColor3 = Enum.Font.SourceSans, 12, Color3.fromRGB(160,160,160)

toggleBtn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

tzLog("TZ All-in-One loaded with AutoFarm aura + elevator fix.")
