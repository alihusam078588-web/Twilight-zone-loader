--[[
	ToonsUI  v1.0.0
	A glossy "aero" style UI library for Roblox, styled after the Toons Universe menus
	(blue wave windows, glass header strips, candy-gloss pill buttons, ON/OFF pill toggles,
	round glass slider knobs, cream pop-up cards and bubbly UI sounds).

	Usage:
		local ToonsUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/ToonsUI.lua"))()
		local Window = ToonsUI:CreateWindow({ Title = "Settings.exe" })
		local Tab = Window:CreateTab({ Name = "Main" })
		Tab:CreateToggle({ Name = "Particles", Default = true, Callback = print })

	Also works as a ModuleScript (require it from a LocalScript).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local WHITE = Color3.new(1, 1, 1)
local function hex(s: string): Color3
	return Color3.fromHex(s)
end

local Library = {
	Version = "1.0.0",
	Flags = {},
	SoundsEnabled = true,
	Volume = 1,
	Windows = {},
	_connections = {},
}

--------------------------------------------------------------------------------
-- Style
--------------------------------------------------------------------------------

Library.Fonts = {
	Regular = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Medium),
	Bold = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
	Heavy = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.ExtraBold),
	Body = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	BodyBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
}

-- Candy-gloss button colours sampled from the game's pill buttons.
Library.Palettes = {
	Blue = { Light = hex("b1efff"), Base = hex("00b8ff"), Mid = hex("0092f3"), Dark = hex("0663da"), Glow = hex("00a6fe"), Rim = hex("053e9d") },
	Lavender = { Light = hex("d0e3ff"), Base = hex("91a9e6"), Mid = hex("8d92ca"), Dark = hex("7478a9"), Glow = hex("919ed8"), Rim = hex("47547a") },
	Green = { Light = hex("b9fbac"), Base = hex("5de155"), Mid = hex("42d24a"), Dark = hex("2eb644"), Glow = hex("56dd52"), Rim = hex("0b662d") },
	Red = { Light = hex("ffc5aa"), Base = hex("ff6d3a"), Mid = hex("f53e0e"), Dark = hex("c51a38"), Glow = hex("ff5312"), Rim = hex("9c0403") },
	Yellow = { Light = hex("ffffab"), Base = hex("fed926"), Mid = hex("ffc300"), Dark = hex("f6a902"), Glow = hex("ffd71d"), Rim = hex("b27215") },
	Orange = { Light = hex("ffe980"), Base = hex("f69c01"), Mid = hex("ec8401"), Dark = hex("e46a02"), Glow = hex("f59901"), Rim = hex("bf4d01") },
	Purple = { Light = hex("ffccff"), Base = hex("f457ff"), Mid = hex("c433db"), Dark = hex("9908b7"), Glow = hex("f152ff"), Rim = hex("7b1ba0") },
	Cyan = { Light = hex("80fffc"), Base = hex("01d2d1"), Mid = hex("00b9c1"), Dark = hex("00a0b4"), Glow = hex("01cfcf"), Rim = hex("008692") },
	White = { Light = hex("ffffff"), Base = hex("f7fcff"), Mid = hex("e6f3ff"), Dark = hex("cfe3fa"), Glow = hex("f2faff"), Rim = hex("2c5fb5"), Text = hex("3a6bc4"), TextStroke = hex("ffffff") },
}

Library.Theme = {
	WindowStops = { { 0, hex("1aa8ff") }, { 0.3, hex("0087fe") }, { 0.55, hex("0070f5") }, { 0.8, hex("0083fa") }, { 1, hex("00b1ff") } },
	WindowRim = hex("0a3d8f"),
	WaveImage = "rbxassetid://133562809418400",
	WaveTransparency = 0.15,
	ShadowImage = "rbxassetid://6014261993",
	InsetStops = { { 0, hex("185492") }, { 0.25, hex("216fb7") }, { 0.6, hex("2773b9") }, { 1, hex("216fb7") } },
	InsetRim = hex("39b9ff"),
	GlassStops = { { 0, hex("ffffff") }, { 0.45, hex("e4f3ff") }, { 0.55, hex("cee8fc") }, { 1, hex("c3dff9") } },
	GlassRim = hex("7aa6dc"),
	Row = hex("54acff"),
	RowTransparency = 0.72,
	Text = WHITE,
	TextStroke = hex("2f78d8"),
	TitleStroke = hex("0d3d8a"),
	TrackStops = { { 0, hex("1d497e") }, { 0.45, hex("0c3f7b") }, { 0.7, hex("003477") }, { 1, hex("17467e") } },
	TrackRim = hex("082a57"),
	KnobStops = { { 0, hex("eef8ff") }, { 0.3, hex("d4eeff") }, { 0.6, hex("b5d4f4") }, { 0.85, hex("a3c2ea") }, { 1, hex("b6d6f5") } },
	KnobRim = hex("426cb8"),
	FillStops = { { 0, hex("d6ffd0") }, { 0.35, hex("8ae469") }, { 0.7, hex("4fc94a") }, { 1, hex("8df095") } },
	Cream = hex("fffef9"),
	Ink = hex("1f2667"),
	InkSoft = hex("3b629d"),
	CardHeaderStops = { { 0, hex("4a88f5") }, { 0.5, hex("2266de") }, { 1, hex("1d60c5") } },
	CardRim = hex("13347e"),
	KeyRowStops = { { 0, hex("2d5a92") }, { 0.5, hex("1c4c86") }, { 1, hex("093e81") } },
	KeyRim = hex("667aa0"),
	ChromeStops = { { 0, WHITE }, { 0.19, WHITE }, { 0.69, hex("c5d0e4") }, { 0.77, hex("fbfcff") }, { 1, WHITE } },
}

-- UI sounds (same ids the game uses). Any id that fails to load falls back to a built-in sound.
Library.Sounds = {
	Click = { Id = "rbxassetid://113015951282811", Volume = 0.35 },
	Bubbly = { Id = "rbxassetid://15675032796", Volume = 0.5 },
	Hover = { Id = "rbxassetid://114349858671788", Volume = 0.25 },
	Open = { Id = "rbxassetid://6874964659", Volume = 0.25 },
	Close = { Id = "rbxassetid://102378262791241", Volume = 0.3 },
	Tab = { Id = "rbxassetid://75778731670006", Volume = 0.3 },
	Toggle = { Id = "rbxassetid://15675032796", Volume = 0.5 },
	Notify = { Id = "rbxassetid://77834755610084", Volume = 0.5 },
	Prompt = { Id = "rbxassetid://6647897822", Volume = 0.5 },
}
local FALLBACK_SOUND = "rbxasset://sounds/electronicpingshort.wav"

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function track(connection: RBXScriptConnection): RBXScriptConnection
	table.insert(Library._connections, connection)
	return connection
end

local function New(className: string, props: { [string]: any }?, children: { Instance }?): any
	local obj = Instance.new(className)
	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			(obj :: any)[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

local function Tween(obj: Instance, props: { [string]: any }, time: number?, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function Corner(radius: any): UICorner
	return New("UICorner", { CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8) })
end

local function Stroke(color: Color3, thickness: number?, transparency: number?, border: boolean?): UIStroke
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = border and Enum.ApplyStrokeMode.Border or Enum.ApplyStrokeMode.Contextual,
	})
end

