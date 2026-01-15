-- ==================== AntiCheat Removal (TOP) ====================
pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local events = ReplicatedStorage:WaitForChild("Events", 5)
    if events then
        local antiCheat = events:FindFirstChild("AntiCheatTrigger")
        if antiCheat then
            antiCheat:Destroy()
        end
    end
end)

-- ==================== Services ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== State ====================
local running = true
local savedCFrame = nil

-- ==================== STOP IF CurrentRoom EXISTS ====================
if workspace:FindFirstChild("CurrentRoom") then
    return
end

-- ==================== Get HumanoidRootPart ====================
local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- ==================== Check leaveButton ====================
local function leaveButtonExists()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return false end

    local mainGui = gui:FindFirstChild("MainGui")
    if not mainGui then return false end

    return mainGui:FindFirstChild("leaveButton") ~= nil
end

-- ==================== Main Logic (Teleport every 10s) ====================
task.spawn(function()
    local hrp = getHRP()
    local gate = workspace
        :WaitForChild("Elevators")
        :WaitForChild("Gate")
        :WaitForChild("Gate")

    savedCFrame = hrp.CFrame

    while running do
        -- Stop if CurrentRoom appears
        if workspace:FindFirstChild("CurrentRoom") then
            running = false
            break
        end

        -- Teleport to elevator
        hrp.CFrame = gate.CFrame

        -- Wait 10 seconds
        task.wait(10)

        -- If leaveButton appears → teleport back & stop
        if leaveButtonExists() then
            hrp.CFrame = savedCFrame
            running = false
            break
        end
    end
end)