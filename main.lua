-- main.lua (Twilight Zone Hub)

-- Simple UI Library
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TwilightZoneUI"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.3, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "🌌 Twilight Zone Hub"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.Parent = Frame

-- Example Button
local ESPButton = Instance.new("TextButton")
ESPButton.Text = "Toggle ESP"
ESPButton.Size = UDim2.new(1, -20, 0, 40)
ESPButton.Position = UDim2.new(0, 10, 0, 60)
ESPButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.Font = Enum.Font.SourceSans
ESPButton.TextSize = 18
ESPButton.Parent = Frame

ESPButton.MouseButton1Click:Connect(function()
    print("[Twilight Zone] ESP toggled!") 
    -- ⚡ Here we will add the ESP feature
end)

-- Another Example Button
local SkillcheckButton = Instance.new("TextButton")
SkillcheckButton.Text = "Always Perfect Skillcheck"
SkillcheckButton.Size = UDim2.new(1, -20, 0, 40)
SkillcheckButton.Position = UDim2.new(0, 10, 0, 110)
SkillcheckButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SkillcheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SkillcheckButton.Font = Enum.Font.SourceSans
SkillcheckButton.TextSize = 18
SkillcheckButton.Parent = Frame

SkillcheckButton.MouseButton1Click:Connect(function()
    print("[Twilight Zone] Always Perfect Skillcheck enabled!") 
    -- ⚡ Here we will add skillcheck bypass code
end)