local function Sequence(stops: { { any } }): ColorSequence
	local points = {}
	for i, stop in ipairs(stops) do
		points[i] = ColorSequenceKeypoint.new(stop[1], stop[2])
	end
	return ColorSequence.new(points)
end

local function Gradient(stops: { { any } }, rotation: number?): UIGradient
	return New("UIGradient", { Color = Sequence(stops), Rotation = rotation or 90 })
end

local function PaletteStops(p: { [string]: Color3 }): { { any } }
	return { { 0, p.Light }, { 0.3, p.Base }, { 0.55, p.Mid }, { 0.8, p.Dark }, { 1, p.Glow } }
end

local function GetPalette(name: any): { [string]: Color3 }
	if typeof(name) == "table" then
		return name
	end
	return Library.Palettes[name] or Library.Palettes.Blue
end

-- White glossy highlight across the top half of a shape (the "Shine" in the game's buttons).
local function Shine(parent: Instance, radius: UDim?, height: number?): Frame
	return New("Frame", {
		Name = "Shine",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.new(1, -8, height or 0.46, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = parent,
	}, {
		Corner(radius or UDim.new(1, 0)),
		New("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.85) }),
		}),
	})
end

local function Label(props: { [string]: any }, strokeColor: Color3?, strokeThickness: number?): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = Library.Fonts.Bold,
		TextColor3 = Library.Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Text = "",
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local label = New("TextLabel", defaults)
	if strokeColor then
		Stroke(strokeColor, strokeThickness or 1.5).Parent = label
	end
	return label
end

local function Chrome(label: GuiObject)
	Gradient(Library.Theme.ChromeStops, 90).Parent = label
end

local function IsClick(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function SafeCall(callback: any, ...)
	if typeof(callback) == "function" then
		local ok, err = pcall(callback, ...)
		if not ok then
			warn("[ToonsUI] callback error: " .. tostring(err))
		end
	end
end

--------------------------------------------------------------------------------
-- Root ScreenGui
--------------------------------------------------------------------------------

local function GetGuiParent(): Instance
	local ok, hui = pcall(function()
		return (getfenv() :: any).gethui()
	end)
	if ok and typeof(hui) == "Instance" then
		return hui
	end
	local canUseCore = pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent = CoreGui
		probe:Destroy()
	end)
	if canUseCore then
		return CoreGui
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetGuiParent()
local old = GuiParent:FindFirstChild("ToonsUI")
if old then
	old:Destroy()
end

local Root = New("ScreenGui", {
	Name = "ToonsUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = GuiParent,
})
Library.Gui = Root

local NotifyHolder = New("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 16),
	Size = UDim2.new(0, 310, 1, -32),
	BackgroundTransparency = 1,
	ZIndex = 100,
	Parent = Root,
}, {
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}),
})

--------------------------------------------------------------------------------
-- Sounds
--------------------------------------------------------------------------------

local SoundFolder = New("Folder", { Name = "Sounds", Parent = Root })
local SoundTemplates: { [string]: Sound } = {}
local lastPlayed: { [string]: number } = {}

function Library:LoadSounds()
	SoundFolder:ClearAllChildren()
	table.clear(SoundTemplates)
	local list = {}
	for name, info in pairs(self.Sounds) do
		local sound = New("Sound", { Name = name, SoundId = info.Id, Volume = info.Volume or 0.5, Parent = SoundFolder })
		SoundTemplates[name] = sound
		table.insert(list, sound)
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(list, function(assetId, status)
				if status ~= Enum.AssetFetchStatus.Success then
					for _, sound in ipairs(list) do
						if sound.SoundId == assetId then
							sound.SoundId = FALLBACK_SOUND
						end
					end
				end
			end)
		end)
	end)
end

function Library:PlaySound(name: string)
	if not self.SoundsEnabled then
		return
	end
	local template = SoundTemplates[name]
	if not template then
		return
	end
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < 0.05 then
		return
	end
	lastPlayed[name] = now
	local sound = template:Clone()
	sound.Volume = template.Volume * self.Volume
	sound.Parent = SoundFolder
	sound:Play()
	task.delay(math.max(sound.TimeLength, 3) + 0.5, function()
		sound:Destroy()
	end)
end

function Library:SetSoundsEnabled(enabled: boolean)
	self.SoundsEnabled = enabled
end

function Library:SetVolume(volume: number)
	self.Volume = math.clamp(volume, 0, 3)
end

Library:LoadSounds()

--------------------------------------------------------------------------------
-- Building blocks
--------------------------------------------------------------------------------

-- Hover grow / press squish / release bounce, like the game's buttons.
local function Bounce(button: GuiButton, target: GuiObject?, hoverSound: boolean?)
	local obj = target or button
	local scale = obj:FindFirstChildOfClass("UIScale") or New("UIScale", { Parent = obj })
	local hovering = false
	track(button.MouseEnter:Connect(function()
		hovering = true
		Tween(scale, { Scale = 1.04 }, 0.15)
		if hoverSound ~= false then
			Library:PlaySound("Hover")
		end
	end))
	track(button.MouseLeave:Connect(function()
		hovering = false
		Tween(scale, { Scale = 1 }, 0.15)
	end))
	track(button.MouseButton1Down:Connect(function()
		Tween(scale, { Scale = 0.93 }, 0.08)
	end))
	track(button.MouseButton1Up:Connect(function()
		Tween(scale, { Scale = hovering and 1.04 or 1 }, 0.3, Enum.EasingStyle.Back)
	end))
	track(button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			hovering = false
			Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		end
	end))
end

