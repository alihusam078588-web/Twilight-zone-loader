-- Twilight Zone (Rayfield) - main.lua
-- Features: ESP (machines/spirits), Teleports (random/elevator), Auto Teleport (with aura),
-- Auto-Elevator when done, AutoSkill, Infinite Stamina, Godmode, Noclip, Speed slider
-- Credits: Created by Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special thanks: Olivia (creator of Riddance Hub / Rayfield window)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- GUI name (for fallback simple GUI)
local GUI_NAME = "TZ_Rayfield_GUI_v1"

-- Utility
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

-- cleanup previous GUI if any
pcall(function()
    if PlayerGui:FindFirstChild(GUI_NAME) then PlayerGui:FindFirstChild(GUI_NAME):Destroy() end
end)

local function tzLog(...) pcall(print, "[TZ]", ...) end

-- ========== CORE GAME LOGIC ==========

-- GODMODE (removes HitPlayer parts) - controlled by godmodeFlag
local godmodeFlag = true
task.spawn(function()
    while true do
        if godmodeFlag then
            pcall(function()
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v and v.Name == "HitPlayer" then
                        pcall(function() v:Destroy() end)
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Gather potential machine parts
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

-- find ProximityPrompt in model/part
local function findProximityPromptInModel(model)
    if not model then return nil end
    for _,d in ipairs(model:GetDescendants()) do
        if d and d:IsA("ProximityPrompt") then return d end
    end
    return nil
end

local function tryFireProximity(prompt)
    if not prompt then return false end
    -- first try exploit helper
    local ok = pcall(function() fireproximityprompt(prompt) end)
    if ok then return true end
    -- try :InputHoldBegin/End if available (some custom UIs)
    pcall(function()
        if typeof(prompt.InputHoldBegin) == "function" then
            prompt:InputHoldBegin()
            task.wait(0.1)
            if typeof(prompt.InputHoldEnd) == "function" then prompt:InputHoldEnd() end
        end
    end)
    -- fallback: send E key (some exploits support VirtualInputManager)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    return true
end

-- ========== BEHAVIOR FLAGS ==========
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

local AddStaminaRemote = nil
pcall(function()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if r and r:FindFirstChild("Gameplay") and r.Gameplay:FindFirstChild("AddStamina") then
        AddStaminaRemote = r.Gameplay.AddStamina
    end
end)

local staminaFlag = false
local autoTeleportFlag = false
local autoTeleportElevWhenDone = true -- default true (user can toggle later)
local autoElevatorFlag = false -- watch elevator message
local autoSkillFlag = true
local noclipFlag = false
local walkSpeedValue = 16

-- ---------- ESP LOOP ----------
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

-- ---------- AutoSkill (attach to remotes named 'skill') ----------
local function tryAttachSkillCheck(remote)
    if not remote then return end
    pcall(function()
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...) return 2 end
        elseif remote:IsA("RemoteEvent") then
            -- nothing to do, but keep connected to avoid errors
            remote.OnClientEvent:Connect(function(...) end)
        end
    end)
end

task.spawn(function()
    while true do
        if autoSkillFlag then
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
                    tryAttachSkillCheck(v)
                end
            end
        end
        task.wait(1.5)
    end
end)

-- ---------- Infinite Stamina ----------
task.spawn(function()
    while true do
        if staminaFlag and AddStaminaRemote then
            pcall(function()
                -- prefer firesignal if available
                if typeof(firesignal) == "function" then
                    firesignal(AddStaminaRemote.OnClientEvent, 45)
                else
                    -- best-effort: fire OnClientEvent manually (may not work on all exploits)
                    pcall(function() AddStaminaRemote:FireClient(LocalPlayer, 45) end)
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- ---------- Auto Elevator (watch message) ----------
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

-- ---------- Auto Teleport to machine (with aura) + optional auto-elevator when done ----------
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts == 0 then
                if autoTeleportElevWhenDone then
                    tzLog("AutoTeleport: no machines found, teleporting to elevator...")
                    pcall(teleportToElevator)
                end
                task.wait(2)
            else
                local target = parts[math.random(1,#parts)]
                if teleportToPart(target) then
                    task.wait(0.25)
                    -- try to find proximity prompt and fire
                    local model = (target.Parent and target.Parent:IsA("Model")) and target.Parent or target
                    local prompt = findProximityPromptInModel(model) or findProximityPromptInModel(target)
                    if prompt then
                        for i=1,8 do
                            if not autoTeleportFlag then break end
                            pcall(function() tryFireProximity(prompt) end)
                            task.wait(0.18)
                        end
                    else
                        -- fallback: try E press to interact
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            for i=1,4 do
                                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                task.wait(0.06)
                                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                task.wait(0.12)
                            end
                        end)
                    end
                end
                task.wait(1.2)
            end
        end
        task.wait(1.2)
    end
end)

-- ========== Player utilities: noclip, speed, godmode toggles ==========
-- Noclip loop (applies to character parts)
task.spawn(function()
    while true do
        if noclipFlag then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        pcall(function() part.CanCollide = false end)
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)

-- Keep speed and humanoid maintained
local function applyWalkSpeed(v)
    local c = LocalPlayer.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.WalkSpeed = v end)
    end
end

Players.PlayerAdded:Connect(function() end) -- placeholder to avoid some analyzers

LocalPlayer.CharacterAdded:Connect(function(character)
    -- reapply speed and noclip quickly when character spawns
    task.wait(0.5)
    applyWalkSpeed(walkSpeedValue)
    if noclipFlag then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                pcall(function() part.CanCollide = false end)
            end
        end
    end
end)

-- ========== UI (Rayfield preferred, fallback to basic ScreenGui) ==========
local function createFallbackGui()
    local sg = Instance.new("ScreenGui", PlayerGui)
    sg.Name = GUI_NAME
    local f = Instance.new("Frame", sg)
    f.Position = UDim2.new(0.05,0,0.18,0)
    f.Size = UDim2.new(0,260,0,420)
    f.BackgroundColor3 = Color3.fromRGB(20,20,20)
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -10, 0, 28)
    t.Position = UDim2.new(0,6,0,6)
    t.BackgroundTransparency = 1
    t.Text = "Twilight Zone (fallback GUI)"
    t.TextColor3 = Color3.fromRGB(220,220,220)
    t.Font = Enum.Font.SourceSansBold
    t.TextSize = 18
    -- minimal buttons for quick testing (teleports & toggles)
    local b1 = Instance.new("TextButton", f)
    b1.Size = UDim2.new(1,-12,0,32); b1.Position = UDim2.new(0,6,0,46); b1.Text="Teleport: Random Machine"
    b1.MouseButton1Click:Connect(function() teleportToRandomMachine() end)
    local b2 = Instance.new("TextButton", f)
    b2.Size = UDim2.new(1,-12,0,32); b2.Position = UDim2.new(0,6,0,86); b2.Text="Teleport: Elevator"
    b2.MouseButton1Click:Connect(function() teleportToElevator() end)
    local toggleStam = Instance.new("TextButton", f)
    toggleStam.Size = UDim2.new(1,-12,0,32); toggleStam.Position = UDim2.new(0,6,0,126)
    toggleStam.Text = "Infinite Stamina: OFF"
    toggleStam.MouseButton1Click:Connect(function()
        staminaFlag = not staminaFlag
        toggleStam.Text = "Infinite Stamina: " .. (staminaFlag and "ON" or "OFF")
    end)
    return sg
end

-- Try to load Rayfield
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/master/source"))()
end)

