-- main.lua - Twilight Zone (WindUI integration)
-- Merges TZ All-in-One features into a WindUI window
-- Credits: Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Special thanks: Olivia (creator of Riddance Hub WindUI)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "TZ_WindUI_Main_v1"

-- ---------- Load WindUI (try multiple raw URLs / dist versions) ----------
local function tryLoad(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res or res == "" then
        return nil, ("Failed to fetch: %s"):format(tostring(url))
    end
    local ok2, lib = pcall(function() return loadstring(res)() end)
    if not ok2 or not lib then
        return nil, ("Failed to load library from: %s (error: %s)"):format(url, tostring(lib))
    end
    return lib, nil
end

local libUrls = {
    "https://raw.githubusercontent.com/FootageSUS/WindUI/main/library.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/library.lua",
    "https://raw.githubusercontent.com/FootageSUS/WindUI/main/dist/main.lua"
}

local Library, loadErr
for _, u in ipairs(libUrls) do
    Library, loadErr = tryLoad(u)
    if Library then break end
end

if not Library then
    warn("[TZ GUI] Could not load WindUI library. Last error:", loadErr)
    warn("[TZ GUI] If you have a local WindUI file, replace the load portion accordingly.")
    return
end

-- helper wrappers to support slightly different WindUI APIs
local function createWindow(opts)
    -- prefer :CreateWindow({Name = ...}) style
    if Library.CreateWindow then
        return Library:CreateWindow(opts)
    elseif Library.Create then
        return Library:Create(opts)
    elseif Library:CreateWindow then
        return Library:CreateWindow(opts)
    else
        error("Unsupported WindUI library API: missing CreateWindow/Create")
    end
end

local function createTab(window, name)
    if not window then return nil end
    if window.CreateTab then
        return window:CreateTab(name)
    elseif window.Tab then
        return window:Tab(name)
    elseif window:CreateTab then
        return window:CreateTab(name)
    else
        error("Unsupported window API: missing CreateTab/Tab")
    end
end

-- ========== TZ CORE FEATURES (adapted) ==========
local function tzLog(...) pcall(print, "[TZ]", ...) end

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

-- GODMODE toggle implementation (destroy HitPlayer objects when enabled)
local godmodeEnabled = false
task.spawn(function()
    while true do
        if godmodeEnabled then
            pcall(function()
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v and v.Name and tostring(v.Name):match("^HitPlayer") then
                        pcall(function() v:Destroy() end)
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- gather machine parts (tries many candidate folders)
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

-- TELEPORT helpers
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

-- ESP
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

-- AutoSkill (toggle)
local autoskillEnabled = false
local function tryAttachSkillCheck(remote)
    if not remote then return end
    pcall(function()
        if remote:IsA("RemoteFunction") then
            -- override invoke responses
            remote.OnClientInvoke = function(...) return 2 end
        elseif remote:IsA("RemoteEvent") then
            -- noop listener to prevent events? keep minimal
            remote.OnClientEvent:Connect(function(...) end)
        end
    end)
end

task.spawn(function()
    while true do
        if autoskillEnabled then
            -- scan existing
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
                    tryAttachSkillCheck(v)
                end
            end
        end
        task.wait(1.5)
    end
end)

ReplicatedStorage.DescendantAdded:Connect(function(desc)
    if autoskillEnabled and (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then
        tryAttachSkillCheck(desc)
    end
end)

-- Infinite Stamina (toggle)
local staminaFlag = false
local AddStamina -- try to resolve safely
pcall(function()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    if rem and rem:FindFirstChild("Gameplay") then
        AddStamina = rem.Gameplay:FindFirstChild("AddStamina")
    end
end)

task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
            pcall(function() -- many exploits provide firesignal
                if firesignal then
                    firesignal(AddStamina.OnClientEvent, 45)
                else
                    -- Try calling OnClientEvent connectors by firing the remote if accessible (best-effort)
                    pcall(function() AddStamina:FireClient(LocalPlayer, 45) end)
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- Auto Elevator (watch message) toggle
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

-- Auto Teleport to Machine (with aura) toggle + optional auto elevator when done
local autoTeleportToMachineFlag = false
local autoTeleportToElevatorWhenDone = true
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
                tzLog("AutoTeleport: no machines found" .. (autoTeleportToElevatorWhenDone and ", teleporting to elevator..." or ""))
                if autoTeleportToElevatorWhenDone then pcall(teleportToElevator) end
                task.wait(1.2)
            else
                local target = parts[math.random(1,#parts)]
                if teleportToPart(target) then
                    task.wait(0.2)
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
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            for i=1,4 do
                                if not autoTeleportToMachineFlag then break end
                                pcall(function()
                                    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                end)
                                task.wait(0.15)
                            end
                        end)
                    end
                    task.wait(0.2)
                end
            end
        end
        task.wait(2)
    end
end)

-- ========== GUI: Create window & tabs ==========
local ok, Window = pcall(function()
    return createWindow({ Name = "Twilight Zone", Themeable = { Info = "Made by Ali_hhjjj" } })
end)
if not ok or not Window then
    warn("[TZ GUI] Failed to create WindUI window. Aborting GUI creation.")
    return
end

local farmTab = createTab(Window, "Auto Farm")
local teleportTab = createTab(Window, "Teleport")
local espTab = createTab(Window, "ESP")
local miscTab = createTab(Window, "Misc")
local creditsTab = createTab(Window, "Credits")

-- helper wrappers for element creation (different WindUI forks use slightly different method names)
local function createToggle(tab, tbl)
    if not tab then return end
    if tab.CreateToggle then
        return tab:CreateToggle(tbl)
    elseif tab.Toggle then
        return tab:Toggle(tbl)
    elseif tab.Create and tab.Create.Toggle then
        return tab:Create.Toggle(tbl)
    else
        -- fallback: create a simple TextButton in StarterGui if possible (not implemented)
        print("[TZ GUI] Toggle created (console):", tbl.Name or tbl.text)
    end
end

local function createButton(tab, tbl)
    if not tab then return end
    if tab.CreateButton then
        return tab:CreateButton(tbl)
    elseif tab.Button then
        return tab:Button(tbl)
    elseif tab.Create and tab.Create.Button then
        return tab:Create.Button(tbl)
    else
        print("[TZ GUI] Button created (console):", tbl.Name or tbl.text)
    end
end

local function createLabel(tab, text)
    if not tab then return end
    if tab.CreateLabel then
        return tab:CreateLabel(text)
    elseif tab.Label then
        return tab:Label(text)
    else
        print("[TZ GUI] Label:", text)
    end
end

-- ---------- Auto Farm Tab ----------
createToggle(farmTab, {
    Name = "Auto Teleport to Machine",
    CurrentValue = false,
    Flag = "AutoTPMachines",
    Description = "Automatically teleport you to machines and perform aura (ProximityPrompt).",
    Callback = function(Value)
        tzLog("Auto Teleport to Machine:", Value)
        autoTeleportToMachineFlag = Value
    end
})

createToggle(farmTab, {
    Name = "Auto Teleport to Elevator (when done)",
    CurrentValue = true,
    Flag = "AutoTPElevatorWhenDone",
    Description = "Automatically teleport to the elevator when no machines remain.",
    Callback = function(Value)
        tzLog("Auto Teleport to Elevator when done:", Value)
        autoTeleportToElevatorWhenDone = Value
    end
})

createToggle(farmTab, {
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfiniteStamina",
    Description = "Toggle infinite stamina on/off.",
    Callback = function(Value)
        tzLog("Infinite Stamina:", Value)
        staminaFlag = Value
    end
})

-- ---------- Teleport Tab ----------
createButton(teleportTab, {
    Name = "Teleport: Random Machine",
    Callback = function() pcall(teleportToRandomMachine) end
})

createButton(teleportTab, {
    Name = "Teleport: Elevator",
    Callback = function() pcall(teleportToElevator) end
})

createToggle(teleportTab, {
    Name = "Auto Teleport (with aura)",
    CurrentValue = false,
    Flag = "AutoTeleportAura",
    Description = "Automatically teleport to machines and use aura.",
    Callback = function(Value)
        tzLog("Auto Teleport (with aura):", Value)
        autoTeleportToMachineFlag = Value
    end
})

createToggle(teleportTab, {
    Name = "Auto Elevator (watch message)",
    CurrentValue = false,
    Flag = "AutoElevator",
    Description = "Automatically teleport to elevator when the elevator message triggers.",
    Callback = function(Value)
        tzLog("Auto Elevator (watch message):", Value)
        autoElevatorFlag = Value
    end
})

-- ---------- ESP Tab ----------
createToggle(espTab, {
    Name = "ESP Machines",
    CurrentValue = false,
    Flag = "ESPMachines",
    Callback = function(Value)
        tzLog("ESP Machines:", Value)
        espMachinesOn = Value
        if not Value then clearAllHighlights() end
    end
})

createToggle(espTab, {
    Name = "ESP Spirits",
    CurrentValue = false,
    Flag = "ESPSpirits",
    Callback = function(Value)
        tzLog("ESP Spirits:", Value)
        espSpiritsOn = Value
        if not Value then clearAllHighlights() end
    end
})

-- ---------- Misc Tab ----------
createToggle(miscTab, {
    Name = "Godmode (destroy HitPlayer objects)",
    CurrentValue = false,
    Flag = "Godmode",
    Callback = function(Value)
        tzLog("Godmode:", Value)
        godmodeEnabled = Value
    end
})

createToggle(miscTab, {
    Name = "AutoSkill (auto skillcheck override)",
    CurrentValue = false,
    Flag = "AutoSkill",
    Callback = function(Value)
        tzLog("AutoSkill:", Value)
        autoskillEnabled = Value
        if Value then
            -- quickly attempt attaching to existing skill remotes
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
                    tryAttachSkillCheck(v)
                end
            end
        end
    end
})

-- ---------- Credits Tab ----------
createLabel(creditsTab, "Created by: Ali_hhjjj")
createLabel(creditsTab, "Tester/Helper: GoodJOBS3")
createLabel(creditsTab, "Special thanks: Olivia (Riddance Hub, WindUI)")

tzLog("Twilight Zone WindUI main.lua loaded successfully.")
