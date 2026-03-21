local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local remote = RS:WaitForChild("Events"):WaitForChild("TwistedSquirmGrab")

local running = false
local dir = "left"

remote.OnClientEvent:Connect(function(action)
    if action == "GrabStart" then
        running = true
    elseif action == "GrabEnd" then
        running = false
    end
end)

task.spawn(function()
    while true do
        task.wait(0.06)

        if running then
            if dir == "left" then
                remote:FireServer("Struggle", "left")
                dir = "right"
            else
                remote:FireServer("Struggle", "right")
                dir = "left"
            end
        end
    end
end)