-- Twilight Zone — Safe GUI Template (WindUI style)
-- Compact GUI for local/testing only. Harmless: does NOT perform teleports, remote fires, or exploits.
-- Created by Ali_hhjjj | Tester/Helper: GoodJOBS3
-- Notes: Replace stub functions with game-approved logic if you have permission. Do NOT use to cheat.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "TZ_AllInOne_SafeTemplate"
if PlayerGui:FindFirstChild(GUI_NAME) then
    pcall(function() PlayerGui[GUI_NAME]:Destroy() end)
end

local function tzLog(...)
    pcall(print, "[TZ-SAFE]", ...)
end

-- ======= SAFE STUBS =======
-- These functions intentionally do not perform world changes.
-- Replace with permitted game logic if you're developing a legit feature for your own game.

local function safeGatherMachineParts()
    -- SAFE: just returns a list of model names present under known folders (no operations)
    local out = {}
    local function safeCollect(container)
        if not container then return end
        for _,c in ipairs(container:GetChildren()) do
            table.insert(out, tostring(c.Name))
        end
    end
    pcall(function()
        safeCollect(workspace:FindFirstChild("Floor") and workspace.Floor:FindFirstChild("Machines"))
        safeCollect(workspace:FindFirstChild("Machines"))
        safeCollect(workspace:FindFirstChild("CurrentRoom"))
    end)
    return out
end

local function safeTeleportToPart(partName)
    -- SAFE: just logs intent
    tzLog("REQUEST teleport to part (safe):", partName)
    -- If you are making a legitimate singleplayer mod for your own place,
    -- replace with actual CFrame logic here (only if you have permission).
    return true
end

local function safeFireAura(partName, times, delay)
    tzLog("REQUEST aura (safe):", partName, times, delay)
    -- harmless; does not press keys or fire prompts
end

local function safeTeleportToElevator()
    tzLog("REQUEST teleport to elevator (safe)")
    return true
end

-- ======= STATE =======
local espMachinesOn = false
local espSpiritsOn = false
local autoTeleportFlag = false
local autoElevatorFlag = false
local staminaFlag = false
local autoFarmFlag = false

-- ======= GUI BUILD =======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Toggle button (small)
local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size = UDim2.new(0,40,0,40)
toggleBtn.Position = UDim2.new(0.03,0,0.18,0)
toggleBtn.Text = "☰"
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
pcall(function() Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1,0) end)
toggleBtn.Active = true
pcall(function() toggleBtn.Draggable = true end)

-- Frame (compact)
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,220,0,420)
frame.Position = UDim2.new(0.12,0,0.18,0)
frame.BackgroundColor3 = Color3.fromRGB(12,12,12)
pcall(function() Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8) end)
frame.Active = true
pcall(function() frame.Draggable = true end)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-10,0,26)
title.Position = UDim2.new(0,5,0,6)
title.BackgroundTransparency = 1
title.Text = "Twilight Zone (Safe Template)"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(220,220,220)

local divider = Instance.new("Frame", frame)
divider.Size = UDim2.new(1,-10,0,2)
divider.Position = UDim2.new(0,5,0,34)
divider.BackgroundColor3 = Color3.fromRGB(30,30,30)

-- Helpers for adding controls
local y = 44
local function addToggleBtn(label, initial, onToggle)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1,-12,0,30)
    b.Position = UDim2.new(0,6,0,y)
    b.BackgroundColor3 = initial and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Text = label .. ": " .. (initial and "ON" or "OFF")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    y = y + 36
    local state = initial
    b.MouseButton1Click:Connect(function()
        state = not state
        b.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
        b.Text = label .. ": " .. (state and "ON" or "OFF")
        pcall(function() onToggle(state) end)
    end)
    return b
end

local function addActionBtn(label, callback)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1,-12,0,30)
    b.Position = UDim2.new(0,6,0,y)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Text = label
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    y = y + 36
    b.MouseButton1Click:Connect(callback)
    return b
end

-- Controls (harmless)
local btnESP_Machines = addToggleBtn("ESP Machines", false, function(s) espMachinesOn = s tzLog("ESP Machines set ->", s) end)
local btnESP_Spirits  = addToggleBtn("ESP Spirits", false, function(s) espSpiritsOn = s tzLog("ESP Spirits set ->", s) end)
local btnTeleportRandom = addActionBtn("Teleport: Random (safe)", function()
    local list = safeGatherMachineParts()
    tzLog("Random machine candidates (safe):", #list)
    if #list > 0 then tzLog("Example machine:", list[math.random(1,#list)]) end
end)
local autoTPBtn = addToggleBtn("Auto Teleport (2s, safe)", false, function(s)
    autoTeleportFlag = s
    tzLog("Auto Teleport (safe) ->", s)
end)

local btnTeleportElev = addActionBtn("Teleport: Elevator (safe)", function() safeTeleportToElevator() end)
local autoElevBtn = addToggleBtn("Auto Elevator (watch, safe)", false, function(s) autoElevatorFlag = s tzLog("AutoElevator (safe) ->", s) end)
local staminaBtn = addToggleBtn("Infinite Stamina (toggle - SAFE)", false, function(s) staminaFlag = s tzLog("Stamina (safe) ->", s) end)
local autoFarmBtn = addToggleBtn("Auto Farm (safe)", false, function(s) autoFarmFlag = s tzLog("AutoFarm (safe) ->", s) end)

-- Always-on informational labels
local godLabel = Instance.new("TextLabel", frame)
godLabel.Size = UDim2.new(1,-12,0,18)
godLabel.Position = UDim2.new(0,6,1,-96)
godLabel.BackgroundTransparency = 1
godLabel.Text = "Godmode: ENABLED (info only)"
godLabel.Font = Enum.Font.SourceSansBold
godLabel.TextSize = 13
godLabel.TextColor3 = Color3.fromRGB(0,255,0)

local skillLabel = Instance.new("TextLabel", frame)
skillLabel.Size = UDim2.new(1,-12,0,18)
skillLabel.Position = UDim2.new(0,6,1,-74)
skillLabel.BackgroundTransparency = 1
skillLabel.Text = "Auto SkillCheck: ACTIVE (info only)"
skillLabel.Font = Enum.Font.SourceSansBold
skillLabel.TextSize = 13
skillLabel.TextColor3 = Color3.fromRGB(0,255,0)

local footerLabel = Instance.new("TextLabel", frame)
footerLabel.Size = UDim2.new(1,-12,0,18)
footerLabel.Position = UDim2.new(0,6,1,-48)
footerLabel.BackgroundTransparency = 1
footerLabel.Text = "Created by Ali_hhjjj | Template by ChatGPT"
footerLabel.Font = Enum.Font.SourceSans
footerLabel.TextSize = 12
footerLabel.TextColor3 = Color3.fromRGB(160,160,160)

toggleBtn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)

-- ======= SIMPLE BACKGROUND TASKS (SAFE) =======
-- Auto Teleport (safe) demo: logs which machine would be targeted
spawn(function()
    while true do
        if autoTeleportFlag then
            local list = safeGatherMachineParts()
            if #list > 0 then
                local pick = list[math.random(1,#list)]
                tzLog("AutoTeleport (safe): would teleport to", pick)
                -- Demonstrate aura intent (safe)
                safeFireAura(pick, 6, 0.15)
            else
                tzLog("AutoTeleport (safe): no machines found")
                -- automatically simulate going to elevator (safe)
                tzLog("AutoTeleport (safe): would teleport to elevator (none found)")
            end
        end
        task.wait(2)
    end
end)

tzLog("TZ All-in-One (SAFE TEMPLATE) loaded.")