-- Candy-gloss pill button.
local function Glossy(paletteName: any, props: { [string]: any }, radius: UDim?)
	local palette = GetPalette(paletteName)
	local defaults = {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local button = New("TextButton", defaults)
	Corner(radius or UDim.new(1, 0)).Parent = button
	local gradient = Gradient(PaletteStops(palette), 90)
	gradient.Parent = button
	local stroke = Stroke(palette.Rim, 2, 0, true)
	stroke.Parent = button
	local shine = Shine(button, radius)

	local self = { Button = button, Gradient = gradient, Stroke = stroke, Shine = shine, Labels = {} }
	function self:AddText(text: string, size: number?): TextLabel
		local p = palette
		local label = Label({
			Name = "Text",
			Text = text,
			FontFace = Library.Fonts.Heavy,
			TextSize = size or 16,
			TextColor3 = p.Text or WHITE,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, -10, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
		}, p.TextStroke or p.Rim, 1.5)
		label.Parent = button
		table.insert(self.Labels, label)
		return label
	end
	function self:SetPalette(name: any)
		palette = GetPalette(name)
		gradient.Color = Sequence(PaletteStops(palette))
		stroke.Color = palette.Rim
		for _, label in ipairs(self.Labels) do
			label.TextColor3 = palette.Text or WHITE
			local s = label:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = palette.TextStroke or palette.Rim
			end
		end
	end
	return self
end

-- Light-blue glass strip (the game's "Top"/"Bott" frame pieces).
local function Glass(props: { [string]: any }, radius: number?): Frame
	local frame = New("Frame", props)
	frame.BackgroundColor3 = WHITE
	frame.BorderSizePixel = 0
	Corner(radius or 6).Parent = frame
	Gradient(Library.Theme.GlassStops, 90).Parent = frame
	Stroke(Library.Theme.GlassRim, 1.5, 0, true).Parent = frame
	return frame
end

-- Dark glossy track with a fill and a round glass knob (sliders / colour picker).
local function Bar(parent: Instance, fillStops: { { any } }, light: boolean?)
	local theme = Library.Theme
	local trackFrame = New("Frame", {
		Name = "Track",
		BackgroundColor3 = WHITE,
		BackgroundTransparency = light and 0.5 or 0,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = parent,
	}, { Corner(UDim.new(1, 0)) })
	if not light then
		Gradient(theme.TrackStops, 90).Parent = trackFrame
		Stroke(theme.TrackRim, 2, 0, true).Parent = trackFrame
	else
		Stroke(theme.TrackRim, 1.5, 0.3, true).Parent = trackFrame
	end
	local fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = trackFrame,
	}, { Corner(UDim.new(1, 0)), Gradient(fillStops, 90) })
	Shine(fill, nil, 0.45).ZIndex = 5
	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = trackFrame,
	}, { Corner(UDim.new(1, 0)), Gradient(theme.KnobStops, 90), Stroke(theme.KnobRim, 2, 0, true) })
	New("Frame", {
		Name = "Gleam",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.1, 0),
		Size = UDim2.new(0.62, 0, 0.38, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 7,
		Parent = knob,
	}, { Corner(UDim.new(1, 0)) })
	local hit = New("TextButton", {
		Name = "Hit",
		Text = "",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -8, 0.5, 0),
		Size = UDim2.new(1, 16, 0, 30),
		ZIndex = 8,
		Parent = trackFrame,
	})
	local knobScale = New("UIScale", { Parent = knob })

	local bar = { Track = trackFrame, Fill = fill, Knob = knob, Hit = hit }
	function bar.SetAlpha(alpha: number, instant: boolean?)
		local t = instant and 0 or 0.08
		Tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, t)
		Tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, t)
	end
	function bar.Bind(onAlpha: (number) -> ())
		local dragging = false
		local function update(x: number)
			local width = math.max(trackFrame.AbsoluteSize.X, 1)
			onAlpha(math.clamp((x - trackFrame.AbsolutePosition.X) / width, 0, 1))
		end
		track(hit.InputBegan:Connect(function(input)
			if IsClick(input) then
				dragging = true
				Tween(knobScale, { Scale = 1.2 }, 0.12)
				update(input.Position.X)
			end
		end))
		track(UserInputService.InputChanged:Connect(function(input)
			if dragging and IsMove(input) then
				update(input.Position.X)
			end
		end))
		track(UserInputService.InputEnded:Connect(function(input)
			if dragging and IsClick(input) then
				dragging = false
				Tween(knobScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
			end
		end))
	end
	return bar
end

local function MakeDraggable(handle: GuiObject, target: GuiObject, onMoved: ((number) -> ())?)
	local dragging, dragStart, startPos, dragInput = false, nil, nil, nil
	track(handle.InputBegan:Connect(function(input)
		if IsClick(input) then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					connection:Disconnect()
				end
			end)
		end
	end))
	track(handle.InputChanged:Connect(function(input)
		if IsMove(input) then
			dragInput = input
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			if onMoved then
				onMoved(delta.Magnitude)
			end
		end
	end))
end

