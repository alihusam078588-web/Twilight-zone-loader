-- Twilight Zone Hub (Rayfield GUI) — Improved local-only Godmode + Infinite Stamina
-- Creator: Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special Thanks: Olivia (Riddance Hub Creator) & Shelly (Riddance Manager) for idea to use Rayfield

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Rayfield loader (fail gracefully)
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then
    warn("[TZ] Rayfield failed to load. Check your executor or network.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = { Enabled = true, FolderName = "TZ_Hub", FileName = "TZ_Config" }
})

local function tzLog(...) pcall(print, "[TZ]", ...) end

-- ---------- UTIL ----------
local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

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

local function gatherMachines()
    local parts = {}
    local floor = Workspace:FindFirstChild("Floor")
    local folder = (floor and floor:FindFirstChild("Machines")) or Workspace:FindFirstChild("Machines")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child and child:IsA("Model") and not isFuseLike(child.Name) then
                local rep = findRepresentativePart(child)
                if rep then
                    table.insert(parts, {model = child, part = rep, prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)})
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
    pcall(function()
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
    end)
    return true
end

local function teleportToRandomMachine(noAura)
    local entries = gatherMachines()
    if #entries == 0 then return false end
    local pick = entries[math.random(1,#entries)]
    if not pick.part then return false end
    teleportToPart(pick.part)
    if (not noAura) and pick.prompt then
        pcall(function()
            if type(fireproximityprompt) == "function" then
                fireproximityprompt(pick.prompt)
            else
                local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
                if ok and vim then
                    pcall(function()
                        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.06)
                        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)
                end
            end
        end)
    end
    return true
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChildWhichIsA("BasePart", true)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- ---------- ESP ----------
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}
local function createHighlight(target, color)
    if not target then return end
    if espMap[target] then return end
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "TZ_HL"
        hl.Adornee = target
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.55
        -- try CoreGui then PlayerGui
        local ok = pcall(function() hl.Parent = game:GetService("CoreGui") end)
        if not ok then hl.Parent = PlayerGui end
        espMap[target] = hl
    end)
end
local function clearAllHighlights()
    for k,v in pairs(espMap) do pcall(function() v:Destroy() end) end
    espMap = {}
end

task.spawn(function()
    while true do
        if espMachinesOn then
            for _, e in ipairs(gatherMachines()) do
                if e.model and not espMap[e.model] then createHighlight(e.model, Color3.fromRGB(0,200,0)) end
            end
        end
        if espSpiritsOn then
            local floor = Workspace:FindFirstChild("Floor")
            local cont = (floor and floor:FindFirstChild("Spirits")) or Workspace:FindFirstChild("Spirits")
            if cont then
                for _, s in ipairs(cont:GetChildren()) do
                    if s and not espMap[s] then createHighlight(s, Color3.fromRGB(200,0,200)) end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then clearAllHighlights() end
        task.wait(0.9)
    end
end)

-- ---------- Local-only Godmode (improved) ----------
-- Strategy:
-- 1) Remove any HitPlayer objects that are parented under YOUR character.
-- 2) When a HitPlayer part appears anywhere, if it's very near your HRP -> destroy it.
-- 3) Aggressively restore local Humanoid Health/MaxHealth on HealthChanged.

local function destroyHitPlayerObject(obj)
    if not obj then return end
    pcall(function() obj:Destroy() end)
end

local function scanAndRemoveNearbyHitPlayers(radius)
    radius = radius or 8
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true)
    if not hrp then return end
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc and desc:IsA("BasePart") and desc.Name == "HitPlayer" then
            local ok, dist = pcall(function() return (desc.Position - hrp.Position).Magnitude end)
            if ok and dist and dist <= radius then
                pcall(function() desc:Destroy() end)
            end
        end
    end
end

-- maintain local humanoid protection
local function protectLocalHumanoid(hum)
    if not hum or hum:GetAttribute("_TZ_Protected") then return end
    hum:SetAttribute("_TZ_Protected", true)
    pcall(function()
        hum.MaxHealth = math.max(200, hum.MaxHealth or 200)
        hum.Health = hum.MaxHealth
    end)
    hum.HealthChanged:Connect(function(new)
        pcall(function()
            if hum and hum.Health and hum.MaxHealth and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
    end)
end

-- initial and ongoing
if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then protectLocalHumanoid(hum) end
end
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
    if hum then protectLocalHumanoid(hum) end
    -- remove any HitPlayer under your new character
    for _, d in ipairs(char:GetDescendants()) do
        if d and d.Name == "HitPlayer" then pcall(function() d:Destroy() end) end
    end
end)

