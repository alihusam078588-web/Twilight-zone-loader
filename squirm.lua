local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

local function deleteIfMonster(obj)
    if obj.Name == "SquirmMonster" then
        pcall(function()
            obj:Destroy()
        end)
    end
end

-- Delete already existing monsters
for _, obj in ipairs(Workspace:GetDescendants()) do
    deleteIfMonster(obj)
end

-- Delete future monsters instantly
Workspace.DescendantAdded:Connect(function(obj)
    deleteIfMonster(obj)
end)

-- UI auto tap system
local gui = player:WaitForChild("PlayerGui")
local ui = gui:WaitForChild("TwistedSquirmEscapeUI")

local leftZone = ui:WaitForChild("LeftTouchZone")
local rightZone = ui:WaitForChild("RightTouchZone")

local function tap(x, y)
    pcall(function()
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local LEFT1_X, LEFT1_Y = 80,171
local LEFT2_X, LEFT2_Y = 76,179
local RIGHT1_X, RIGHT1_Y = 669,174
local RIGHT2_X, RIGHT2_Y = 673,178

local function zonesVisible()
    return leftZone.Visible and rightZone.Visible
end

task.spawn(function()
    while true do
        repeat task.wait() until zonesVisible()

        while zonesVisible() do
            tap(LEFT1_X, LEFT1_Y)
            if not zonesVisible() then break end
            task.wait(0.06)

            tap(LEFT2_X, LEFT2_Y)
            if not zonesVisible() then break end
            task.wait(0.06)

            tap(RIGHT1_X, RIGHT1_Y)
            if not zonesVisible() then break end
            task.wait(0.06)

            tap(RIGHT2_X, RIGHT2_Y)
            if not zonesVisible() then break end
            task.wait(0.06)
        end
    end
end)