local function SpawnBubbles(layer: Frame, count: number)
	for _ = 1, count do
		local size = math.random(12, 38)
		local bubble = New("Frame", {
			Name = "Bubble",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			Parent = layer,
		}, {
			Corner(UDim.new(1, 0)),
			Stroke(WHITE, 1, 0.55, true),
			New("Frame", {
				Position = UDim2.new(0.18, 0, 0.14, 0),
				Size = UDim2.new(0.4, 0, 0.28, 0),
				BackgroundColor3 = WHITE,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
			}, { Corner(UDim.new(1, 0)) }),
		})
		task.spawn(function()
			local first = true
			while bubble.Parent do
				local x = math.random(5, 95) / 100
				local startY = first and math.random(10, 100) / 100 or 1.15
				first = false
				bubble.Position = UDim2.new(x, 0, startY, 0)
				local duration = math.random(90, 180) / 10 * (startY + 0.15)
				local t = Tween(bubble, { Position = UDim2.new(x + math.random(-8, 8) / 100, 0, -0.15, 0) }, duration, Enum.EasingStyle.Linear)
				t.Completed:Wait()
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- Notifications & dialogs
--------------------------------------------------------------------------------

local notifyOrder = 0

--[[
	Library:Notify({
		Title = "Saved!",
		Content = "Your settings were saved.",
		Duration = 4,
		Color = "Green",   -- palette for the timer bar
	})
]]
function Library:Notify(opts: { [string]: any })
	opts = opts or {}
	local theme = self.Theme
	notifyOrder += 1
	local holder = New("Frame", {
		Name = "Notification",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = notifyOrder,
		ZIndex = 100,
		Parent = NotifyHolder,
	})
	local card = New("TextButton", {
		Name = "Card",
		Text = "",
		AutoButtonColor = false,
		Position = UDim2.new(1.2, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Cream,
		BorderSizePixel = 0,
		ZIndex = 100,
		Parent = holder,
	}, { Corner(10), Stroke(theme.CardRim, 2, 0, true) })
	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 101,
		Parent = card,
	}, { Corner(10), Gradient(theme.CardHeaderStops, 90) })
	New("Frame", { -- squares off the header's bottom corners
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 101,
		Parent = header,
	}, { Gradient({ { 0, hex("2266de") }, { 1, hex("1d60c5") } }, 90) })
	Shine(header, UDim.new(0, 8), 0.45).ZIndex = 102
	local title = Label({
		Text = opts.Title or "Notification",
		FontFace = self.Fonts.Heavy,
		TextSize = 17,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		ZIndex = 103,
		Parent = header,
	}, theme.TitleStroke, 1.5)
	Chrome(title)
	New("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 36),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = self.Fonts.Body,
		Text = opts.Content or "",
		TextColor3 = theme.Ink,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 101,
		Parent = card,
	})
	New("UIPadding", { PaddingBottom = UDim.new(0, 18), Parent = card })
	local timer = New("Frame", {
		Name = "Timer",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, 12),
		Size = UDim2.new(1, -20, 0, 5),
		BackgroundColor3 = hex("c9daf2"),
		BorderSizePixel = 0,
		ZIndex = 101,
		Parent = card,
	}, { Corner(UDim.new(1, 0)) })
	local timerFill = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 102,
		Parent = timer,
	}, { Corner(UDim.new(1, 0)), Gradient(PaletteStops(GetPalette(opts.Color or "Green")), 90) })

	self:PlaySound("Notify")
	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.45, Enum.EasingStyle.Back)
	local duration = opts.Duration or 4
	Tween(timerFill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		local t = Tween(card, { Position = UDim2.new(1.2, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		t.Completed:Wait()
		holder:Destroy()
	end
	card.Activated:Connect(function()
		Library:PlaySound("Click")
		close()
	end)
	task.delay(duration, close)
end

--[[
	Library:Dialog({
		Title = "Do you wish to purchase?",
		Content = "This will cost 100 coins.",
		Buttons = {
			{ Text = "CONFIRM", Color = "White", Callback = function() end },
			{ Text = "BACK", Color = "Red" },
		},
	})
	Default buttons: CONFIRM / BACK. `Callback(confirmed: boolean)` is called for the defaults.
]]
function Library:Dialog(opts: { [string]: any })
	opts = opts or {}
	local theme = self.Theme
	local overlay = New("TextButton", {
		Name = "DialogOverlay",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 200,
		Parent = Root,
	})
	local card = New("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 400, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Cream,
		BorderSizePixel = 0,
		ZIndex = 201,
		Parent = overlay,
	}, { Corner(14), Stroke(theme.CardRim, 3, 0, true) })
	local scale = New("UIScale", { Scale = 0.6, Parent = card })
	local band = New("Frame", {
		Name = "Band",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 202,
		Parent = card,
	}, { Corner(14), Gradient(theme.CardHeaderStops, 90) })
	New("Frame", {
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = hex("1d60c5"),
		BorderSizePixel = 0,
		ZIndex = 202,
		Parent = band,
	})
	Shine(band, UDim.new(0, 10), 0.5).ZIndex = 203
	local body = New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 22),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 202,
		Parent = card,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		New("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	New("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = self.Fonts.BodyBold,
		Text = opts.Title or "Are you sure?",
		TextColor3 = WHITE,
		TextSize = 22,
		TextWrapped = true,
		LayoutOrder = 1,
		ZIndex = 203,
		Parent = body,
	}, { Gradient({ { 0, hex("1d5cda") }, { 1, hex("152d82") } }, 90) })
	if opts.Content then
		New("TextLabel", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			FontFace = self.Fonts.Body,
			Text = opts.Content,
			TextColor3 = theme.InkSoft,
			TextSize = 15,
			TextWrapped = true,
			LayoutOrder = 2,
			ZIndex = 203,
			Parent = body,
		})
	end
	local row = New("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 3,
		ZIndex = 203,
		Parent = body,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local buttons = opts.Buttons
		or {
			{ Text = opts.ConfirmText or "CONFIRM", Color = "White", Callback = function()
				SafeCall(opts.Callback, true)
			end },
			{ Text = opts.CancelText or "BACK", Color = "Red", Callback = function()
				SafeCall(opts.Callback, false)
			end },
		}

	local closing = false
	local function close()
		if closing then
			return
		end
		closing = true
		Tween(overlay, { BackgroundTransparency = 1 }, 0.2)
		local t = Tween(scale, { Scale = 0 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		t.Completed:Wait()
		overlay:Destroy()
	end

	local width = math.min(160, math.floor((364 - 14 * (#buttons - 1)) / math.max(#buttons, 1)))
	for i, info in ipairs(buttons) do
		local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, width, 1, 0), LayoutOrder = i, ZIndex = 203, Parent = row })
		local gloss = Glossy(info.Color or "Blue", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, -4),
			ZIndex = 204,
			Parent = holder,
		}, UDim.new(0, 10))
		gloss.Shine.ZIndex = 205
		gloss:AddText(info.Text or "OK", 20).ZIndex = 206
		Bounce(gloss.Button)
		gloss.Button.Activated:Connect(function()
			Library:PlaySound("Click")
			SafeCall(info.Callback)
			close()
		end)
	end

	self:PlaySound("Prompt")
	Tween(overlay, { BackgroundTransparency = 0.45 }, 0.25)
	Tween(scale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
	return { Close = close }
end

--------------------------------------------------------------------------------
-- Elements (shared by tabs and sections)
--------------------------------------------------------------------------------

local Elements = {}
Elements.__index = Elements

function Elements:_order(): number
	self.Tab._layout += 1
	return self.Tab._layout
end

function Elements:_row(height: number, button: boolean?): any
	local theme = Library.Theme
	local row = New(button and "TextButton" or "Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = theme.RowTransparency,
		BorderSizePixel = 0,
		LayoutOrder = self:_order(),
		Parent = self.Container,
	}, {
		Corner(8),
		Gradient({ { 0, hex("8fd0ff") }, { 0.5, theme.Row }, { 1, hex("3f95ea") } }, 90),
		Stroke(WHITE, 1, 0.75, true),
	})
	if button then
		row.Text = ""
		row.AutoButtonColor = false
		track(row.MouseEnter:Connect(function()
			Tween(row, { BackgroundTransparency = theme.RowTransparency - 0.15 }, 0.12)
		end))
		track(row.MouseLeave:Connect(function()
			Tween(row, { BackgroundTransparency = theme.RowTransparency }, 0.12)
		end))
	end
	return row
end

function Elements:_title(row: GuiObject, text: string, rightSpace: number?, y: number?, height: number?): TextLabel
	return Label({
		Name = "Title",
		Text = text,
		TextSize = 17,
		Position = UDim2.new(0, 12, 0, y or 0),
		Size = UDim2.new(1, -(rightSpace or 0) - 20, 0, height or row.Size.Y.Offset),
		Parent = row,
	}, Library.Theme.TextStroke, 1.6)
end

local function SetFlag(opts: { [string]: any }, value: any)
	if opts.Flag then
		Library.Flags[opts.Flag] = value
	end
end

-- Section header: chrome caption + glass strip.
function Elements:CreateSection(name: string)
	local holder = New("Frame", {
		Name = "Section",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = self:_order(),
		Parent = self.Container,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 2) }),
	})
	local caption = Label({
		Text = string.upper(name or "Section"),
		FontFace = Library.Fonts.Heavy,
		TextSize = 16,
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		Parent = holder,
	}, Library.Theme.TitleStroke, 1.6)
	Chrome(caption)
	local strip = Glass({
		Name = "Strip",
		Size = UDim2.new(0, 10, 0, 6),
		LayoutOrder = 2,
		Parent = holder,
	}, 3)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = strip })
	local section = setmetatable({ Tab = self.Tab, Container = self.Container, Frame = holder }, Elements)
	function section:SetName(text: string)
		caption.Text = string.upper(text)
	end
	return section
end

function Elements:CreateLabel(text: string)
	local row = self:_row(34)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local label = Label({
		Text = text or "",
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -24, 0, 34),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = row,
	}, Library.Theme.TextStroke, 1.6)
	New("UIPadding", { PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0), Parent = label })
	return {
		Instance = row,
		Set = function(_, value: string)
			label.Text = value
		end,
	}
end

-- Cream card with a blue title band (like the game's pop-up cards).
function Elements:CreateParagraph(opts: { [string]: any })
	opts = opts or {}
	local theme = Library.Theme
	local card = New("Frame", {
		Name = "Paragraph",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Cream,
		BorderSizePixel = 0,
		LayoutOrder = self:_order(),
		Parent = self.Container,
	}, { Corner(10), Stroke(theme.CardRim, 2, 0, true), New("UIPadding", { PaddingBottom = UDim.new(0, 10) }) })
	local band = New("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = card,
	}, { Corner(10), Gradient(theme.CardHeaderStops, 90) })
	New("Frame", { Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = hex("1d60c5"), BorderSizePixel = 0, ZIndex = 2, Parent = band })
	Shine(band, UDim.new(0, 8), 0.45).ZIndex = 3
	local title = Label({
		Text = opts.Title or "Paragraph",
		FontFace = Library.Fonts.Heavy,
		TextSize = 16,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		ZIndex = 4,
		Parent = band,
	}, theme.TitleStroke, 1.5)
	Chrome(title)
	local content = New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 34),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = Library.Fonts.Body,
		Text = opts.Content or "",
		TextColor3 = theme.Ink,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2,
		Parent = card,
	})
	return {
		Instance = card,
		Set = function(_, newTitle: string?, newContent: string?)
			if newTitle then
				title.Text = newTitle
			end
			if newContent then
				content.Text = newContent
			end
		end,
	}
