-- Twilight Zone (WindUI) — Full Script (Keyless)
-- Uses WindUI loader: local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
-- Keeps features: Godmode, AutoSkill, ESP (Machines/Spirits), Teleports, Auto Teleport/Elevator, Infinite Stamina,
-- WalkSpeed, Noclip (fixed), Startup notification ("TZ Script 💫 Godmode and Auto Skillcheck is ACTIVE!")

-- ===== Services =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ===== Utility =====
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart"}
    for _, n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then return f end
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

-- ===== Godmode: Remove HitPlayer =====
task.spawn(function()
    while true do
        pcall(function()
            local floor = Workspace:FindFirstChild("Floor")
            if floor and floor:FindFirstChild("Spirits") then
                for _, folder in ipairs(floor.Spirits:GetChildren()) do
                    for _, v in ipairs(folder:GetChildren()) do
                        if v and v.Name == "HitPlayer" then
                            pcall(function() v:Destroy() end)
                        end
                    end
                end
            end
        end)
        task.wait(0.6)
    end
end)

-- ===== Machines gathering (robust) =====
local function findMachinesFolders()
    local folders = {}

    if Workspace:FindFirstChild("Machines") then
        table.insert(folders, Workspace.Machines)
    end

    if Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
                table.insert(folders, obj)
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
            table.insert(folders, obj)
        end
    end

    local seen = {}
    local unique = {}
    for _, f in ipairs(folders) do
        if f and not seen[f] then
            seen[f] = true
            table.insert(unique, f)
        end
    end
    return unique
end

local function gatherMachineParts()
    local parts = {}
    local folders = findMachinesFolders()
    for _, machinesFolder in ipairs(folders) do
        for _, machine in ipairs(machinesFolder:GetChildren()) do
            if machine and machine:IsA("Model") and not isFuseLike(machine.Name) then
                local rep = findRepresentativePart(machine) or machine
                if rep then table.insert(parts, rep) end
            end
        end
    end

    if #parts == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj and obj:IsA("Model") and not isFuseLike(obj.Name) then
                if tostring(obj.Name):lower():find("machine") then
                    local rep = findRepresentativePart(obj) or obj
                    table.insert(parts, rep)
                end
            end
        end
    end

    if #parts == 0 and Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            if obj and obj:IsA("Model") and not isFuseLike(obj.Name) then
                local rep = findRepresentativePart(obj)
                if rep and (tostring(obj.Name):lower():find("machine") or rep.Name:lower():find("machine")) then
                    table.insert(parts, rep)
                end
            end
        end
    end

    return parts
end

local function findNearestMachinePart()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local parts = gatherMachineParts()
    if #parts == 0 then return nil end
    table.sort(parts, function(a,b)
        return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
    end)
    return parts[1]
end

-- ===== Teleports =====
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

local function teleportToNearestMachine()
    local p = findNearestMachinePart()
    if not p then return false end
    return teleportToPart(p)
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- ===== ESP =====
local espMachinesOn, espSpiritsOn = false, false
local espMap = {} -- model -> highlight

