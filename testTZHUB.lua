local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local panicMode = ReplicatedStorage.GameValues.PanicMode

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    return getCharacter():WaitForChild("HumanoidRootPart")
end

local function tweenTo(targetCFrame)
    local hrp = getHRP()
    local distance = (hrp.CFrame.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(distance / 16, 0.1, 12)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
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

local function moveToMachine(machine)
    local tpPart = machine:FindFirstChild("TPPart")
    if tpPart then
        tweenTo(tpPart.CFrame + Vector3.new(0, 3, 0))
    else
        local core = machine:FindFirstChild("MachineCore")
        if core then
            tweenTo(core.CFrame + Vector3.new(0, 3, 0))
        end
    end
end

local function fireMachinePrompt(machine)
    local prompt = machine.MachineCore:FindFirstChild("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
    end
end

local function waitForMachineDone(machine, timeout)
    timeout = timeout or 30
    local elapsed = 0
    while elapsed < timeout do
        local v = machine.MachineCore.Values.Extracted
        if not v or v.Value >= 100 then break end
        task.wait(0.5)
        elapsed += 0.5
    end
end

local function goToElevator()
    local floorHitbox = workspace.Elevator:FindFirstChild("FloorHitbox")
    if floorHitbox then
        tweenTo(floorHitbox.CFrame + Vector3.new(0, 3, 0))
    end
end

panicMode.Changed:Connect(function()
    if panicMode.Value == true then
        goToElevator()
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if panicMode.Value == true then continue end
        local target = findTargetMachine()
        if target then
            moveToMachine(target)
            task.wait(0.2)
            fireMachinePrompt(target)
            waitForMachineDone(target)
        end
    end
end)