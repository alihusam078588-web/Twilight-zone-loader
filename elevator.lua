local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local inGamePlayers = workspace:WaitForChild("InGamePlayers")
local elevatorModel = workspace:WaitForChild("Elevators"):WaitForChild("Elevator")

local elevatorPart =
	elevatorModel.PrimaryPart
	or elevatorModel:FindFirstChildWhichIsA("BasePart")

local function teleportTwice()
	local character = LocalPlayer.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if not elevatorPart then return end

	for i = 1, 2 do
		hrp.CFrame = elevatorPart.CFrame + Vector3.new(0, 5, 0)
		task.wait(0.1)
	end
end

local function checkPlayers()
	for _, folder in ipairs(inGamePlayers:GetChildren()) do
		
		if folder.Name ~= LocalPlayer.Name then
			local stats = folder:FindFirstChild("Stats")

			if stats then
				local inElevator = stats:FindFirstChild("InElevator")

				if inElevator
					and inElevator:IsA("BoolValue")
					and inElevator.Value then

					teleportTwice()
					return
				end
			end
		end
	end
end

while task.wait(0.2) do
	checkPlayers()
end
