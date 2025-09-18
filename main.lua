-- main.lua
-- Twilight Zone Hub (Rayfield)
-- Creator: Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special Thanks: Olivia (Riddance Hub) & Shelly (Riddance Manager) for idea to use Rayfield

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Load Rayfield (change URL if using a different host)
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok or not Rayfield then
    warn("[TZ] Rayfield failed to load. Make sure executor allows HttpGet and the URL is reachable.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = { Enabled = true, FolderName = "TZ_Hub", FileName = "TZ_Config" }
})

local function tzLog(...) pcall(print, "[TZ]", ...) end

-- ---------- Utilities ----------
local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

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

-- gather machine entries: model, representative part, proximity prompt (if any)
local function gatherMachineEntries()
    local entries = {}
    local floor = Workspace:FindFirstChild("Floor")
    local machinesFolder = (floor and floor:FindFirstChild("Machines")) or Workspace:FindFirstChild("Machines")
    if not machinesFolder then
        -- fallback: search workspace children models (filter fuse-like)
        for _,c in ipairs(Workspace:GetChildren()) do
            if c:IsA("Model") and not isFuseLike(c.Name) then
                table.insert(entries, { model = c, part = findRepresentativePart(c), prompt = c:FindFirstChildWhichIsA("ProximityPrompt", true) })
            end
        end
        return entries
    end

    for _, child in ipairs(machinesFolder:GetChildren()) do
        if child and child:IsA("Model") and not isFuseLike(child.Name) then
            local rep = findRepresentativePart(child)
            local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
            table.insert(entries, { model = child, part = rep, prompt = prompt })
        end
    end
    return entries
end

-- ---------- Teleport helpers ----------
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0) end)
    return true
end

-- manual teleport to random machine (NO aura)
local function teleportToRandomMachineManual()
    local entries = gatherMachineEntries()
    if #entries == 0 then return false end
    local pick = entries[math.random(1, #entries)]
    if pick and (pick.part or pick.model) then
        local part = pick.part or findRepresentativePart(pick.model)
        return teleportToPart(part)
    end
    return false
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChildWhichIsA("BasePart", true)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- attempt to "use" a machine: try fire proximity prompt (preferred), else VirtualInputManager spam E
local function interactWithPrompt(prompt)
    if not prompt then return end
    pcall(function()
        -- prefer built-in function if available
        if type(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
        else
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.06)
            vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

-- ---------- ESP ----------
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

local function createHighlightFor(target, color)
    if not target or espMap[target] then return end
    pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "TZ_HL"
        h.Adornee = target
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.55
        -- parent to CoreGui if available, else PlayerGui (some executors restrict CoreGui parenting)
        local parentOk = pcall(function() h.Parent = game:GetService("CoreGui") end)
        if not parentOk then h.Parent = PlayerGui end
        espMap[target] = h
    end)
end

local function clearAllHighlights()
    for k,v in pairs(espMap) do
        pcall(function() v:Destroy() end)
    end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            for _, e in ipairs(gatherMachineEntries()) do
                local target = e.model or e.part
                if target and not espMap[target] then createHighlightFor(target, Color3.fromRGB(0,200,0)) end
            end
        end
        if espSpiritsOn then
            local floor = Workspace:FindFirstChild("Floor")
            local cont = (floor and floor:FindFirstChild("Spirits")) or Workspace:FindFirstChild("Spirits")
            if cont then
                for _, s in ipairs(cont:GetChildren()) do
                    if s and not espMap[s] then createHighlightFor(s, Color3.fromRGB(200,0,200)) end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then clearAllHighlights() end
        task.wait(0.9)
    end
end)

-- ---------- Godmode (targeted client-only removal of HitPlayer) ----------
do
    local function destroyIfHitPlayer(inst)
        if not inst then return end
        pcall(function()
            if inst:IsA("BasePart") and inst.Name == "HitPlayer" then
                inst:Destroy()
            end
        end)
    end

    local function scanAndDestroy(parent)
        if not parent then return end
        for _,desc in ipairs(parent:GetDescendants()) do
            destroyIfHitPlayer(desc)
        end
    end

    -- targeted: remove HitPlayer in Floor.Spirits numeric children (where you said they appear)
    local floor = Workspace:FindFirstChild("Floor")
    local spirits = floor and floor:FindFirstChild("Spirits")
    if spirits then
        for _, child in ipairs(spirits:GetChildren()) do
            scanAndDestroy(child)
            child.DescendantAdded:Connect(function(d) destroyIfHitPlayer(d) end)
        end
        spirits.ChildAdded:Connect(function(newChild)
            scanAndDestroy(newChild)
            newChild.DescendantAdded:Connect(function(d) destroyIfHitPlayer(d) end)
        end)
    end

    -- also remove HitPlayer under the local character only (client-side)
    local function removeHitInCharacter(char)
        if not char then return end
        scanAndDestroy(char)
        char.DescendantAdded:Connect(function(d) destroyIfHitPlayer(d) end)
    end
    if LocalPlayer.Character then removeHitInCharacter(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(removeHitInCharacter)

    -- fallback: global workspace watcher to remove any HitPlayer parts created anywhere (client-side)
    scanAndDestroy(Workspace)
    Workspace.DescendantAdded:Connect(function(d) destroyIfHitPlayer(d) end)

    tzLog("Godmode: HitPlayer removal listeners set (client-side).")
end

-- ---------- AutoSkill (always-on, client-side) ----------
do
    local function attachSkill(remote)
        pcall(function()
            if remote:IsA("RemoteFunction") then
                remote.OnClientInvoke = function() return 2 end
            elseif remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function() end)
            end
        end)
    end
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            attachSkill(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(d)
        if (d:IsA("RemoteFunction") or d:IsA("RemoteEvent")) and tostring(d.Name):lower():find("skill") then
            attachSkill(d)
        end
    end)
    tzLog("AutoSkill: attached to skill remotes (client-side).")
end

-- ---------- Infinite Stamina (attempt, client-side) ----------
local staminaFlag = false
local function findAddStaminaRemote()
    local ok, rem = pcall(function()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        if r and r:FindFirstChild("Gameplay") and r.Gameplay:FindFirstChild("AddStamina") then
            return r.Gameplay.AddStamina
        end
        return nil
    end)
    return ok and rem or nil
end
local AddStaminaRemote = findAddStaminaRemote()

-- try to keep local stamina numeric values high
local function fillLocalStaminaValues()
    pcall(function()
        for _, obj in ipairs(LocalPlayer:GetDescendants()) do
            if (obj:IsA("NumberValue") or obj:IsA("IntValue")) and tostring(obj.Name):lower():find("stamina") then
                obj.Value = math.max(obj.Value, 100)
            end
        end
        local char = LocalPlayer.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if (obj:IsA("NumberValue") or obj:IsA("IntValue")) and tostring(obj.Name):lower():find("stamina") then
                    obj.Value = math.max(obj.Value, 100)
                end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if staminaFlag then
            -- 1) Fire discovered AddStamina remote if present
            if AddStaminaRemote then
                pcall(function()
                    if AddStaminaRemote.FireClient then
                        AddStaminaRemote:FireClient(LocalPlayer, 45)
                    elseif AddStaminaRemote.FireServer then
                        AddStaminaRemote:FireServer(45)
                    end
                end)
            end
            -- 2) patch local values
            fillLocalStaminaValues()
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
                if msg and msg.Enabled then
                    pcall(teleportToElevator)
                    repeat task.wait(1) until not (tele and tele:FindFirstChild("Message") and tele.Message.Enabled)
                end
            end
        end
        task.wait(1)
    end
