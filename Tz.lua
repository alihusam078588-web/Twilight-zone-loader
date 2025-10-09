local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Utility
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

-- Godmode
task.spawn(function()
    while true do
        pcall(function()
            local floor = Workspace:FindFirstChild("Floor")
            if floor and floor:FindFirstChild("Spirits") then
                for _, folder in ipairs(floor.Spirits:GetChildren()) do
                    for _, v in ipairs(folder:GetChildren()) do
                        if v and v.Name == "HitPlayer" then
                            v:Destroy()
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- ESP + Auto functions setup
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

local function createHighlight(model, color)
    if not model or espMap[model] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.55
    hl.Adornee = model
    hl.Parent = workspace
    espMap[model] = hl
end

-- WindUI Window
local Window = WindUI:CreateWindow({
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

local MainTab = Window:CreateTab({ Name = "Main" })
local VisualsTab = Window:CreateTab({ Name = "ESP" })
local PlayerTab = Window:CreateTab({ Name = "Player" })

-- Example buttons
MainTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        local elevator = Workspace:FindFirstChild("Elevator")
        if elevator then
            local part = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChildWhichIsA("BasePart")
            if part then
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0) end
            end
        end
    end
})

VisualsTab:CreateToggle({
    Name = "ESP Machines",
    Default = false,
    Callback = function(value)
        espMachinesOn = value
    end
})

VisualsTab:CreateToggle({
    Name = "ESP Spirits",
    Default = false,
    Callback = function(value)
        espSpiritsOn = value
    end
})

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Callback = function(v)
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = v
        end
    end
})

task.spawn(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Twilight Zone 💫",
        Text = "Godmode and Auto Skillcheck are ACTIVE!",
        Duration = 6
    })
end)
