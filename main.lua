-- main.lua (Twilight Zone Hub test)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TwilightZoneUI"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.3, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "🌌 Twilight Zone Hub (TEST)"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.Parent = Frame

-- Button 1
local Button1 = Instance.new("TextButton")
Button1.Text = "Test Button 1"
Button1.Size = UDim2.new(1, -20, 0, 40)
Button1.Position = UDim2.new(0, 10, 0, 60)
Button1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Button1.TextColor3 = Color3.fromRGB(255, 255, 255)
Button1.Font = Enum.Font.SourceSans
Button1.TextSize = 18
Button1.Parent = Frame

Button1.MouseButton1Click:Connect(function()
    print("[Twilight Zone] Button 1 clicked")
end)

-- Button 2
local Button2 = Instance.new("TextButton")
Button2.Text = "Test Button 2"
Button2.Size = UDim2.new(1, -20, 0, 40)
Button2.Position = UDim2.new(0, 10, 0, 110)
Button2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Button2.TextColor3 = Color3.fromRGB(255, 255, 255)
Button2.Font = Enum.Font.SourceSans
Button2.TextSize = 18
Button2.Parent = Frame

Button2.MouseButton1Click:Connect(function()
    print("[Twilight Zone] Button 2 clicked")
end)