end

--[[ Tab:CreateButton({ Name = "Reset Settings", Color = "Red", Callback = function() end }) ]]
function Elements:CreateButton(opts: { [string]: any })
	opts = opts or {}
	local holder = New("Frame", {
		Name = "Button",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = self:_order(),
		Parent = self.Container,
	})
	local gloss = Glossy(opts.Color or "Blue", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -6, 1, -6),
		Parent = holder,
	})
	local label = gloss:AddText(opts.Name or "Button", 18)
	Bounce(gloss.Button)
	track(gloss.Button.Activated:Connect(function()
		Library:PlaySound("Click")
		SafeCall(opts.Callback)
	end))
	return {
		Instance = holder,
		SetText = function(_, text: string)
			label.Text = text
		end,
		SetColor = function(_, color: any)
			gloss:SetPalette(color)
		end,
	}
end

--[[ Tab:CreateToggle({ Name = "Particles", Default = true, Flag = "Particles", Callback = function(on) end }) ]]
function Elements:CreateToggle(opts: { [string]: any })
	opts = opts or {}
	local row = self:_row(40, true)
	self:_title(row, opts.Name or "Toggle", 104)
	local theme = Library.Theme
	local trackFrame = New("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 92, 0, 28),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = row,
	}, { Corner(UDim.new(1, 0)), Gradient(theme.TrackStops, 90), Stroke(theme.TrackRim, 2, 0, true) })
	local pill = Glossy("Green", {
		Name = "Pill",
		Active = false,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0.56, 0, 1, -4),
		ZIndex = 4,
		Parent = trackFrame,
	})
	pill.Button.Interactable = false
	pill.Shine.ZIndex = 5
	local pillText = pill:AddText("ON", 14)
	pillText.ZIndex = 6
	local scale = New("UIScale", { Parent = trackFrame })

	local toggle = { Value = false, Instance = row }
	function toggle:Set(value: boolean, silent: boolean?)
		self.Value = value and true or false
		pill:SetPalette(self.Value and "Green" or "Red")
		pillText.Text = self.Value and "ON" or "OFF"
		Tween(pill.Button, {
			Position = self.Value and UDim2.new(0.44, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		}, 0.25, Enum.EasingStyle.Back)
		SetFlag(opts, self.Value)
		if not silent then
			SafeCall(opts.Callback, self.Value)
		end
	end
	function toggle:Get(): boolean
		return self.Value
	end
	track(row.Activated:Connect(function()
		Library:PlaySound("Toggle")
		scale.Scale = 0.92
		Tween(scale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
		toggle:Set(not toggle.Value)
	end))
	toggle:Set(opts.Default == true, true)
	if opts.Default ~= nil then
		SafeCall(opts.Callback, toggle.Value)
	end
	return toggle
end

--[[ Tab:CreateSlider({ Name = "Music", Min = 0, Max = 100, Default = 67, Increment = 1, Suffix = "%", Callback = function(v) end }) ]]
function Elements:CreateSlider(opts: { [string]: any })
	opts = opts or {}
	local min, max = opts.Min or 0, opts.Max or 100
	local increment = opts.Increment or 1
	local suffix = opts.Suffix or ""
	local row = self:_row(58)
	self:_title(row, string.upper(opts.Name or "Slider"), 90, 4, 26)
	local valueLabel = Label({
		Name = "Value",
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 4),
		Size = UDim2.new(0, 90, 0, 26),
		TextSize = 17,
		Parent = row,
	}, Library.Theme.TextStroke, 1.6)
	local bar = Bar(row, Library.Theme.FillStops)
	bar.Track.AnchorPoint = Vector2.new(0, 0.5)
	bar.Track.Position = UDim2.new(0, 16, 1, -16)
	bar.Track.Size = UDim2.new(1, -32, 0, 12)

	local decimals = 0
	local incText = tostring(increment)
	local dot = string.find(incText, "%.")
	if dot then
		decimals = #incText - dot
	end

	local slider = { Value = min, Instance = row }
	function slider:Set(value: number, silent: boolean?)
		value = math.clamp(math.floor((value - min) / increment + 0.5) * increment + min, min, max)
		local changed = value ~= self.Value
		self.Value = value
		valueLabel.Text = string.format("%." .. decimals .. "f", value) .. suffix
		bar.SetAlpha((value - min) / math.max(max - min, 1e-9))
		SetFlag(opts, value)
		if changed and not silent then
			SafeCall(opts.Callback, value)
		end
	end
	function slider:Get(): number
		return self.Value
	end
	bar.Bind(function(alpha)
		local before = slider.Value
		slider:Set(min + (max - min) * alpha)
		if slider.Value ~= before then
			Library:PlaySound("Hover")
		end
	end)
	slider.Value = math.huge
	slider:Set(opts.Default or min, true)
	bar.SetAlpha((slider.Value - min) / math.max(max - min, 1e-9), true)
	if opts.Default ~= nil then
		SafeCall(opts.Callback, slider.Value)
	end
	return slider
end

--[[ Tab:CreateDropdown({ Name = "Mode", Options = {"A","B"}, Default = "A", Multi = false, Callback = function(v) end }) ]]
function Elements:CreateDropdown(opts: { [string]: any })
	opts = opts or {}
	local theme = Library.Theme
	local row = self:_row(42)
	row.ClipsDescendants = true
	self:_title(row, opts.Name or "Dropdown", 200, 0, 42)
	local selector = Glossy("Lavender", {
		Name = "Select",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 7),
		Size = UDim2.new(0.46, 0, 0, 28),
		ZIndex = 3,
		Parent = row,
	})
	selector.Shine.ZIndex = 4
	local selectText = selector:AddText("...", 14)
	selectText.ZIndex = 5
	selectText.Size = UDim2.new(1, -34, 1, 0)
	selectText.Position = UDim2.new(0, 10, 0, 0)
	local arrow = Label({
		Text = "▼",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 5,
		Parent = selector.Button,
	}, Library.Palettes.Lavender.Rim, 1.2)
	Bounce(selector.Button)

	local list = New("ScrollingFrame", {
		Name = "List",
		Position = UDim2.new(0, 8, 0, 44),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = hex("2f78d8"),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 3,
		Parent = row,
	}, {
		Corner(8),
		Gradient(theme.GlassStops, 90),
		New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8) }),
	})

	local dropdown = { Options = {}, Value = opts.Multi and {} or nil, Open = false, Instance = row }
	local optionButtons = {}

	local function displayText(): string
		if opts.Multi then
			local count = #dropdown.Value
			if count == 0 then
				return "None"
			end
			return table.concat(dropdown.Value, ", ")
		end
		return dropdown.Value ~= nil and tostring(dropdown.Value) or "None"
	end

	local function isSelected(option: any): boolean
		if opts.Multi then
			return table.find(dropdown.Value, option) ~= nil
		end
		return dropdown.Value == option
	end

	local function refreshVisuals()
		selectText.Text = displayText()
		for option, gloss in pairs(optionButtons) do
			gloss:SetPalette(isSelected(option) and "Blue" or "White")
		end
	end

	local function listHeight(): number
		return math.min(#dropdown.Options, 5) * 32 + 8
	end

	function dropdown:SetOpen(open: boolean)
		self.Open = open
		Library:PlaySound(open and "Tab" or "Close")
		Tween(arrow, { Rotation = open and 180 or 0 }, 0.2)
		Tween(list, { Size = UDim2.new(1, -16, 0, open and listHeight() or 0) }, 0.25)
		Tween(row, { Size = UDim2.new(1, 0, 0, open and 42 + listHeight() + 8 or 42) }, 0.25)
	end

	function dropdown:Set(value: any, silent: boolean?)
		if opts.Multi then
			self.Value = typeof(value) == "table" and table.clone(value) or { value }
		else
			self.Value = value
		end
		refreshVisuals()
		SetFlag(opts, self.Value)
		if not silent then
			SafeCall(opts.Callback, self.Value)
		end
	end

	function dropdown:Get(): any
		return self.Value
	end

	function dropdown:Refresh(options: { any }, keepSelection: boolean?)
		for _, gloss in pairs(optionButtons) do
			gloss.Button.Parent:Destroy()
		end
		table.clear(optionButtons)
		self.Options = options or {}
		for i, option in ipairs(self.Options) do
			local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, ZIndex = 4, Parent = list })
			local gloss = Glossy("White", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, -4, 1, -2),
				ZIndex = 4,
				Parent = holder,
			}, UDim.new(0, 8))
			gloss.Shine.ZIndex = 5
			gloss:AddText(tostring(option), 14).ZIndex = 6
			Bounce(gloss.Button, nil, false)
			optionButtons[option] = gloss
			track(gloss.Button.Activated:Connect(function()
				Library:PlaySound("Click")
				if opts.Multi then
					local current = table.clone(dropdown.Value)
					local index = table.find(current, option)
					if index then
						table.remove(current, index)
					else
						table.insert(current, option)
					end
					dropdown:Set(current)
				else
					dropdown:Set(option)
					dropdown:SetOpen(false)
				end
			end))
		end
		if not keepSelection then
			self.Value = opts.Multi and {} or nil
		end
		refreshVisuals()
		if self.Open then
			self:SetOpen(true)
		end
	end

	track(selector.Button.Activated:Connect(function()
		dropdown:SetOpen(not dropdown.Open)
	end))

	dropdown:Refresh(opts.Options or {})
	if opts.Default ~= nil then
		dropdown:Set(opts.Default)
	end
	return dropdown
