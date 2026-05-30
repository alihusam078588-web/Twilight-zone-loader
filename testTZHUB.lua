local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local panicValue = workspace.Info.Panic

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    return getCharacter():WaitForChild("HumanoidRootPart")
end

local function tweenStep(targetCFrame, speed)
    speed = speed or 35
    local hrp = getHRP()
    local distance = (hrp.CFrame.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(distance / speed, 0.1, 8)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local UNDERGROUND_Y = -30

local function moveToPosition(targetPos)
    local hrp = getHRP()
    local currentPos = hrp.Position
    tweenStep(CFrame.new(currentPos.X, UNDERGROUND_Y, currentPos.Z), 35)
    tweenStep(CFrame.new(targetPos.X, UNDERGROUND_Y, targetPos.Z), 35)
    tweenStep(CFrame.new(targetPos.X, targetPos.Y + 3, targetPos.Z), 35)
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
        moveToPosition(floorHitbox.Position)
    end
end

panicValue.Changed:Connect(function()
    if panicValue.Value == true then
        goToElevator()
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if panicValue.Value == true then continue end

        local target = findTargetMachine()
        if target then
            local machinePos = target.MachineCore.Position
            moveToPosition(machinePos)
            task.wait(0.2)
            fireMachinePrompt(target)
            waitForMachineDone(target)
        end
    end
end)