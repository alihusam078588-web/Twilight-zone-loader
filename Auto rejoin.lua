local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local targetGameId = 16116270224
local player = Players.LocalPlayer

-- Wait until CurrentRoom appears (up to 30 seconds)
local currentRoom = Workspace:WaitForChild("CurrentRoom", 30)

if not currentRoom then
    warn("CurrentRoom not found. Script stopped.")
    return
end

-- Wait a moment so players load
task.wait(1)

local playerCount = #Players:GetPlayers()

if playerCount > 2 then
    TeleportService:Teleport(targetGameId, player)
else
    print("Only", playerCount, "players — not teleporting")
end