end

--[[ Tab:CreateTextbox({ Name = "Code", Placeholder = "Enter code...", ClearOnSubmit = false, NumbersOnly = false, Callback = function(text, enter) end }) ]]
function Elements:CreateTextbox(opts: { [string]: any })
	opts = opts or {}
	local theme = Library.Theme
	local row = self:_row(42)
	self:_title(row, opts.Name or "Textbox", 210)
	local frame = New("Frame", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 28),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = row,
	}, {
		Corner(7),
		Gradient({ { 0, hex("eef6ff") }, { 0.25, theme.Cream }, { 1, hex("ffffff") } }, 90),
	})
	local stroke = Stroke(hex("2b67c0"), 2, 0, true)
	stroke.Parent = frame
	local box = New("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		FontFace = Library.Fonts.Body,
		Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "Type here...",
		PlaceholderColor3 = hex("8fa9cf"),
		TextColor3 = theme.InkSoft,
		TextSize = 15,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = frame,
	})
	track(box.Focused:Connect(function()
		Library:PlaySound("Click")
		Tween(stroke, { Color = hex("39b9ff"), Thickness = 2.5 }, 0.15)
	end))
	if opts.NumbersOnly then
		track(box:GetPropertyChangedSignal("Text"):Connect(function()
			local filtered = box.Text:gsub("[^%d%.%-]", "")
			if filtered ~= box.Text then
				box.Text = filtered
			end
		end))
	end
	local textbox = { Instance = row, Box = box }
	track(box.FocusLost:Connect(function(enterPressed)
		Tween(stroke, { Color = hex("2b67c0"), Thickness = 2 }, 0.15)
		local text = box.Text
		SetFlag(opts, text)
		SafeCall(opts.Callback, text, enterPressed)
		if opts.ClearOnSubmit and enterPressed then
			box.Text = ""
		end
	end))
	function textbox:Set(text: string)
		box.Text = text
		SetFlag(opts, text)
	end
	function textbox:Get(): string
		return box.Text
	end
	return textbox
end

--[[ Tab:CreateKeybind({ Name = "Sprint", Default = Enum.KeyCode.LeftShift, Callback = function(key) end, Changed = function(key) end }) ]]
function Elements:CreateKeybind(opts: { [string]: any })
	opts = opts or {}
	local theme = Library.Theme
	local row = New("Frame", {
		Name = "Keybind",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		LayoutOrder = self:_order(),
		Parent = self.Container,
	}, { Corner(8), Gradient(theme.KeyRowStops, 90), Stroke(hex("0a2e5c"), 1.5, 0, true) })
	Shine(row, UDim.new(0, 6), 0.4).BackgroundTransparency = 0.6
	Label({
		Name = "Title",
		Text = opts.Name or "Keybind",
		FontFace = Library.Fonts.Heavy,
		TextSize = 17,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -130, 1, 0),
		Parent = row,
	}, hex("22447f"), 1.6)
	local key = New("TextButton", {
		Name = "Key",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 96, 0, 30),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = row,
	}, {
		Corner(UDim.new(1, 0)),
		Gradient({ { 0, WHITE }, { 0.5, hex("e6f5ff") }, { 1, hex("cfe9fd") } }, 90),
	})
	Stroke(theme.KeyRim, 2, 0, true).Parent = key
	local keyText = Label({
		Text = "None",
		FontFace = Library.Fonts.Heavy,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.new(0, 4, 0, 0),
		ZIndex = 4,
		Parent = key,
	}, theme.KeyRim, 2)
	Chrome(keyText)
	Bounce(key)

	local keybind = { Value = opts.Default, Instance = row }
	local listening = false
	local function keyName(value: any): string
		if typeof(value) == "EnumItem" then
			return value.Name
		end
		return "None"
	end
	function keybind:Set(value: any, silent: boolean?)
		self.Value = value
		keyText.Text = keyName(value)
		SetFlag(opts, value)
		if not silent then
			SafeCall(opts.Changed, value)
		end
	end
	function keybind:Get(): any
		return self.Value
	end
	track(key.Activated:Connect(function()
		Library:PlaySound("Click")
		listening = true
		keyText.Text = "..."
	end))
	track(UserInputService.InputBegan:Connect(function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
					keybind:Set(nil)
				else
					keybind:Set(input.KeyCode)
				end
				Library:PlaySound("Toggle")
			end
			return
		end
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end
		if keybind.Value and input.KeyCode == keybind.Value then
			SafeCall(opts.Callback, keybind.Value)
		end
	end))
	keybind:Set(opts.Default, true)
	return keybind
end

