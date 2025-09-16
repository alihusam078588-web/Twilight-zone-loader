-- main.lua (SAFE test version)
-- A small, harmless Twilight Zone test GUI for loader verification.
-- DOES NOT interact with game state or remotes.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("Twilight Zone main script loaded (SAFE test).")

-- small GUI container
local GUI_NAME = "TZ_Safe_Test_v1"
if PlayerGui:FindFirstChild(GUI_NAME) then
    pcall(function() PlayerGui[GUI_NAME]:Destroy() end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,200,0,120)
frame.Position = UDim2.new(0.02,0,0.15,0)
frame.BackgroundColor3 = Color3.fromRGB(22,22,22)
frame.BorderSizePixel = 0
pcall(function() Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6) end)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -10, 0, 24)
title.Position = UDim2.new(0,6,0,6)
title.BackgroundTransparency = 1
title.Text = "Twilight Zone (SAFE)"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(230,230,230)

local info = Instance.new("TextLabel", frame)
info.Size = UDim2.new(1, -10, 0, 50)
info.Position = UDim2.new(0,6,0,34)
info.BackgroundTransparency = 1
info.Text = "This is a safe test UI.\nUse this to verify your loader and layout."
info.Font = Enum.Font.SourceSans
info.TextSize = 12
info.TextColor3 = Color3.fromRGB(180,180,180)
info.TextWrapped = true

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -12, 0, 28)
btn.Position = UDim2.new(0,6,1,-38)
btn.BackgroundColor3 = Color3.fromRGB(80,120,200)
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.Text = "Log Test Message"
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 14
pcall(function() Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6) end)

btn.MouseButton1Click:Connect(function()
    print("[TZ-SAFE] Test button clicked by", LocalPlayer.Name)
    -- update the info label with a small feedback (local only)
    info.Text = "Last pressed: "..os.date("%X")
end)

print("[TZ-SAFE] GUI created. You can now test your loader or launcher.")
