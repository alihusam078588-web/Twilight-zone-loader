local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

task.spawn(function()
    while true do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "SquirmMonster" then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
        task.wait(0.3)
    end
end)

Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "SquirmMonster" then
        pcall(function()
            obj:Destroy()
        end)
    end
end)

local function tap(x,y)
    pcall(function()
        VIM:SendMouseButtonEvent(x,y,0,true,game,1)
        task.wait(0.015)
        VIM:SendMouseButtonEvent(x,y,0,false,game,1)
    end)
end

local function pressKey(key)
    pcall(function()
        VIM:SendKeyEvent(true,key,false,game)
        task.wait(0.02)
        VIM:SendKeyEvent(false,key,false,game)
    end)
end

local LEFT1_X, LEFT1_Y = 80,171
local LEFT2_X, LEFT2_Y = 76,179
local RIGHT1_X, RIGHT1_Y = 669,174
local RIGHT2_X, RIGHT2_Y = 673,178

task.spawn(function()
    while true do
        local gui = player:FindFirstChild("PlayerGui")
        if gui then
            local ui = gui:FindFirstChild("TwistedSquirmEscapeUI")
            if ui then
                local leftZone = ui:FindFirstChild("LeftTouchZone")
                local rightZone = ui:FindFirstChild("RightTouchZone")

                if leftZone and rightZone and leftZone.Visible and rightZone.Visible then
                    while leftZone.Visible and rightZone.Visible do

                        if UIS.TouchEnabled then
                            tap(LEFT1_X, LEFT1_Y)
                            task.wait(0.05)

                            tap(LEFT2_X, LEFT2_Y)
                            task.wait(0.05)

                            tap(RIGHT1_X, RIGHT1_Y)
                            task.wait(0.05)

                            tap(RIGHT2_X, RIGHT2_Y)
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
        task.wait(0.1)
    end
end)