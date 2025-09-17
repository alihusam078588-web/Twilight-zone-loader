-- Load with:
-- loadstring(game:HttpGet("https://pastebin.com/raw/WwFjz0gy"))()

-- TZ Rayfield-like All-in-One v1
-- Features: ESP (machines/spirits), Teleport (random machine/elevator), Auto Teleport (machines + aura), Auto Elevator,
-- Godmode (always-on), Auto SkillCheck (always-on), Infinite Stamina, Player speed/noclip
-- Created by Ali_hhjjj | Tester/Helper: GoodJOBS3 | Thanks Olivia

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Kill any previous GUI to avoid duplicates
local GUI_NAME = "TZ_Rayfield_AllInOne_v1"
if PlayerGui:FindFirstChild(GUI_NAME) then
    pcall(function() PlayerGui[GUI_NAME]:Destroy() end)
end

local function tzLog(...) pcall(print, "[TZ]", ...) end

-- ---------- Utility ----------
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart","Torso","UpperTorso","LowerTorso"}
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

-- ---------- GODMODE (always-on) ----------
local function enableGodmodeLoop()
    task.spawn(function()
        while true do
            pcall(function()
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v and v.Name == "HitPlayer" then
                        v:Destroy()
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end
-- start godmode immediately
enableGodmodeLoop()

-- ---------- AutoSkill (always-on) ----------
local function tryAttachSkillCheck(remote)
    if not remote then return end
    if remote:IsA("RemoteFunction") then
        pcall(function() remote.OnClientInvoke = function(...) return 2 end end)
    elseif remote:IsA("RemoteEvent") then
        pcall(function() remote.OnClientEvent:Connect(function(...) end) end)
    end
end

task.spawn(function()
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
end)

-- ---------- Gather machine parts ----------
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

-- ---------- Teleport helpers ----------
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
    end)
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
    if not target or espMap[target] then return end
    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "TZ_HL"
        h.Adornee = target
        h.FillColor = color
        h.OutlineColor = color
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

-- ---------- Infinite Stamina ----------
local staminaFlag = false
local AddStamina = nil
pcall(function()
    AddStamina = ReplicatedStorage:WaitForChild("Remotes", 1):WaitForChild("Gameplay", 1):WaitForChild("AddStamina", 1)
end)
task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
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

-- ---------- Auto Teleport (machines) ----------
-- autoTeleportFlag controls continuous teleporting to random machines.
-- When machines run out it will teleport to elevator automatically (even if Teleport->Elevator button is off).
local autoTeleportFlag = false
local machineAuraSpamE = true -- machine aura when teleporting (spams E). Controlled by Auto Teleport toggle (enabled when auto on).
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then
                local p = parts[math.random(1,#parts)]
                if p then
                    teleportToPart(p)
                    -- if aura enabled, spam E a few times (no notifications)
                    if machineAuraSpamE then
                        for i=1,6 do
                            pcall(function()
                                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                task.wait(0.08)
                                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                            end)
                            task.wait(0.08)
                        end
                    end
                end
                task.wait(1.5)
            else
                -- no machines left -> teleport to elevator automatically
                teleportToElevator()
                -- wait a bit before checking again
                task.wait(3)
            end
        end
        task.wait(0.5)
    end
end)

-- ---------- Player movement & noclip ----------
local playerSpeed = 16
local noclipEnabled = false
local noclipConn = nil

local function setSpeed(v)
    playerSpeed = v or 16
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.WalkSpeed = playerSpeed end) end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    setSpeed(playerSpeed)
end)

local function enableNoclip(on)
    noclipEnabled = on
    if on then
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        pcall(function() part.CanCollide = false end)
                    end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
            end
        end
    end
end

-- ---------- GUI (Rayfield-like minimal) ----------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- toggle button
local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size = UDim2.new(0,56,0,56)
toggleBtn.Position = UDim2.new(0.02,0,0.12,0)
toggleBtn.Text = "☰"
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggleBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1,0)

