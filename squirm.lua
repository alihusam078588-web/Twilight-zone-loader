local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local function scanAndDelete()
    local currentRoom = Workspace:FindFirstChild("CurrentRoom")
    if not currentRoom then return end
    for _, map in pairs(currentRoom:GetChildren()) do
        local monstersFolder = map:FindFirstChild("Monsters")
        if monstersFolder then
            for _, monster in pairs(monstersFolder:GetChildren()) do
                if monster.Name == "SquirmMonster" then
                    monster:Destroy()
                end
            end
            monstersFolder.ChildAdded:Connect(function(child)
                if child.Name == "SquirmMonster" then
                    child:Destroy()
                end
            end)
        end
    end
end

RunService.Heartbeat:Connect(scanAndDelete)

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "CurrentRoom" then
        child.ChildAdded:Connect(scanAndDelete)
    end
end)
local Players = game:GetService("Players")
local task = task
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local gui = player:WaitForChild("PlayerGui")
local ui = gui:WaitForChild("TwistedSquirmEscapeUI")

local leftZone = ui:WaitForChild("LeftTouchZone")
local rightZone = ui:WaitForChild("RightTouchZone")

local function tap(x, y)
    if not VIM then return end
    local ok, err = pcall(function()
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
    if not ok then
        warn("tap error:", err)
    end
end

local LEFT1_X, LEFT1_Y = 80, 171
local LEFT2_X, LEFT2_Y = 76, 179
local RIGHT1_X, RIGHT1_Y = 669, 174
local RIGHT2_X, RIGHT2_Y = 673, 178

task.spawn(function()
    while true do
        repeat
            task.wait(0.05)
        until (leftZone and rightZone and leftZone.Visible and rightZone.Visible)

        while leftZone and rightZone and leftZone.Visible and rightZone.Visible do
            tap(LEFT1_X, LEFT1_Y)
            task.wait(0.08)
            tap(LEFT2_X, LEFT2_Y)
            task.wait(0.08)

            tap(RIGHT1_X, RIGHT1_Y)
            task.wait(0.08)
            tap(RIGHT2_X, RIGHT2_Y)
            task.wait(0.08)

            task.wait(0.05)
        end

        task.wait(0.1)
    end
end)