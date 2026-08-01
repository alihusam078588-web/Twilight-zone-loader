local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local DISCORD_LINK = "https://discord.gg/qxCkUTGerf"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	setclipboard(DISCORD_LINK)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NotifyGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5,0.5)
main.Position = UDim2.fromScale(0.5,0.5)
main.Size = UDim2.fromOffset(0,0)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner",main).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke")
stroke.Parent = main
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(99,102,241)

local title = Instance.new("TextLabel")
title.Parent = main
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,-20,0,35)
title.Position = UDim2.fromOffset(10,10)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Text = "Before Running The Script"

local msg = Instance.new("TextLabel")
msg.Parent = main
msg.BackgroundTransparency = 1
msg.Position = UDim2.fromOffset(15,50)
msg.Size = UDim2.new(1,-30,0,150)
msg.Font = Enum.Font.Gotham
msg.TextWrapped = true
msg.TextYAlignment = Enum.TextYAlignment.Top
msg.TextSize = 14
msg.TextColor3 = Color3.fromRGB(220,220,220)
msg.Text =
[[The Discord invite has already been copied to your clipboard.

If the script doesn't load after a few minutes, open the Developer Console and copy the error.

game.StarterGui:SetCore("DevConsoleVisible", true)

Join our Discord server and send us the error so we can help you.
After clicking Continue the script will run.]]

local copied = Instance.new("TextLabel")
copied.Parent = main
copied.BackgroundTransparency = 1
copied.Position = UDim2.new(0,0,1,-70)
copied.Size = UDim2.new(1,0,0,20)
copied.Font = Enum.Font.GothamBold
copied.TextSize = 13
copied.TextColor3 = Color3.fromRGB(80,255,120)
copied.Text = "Discord link copied to clipboard!"

local button = Instance.new("TextButton")
button.Parent = main
button.Size = UDim2.new(1,-20,0,38)
button.Position = UDim2.new(0,10,1,-45)
button.Text = "Continue"
button.Font = Enum.Font.GothamBold
button.TextSize = 15
button.TextColor3 = Color3.new(1,1,1)
button.BackgroundColor3 = Color3.fromRGB(99,102,241)
button.BorderSizePixel = 0
Instance.new("UICorner",button).CornerRadius = UDim.new(0,8)


TweenService:Create(
	main,
	TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
	{Size=UDim2.fromOffset(450,280)}
):Play()


task.spawn(function()
	while gui.Parent do
		TweenService:Create(
			stroke,
			TweenInfo.new(1.5),
			{Color=Color3.fromHSV(math.random(),0.7,1)}
		):Play()
		task.wait(1.5)
	end
end)

button.MouseEnter:Connect(function()
	TweenService:Create(
		button,
		TweenInfo.new(.15),
		{
			BackgroundColor3=Color3.fromRGB(125,128,255),
			Size=UDim2.new(1,-16,0,42)
		}
	):Play()
end)

button.MouseLeave:Connect(function()
	TweenService:Create(
		button,
		TweenInfo.new(.15),
		{
			BackgroundColor3=Color3.fromRGB(99,102,241),
			Size=UDim2.new(1,-20,0,38)
		}
	):Play()
end)

local closing = false

local function Close()
	if closing then
		return
	end

	closing = true

	
	button.Active = false
	button.AutoButtonColor = false
	button.Text = "Running script..."

	
	copied.Text = "After clicking Continue, the script will run now."
	copied.TextColor3 = Color3.fromRGB(255, 255, 120)

	
	TweenService:Create(
		main,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad),
		{
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1
		}
	):Play()

	for _, v in ipairs(main:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			TweenService:Create(
				v,
				TweenInfo.new(0.2),
				{TextTransparency = 1}
			):Play()
		end
	end

	task.wait(0.3)
	gui:Destroy()

	
	loadstring(game:HttpGet(
		"https://www.keyforge.win/v1/load/cms8srp7q0e1838kvx40dw543?e=1&script=cms8sugct0ebf38kvveufk8el&lsig=wpxEWkrcykvYDTKM78E6358XjJqqUMsPKh8SzLGLUqU"
		.. "&_cb=" .. tostring(os.clock()) .. "-" .. tostring(math.random(1, 1e9)),
		true
	))()
end

button.MouseButton1Click:Connect(Close)

UserInputService.InputBegan:Connect(function(input,gp)
	if gp then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape then
		Close()
	end
end)

print("Discord link copied to clipboard")