-- main frame
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,420,0,520)
frame.Position = UDim2.new(0.06,0,0.12,0)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.Visible = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-16,0,36)
title.Position = UDim2.new(0,8,0,6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(230,230,230)
title.Text = "Twilight Zone - Raylike GUI"

-- left tabs
local left = Instance.new("Frame", frame)
left.Size = UDim2.new(0,160,1,-56)
left.Position = UDim2.new(0,8,0,48)
left.BackgroundTransparency = 1
local tabsList = Instance.new("UIListLayout", left)
tabsList.SortOrder = Enum.SortOrder.LayoutOrder
tabsList.Padding = UDim.new(0,8)

-- content area
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1,-184,1,-56)
content.Position = UDim2.new(0,176,0,48)
content.BackgroundColor3 = Color3.fromRGB(28,28,28)
Instance.new("UICorner", content).CornerRadius = UDim.new(0,8)
local contentLayout = Instance.new("UIListLayout", content)
contentLayout.Padding = UDim.new(0,8)

-- tab factory
local tabButtons = {}
local function createTab(name)
    local tb = Instance.new("TextButton", left)
    tb.Size = UDim2.new(1,0,0,40)
    tb.BackgroundColor3 = Color3.fromRGB(40,40,40)
    tb.Font = Enum.Font.SourceSans
    tb.TextSize = 18
    tb.TextColor3 = Color3.fromRGB(230,230,230)
    tb.Text = "  "..name
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,8)

    local page = Instance.new("Frame", content)
    page.Size = UDim2.new(1,-16,0,0)
    page.Position = UDim2.new(0,8,0,0)
    page.BackgroundTransparency = 1
    page.Visible = false
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0,8)

    tb.MouseButton1Click:Connect(function()
        for _,t in pairs(tabButtons) do
            t.button.BackgroundColor3 = Color3.fromRGB(40,40,40)
            t.page.Visible = false
        end
        tb.BackgroundColor3 = Color3.fromRGB(70,70,70)
        page.Visible = true
    end)

    table.insert(tabButtons, {button = tb, page = page})
    if #tabButtons == 1 then
        tb.BackgroundColor3 = Color3.fromRGB(70,70,70)
        page.Visible = true
    end
    return page
end

local function makeToggle(page, label, initial, callback)
    local b = Instance.new("TextButton", page)
    b.Size = UDim2.new(1,0,0,36)
    b.BackgroundColor3 = initial and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 16
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Text = label..": "..(initial and "ON" or "OFF")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    local state = initial
    b.MouseButton1Click:Connect(function()
        state = not state
        b.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
        b.Text = label..": "..(state and "ON" or "OFF")
        pcall(callback, state)
    end)
    return b
end

local function makeButton(page, label, callback)
    local b = Instance.new("TextButton", page)
    b.Size = UDim2.new(1,0,0,36)
    b.BackgroundColor3 = Color3.fromRGB(70,70,70)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 16
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Text = label
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.MouseButton1Click:Connect(function() pcall(callback) end)
    return b
end

local function makeNumberControl(page, label, min, max, default, onChange)
    local container = Instance.new("Frame", page)
    container.Size = UDim2.new(1,0,0,44)
    container.BackgroundTransparency = 1

    local lab = Instance.new("TextLabel", container)
    lab.Size = UDim2.new(0.6,0,1,0)
    lab.BackgroundTransparency = 1
    lab.Font = Enum.Font.SourceSans
    lab.TextSize = 14
    lab.TextColor3 = Color3.fromRGB(230,230,230)
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Text = label..": "..tostring(default)

    local minus = Instance.new("TextButton", container)
    minus.Size = UDim2.new(0,28,0,28)
    minus.Position = UDim2.new(0.6,8,0.5,-14)
    minus.Text = "-"
    minus.Font = Enum.Font.SourceSansBold
    minus.TextSize = 18
    minus.BackgroundColor3 = Color3.fromRGB(100,100,100)
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0,6)

    local plus = Instance.new("TextButton", container)
    plus.Size = UDim2.new(0,28,0,28)
    plus.Position = UDim2.new(1,-36,0.5,-14)
    plus.AnchorPoint = Vector2.new(1,0)
    plus.Text = "+"
    plus.Font = Enum.Font.SourceSansBold
    plus.TextSize = 18
    plus.BackgroundColor3 = Color3.fromRGB(100,100,100)
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0,6)

    local val = default
    local valLabel = Instance.new("TextLabel", container)
    valLabel.Size = UDim2.new(0,60,0,20)
    valLabel.Position = UDim2.new(1,-110,0.5,-10)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.SourceSans
    valLabel.TextSize = 14
    valLabel.TextColor3 = Color3.fromRGB(230,230,230)
    valLabel.Text = tostring(val)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    minus.MouseButton1Click:Connect(function()
        val = math.max(min, val - 1)
        lab.Text = label..": "..tostring(val)
        valLabel.Text = tostring(val)
        pcall(onChange, val)
    end)
    plus.MouseButton1Click:Connect(function()
        val = math.min(max, val + 1)
        lab.Text = label..": "..tostring(val)
        valLabel.Text = tostring(val)
        pcall(onChange, val)
    end)

    return container
