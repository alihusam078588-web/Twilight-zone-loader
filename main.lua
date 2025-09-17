-- main.lua
-- Twilight Zone Rayfield-like All-in-One (fixed + Rayfield attempt + fallback)
-- Created by Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special thanks: Thanks to Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving idea to use Rayfield

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "TwilightZone_Raylike_v1"
if PlayerGui:FindFirstChild(GUI_NAME) then
    pcall(function() PlayerGui[GUI_NAME]:Destroy() end)
end

local function TZLog(...) pcall(print, "[TZ]", ...) end

-- =======================
-- Utilities
-- =======================
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    -- prefer "Front" or "front" child (many numbered machines have it)
    local front = model:FindFirstChild("Front") or model:FindFirstChild("front")
    if front and front:IsA("BasePart") then return front end
    local names = {"Head","head","HumanoidRootPart","PrimaryPart","Torso","UpperTorso","LowerTorso"}
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

-- =======================
-- Godmode (always-on) - remove 'HitPlayer' parts
-- =======================
local function startGodmode()
    task.spawn(function()
        while true do
            pcall(function()
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v and v.Name == "HitPlayer" then
                        pcall(function() v:Destroy() end)
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end
startGodmode()

-- =======================
-- Auto SkillCheck (always-on)
-- =======================
local function attachSkill(remote)
    if not remote then return end
    pcall(function()
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...) return 2 end
        elseif remote:IsA("RemoteEvent") then
            -- don't break events; best-effort
            remote.OnClientEvent:Connect(function(...) end)
        end
    end)
end

task.spawn(function()
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            attachSkill(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then
            attachSkill(desc)
        end
    end)
end)

-- =======================
-- Gather Machines (tries Floor.Machines -> Machines -> CurrentRoom -> Workspace)
-- Returns list of BaseParts (preferably 'Front' child)
-- =======================
local function gatherMachineParts()
    local parts = {}
    local candidates = {
        (Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")) or nil,
        Workspace:FindFirstChild("Machines") or nil,
        Workspace:FindFirstChild("CurrentRoom") or nil,
        Workspace
    }
    for _,folder in ipairs(candidates) do
        if folder and folder.GetChildren then
            for _,child in ipairs(folder:GetChildren()) do
                -- If it's a model and not a fuse, prefer giving model's 'Front' or representative part
                if child:IsA("Model") then
                    if not isFuseLike(child.Name) then
                        local rep = findRepresentativePart(child)
                        if rep then table.insert(parts, rep) end
                    end
                elseif child:IsA("BasePart") then
                    if not isFuseLike(child.Name) then
                        table.insert(parts, child)
                    end
                end
            end
        end
    end
    return parts
end

-- =======================
-- Teleport helpers
-- =======================
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

local function teleportToRandomMachine(manual)
    -- manual == true => called by manual button => no aura
    local parts = gatherMachineParts()
    if #parts == 0 then return false end
    local p = parts[ math.random(1,#parts) ]
    if not p then return false end
    local ok = teleportToPart(p)
    return ok
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- =======================
-- ESP (Highlights)
-- =======================
local espMachinesOn, espSpiritsOn = false, false
local espMap = {} -- target -> highlight

local function createHighlightFor(target, color)
    if not target or espMap[target] then return end
    pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "TZ_HL"
        h.Adornee = target
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.55
        h.Parent = target
        espMap[target] = h
    end)
end

local function clearAllHighlights()
    for _,hl in pairs(espMap) do
        pcall(function() hl:Destroy() end)
    end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            local parts = gatherMachineParts()
            for _,p in ipairs(parts) do
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
            for _,c in ipairs(containers) do
                for _,s in ipairs(c:GetChildren()) do
                    if s and not espMap[s] then
                        createHighlightFor(s, Color3.fromRGB(200,0,200))
                    end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then
            clearAllHighlights()
        end
        task.wait(0.9)
    end
end)

-- =======================
-- Infinite stamina remote (best-effort)
-- =======================
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

-- =======================
-- Auto Elevator (watch message)
-- =======================
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

-- =======================
-- Auto Teleport to random machines (with aura when auto on)
-- =======================
local autoTeleportFlag = false
local machineAuraSpamE = true -- aura is active when autoTeleportFlag is true by default

task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then
                local p = parts[ math.random(1,#parts) ]
                if p then
                    teleportToPart(p)
                    if machineAuraSpamE then
                        -- Best-effort aura: try VirtualInputManager (may not be present on all executors)
                        for i=1,6 do
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                if vim then
                                    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    task.wait(0.06)
                                    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                end
                            end)
                            task.wait(0.08)
                        end
                    end
                end
                task.wait(1.5)
            else
                -- no machines -> teleport to elevator automatically
                teleportToElevator()
                task.wait(3)
            end
        end
        task.wait(0.5)
    end
end)

-- =======================
-- Player WalkSpeed (simple number control)
-- =======================
local playerSpeed = 16
local function setSpeed(v)
    playerSpeed = v or 16
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = playerSpeed end
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    setSpeed(playerSpeed)
end)

-- =======================
-- Try to load Rayfield (common raw URL) — fallback to built-in UI
-- You can replace rayfieldUrls with a Rayfield raw URL you trust
-- =======================
local Rayfield = nil
local function tryLoadRayfield()
    local rayfieldUrls = {
        -- Common community locations (may be blocked). If you host Rayfield yourself, place URL first.
        "https://raw.githubusercontent.com/DaGameDevGuy/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/strawhat1212/Rayfield-/main/Rayfield.lua"
    }
    for _,u in ipairs(rayfieldUrls) do
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(u))()
        end)
        if ok and res then
            return res
        end
    end
    return nil
