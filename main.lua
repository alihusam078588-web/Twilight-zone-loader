-- Twilight Zone GUI (Rayfield) - full features
-- Author: Ali_hhjjj | Tester/Helper: GOODJOBS3
-- Special thanks: Olivia (creator of Riddance Hub, WindUI/Rayfield)

-- ===== services & vars =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local tz = {}
local function tzLog(...) pcall(print, "[TZ]", ...) end

-- ===== try load Rayfield (tolerant) =====
local Rayfield = nil
do
    local tried = {
        "https://sirius.menu/rayfield", -- common
        "https://raw.githubusercontent.com/DaHaxor464/Rayfield/main/source.lua", -- fallback example (replace if you have another)
    }
    for _, url in ipairs(tried) do
        local ok, res = pcall(function() return loadstring(game:HttpGet(url))() end)
        if ok and res then
            Rayfield = res
            break
        end
    end
    if not Rayfield then
        warn("[TZ] Could not load Rayfield UI. Replace the Rayfield URL(s) in the script with one that works for you.")
        return
    end
end

-- ===== utilities =====
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart","Root"}
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

-- find ProximityPrompt in model/part
local function findProximityPromptInInstance(inst)
    if not inst then return nil end
    for _,d in ipairs(inst:GetDescendants()) do
        if d and d:IsA("ProximityPrompt") then return d end
    end
    return nil
end

-- ===== gather machines =====
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

-- ===== teleport helpers =====
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

-- ===== ESP =====
local espMachinesOn, espSpiritsOn = false, false
local espMap = {} -- [instance] = highlight

local function createHighlightFor(target, color)
    if not target or not target.Parent then return end
    if espMap[target] and espMap[target].Parent then return end
    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "TZ_HL"
        h.Adornee = target
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.55
        h.Parent = target -- keep highlight near the object
        return h
    end)
    if ok and hl then espMap[target] = hl end
end

local function clearAllHighlights()
    for k,hl in pairs(espMap) do
        pcall(function() hl:Destroy() end)
        espMap[k] = nil
    end
    espMap = {}
end

-- ESP loop
task.spawn(function()
    while true do
        -- machines
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
        -- spirits
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

-- ===== AutoSkill (always attempt to attach) =====
do
    local function tryAttach(remote)
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote.OnClientInvoke = function(...) return 2 end
            elseif remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function() end)
            end
        end)
    end
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            tryAttach(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then
            tryAttach(desc)
        end
    end)
end

-- ===== Godmode (remove HitPlayer parts) =====
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

-- ===== Infinite Stamina (toggle) =====
local staminaFlag = false
local AddStaminaRemote = nil
-- try to locate a stamina-related remote
pcall(function()
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        local n = tostring(v.Name):lower()
        if n:find("stamina") or n:find("addstamina") then
            AddStaminaRemote = v
            break
        end
    end
end)