end)

-- ---------- Auto Teleport to machine (with aura spam) ----------
-- Behavior: when autoTeleportFlag is ON, script prefers machines that have a ProximityPrompt (machine aura).
-- If none have prompts, it will still pick random machine entries.
local autoTeleportFlag = false
local machineAuraEnabled = true -- controlled by toggle (auto teleport toggle turns aura on)
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local entries = gatherMachineEntries()
            if #entries > 0 then
                -- prefer prompt-bearing machines
                local promptList = {}
                for _,e in ipairs(entries) do if e.prompt then table.insert(promptList, e) end end
                local pickList = (#promptList > 0) and promptList or entries
                local pick = pickList[math.random(1,#pickList)]
                if pick and (pick.part or pick.model) then
                    local part = pick.part or findRepresentativePart(pick.model)
                    teleportToPart(part)
                    if machineAuraEnabled and pick.prompt then
                        -- spam the prompt a few times
                        for i = 1, 4 do
                            interactWithPrompt(pick.prompt)
                            task.wait(0.08)
                        end
                    end
                end
            else
                -- no machines found; wait a bit
                task.wait(1)
            end
            task.wait(1.2)
        end
        task.wait(0.25)
    end
end)

-- ---------- GUI (Rayfield) ----------
local tabESP = Window:CreateTab("ESP")
tabESP:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachinesOn = v if not v then clearAllHighlights() end end })
tabESP:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpiritsOn = v if not v then clearAllHighlights() end end })

local tabTP = Window:CreateTab("Teleport")
tabTP:CreateButton({ Name = "Teleport to Random Machine (manual, NO aura)", Callback = function() teleportToRandomMachineManual() end })
tabTP:CreateButton({ Name = "Teleport to Elevator", Callback = teleportToElevator })

local tabAuto = Window:CreateTab("Auto Farm")
tabAuto:CreateToggle({ Name = "Auto Teleport to Machines (with aura)", CurrentValue = false, Callback = function(v) autoTeleportFlag = v machineAuraEnabled = v end })
tabAuto:CreateToggle({ Name = "Auto Elevator (when message appears)", CurrentValue = false, Callback = function(v) autoElevatorFlag = v end })
tabAuto:CreateButton({ Name = "Teleport Now (random machine)", Callback = function() teleportToRandomMachineManual() end })

local tabPlayer = Window:CreateTab("Player")
tabPlayer:CreateSlider({ Name = "WalkSpeed", Range = {8, 250}, Increment = 1, CurrentValue = 16, Callback = function(v)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.WalkSpeed = v end) end
    end
end})
tabPlayer:CreateToggle({ Name = "Infinite Stamina (attempt)", CurrentValue = false, Callback = function(v) staminaFlag = v end })
tabPlayer:CreateLabel("Godmode: ACTIVE (client-side HitPlayer removal)")
tabPlayer:CreateLabel("Auto SkillCheck: ACTIVE (client-side)")

local tabCredits = Window:CreateTab("Credits")
tabCredits:CreateLabel("Creator: Ali_hhjjj")
tabCredits:CreateLabel("Tester/Helper: GoodJOBS3")
tabCredits:CreateLabel("Special Thanks: Olivia (Riddance Hub) & Shelly (Riddance Manager)")

Rayfield:LoadConfiguration()
tzLog("Twilight Zone (Rayfield) loaded.")