-- scan loop: remove hitplayers that are dangerously close
task.spawn(function()
    while true do
        pcall(function()
            scanAndRemoveNearbyHitPlayers(8)
            -- also remove any HitPlayer that accidentally got parented under our character
            local char = LocalPlayer.Character
            if char then
                for _, d in ipairs(char:GetDescendants()) do
                    if d and d.Name == "HitPlayer" then pcall(function() d:Destroy() end) end
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- listen to new HitPlayer creation and remove if near us or parented to our character
Workspace.DescendantAdded:Connect(function(desc)
    if not desc then return end
    if desc.Name == "HitPlayer" and desc:IsA("BasePart") then
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart", true))
            -- if the new HitPlayer is under our character, remove it
            if char and (desc:IsDescendantOf(char)) then
                desc:Destroy()
                return
            end
            -- if it's very close to us, remove it
            if hrp then
                local ok, dist = pcall(function() return (desc.Position - hrp.Position).Magnitude end)
                if ok and dist and dist <= 8 then pcall(function() desc:Destroy() end) end
            end
        end)
    end
end)

-- ---------- Auto SkillCheck (always-on) ----------
task.spawn(function()
    local function attachSkill(remote)
        pcall(function()
            if remote:IsA("RemoteFunction") then remote.OnClientInvoke = function() return 2 end
            elseif remote:IsA("RemoteEvent") then remote.OnClientEvent:Connect(function() end) end
        end)
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            attachSkill(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(d)
        if (d:IsA("RemoteFunction") or d:IsA("RemoteEvent")) and tostring(d.Name):lower():find("skill") then
            attachSkill(d)
        end
    end)
end)

-- ---------- Infinite Stamina (robust, client-only best-effort) ----------
local staminaFlag = false
local staminaRemotes = {}

local function scanStaminaRemotes(root)
    if not root then return end
    for _, v in ipairs(root:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and tostring(v.Name):lower():find("stamina") then
            staminaRemotes[v] = true
        end
    end
end
scanStaminaRemotes(ReplicatedStorage)
ReplicatedStorage.DescendantAdded:Connect(function(d)
    if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and tostring(d.Name):lower():find("stamina") then
        staminaRemotes[d] = true
    end
end)

local function patchLocalStaminaValues()
    for _, obj in ipairs(LocalPlayer:GetDescendants()) do
        if (obj:IsA("NumberValue") or obj:IsA("IntValue")) and tostring(obj.Name):lower():find("stamina") then
            pcall(function() obj.Value = math.max(obj.Value or 0, 250) end)
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if (obj:IsA("NumberValue") or obj:IsA("IntValue")) and tostring(obj.Name):lower():find("stamina") then
                pcall(function() obj.Value = math.max(obj.Value or 0, 250) end)
            end
        end
    end
end

task.spawn(function()
    while true do
        if staminaFlag then
            -- try discovered remotes
            for r,_ in pairs(staminaRemotes) do
                pcall(function()
                    if r.FireServer then
                        r:FireServer(999)
                    elseif r.InvokeServer then
                        r:InvokeServer(999)
                    elseif r.FireClient then
                        r:FireClient(LocalPlayer, 999)
                    end
                end)
            end
            -- try common path: ReplicatedStorage.Remotes.Gameplay.AddStamina
            pcall(function()
                local rems = ReplicatedStorage:FindFirstChild("Remotes")
                if rems and rems:FindFirstChild("Gameplay") then
                    local a = rems.Gameplay:FindFirstChild("AddStamina")
                    if a and a.FireServer then a:FireServer(45) end
                end
            end)
            -- patch local values as last resort
            pcall(function() patchLocalStaminaValues() end)
        end
        task.wait(0.25)
    end
end)

-- ---------- Auto Teleport (machines with aura) ----------
local autoTeleportFlag = false
local machineAuraEnabled = true

task.spawn(function()
    while true do
        if autoTeleportFlag then
            local entries = gatherMachines()
            if #entries > 0 then
                local pick = entries[math.random(1,#entries)]
                if pick and pick.part then
                    teleportToPart(pick.part)
                    if machineAuraEnabled and pick.prompt then
                        pcall(function()
                            if type(fireproximityprompt) == "function" then
                                fireproximityprompt(pick.prompt)
                            else
                                local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
                                if ok and vim then
                                    pcall(function()
                                        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                        task.wait(0.06)
                                        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    end)
                                end
                            end
                        end)
                    end
                end
                task.wait(1.2)
            else
                task.wait(1)
            end
        end
        task.wait(0.25)
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
                    pcall(teleportToElevator)
                    repeat task.wait(1) until not (tele and tele:FindFirstChild("Message") and tele.Message.Enabled)
                end
            end
        end
        task.wait(1)
    end
end)

-- ---------- GUI (Rayfield) ----------
local tabESP = Window:CreateTab("ESP")
tabESP:CreateToggle({ Name = "ESP Machines", CurrentValue = false, Callback = function(v) espMachinesOn = v if not v then clearAllHighlights() end end })
tabESP:CreateToggle({ Name = "ESP Spirits", CurrentValue = false, Callback = function(v) espSpiritsOn = v if not v then clearAllHighlights() end end })

local tabTP = Window:CreateTab("Teleport")
tabTP:CreateButton({ Name = "Teleport to Random Machine (manual, no aura)", Callback = function() teleportToRandomMachine(true) end })
tabTP:CreateButton({ Name = "Teleport to Elevator", Callback = teleportToElevator })

local tabAuto = Window:CreateTab("Auto Farm")
tabAuto:CreateToggle({ Name = "Auto Teleport to Machines (with aura)", CurrentValue = false, Callback = function(v) autoTeleportFlag = v machineAuraEnabled = v end })
tabAuto:CreateToggle({ Name = "Auto Elevator (when message appears)", CurrentValue = false, Callback = function(v) autoElevatorFlag = v end })

local tabPlayer = Window:CreateTab("Player")
tabPlayer:CreateSlider({ Name = "WalkSpeed", Range = {8,250}, Increment = 1, CurrentValue = 16, Callback = function(v)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.WalkSpeed = v end) end
end})
tabPlayer:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end })
tabPlayer:CreateLabel("Godmode: ENABLED (self-only, best-effort)")
tabPlayer:CreateLabel("Auto SkillCheck: ENABLED (client-side)")

local tabCredits = Window:CreateTab("Credits")
tabCredits:CreateLabel("Created by: Ali_hhjjj")
tabCredits:CreateLabel("Tester/Helper: GoodJOBS3")
tabCredits:CreateLabel("Special Thanks: Olivia (Riddance Hub Creator) & Shelly (Riddance Manager)")

Rayfield:LoadConfiguration()
tzLog("Twilight Zone Hub loaded. (Local-only godmode + robust stamina applied.)")