--[[ Tab:CreateColorPicker({ Name = "Highlight", Default = Color3.fromRGB(255, 80, 80), Callback = function(color) end }) ]]
function Elements:CreateColorPicker(opts: { [string]: any })
	opts = opts or {}
	local row = self:_row(42)
	row.ClipsDescendants = true
	self:_title(row, opts.Name or "Color", 80, 0, 42)
	local swatch = New("TextButton", {
		Name = "Swatch",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.new(0, 60, 0, 26),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = row,
	}, { Corner(UDim.new(1, 0)), Stroke(Library.Theme.TrackRim, 2, 0, true) })
	Shine(swatch).ZIndex = 4
	Bounce(swatch)

	local channels = {
		{ Name = "R", Fill = { { 0, hex("ff8a7a") }, { 0.5, hex("d81413") }, { 1, hex("ff4a3a") } } },
		{ Name = "G", Fill = { { 0, hex("b6ffa8") }, { 0.5, hex("3bf527") }, { 1, hex("6bff58") } } },
		{ Name = "B", Fill = { { 0, hex("9aa0ff") }, { 0.5, hex("2729ee") }, { 1, hex("5a5cff") } } },
	}
	local picker = { Value = opts.Default or Color3.new(1, 1, 1), Open = false, Instance = row }
	local rgb = { 255, 255, 255 }
	local bars, values = {}, {}

	local function apply(silent: boolean?)
		picker.Value = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
		swatch.BackgroundColor3 = picker.Value
		for i = 1, 3 do
			bars[i].SetAlpha(rgb[i] / 255)
			values[i].Text = tostring(rgb[i])
		end
		SetFlag(opts, picker.Value)
		if not silent then
			SafeCall(opts.Callback, picker.Value)
		end
	end

	for i, channel in ipairs(channels) do
		local y = 46 + (i - 1) * 30
		Label({
			Text = channel.Name,
			FontFace = Library.Fonts.Heavy,
			TextSize = 15,
			Position = UDim2.new(0, 14, 0, y),
			Size = UDim2.new(0, 20, 0, 24),
			Parent = row,
		}, Library.Theme.KeyRim, 1.5)
		local bar = Bar(row, channel.Fill, true)
		bar.Track.AnchorPoint = Vector2.new(0, 0.5)
		bar.Track.Position = UDim2.new(0, 42, 0, y + 12)
		bar.Track.Size = UDim2.new(1, -112, 0, 12)
		bar.Knob.Size = UDim2.fromOffset(18, 18)
		bars[i] = bar
		local valueLabel = Label({
			Text = "255",
			FontFace = Library.Fonts.Heavy,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, y),
			Size = UDim2.new(0, 44, 0, 24),
			Parent = row,
		}, Library.Theme.KeyRim, 1.5)
		Chrome(valueLabel)
		values[i] = valueLabel
		bar.Bind(function(alpha)
			local v = math.floor(alpha * 255 + 0.5)
			if v ~= rgb[i] then
				rgb[i] = v
				apply()
			end
		end)
	end

	function picker:Set(color: Color3, silent: boolean?)
		rgb = { math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5) }
		apply(silent)
	end
	function picker:Get(): Color3
		return self.Value
	end
	function picker:SetOpen(open: boolean)
		self.Open = open
		Library:PlaySound(open and "Tab" or "Close")
		Tween(row, { Size = UDim2.new(1, 0, 0, open and 42 + 3 * 30 + 10 or 42) }, 0.25)
	end
	track(swatch.Activated:Connect(function()
		picker:SetOpen(not picker.Open)
	end))
	picker:Set(picker.Value, true)
	return picker
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local Window = {}
Window.__index = Window

