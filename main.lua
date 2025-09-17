-- Twilight Zone - Rayfield GUI
-- by Ali_hhjjj | Tester: GOODJOBS3 | Special thanks: Olivia (Riddance Hub)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer
local hrp = lp.Character and lp.Character:WaitForChild("HumanoidRootPart")

-- Utility
local function safeTP(pos)
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = pos
    end
end

local function gatherMachines()
    local out = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("machine") then
            table.insert(out, v)
        end
    end
    return out
end

local function gatherSpirits()
    local out = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("spirit") then
            table.insert(out, v)
        end
    end
    return out
end

local function teleportToRandomMachine()
    local machines = gatherMachines()
    if #machines > 0 then
        local choice = machines[math.random(1, #machines)]
        safeTP(choice.CFrame + Vector3.new(0, 3, 0))
    end
end

local function teleportToElevator()
    local target = workspace:FindFirstChild("Elevator")
    if target and target:IsA("BasePart") then
        safeTP(target.CFrame + Vector3.new(0, 5, 0))
    end
end

-- ESP
local function createESP(obj, color)
    if not obj:FindFirstChild("ESP") then
        local b = Instance.new("BillboardGui", obj)
        b.Name = "ESP"
        b.Size = UDim2.new(0, 200, 0, 50)
        b.AlwaysOnTop = true
        b.Adornee = obj
        local label = Instance.new("TextLabel", b)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.Text = obj.Name
    end
end

-- Aura spam (press E)
local function machineAuraSpam()
    for i = 1, 6 do
        pcall(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.08)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        task.wait(0.08)
    end
end

-- Auto Teleport loop
local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local machines = gatherMachines()
            if #machines > 0 then
                local choice = machines[math.random(1, #machines)]
                safeTP(choice.CFrame + Vector3.new(0, 3, 0))
                machineAuraSpam()
                task.wait(1.5)
            else
                teleportToElevator()
                task.wait(3)
            end
        end
        task.wait(0.5)
    end
end)

-- Rayfield Setup
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TZ_Config",
        FileName = "TwilightZoneHub"
    }
})

-- ESP Tab
local tabESP = Window:CreateTab("ESP", 4483362458)
tabESP:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Flag = "ESPMachines",
    Callback = function(v)
        if v then
            for _, obj in pairs(gatherMachines()) do
                createESP(obj, Color3.fromRGB(0,255,0))
            end
        else
            for _, b in pairs(workspace:GetDescendants()) do
                if b.Name == "ESP" then b:Destroy() end
            end
        end
    end
})
tabESP:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Flag = "ESpSpirits",
    Callback = function(v)
        if v then
            for _, obj in pairs(gatherSpirits()) do
                createESP(obj, Color3.fromRGB(255,0,0))
            end
        else
            for _, b in pairs(workspace:GetDescendants()) do
                if b.Name == "ESP" then b:Destroy() end
            end
        end
    end
})

-- Teleport Tab
local tabTP = Window:CreateTab("Teleport", 4483362458)
tabTP:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = teleportToRandomMachine
})
tabTP:CreateParagraph({
    Title = "Note",
    Content = "Aura (spam E) works only when Auto Teleport is enabled."
})
tabTP:CreateButton({
    Name = "Teleport to Elevator",
    Callback = teleportToElevator
})

-- Auto Farm Tab
local tabFarm = Window:CreateTab("Auto Farm", 4483362458)
tabFarm:CreateToggle({
    Name = "Auto Teleport to Machine",
    CurrentValue = false,
    Flag = "AutoTPMachines",
    Callback = function(v)
        autoTeleportFlag = v
    end
})

-- Player Tab
local tabPlayer = Window:CreateTab("Player", 4483362458)
tabPlayer:CreateSlider({
    Name = "Custom Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "WalkSpeed",
    CurrentValue = 16,
    Flag = "Speed",
    Callback = function(val)
        lp.Character.Humanoid.WalkSpeed = val
    end
})
tabPlayer:CreateToggle({
    Name = "Godmode (Always On)",
    CurrentValue = true,
    Flag = "Godmode",
    Callback = function(v) end
})
tabPlayer:CreateToggle({
    Name = "Auto Skillcheck (Always On)",
    CurrentValue = true,
    Flag = "Skillcheck",
    Callback = function(v) end
})
tabPlayer:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Flag = "InfStamina",
    Callback = function(v) end
})
tabPlayer:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        if v then
            RunService.Stepped:Connect(function()
                if lp.Character then
                    for _, p in pairs(lp.Character:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
})

-- Credits Tab
local tabCredits = Window:CreateTab("Credits", 4483362458)
tabCredits:CreateParagraph({
    Title = "Credits",
    Content = "Created by: Ali_hhjjj\nTester/Helper: GOODJOBS3\nSpecial Thanks: Olivia (Riddance Hub)"
})
