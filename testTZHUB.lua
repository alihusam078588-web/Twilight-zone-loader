local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local panicMode = ReplicatedStorage.GameValues:WaitForChild("PanicMode")

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    return getCharacter():WaitForChild("HumanoidRootPart")
end

local function tweenStep(targetCFrame, speed)
    speed = speed or 150
    local hrp = getHRP()
    local distance = (hrp.CFrame.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(distance / speed, 0.05, 3)
    hrp.Anchored = true
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    hrp.Anchored = false
end

local UNDERGROUND_Y = -50

local function moveToModel(model)
    if not (model and model:IsA("Model")) then return end
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    local hrp = getHRP()
    local targetPos = part.Position
    local currentPos = hrp.Position

    tweenStep(CFrame.new(currentPos.X, UNDERGROUND_Y, currentPos.Z), 200)
    tweenStep(CFrame.new(targetPos.X, UNDERGROUND_Y, targetPos.Z), 200)
    tweenStep(CFrame.new(targetPos.X, targetPos.Y + 3, targetPos.Z), 200)
end

local function firePrompt(model)
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        fireproximityprompt(prompt)
    end
end

local function getMachines()
    local machines = {}
    for _, m in ipairs(workspace.Generators:GetChildren()) do
        if m:IsA("Model")
            and m:FindFirstChild("MachineCore")
            and m.MachineCore:FindFirstChild("Values")
            and m.MachineCore.Values:FindFirstChild("Extracted") then
            table.insert(machines, m)
        end
    end
    return machines
end

local function findTargetMachine()
    for _, m in ipairs(getMachines()) do
        local v = m.MachineCore.Values.Extracted
        if v and v.Value < 100 then
            return m
        end
    end
end

local function findElevator()
    local elevator = workspace:FindFirstChild("Elevator", true)
    if elevator then return elevator end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("elevator") then
            return obj
        end
    end
end

panicMode.Changed:Connect(function()
    if panicMode.Value == true then
        local elevator = findElevator()
        if elevator then
            moveToModel(elevator)
            task.wait(0.3)
            firePrompt(elevator)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if panicMode.Value == true then continue end
        local target = findTargetMachine()
        if target then
            moveToModel(target)
            task.wait(0.2)
            firePrompt(target)
        end
    end
end)