if not ok or not Rayfield then
    warn("[TZ] Rayfield library failed to load — using fallback UI.")
    createFallbackGui()
    tzLog("Loaded fallback GUI. (Rayfield missing)")
    return
end

-- Create Rayfield window
local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false
})

-- Tabs
local teleportTab = Window:CreateTab("Teleport")
local espTab = Window:CreateTab("ESP")
local autofarmTab = Window:CreateTab("Auto Farm")
local playerTab = Window:CreateTab("Player")
local creditsTab = Window:CreateTab("Credits")
local miscTab = Window:CreateTab("Misc")

-- TELEPORT TAB
teleportTab:CreateSection("Teleports")
teleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function() pcall(teleportToElevator) end
})
teleportTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = function() pcall(teleportToRandomMachine) end
})
teleportTab:CreateToggle({
    Name = "Auto Teleport to Machine",
    CurrentValue = false,
    Flag = "AutoTeleportMachines",
    Callback = function(v) autoTeleportFlag = v end,
    Description = "Automatically teleport to machines and attempt to interact."
})
teleportTab:CreateToggle({
    Name = "Auto Teleport to Elevator when done",
    CurrentValue = true,
    Flag = "AutoTeleportElevWhenDone",
    Callback = function(v) autoTeleportElevWhenDone = v end,
    Description = "When auto-teleport enabled and no machines remain, teleport to elevator."
})
teleportTab:CreateToggle({
    Name = "Auto Elevator (watch message)",
    CurrentValue = false,
    Flag = "AutoElevatorWatch",
    Callback = function(v) autoElevatorFlag = v end,
    Description = "Automatically teleport to elevator when elevator message appears."
})

-- ESP TAB
espTab:CreateSection("ESP")
espTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Flag = "ESP_Machines",
    Callback = function(v) espMachinesOn = v if not v then clearAllHighlights() end end
})
espTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Flag = "ESP_Spirits",
    Callback = function(v) espSpiritsOn = v if not v then clearAllHighlights() end end
})

-- AUTO FARM TAB
autofarmTab:CreateSection("AutoFarm")
autofarmTab:CreateToggle({
    Name = "Auto Teleport to Machine (same as Teleport Toggle)",
    CurrentValue = false,
    Flag = "AutoFarm_AutoTeleport",
    Callback = function(v) autoTeleportFlag = v end
})
autofarmTab:CreateToggle({
    Name = "Auto Teleport Elevator when done",
    CurrentValue = autoTeleportElevWhenDone,
    Flag = "AutoFarm_AutoElevWhenDone",
    Callback = function(v) autoTeleportElevWhenDone = v end
})

-- PLAYER TAB
playerTab:CreateSection("Player")
playerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(val)
        walkSpeedValue = val
        applyWalkSpeed(val)
    end
})
playerTab:CreateToggle({
    Name = "Godmode (remove HitPlayer)",
    CurrentValue = godmodeFlag,
    Flag = "GodmodeFlag",
    Callback = function(v) godmodeFlag = v end
})
playerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipFlag",
    Callback = function(v) noclipFlag = v end
})
playerTab:CreateToggle({
    Name = "AutoSkill (attempt auto skillcheck)",
    CurrentValue = autoSkillFlag,
    Flag = "AutoSkillFlag",
    Callback = function(v) autoSkillFlag = v end
})
playerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfiniteStaminaFlag",
    Callback = function(v) staminaFlag = v end
})

-- MISC TAB
miscTab:CreateSection("Misc")
miscTab:CreateButton({
    Name = "Teleport -> Random machine (quick)",
    Callback = function() pcall(teleportToRandomMachine) end
})

-- CREDITS TAB
creditsTab:CreateSection("Credits")
creditsTab:CreateLabel("Created by: Ali_hhjjj")
creditsTab:CreateLabel("Tester/Helper: GoodJOBS3")
creditsTab:CreateLabel("Special thanks: Olivia (Riddance Hub / Rayfield)")

tzLog("Twilight Zone Rayfield main.lua loaded.")
