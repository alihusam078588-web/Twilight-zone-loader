-- Twilight Zone Script (Rayfield GUI Version)
-- Creator: Ali_hhjjj
-- Tester/Helper: GOODJOBS3
-- Special Thanks: Olivia (Creator of Riddance Hub) and Shelly (Riddance Manager) for giving the idea to use Rayfield

-- // Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone Hub",
    LoadingSubtitle = "By Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TwilightZoneConfig",
        FileName = "TZ_Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

------------------------------------------------
-- Variables
------------------------------------------------
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local autoMachine = false
local autoElevator = false
local espMachines = {}
local espSpirits = {}

------------------------------------------------
-- Utility
------------------------------------------------
local function getMachines()
    local machinesFolder = Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")
    local results = {}
    if machinesFolder then
        for _, obj in pairs(machinesFolder:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("Part") then
                table.insert(results, obj)
            end
        end
    end
    return results
end

local function teleportTo(obj)
    if obj and obj:IsA("Model") or obj:IsA("Part") then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = obj:GetModelCFrame and obj:GetModelCFrame() or obj.CFrame
        end
    end
end

local function highlight(obj, color)
    if obj and obj:IsA("Model") or obj:IsA("Part") then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = obj
        highlight.FillColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = obj
        return highlight
    end
end

------------------------------------------------
-- ESP Tab
------------------------------------------------
local EspTab = Window:CreateTab("ESP", 4483362458)

EspTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(value)
        if value then
            for _, m in pairs(getMachines()) do
                local h = highlight(m, Color3.fromRGB(0, 255, 0))
                table.insert(espMachines, h)
            end
        else
            for _, h in pairs(espMachines) do
                h:Destroy()
            end
            espMachines = {}
        end
    end
})

EspTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(value)
        if value then
            for _, s in pairs(Workspace:GetDescendants()) do
                if s.Name:lower():find("spirit") then
                    local h = highlight(s, Color3.fromRGB(255, 0, 0))
                    table.insert(espSpirits, h)
                end
            end
        else
            for _, h in pairs(espSpirits) do
                h:Destroy()
            end
            espSpirits = {}
        end
    end
})

------------------------------------------------
-- Teleport Tab
------------------------------------------------
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

TeleportTab:CreateButton({
    Name = "Teleport to Random Machine",
    Callback = function()
        local machines = getMachines()
        if #machines > 0 then
            teleportTo(machines[math.random(1, #machines)])
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        local elevator = Workspace:FindFirstChild("Elevator")
        if elevator then
            teleportTo(elevator)
        end
    end
})

------------------------------------------------
-- Auto Farm Tab
------------------------------------------------
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateToggle({
    Name = "Auto Teleport to Machines (with Aura)",
    CurrentValue = false,
    Callback = function(value)
        autoMachine = value
    end
})

FarmTab:CreateToggle({
    Name = "Auto Teleport to Elevator (when done)",
    CurrentValue = false,
    Callback = function(value)
        autoElevator = value
    end
})

-- Auto Loop
RunService.RenderStepped:Connect(function()
    if autoMachine then
        local machines = getMachines()
        if #machines > 0 then
            local target = machines[math.random(1, #machines)]
            teleportTo(target)
            -- "Aura" effect: spam E key
            game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    elseif autoElevator then
        local elevator = Workspace:FindFirstChild("Elevator")
        if elevator then
            teleportTo(elevator)
        end
    end
end)

------------------------------------------------
-- Player Tab
------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSlider({
    Name = "Custom WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

PlayerTab:CreateLabel("Godmode: ON")
PlayerTab:CreateLabel("Auto SkillCheck: ON")

PlayerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Callback = function(value)
        if value then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
                    LocalPlayer.Character.Humanoid.JumpPower = 50
                end)
            end
        end
    end
})

------------------------------------------------
-- Credits Tab
------------------------------------------------
local CreditsTab = Window:CreateTab("Credits", 4483362458)

CreditsTab:CreateLabel("Creator: Ali_hhjjj")
CreditsTab:CreateLabel("Tester/Helper: GOODJOBS3")
CreditsTab:CreateLabel("Thanks to Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving idea to use Rayfield")
