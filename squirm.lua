local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

task.spawn(function()
    while task.wait(0.05) do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if typeof(obj) == "Instance" and obj.Name and obj.Name:find("SquirmMonster") then
                pcall(function()
                    if obj.Parent then
                        obj:Destroy()
                    end
                end)
            end
        end
    end
end)

local function tapGui(guiObject)
    if not guiObject then return end
    
    local absPos = guiObject.AbsolutePosition
    local absSize = guiObject.AbsoluteSize
    
    local x = absPos.X + absSize.X / 2
    local y = absPos.Y + absSize.Y / 2

    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.01)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

local function pressKey(key)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(0.02)
    VIM:SendKeyEvent(false, key, false, game)
end

task.spawn(function()
    while task.wait(0.1) do
        local gui = player:FindFirstChild("PlayerGui")
        if gui then
            local ui = gui:FindFirstChild("TwistedSquirmEscapeUI")
            if ui then
                local left = ui:FindFirstChild("LeftTouchZone")
                local right = ui:FindFirstChild("RightTouchZone")

                if left and right and left.Visible and right.Visible then
                    while left.Visible and right.Visible do
                        if UIS.TouchEnabled then
                            tapGui(left)
                            task.wait(0.05)
                            tapGui(right)
                            task.wait(0.05)
                        else
                            pressKey(Enum.KeyCode.A)
                            task.wait(0.05)
                            pressKey(Enum.KeyCode.D)
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)