task.spawn(function()
    while true do
        if staminaFlag and AddStaminaRemote then
            pcall(function()
                -- try firesignal if present (exploit function) or FireServer fallback
                if typeof(AddStaminaRemote) == "Instance" and AddStaminaRemote:IsA("RemoteEvent") then
                    if firesignal then
                        pcall(function() firesignal(AddStaminaRemote.OnClientEvent, 45) end)
                    else
                        pcall(function() AddStaminaRemote:FireServer(45) end)
                    end
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- ===== Auto Elevator (watch message) =====
local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoElevatorFlag then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                local enabled = false
                pcall(function() enabled = msg and msg.Enabled end)
                if enabled then
                    pcall(teleportToElevator)
                    repeat task.wait(1) pcall(function() enabled = msg and msg.Enabled end) until not enabled
                end
            end
        end
        task.wait(1)
    end
end)

-- ===== Auto Teleport to Machine (with aura) + optional auto-elevator when done =====
local autoTeleportToMachineFlag = false
local auraRepeat = 8
local auraDelay = 0.18
local autoElevWhenDoneFlag = true

task.spawn(function()
    while true do
        if autoTeleportToMachineFlag then
            local parts = gatherMachineParts()
            if #parts == 0 then
                tzLog("AutoTP: no machines found.")
                if autoElevWhenDoneFlag then
                    tzLog("AutoTP: teleporting to elevator (autoElevWhenDone enabled).")
                    pcall(teleportToElevator)
                end
            else
                -- choose nearest part (better than random)
                local hrp = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
                local target = parts[math.random(1,#parts)]
                if hrp then
                    local best, bestDist = nil, 9e9
                    for _,p in ipairs(parts) do
                        local success, pos = pcall(function() return p.Position end)
                        if success and pos then
                            local dist = (pos - hrp.Position).Magnitude
                            if dist < bestDist then bestDist, best = dist, p end
                        end
                    end
                    if best then target = best end
                end

                if target and teleportToPart(target) then
                    task.wait(0.2)
                    local model = (target.Parent and target.Parent:IsA("Model")) and target.Parent or target
                    local prompt = findProximityPromptInInstance(model) or findProximityPromptInInstance(target)
                    if prompt then
                        for i=1,auraRepeat do
                            if not autoTeleportToMachineFlag then break end
                            pcall(function()
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                else
                                    -- fallback: try VirtualInputManager to press E
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    task.wait(0.03)
                                    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                end
                            end)
                            task.wait(auraDelay)
                        end
                    else
                        -- fallback to pressing E a few times
                        for i=1,4 do
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
                end
            end
        end
        task.wait(1.6)
    end
end)

-- ===== Player features (speed, godmode, noclip) =====
local playerSpeed = 16
local noclipOn = false
local godmodeOn = true

local function applyPlayerSettingsToCharacter(char)
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        pcall(function() hum.WalkSpeed = playerSpeed end)
        if godmodeOn then
            pcall(function()
                hum.MaxHealth = math.huge
                hum.Health = hum.MaxHealth
            end)
        end
    end
    if noclipOn and char then
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end
end

Players.LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applyPlayerSettingsToCharacter(char)
end)

-- enforce speed/godmode periodically
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then applyPlayerSettingsToCharacter(char) end
        task.wait(0.6)
    end
end)

-- Noclip loop while enabled
task.spawn(function()
    while true do
        if noclipOn and LocalPlayer.Character then
            for _,part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
        task.wait(0.25)
    end
end)

-- ===== UI (Rayfield) - build window & tabs =====
local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {Enabled = false},
})

-- helper: compatibility wrappers (some Rayfield forks have slightly different function names)
local function safeCreateToggle(tab, opts)
    opts = opts or {}
    local ok, _ = pcall(function() tab:CreateToggle(opts) end)
    if not ok then
        -- fallback: simple button acting as toggle
        local state = opts.CurrentValue or false
        tab:CreateButton({Name = opts.Name .. (state and " (ON)" or " (OFF)"), Callback = function()
            state = not state
            if opts.Callback then pcall(opts.Callback, state) end
        end})
    end
end

local function safeCreateButton(tab, opts)
    opts = opts or {}
    local ok, _ = pcall(function() tab:CreateButton(opts) end)
    if not ok then
        tab:CreateButton({Name = opts.Name or "Button", Callback = opts.Callback})
    end
end

local function safeCreateSlider(tab, opts)
    opts = opts or {}
    local ok, _ = pcall(function() tab:CreateSlider(opts) end)
    if not ok then
        -- fallback: button that increments/decrements (basic)
        tab:CreateButton({Name = opts.Name or "Slider (unsupported)", Callback = function() if opts.Callback then opts.Callback(opts.Default or opts.Min or 16) end end})
    end
end

-- === ESP Tab ===
local espTab = Window:CreateTab("ESP")
safeCreateToggle(espTab, {Name = "ESP Machines", CurrentValue = false, Callback = function(val) espMachinesOn = val; if not val then clearAllHighlights() end end})
safeCreateToggle(espTab, {Name = "ESP Spirits", CurrentValue = false, Callback = function(val) espSpiritsOn = val; if not val then clearAllHighlights() end end})

