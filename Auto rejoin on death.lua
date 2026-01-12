local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local targetGameId = 16116270224

local function teleport()
	TeleportService:Teleport(targetGameId, player)
end

local playerGui = player:WaitForChild("PlayerGui")

local function checkDeathScreen(deathScreen)
	spawn(function()
		while deathScreen and deathScreen.Parent do
			if deathScreen.Visible then
				teleport()
				break
			end
			task.wait(0.1)
		end
	end)
end

playerGui.ChildAdded:Connect(function(child)
	if child.Name == "DeathGui" then
		child.ChildAdded:Connect(function(screen)
			if screen.Name == "DeathScreen" then
				checkDeathScreen(screen)
			end
		end)

		local existingScreen = child:FindFirstChild("DeathScreen")
		if existingScreen then
			checkDeathScreen(existingScreen)
		end
	end
end)

local existingDeathGui = playerGui:FindFirstChild("DeathGui")
if existingDeathGui then
	local existingScreen = existingDeathGui:FindFirstChild("DeathScreen")
	if existingScreen then
		checkDeathScreen(existingScreen)
	end
end