--[[
	ToonsUI:CreateWindow({
		Title = "Settings.exe",
		Subtitle = "by you",            -- optional, shown next to the title
		Footer = "ToonsUI v1.0",        -- text in the bottom glass tab
		Size = UDim2.fromOffset(640, 440),
		ToggleKey = Enum.KeyCode.RightShift,
		Bubbles = true,                 -- floating aero bubbles in the background
		OpenButton = true,              -- round glass button to reopen the window when hidden
	})
]]
function Library:CreateWindow(opts: { [string]: any })
	opts = opts or {}
	local theme = self.Theme
	local size = opts.Size or UDim2.fromOffset(640, 440)
	if typeof(size) == "Vector2" then
		size = UDim2.fromOffset(size.X, size.Y)
	end

	local window = setmetatable({
		Tabs = {},
		Visible = true,
		ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
	}, Window)

	local holder = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		BackgroundTransparency = 1,
		Parent = Root,
	})
	local fit = New("UIScale", { Parent = holder })
	local anim = New("Frame", { Name = "Anim", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = holder })
	local pop = New("UIScale", { Parent = anim })

	New("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, 56, 1, 56),
		BackgroundTransparency = 1,
		Image = theme.ShadowImage,
		ImageColor3 = hex("001a4d"),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Parent = anim,
	})

	local main = New("Frame", {
		Name = "Main",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = anim,
	}, { Corner(14), Gradient(theme.WindowStops, 90), Stroke(theme.WindowRim, 3, 0, true) })

	New("ImageLabel", {
		Name = "Waves",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = theme.WaveImage,
		ImageTransparency = theme.WaveTransparency,
		ScaleType = Enum.ScaleType.Stretch,
		Parent = main,
	}, { Corner(14) })

	New("Frame", {
		Name = "InnerRim",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -6, 1, -6),
		BackgroundTransparency = 1,
		Parent = main,
	}, { Corner(11), Stroke(WHITE, 1.5, 0.45, true) })

	if opts.Bubbles ~= false then
		local layer = New("Frame", { Name = "Bubbles", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = main })
		SpawnBubbles(layer, 9)
	end

	-- Header -----------------------------------------------------------------
	local dragHandle = New("Frame", { Name = "DragHandle", Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Active = true, ZIndex = 2, Parent = main })

	Glass({ Name = "TopStrip", Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -130, 0, 7), ZIndex = 2, Parent = main }, 4)
	local topTab = Glass({
		Name = "TopTab",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.new(0, 104, 0, 40),
		ZIndex = 2,
		Parent = main,
	}, 10)
	Shine(topTab, UDim.new(0, 8), 0.45).ZIndex = 3

	local titleRow = New("Frame", {
		Name = "TitleRow",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 17),
		Size = UDim2.new(1, -150, 0, 28),
		ZIndex = 4,
		Parent = main,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local titleLabel = Label({
		Name = "Title",
		Text = opts.Title or "ToonsUI",
		FontFace = self.Fonts.Heavy,
		TextSize = 24,
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		ZIndex = 4,
		Parent = titleRow,
	}, theme.TitleStroke, 2)
	Chrome(titleLabel)
	Label({
		Name = "Subtitle",
		Text = opts.Subtitle or "",
		FontFace = self.Fonts.Bold,
		TextSize = 14,
		TextColor3 = hex("d8ecff"),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(0, 0, 0, 22),
		LayoutOrder = 2,
		ZIndex = 4,
		Parent = titleRow,
	}, theme.TitleStroke, 1.2)

	local function squareButton(name: string, palette: string, x: number): any
		local gloss = Glossy(palette, {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, x, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			ZIndex = 4,
			Parent = topTab,
		}, UDim.new(0, 7))
		gloss.Shine.ZIndex = 5
		Bounce(gloss.Button)
		return gloss
	end
	local minimize = squareButton("Minimize", "Blue", 32)
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.new(0.5, 0, 0, 4),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = minimize.Button,
	}, { Corner(UDim.new(1, 0)), Stroke(Library.Palettes.Blue.Rim, 1, 0, true) })
	local close = squareButton("Close", "Red", 72)
	for _, rotation in ipairs({ 45, -45 }) do
		New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.62, 0, 0, 5),
			Rotation = rotation,
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = close.Button,
		}, { Corner(UDim.new(1, 0)), Stroke(Library.Palettes.Red.Rim, 1, 0, true) })
	end

	-- Tab bar ------------------------------------------------------------------
	local tabBar = New("ScrollingFrame", {
		Name = "TabBar",
		Position = UDim2.new(0, 12, 0, 54),
		Size = UDim2.new(1, -24, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ZIndex = 3,
		Parent = main,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
	})

	-- Content inset --------------------------------------------------------------
	local inset = New("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 12, 0, 96),
		Size = UDim2.new(1, -24, 1, -96 - 46),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = main,
	}, { Corner(10), Gradient(theme.InsetStops, 90), Stroke(theme.InsetRim, 2, 0, true) })

	-- Footer ---------------------------------------------------------------------
	local bottomTab = Glass({
		Name = "BottomTab",
		Position = UDim2.new(0, 10, 1, -40),
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 2,
		Parent = main,
	}, 9)
	Label({
		Text = opts.Footer or ("ToonsUI v" .. Library.Version),
		FontFace = self.Fonts.Heavy,
		TextSize = 14,
		TextColor3 = hex("2a5ca8"),
		TextTruncate = Enum.TextTruncate.None,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 3,
		Parent = bottomTab,
	}, WHITE, 1.2)
	New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = bottomTab })
	Glass({ Name = "BottomStrip", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 1, -18), Size = UDim2.new(1, -230, 0, 7), ZIndex = 2, Parent = main }, 4)

	-- Floating reopen button -------------------------------------------------------
	local openButton = New("TextButton", {
		Name = "OpenButton",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 46, 0.5, 0),
		Size = UDim2.fromOffset(54, 54),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 50,
		Parent = Root,
	}, { Corner(UDim.new(1, 0)), Gradient(theme.KnobStops, 90), Stroke(theme.KnobRim, 3, 0, true) })
	Shine(openButton, nil, 0.42).ZIndex = 51
	local initial = Label({
		Text = string.sub(opts.Title or "T", 1, 1),
		FontFace = self.Fonts.Heavy,
		TextSize = 26,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 52,
		Parent = openButton,
	}, theme.TitleStroke, 2)
	Chrome(initial)
	Bounce(openButton)
	local openMoved = 0
	MakeDraggable(openButton, openButton, function(distance)
		openMoved = distance
	end)

	window.Gui = holder
	window.Main = main
	window.Content = inset
	window.TabBar = tabBar

	-- Behaviour ------------------------------------------------------------------
	local function refit()
		local viewport = Root.AbsoluteSize
		if viewport.X <= 0 then
			return
		end
		fit.Scale = math.min(1, (viewport.X - 24) / size.X.Offset, (viewport.Y - 24) / size.Y.Offset)
	end
	track(Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit))
	refit()

	MakeDraggable(dragHandle, holder)

	local showOpenButton = opts.OpenButton ~= false
	function window:SetVisible(visible: boolean)
		if visible == self.Visible then
			return
		end
		self.Visible = visible
		if visible then
			holder.Visible = true
			openButton.Visible = false
			Library:PlaySound("Open")
			pop.Scale = 0.75
			Tween(pop, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
		else
			Library:PlaySound("Close")
			local t = Tween(pop, { Scale = 0.75 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			t.Completed:Once(function()
				if not self.Visible then
					holder.Visible = false
					openButton.Visible = showOpenButton
				end
			end)
		end
	end
	function window:Toggle()
		self:SetVisible(not self.Visible)
	end

	track(minimize.Button.Activated:Connect(function()
		window:SetVisible(false)
	end))
	track(close.Button.Activated:Connect(function()
		Library:Dialog({
			Title = "Close " .. (opts.Title or "window") .. "?",
			Content = "You can't reopen it after closing.",
			Callback = function(confirmed)
				if confirmed then
					window:Destroy()
				end
			end,
		})
	end))
	track(openButton.Activated:Connect(function()
		if openMoved > 6 then
			openMoved = 0
			return
		end
		window:SetVisible(true)
	end))
	track(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end
		if window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:Toggle()
		end
	end))

	function window:Destroy()
		Library:PlaySound("Close")
		local t = Tween(pop, { Scale = 0 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		t.Completed:Wait()
		holder:Destroy()
		openButton:Destroy()
		local index = table.find(Library.Windows, self)
		if index then
			table.remove(Library.Windows, index)
		end
	end

	pop.Scale = 0.6
	Tween(pop, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
	self:PlaySound("Open")
	table.insert(self.Windows, window)
	return window
end

function Window:Notify(opts: { [string]: any })
	Library:Notify(opts)
end

function Window:Dialog(opts: { [string]: any })
	return Library:Dialog(opts)
end

--[[ Window:CreateTab({ Name = "Main", Color = "Blue", Icon = "rbxassetid://..." }) or Window:CreateTab("Main") ]]
function Window:CreateTab(opts: any)
	if typeof(opts) == "string" then
		opts = { Name = opts }
	end
	opts = opts or {}
	local index = #self.Tabs + 1
	local activeColor = opts.Color or "Blue"

	local gloss = Glossy("Lavender", {
		Name = opts.Name or "Tab",
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = index,
		ZIndex = 4,
		Parent = self.TabBar,
	})
	gloss.Shine.ZIndex = 5
	local content = New("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 6,
		Parent = gloss.Button,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		New("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	if opts.Icon then
		New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = opts.Icon,
			Size = UDim2.fromOffset(18, 18),
			LayoutOrder = 1,
			ZIndex = 6,
			Parent = content,
		})
	end
	local text = gloss:AddText(opts.Name or "Tab", 16)
	text.Parent = content
	text.AutomaticSize = Enum.AutomaticSize.X
	text.TextTruncate = Enum.TextTruncate.None
	text.Size = UDim2.new(0, 0, 1, 0)
	text.Position = UDim2.new()
	text.LayoutOrder = 2
	text.ZIndex = 7
	Bounce(gloss.Button)

	local container = New("ScrollingFrame", {
		Name = (opts.Name or "Tab") .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = hex("bfe6ff"),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 3,
		Parent = self.Content,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }),
		New("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 14) }),
	})

	local tab = setmetatable({ Window = self, Container = container, Button = gloss.Button, _layout = 0, _gloss = gloss, _color = activeColor }, Elements)
	tab.Tab = tab
	table.insert(self.Tabs, tab)

	function tab:Select()
		self.Window:SelectTab(self)
	end

	track(gloss.Button.Activated:Connect(function()
		if self.Selected ~= tab then
			Library:PlaySound("Tab")
		end
		self:SelectTab(tab)
	end))

	if index == 1 then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab: any)
	for _, other in ipairs(self.Tabs) do
		local active = other == tab
		other._gloss:SetPalette(active and other._color or "Lavender")
		if active and not other.Container.Visible then
			other.Container.Visible = true
			other.Container.Position = UDim2.new(0, 0, 0, 14)
			Tween(other.Container, { Position = UDim2.new(0, 0, 0, 0) }, 0.25, Enum.EasingStyle.Back)
		elseif not active then
			other.Container.Visible = false
		end
	end
	self.Selected = tab
end

--------------------------------------------------------------------------------

function Library:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	Root:Destroy()
end

return Library