end

-- Create tabs and controls
local pageESP = createTab("ESP")
makeToggle(pageESP, "ESP Machines", false, function(s) espMachinesOn = s if not s then clearAllHighlights() end end)
makeToggle(pageESP, "ESP Spirits", false, function(s) espSpiritsOn = s if not s then clearAllHighlights() end end)

local pageTP = createTab("Teleport")
-- Teleport to Random Machine with a small description label about aura (non-notifying)
local btnTeleportRandom = makeButton(pageTP, "Teleport to Random Machine (uses machine aura)", function()
    teleportToRandomMachine()
    -- short aura spam when manual teleported
    for i=1,6 do
        pcall(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.08)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        task.wait(0.08)
    end
end)
local descLabel = Instance.new("TextLabel", pageTP)
descLabel.Size = UDim2.new(1,0,0,24)
descLabel.BackgroundTransparency = 1
descLabel.Font = Enum.Font.SourceSans
descLabel.TextSize = 12
descLabel.TextColor3 = Color3.fromRGB(180,180,180)
descLabel.Text = "Machine Aura: Teleport->Random will spam E to trigger machines (no popup/notification)."

makeButton(pageTP, "Teleport to Elevator", teleportToElevator)

local pageAuto = createTab("Auto Farm")
makeToggle(pageAuto, "Auto Teleport to Machine (with aura)", false, function(s) autoTeleportFlag = s machineAuraSpamE = s end)
makeToggle(pageAuto, "Auto Teleport to Elevator (when message appears)", false, function(s) autoElevatorFlag = s end)
makeButton(pageAuto, "Teleport Now (random machine)", teleportToRandomMachine)

local pagePlayer = createTab("Player")
local speedControl = makeNumberControl(pagePlayer, "WalkSpeed", 8, 250, 16, function(v) setSpeed(v) end)
makeToggle(pagePlayer, "Noclip", false, function(s) enableNoclip(s) end)
makeToggle(pagePlayer, "Infinite Stamina", false, function(s) staminaFlag = s end)

-- Godmode & SkillCheck labels (always-on)
local godLabel = Instance.new("TextLabel", pagePlayer)
godLabel.Size = UDim2.new(1,0,0,24)
godLabel.BackgroundTransparency = 1
godLabel.Font = Enum.Font.SourceSansBold
godLabel.TextSize = 14
godLabel.TextColor3 = Color3.fromRGB(0,255,0)
godLabel.Text = "Godmode: ENABLED (always-on)"

local skillLabel = Instance.new("TextLabel", pagePlayer)
skillLabel.Size = UDim2.new(1,0,0,24)
skillLabel.BackgroundTransparency = 1
skillLabel.Font = Enum.Font.SourceSansBold
skillLabel.TextSize = 14
skillLabel.TextColor3 = Color3.fromRGB(0,255,0)
skillLabel.Text = "Auto SkillCheck: ENABLED (always-on)"

local pageCredits = createTab("Credits")
local creditLabel = Instance.new("TextLabel