local function createHighlightForModel(model, color)
    if not model or not model.Parent then return end
    if espMap[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "TZ_HL"
    hl.Adornee = model
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.55
    hl.Parent = workspace
    espMap[model] = hl
end

local function clearAllHighlights()
    for model, hl in pairs(espMap) do
        pcall(function() if hl then hl:Destroy() end end)
    end
    espMap = {}
end

local function cleanupDeadHighlights()
    for model, hl in pairs(espMap) do
        if not model or not model.Parent then
            pcall(function() if hl then hl:Destroy() end end)
            espMap[model] = nil
        end
    end
end

task.spawn(function()
    while true do
        cleanupDeadHighlights()

        if espMachinesOn then
            local parts = gatherMachineParts()
            for _, rep in ipairs(parts) do
                local model = (rep and rep:IsA("BasePart") and rep.Parent) or rep
                if model and model:IsA("Model") and not espMap[model] then
                    createHighlightForModel(model, Color3.fromRGB(0,200,0))
                end
            end
        end

        if espSpiritsOn then
            local foundSpiritFolders = {}
            if Workspace:FindFirstChild("Floor") then
                for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
                    if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then
                        table.insert(foundSpiritFolders, obj)
                    end
                end
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then
                    table.insert(foundSpiritFolders, obj)
                end
            end
            local seen = {}
            for _, folder in ipairs(foundSpiritFolders) do
                if folder and not seen[folder] then
                    seen[folder] = true
                    for _, spirit in ipairs(folder:GetChildren()) do
                        if spirit and spirit:IsA("Model") and not espMap[spirit] then
                            createHighlightForModel(spirit, Color3.fromRGB(200,0,200))
                        end
                    end
                end
            end
        end

        if not espMachinesOn and not espSpiritsOn then
            clearAllHighlights()
        end

        task.wait(1)
    end
end)

-- ===== AutoSkill =====
do
    local function tryAttachSkillCheck(remote)
        if not remote then return end
        if remote:IsA("RemoteFunction") then
            pcall(function() remote.OnClientInvoke = function() return 2 end end)
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

-- ===== Infinite Stamina =====
local staminaFlag = false
local AddStamina = nil
pcall(function()
    if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Gameplay") then
        AddStamina = ReplicatedStorage.Remotes.Gameplay:FindFirstChild("AddStamina")
    end
end)

task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
            pcall(function()
                if typeof(firesignal) == "function" then
                    firesignal(AddStamina.OnClientEvent, 45)
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- ===== Auto Elevator =====
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

-- ===== Auto Teleport =====
local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then
                teleportToPart(parts[math.random(1,#parts)])
            end
        end
        task.wait(3)
    end
end)

-- ===== Player controls (WalkSpeed & Noclip) =====
local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
local walkspeed = 16
if Humanoid and Humanoid.Parent then
    pcall(function() walkspeed = Humanoid.WalkSpeed or 16 end)
end

local noclip = false
local noclipConnection = nil

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclip then return end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        pcall(function() noclipConnection:Disconnect() end)
        noclipConnection = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = true end)
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Humanoid = char:WaitForChild("Humanoid")
    task.wait(0.2)
    pcall(function() Humanoid.WalkSpeed = walkspeed end)
    if noclip then enableNoclip() else disableNoclip() end
end)

-- ===== WindUI Loading =====
local WindUI, Window
local ok, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if ok and WindUI and type(WindUI.CreateWindow) == "function" then
    local successCreate, w = pcall(function()
        return WindUI:CreateWindow({
            Title = "Twilight Zone Hub",
            Icon = "door-open",
            Author = "by Ali_hhjjj",
            Folder = "TwilightZoneHub",
            Size = UDim2.fromOffset(680, 460),
            MinSize = Vector2.new(560, 350),
            MaxSize = Vector2.new(900, 640),
            Transparent = true,
            Theme = "Dark",
            Resizable = true,
            SideBarWidth = 200,
            BackgroundImageTransparency = 0.42,
            HideSearchBar = true,
            ScrollBarEnabled = false,
            User = { Enabled = false },
            KeySystem = false
        })
    end)
    if successCreate and w then
        Window = w
    else
        Window = nil
    end
else
    Window = nil
end

-- ===== Fallback GUI creation (if WindUI failed) =====
local fallback = false
if not Window then
    fallback = true
    -- build a minimal UI similar to earlier fallback (simple ScreenGui)
    -- Remove old UI
    if CoreGui:FindFirstChild("TZ_UI") then
        pcall(function() CoreGui.TZ_UI:Destroy() end)
    end
    local screen = Instance.new("ScreenGui")
    screen.Name = "TZ_UI"
    screen.Parent = CoreGui
    screen.ResetOnSpawn = false

    local windowFrame = Instance.new("Frame")
    windowFrame.Name = "Window"
    windowFrame.Size = UDim2.new(0,480,0,360)
    windowFrame.Position = UDim2.new(0.5,-240,0.5,-180)
    windowFrame.AnchorPoint = Vector2.new(0.5,0.5)
    windowFrame.BackgroundColor3 = Color3.fromRGB(25,25,30)
    windowFrame.BorderSizePixel = 0
    windowFrame.Parent = screen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,28)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundColor3 = Color3.fromRGB(20,20,24)
    title.BorderSizePixel = 0
    title.TextColor3 = Color3.fromRGB(230,230,230)
    title.Text = "Twilight Zone Hub — TZ Script"
    title.Font = Enum.Font.SourceSansSemibold
    title.TextSize = 18
    title.Parent = windowFrame

    -- simple tab system: we'll reuse previously-safe UI helper creators
    local tabbar = Instance.new("Frame")
    tabbar.Size = UDim2.new(1,0,0,36)
    tabbar.Position = UDim2.new(0,0,0,28)
    tabbar.BackgroundTransparency = 1
    tabbar.Parent = windowFrame

    local function makeTabButton(name, x)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,115,0,28)
        btn.Position = UDim2.new(0,x,0,4)
        btn.Text = name
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(40,40,46)
        btn.TextColor3 = Color3.fromRGB(220,220,220)
        btn.BorderSizePixel = 0
        btn.Parent = tabbar
        return btn
    end

    local tabMainBtn = makeTabButton("Main", 8)
    local tabVisualsBtn = makeTabButton("Visuals", 125)
    local tabPlayerBtn = makeTabButton("Player", 242)
    local tabInfoBtn = makeTabButton("Info", 359)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-10,1,-74)
    content.Position = UDim2.new(0,5,0,70)
    content.BackgroundTransparency = 1
    content.Parent = windowFrame

    local function makeContentFrame()
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,0,1,0)
        f.BackgroundTransparency = 1
        f.Parent = content
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0,6)
        layout.Parent = f
        return f
    end

    local mainFrame = makeContentFrame()
    local visualsFrame = makeContentFrame(); visualsFrame.Visible = false
    local playerFrame = makeContentFrame(); playerFrame.Visible = false
    local infoFrame = makeContentFrame(); infoFrame.Visible = false

    local function showTab(frame)
        mainFrame.Visible = false
        visualsFrame.Visible = false
        playerFrame.Visible = false
        infoFrame.Visible = false
        frame.Visible = true
    end

    tabMainBtn.MouseButton1Click:Connect(function() showTab(mainFrame) end)
    tabVisualsBtn.MouseButton1Click:Connect(function() showTab(visualsFrame) end)
    tabPlayerBtn.MouseButton1Click:Connect(function() showTab(playerFrame) end)
    tabInfoBtn.MouseButton1Click:Connect(function() showTab(infoFrame) end)

    -- UI helper functions for fallback (same as earlier safe helpers)
    local function addLabel(parent, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Text = text or ""
        lbl.TextColor3 = Color3.fromRGB(230,230,230)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 14
        lbl.Parent = parent
        return lbl
    end

    local function addButton(parent, text, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -10, 0, 30)
        b.BackgroundColor3 = Color3.fromRGB(58,58,64)
        b.BorderSizePixel = 0
        b.TextColor3 = Color3.fromRGB(235,235,235)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 14
        b.Text = text or "Button"
        b.Parent = parent
        b.MouseButton1Click:Connect(function() pcall(cb) end)
        return b
    end

    local function addToggle(parent, name, initial, cb)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 30)
        container.BackgroundTransparency = 1
        container.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(230,230,230)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.Parent = container

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.28, 0, 0.9, 0)
        btn.Position = UDim2.new(0.72, 0, 0.05, 0)
        btn.BackgroundColor3 = initial and Color3.fromRGB(0,150,0) or Color3.fromRGB(120,120,120)
        btn.BorderSizePixel = 0
        btn.Text = initial and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 13
        btn.Parent = container

        local state = initial or false
        btn.MouseButton1Click:Connect(function()
            state = not state
            pcall(function() cb(state) end)
            btn.BackgroundColor3 = state and Color3.fromRGB(0,150,0) or Color3.fromRGB(120,120,120)
            btn.Text = state and "ON" or "OFF"
        end)
        return container
    end

    local function addSlider(parent, name, minVal, maxVal, step, initial, cb)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 32)
        container.BackgroundTransparency = 1
        container.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.55, 
