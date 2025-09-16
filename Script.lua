-- Twilight Zone Script (script.lua)
-- This is where your main features go

-- Example: Notify when loaded
game.StarterGui:SetCore("SendNotification", {
    Title = "Twilight Zone";
    Text = "Script Loaded Successfully!";
    Duration = 5;
})

-- Example Feature: ESP (Players)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function createESP(player)
    if player.Character and player.Character:FindFirstChild("Head") then
        if not player.Character.Head:FindFirstChild("ESP") then
            local billboard = Instance.new("BillboardGui", player.Character.Head)
            billboard.Name = "ESP"
            billboard.Size = UDim2.new(0, 100, 0, 50)
            billboard.AlwaysOnTop = true
            billboard.Adornee = player.Character.Head

            local text = Instance.new("TextLabel", billboard)
            text.Size = UDim2.new(1, 0, 1, 0)
            text.Text = player.Name
            text.TextColor3 = Color3.fromRGB(255, 0, 0)
            text.BackgroundTransparency = 1
        end
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            createESP(player)
        end
    end
end)

-- Example Feature: Teleport to Spawn
function teleportToSpawn()
    local lp = Players.LocalPlayer
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0) -- change position
    end
end

-- Keybind Example (Press "T" to teleport)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.T then
        teleportToSpawn()
    end
end)
