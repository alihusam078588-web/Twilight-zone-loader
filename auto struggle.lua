local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local function tap(x, y)
    pcall(function()
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function getCenter(guiObject)
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return pos.X + size.X/2, pos.Y + size.Y/2
end

task.spawn(function()
    while true do
        local ui = gui:FindFirstChild("TwistedSquirmEscapeUI")

        if ui then
            local left = ui:FindFirstChild("LeftTouchZone")
            local right = ui:FindFirstChild("RightTouchZone")

            if left and right and left.Visible and right.Visible then
                while left.Visible and right.Visible do
                    
                    local lx, ly = getCenter(left)
                    local rx, ry = getCenter(right)

                    tap(lx, ly)
                    tap(rx, ry)

                    task.wait(0.03)
                end
            end
        end

        task.wait(0.1)
    end
end)