end

local ok, rf = pcall(tryLoadRayfield)
if ok and rf then
    Rayfield = rf
    TZLog("Rayfield loaded.")
else
    TZLog("Rayfield not available — using fallback UI.")
end

-- =======================
-- UI: If Rayfield available, build with it; otherwise fallback to internal UI
-- =======================
local ui = nil

if Rayfield and type(Rayfield) == "table" and Rayfield.CreateWindow then
    -- try to create window using Rayfield's API (typical)
    pcall(function()
        ui = Rayfield:CreateWindow({
            Name = "Twilight Zone",
            LoadingTitle = "Twilight Zone",
            LoadingSubtitle = "by Ali_hhjjj",
            ConfigurationSaving = {
                Enabled = true,
                FolderName = "TZ_Config",
                FileName = "tzconfig"
            }
        })

        -- ESP
        local espTab = ui:CreateTab("ESP")
        espTab:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Flag = "espMachines", Callback = function(val) espMachinesOn = val if not val then clearAllHighlights() end end })
        espTab:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Flag = "espSpirits", Callback = function(val) espSpiritsOn = val if not val then clearAllHighlights() end end })

        -- Teleport
        local tpTab = ui:CreateTab("Teleport")
        tpTab:CreateButton({ Name = "Teleport to Random Machine", Callback = function() teleportToRandomMachine(true) end })
        tpTab:CreateButton({ Name = "Teleport to Elevator", Callback = function() teleportToElevator() end })
        tpTab:CreateLabel({ Name = "Note: Manual teleport does NOT use machine aura. Auto Teleport does." })

        -- Auto Farm
        local autoTab = ui:CreateTab("Auto Farm")
        autoTab:CreateToggle({ Name = "Auto Teleport (machines) [with aura]", CurrentValue = false, Callback = function(val) autoTeleportFlag = val machineAuraSpamE = val end })
        autoTab:CreateToggle({ Name = "Auto Elevator (watch message)", CurrentValue = false, Callback = function(val) autoElevatorFlag = val end })
        autoTab:CreateButton({ Name = "Teleport Now (random machine)", Callback = function() teleportToRandomMachine(true) end })

        -- Player
        local playerTab = ui:CreateTab("Player")
        playerTab:CreateSlider({ Name = "WalkSpeed", Range = {8,250,1}, CurrentValue = 16, Callback = function(v) setSpeed(v) end })
        playerTab:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end })
        -- show always-on labels
        playerTab:CreateLabel({ Name = "Godmode: ENABLED (always-on)" })
        playerTab:CreateLabel({ Name = "Auto SkillCheck: ENABLED (always-on)" })

        -- Credits
        local creditsTab = ui:CreateTab("Credits")
        creditsTab:CreateLabel({ Name = "Creator: Ali_hhjjj" })
        creditsTab:CreateLabel({ Name = "Tester/Helper: GoodJOBS3" })
        creditsTab:CreateLabel({ Name = "Special thanks: Thanks to Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving idea to use Rayfield" })
    end)
else
    -- Fallback UI (built-in minimal window)
    TZLog("Using fallback UI")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = GUI_NAME
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    local toggleBtn = Instance.new("TextButton", screenGui)
    toggleBtn.Size = UDim2.new(0,56,0,56)
    toggleBtn.Position = UDim2.new(0.02,0,0.12,0)
    toggleBtn.Text = "☰"
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1,0)

    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0,420,0,520)
    frame.Position = UDim2.new(0.06,0,0.12,0)
    frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    frame.Visible = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,-16,0,36)
    title.Position = UDim2.new(0,8,0,6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(230,230,230)
    title.Text = "Twilight Zone - Fallback GUI"

    local left = Instance.new("Frame", frame)
    left.Size = UDim2.new(0,160,1,-56)
    left.Position = UDim2.new(0,8,0,48)
    left.BackgroundTransparency = 1
    local tabsList = Instance.new("UIListLayout", left)
    tabsList.SortOrder = Enum.SortOrder.LayoutOrder
    tabsList.Padding = UDim.new(0,8)

    local content = Instance.new("Frame", frame)
    content.Size = UDim2.new(1,-184,1,-56)
    content.Position = UDim2.new(0,176,0,48)
    content.BackgroundColor3 = Color3.fromRGB(28,28,28)
    Instance.new("UICorner", content).CornerRadius = UDim.new(0,8)
    local contentLayout = Instance.new("UIListLayout", content)
    contentLayout.Padding = UDim.new(0,8)

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
        minus.Size = UDim2.new(0,28,0,2