-- === Teleport Tab ===
local tpTab = Window:CreateTab("Teleport")
safeCreateButton(tpTab, {Name = "Teleport: Elevator", Callback = function() pcall(teleportToElevator) tzLog("Teleport to Elevator pressed") end})
safeCreateButton(tpTab, {Name = "Teleport: Random Machine", Callback = function() pcall(teleportToRandomMachine) tzLog("Teleport to random machine pressed") end})
safeCreateToggle(tpTab, {Name = "Auto Teleport To Machine", CurrentValue = false, Callback = function(val) autoTeleportToMachineFlag = val tzLog("AutoTP to machine:", val) end, Description = "Automatically teleport you to machines"})
safeCreateToggle(tpTab, {Name = "Auto Teleport To Elevator (when done)", CurrentValue = true, Callback = function(val) autoElevWhenDoneFlag = val tzLog("AutoTP to elevator when done:", val) end, Description = "Automatically teleport to elevator when all machines done"})
safeCreateToggle(tpTab, {Name = "Auto Elevator (watch message)", CurrentValue = false, Callback = function(val) autoElevatorFlag = val tzLog("Auto Elevator (watch message):", val) end})

-- === Player Tab ===
local playerTab = Window:CreateTab("Player")
safeCreateSlider(playerTab, {Name = "Walk Speed", Min = 16, Max = 250, Default = 16, Flag = "WalkSpeed", Callback = function(v) playerSpeed = v local char = LocalPlayer.Character if char and char:FindFirstChildWhichIsA("Humanoid") then pcall(function() char:FindFirstChildWhichIsA("Humanoid").WalkSpeed = v end) end tzLog("WalkSpeed set to", v) end})
safeCreateToggle(playerTab, {Name = "Godmode (remove hit parts / keep health)", CurrentValue = true, Callback = function(v) godmodeOn = v tzLog("Godmode:", v) end})
safeCreateToggle(playerTab, {Name = "Noclip", CurrentValue = false, Callback = function(v) noclipOn = v tzLog("Noclip:", v) end})
safeCreateToggle(playerTab, {Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v tzLog("Infinite Stamina:", v) end})
-- Auto SkillCheck label (it runs automatically)
do
    local ok, _ = pcall(function() playerTab:CreateLabel("Auto SkillCheck: ACTIVE") end)
    if not ok then
        pcall(function() playerTab:CreateParagraph({Title = "Auto SkillCheck", Content = "ACTIVE"}) end)
    end
end

-- === Auto Farm tab (alternative controls) ===
local farmTab = Window:CreateTab("Auto Farm")
safeCreateToggle(farmTab, {Name = "Auto Farm (TP+Aura)", CurrentValue = false, Callback = function(v) autoTeleportToMachineFlag = v tzLog("AutoFarm (AutoTP+Aura):", v) end})
safeCreateToggle(farmTab, {Name = "Auto Teleport to Elevator (when done)", CurrentValue = autoElevWhenDoneFlag, Callback = function(v) autoElevWhenDoneFlag = v tzLog("AutoElevWhenDone:", v) end})

-- === Credits tab ===
local creditsTab = Window:CreateTab("Credits")
-- try paragraph, then label fallback
pcall(function() creditsTab:CreateParagraph({Title = "Creator", Content = "Ali_hhjjj"}) end)
pcall(function() creditsTab:CreateParagraph({Title = "Tester/Helper", Content = "GOODJOBS3"}) end)
pcall(function() creditsTab:CreateParagraph({Title = "Special thanks", Content = "Olivia (creator of Riddance Hub, WindUI/Rayfield)"}) end)
-- label fallback
pcall(function() creditsTab:CreateLabel("Created by Ali_hhjjj") end)
pcall(function() creditsTab:CreateLabel("Tester/Helper: GOODJOBS3") end)
pcall(function() creditsTab:CreateLabel("Special thanks: Olivia (Riddance Hub)") end)

tzLog("Twilight Zone: UI created. Features: ESP, Teleport, Auto Farm (TP+Aura), Player mods, AutoSkill, Infinite Stamina.")
