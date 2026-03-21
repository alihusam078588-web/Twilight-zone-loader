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
local Workspace = game:GetService("Workspace")

local currentRoom = Workspace:WaitForChild("CurrentRoom")
local map = currentRoom:GetChildren()[1]

local function deleteMonsters()
    local monstersFolder = map:FindFirstChild("Monsters")
    if monstersFolder then
        for _, obj in ipairs(monstersFolder:GetChildren()) do
            if obj.Name == "SquirmMonster" then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
    end
end

deleteMonsters()

if map:FindFirstChild("Monsters") then
    map.Monsters.DescendantAdded:Connect(function(obj)
        if obj.Name == "SquirmMonster" then
            pcall(function()
                obj:Destroy()
            end)
        end
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        deleteMonsters()
    end
end)