--[[
	DandysUI  v1.0.0
	A Roblox UI library styled after the Dandy's World menus:
	dark striped panels with chunky black outlines, Fredoka One text with a silver
	gradient, yellow headers, ◀ ON ▶ toggles, orange -/+ sliders, an info side panel,
	purchase-style dialogs and the game's UI sounds.

	local DandysUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/DandysUI.lua"))()
	local Window = DandysUI:CreateWindow({ Title = "Settings" })
	local Tab = Window:CreateTab({ Name = "General" })
	Tab:CreateToggle({ Name = "Dust Particles", Default = true, Callback = print })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local function hex(s: string): Color3
	return Color3.fromHex(s)
end
local function grey(v: number): Color3
	return Color3.new(v, v, v)
end

local Library = {
	Version = "1.0.0",
	Flags = {},
	SoundsEnabled = true,
	Volume = 1,
	Windows = {},
	_connections = {},
}

Library.Fonts = {
	Title = Font.new("rbxasset://fonts/families/FredokaOne.json"),
	Value = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold),
	Body = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold),
}

Library.Images = {
	Stripes = "rbxassetid://6794283750",
	Selected = "rbxassetid://133672226400016",
	ArrowNext = "rbxassetid://129745804935011",
	ArrowPrev = "rbxassetid://91978249342516",
}

-- Colours/gradients pulled from the game's MainGui.
Library.Theme = {
	Panel = hex("4a4a4a"),
	Row = hex("4d4d4d"),
	Dialog = hex("8c8c8c"),
	Tab = hex("0f0f0f"),
	Text = WHITE,
	SubText = hex("dedede"),
	Header = hex("ffd900"),
	On = hex("6cff64"),
	Off = hex("ff6d6f"),
	Value = hex("efb524"),
	Fill = hex("ffb710"),
	Error = hex("ff7d7f"),
	Outline = BLACK,
	-- multiplier gradients (UIGradient colour multiplies the base colour)
	PanelShade = { { 0, 1 }, { 0.513, 0.541 }, { 0.789, 0.357 }, { 1, 0.357 } },
	RowShade = { { 0, 0.826 }, { 0.513, 0.367 }, { 0.789, 0.183 }, { 1, 0.183 } },
	TextShade = { { 0, 1 }, { 0.097, 0.923 }, { 0.458, 0.944 }, { 1, 0.208 } },
	KnobShade = { { 0, 0.87 }, { 1, 0.639 } },
}

Library.Colors = {
	Grey = hex("797979"),
	Green = hex("37963a"),
	Red = hex("7f2a2a"),
	Yellow = hex("e0a516"),
	Orange = hex("d9661c"),
	Blue = hex("2f7fd6"),
	Purple = hex("7a45c4"),
	Pink = hex("d64f8a"),
	Black = hex("2b2b2b"),
}

-- Sound ids taken from MainGui / SoundService.UI in the place file.
Library.Sounds = {
	Click = { Id = "rbxassetid://552900451", Volume = 0.5 },
	Hover = { Id = "rbxassetid://6895079853", Volume = 0.3 },
	Toggle = { Id = "rbxassetid://121531878137469", Volume = 0.7 },
	Tick = { Id = "rbxassetid://147982968", Volume = 0.3 },
	Tab = { Id = "rbxassetid://2034189546", Volume = 0.3 },
	Open = { Id = "rbxassetid://261072074", Volume = 0.33 },
	Close = { Id = "rbxassetid://4228160116", Volume = 0.4 },
	Notify = { Id = "rbxassetid://2789427964", Volume = 0.3 },
	Error = { Id = "rbxassetid://4499400560", Volume = 0.3 },
	Purchase = { Id = "rbxassetid://4612383453", Volume = 0.4 },
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
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			(obj :: any)[k] = v
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
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function Corner(radius: any): UICorner
	return New("UICorner", { CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8) })
end

local function Stroke(thickness: number?, transparency: number?, border: boolean?, color: Color3?): UIStroke
	return New("UIStroke", {
		Color = color or BLACK,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = border and Enum.ApplyStrokeMode.Border or Enum.ApplyStrokeMode.Contextual,
	})
end

local function Shade(stops: { { number } }, rotation: number?): UIGradient
	local points = {}
	for i, s in ipairs(stops) do
		points[i] = ColorSequenceKeypoint.new(s[1], grey(s[2]))
	end
	return New("UIGradient", { Color = ColorSequence.new(points), Rotation = rotation or 90 })
end

-- Faint diagonal stripes that cover every panel in the game.
local function Stripes(parent: Instance, radius: any, transparency: number?, color: Color3?): ImageLabel
	local decor = parent:FindFirstChild("Decor") or New("Folder", { Name = "Decor", Parent = parent })
	return New("ImageLabel", {
		Name = "Stripes",
		BackgroundTransparency = 1,
		Image = Library.Images.Stripes,
		ImageColor3 = color or WHITE,
		ImageTransparency = transparency or 0.94,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(56, 56),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = decor,
	}, { Corner(radius) })
end

-- White Fredoka text with the silver gradient and black outline.
local function Text(props: { [string]: any }, strokeThickness: number?, shade: boolean?): TextLabel
	local defaults: { [string]: any } = {
		BackgroundTransparency = 1,
		FontFace = Library.Fonts.Title,
		TextColor3 = Library.Theme.Text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Text = "",
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local label = New("TextLabel", defaults)
	Stroke(strokeThickness or 2).Parent = label
	if shade ~= false then
		Shade(Library.Theme.TextShade).Parent = label
	end
	return label
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
			warn("[DandysUI] callback error: " .. tostring(err))
		end
	end
end

local function GetColor(c: any, default: Color3?): Color3
	if typeof(c) == "Color3" then
		return c
	end
	return Library.Colors[c] or default or Library.Colors.Grey
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
local old = GuiParent:FindFirstChild("DandysUI")
if old then
	old:Destroy()
end

local Root = New("ScreenGui", {
	Name = "DandysUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = GuiParent,
})
Library.Gui = Root

local NotifyHolder = New("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -18),
	Size = UDim2.new(0, 320, 1, -36),
	BackgroundTransparency = 1,
	ZIndex = 100,
	Parent = Root,
}, {
	New("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
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

-- Hover grow / press squish, plus the hover sound.
local function Bounce(button: GuiButton, target: GuiObject?, amount: number?)
	local obj = target or button
	local scale = obj:FindFirstChild("BounceScale") or New("UIScale", { Name = "BounceScale", Parent = obj })
	local up = 1 + (amount or 0.05)
	local hovering = false
	track(button.MouseEnter:Connect(function()
		hovering = true
		Tween(scale, { Scale = up }, 0.12)
		Library:PlaySound("Hover")
	end))
	track(button.MouseLeave:Connect(function()
		hovering = false
		Tween(scale, { Scale = 1 }, 0.12)
	end))
	track(button.MouseButton1Down:Connect(function()
		Tween(scale, { Scale = 0.92 }, 0.07)
	end))
	track(button.MouseButton1Up:Connect(function()
		Tween(scale, { Scale = hovering and up or 1 }, 0.25, Enum.EasingStyle.Back)
	end))
	track(button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			hovering = false
			Tween(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
		end
	end))
end

-- Dark striped panel with the thick black outline.
local function Panel(props: { [string]: any }, radius: number?, strokeThickness: number?, shade: any?): Frame
	local defaults: { [string]: any } = {
		BackgroundColor3 = Library.Theme.Panel,
		BorderSizePixel = 0,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local frame = New("Frame", defaults)
	Corner(radius or 12).Parent = frame
	Stroke(strokeThickness or 3, 0, true).Parent = frame
	Shade(shade or Library.Theme.PanelShade).Parent = frame
	Stripes(frame, radius or 12)
	return frame
end

-- Chunky game button: black "FrameBG" backing + shaded coloured face + outline.
local function Chunky(props: { [string]: any }, color: any, radius: number?)
	local defaults: { [string]: any } = {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 0, 40),
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local button = New("TextButton", defaults)
	local holder = New("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = button,
	})
	New("Frame", {
		Name = "FrameBG",
		Position = UDim2.fromOffset(0, 4),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BLACK,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = holder,
	}, { Corner(radius or 8) })
	local face = New("Frame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = GetColor(color),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = holder,
	}, {
		Corner(radius or 8),
		Stroke(2.5, 0, true),
		Shade(Library.Theme.PanelShade),
	})
	local label = Text({
		Name = "Label",
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 20,
		ZIndex = 4,
		Parent = holder,
	})
	Bounce(button, holder)
	return { Button = button, Face = face, Label = label, Holder = holder }
end

-- Dark rounded box used for dropdown/keybind/value fields.
local function Field(props: { [string]: any }, radius: number?): Frame
	local defaults: { [string]: any } = {
		BackgroundColor3 = Library.Theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 2,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local frame = New("Frame", defaults)
	Corner(radius or 6).Parent = frame
	Stroke(2, 0.2, true).Parent = frame
	Shade(Library.Theme.PanelShade).Parent = frame
	return frame
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

-- Horizontal drag bar: calls onAlpha(0..1) while the user drags along `track`.
local function DragBar(hit: GuiButton, bar: GuiObject, onAlpha: (number) -> (), onRelease: (() -> ())?)
	local dragging = false
	local function update(x: number)
		local w = bar.AbsoluteSize.X
		if w > 0 then
			onAlpha(math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1))
		end
	end
	track(hit.InputBegan:Connect(function(input)
		if IsClick(input) then
			dragging = true
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
			if onRelease then
				onRelease()
			end
		end
	end))
end

--------------------------------------------------------------------------------
-- Notifications, messages and dialogs
--------------------------------------------------------------------------------

local notifyOrder = 0

-- DandysUI:Notify({ Title = "Code redeemed", Content = "...", Duration = 4, Color = "Green" })
function Library:Notify(opts: { [string]: any })
	opts = opts or {}
	notifyOrder += 1
	local duration = opts.Duration or 4
	local accent = GetColor(opts.Color, Library.Theme.Fill)
	local slot = New("Frame", {
		Name = "Notification",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = notifyOrder,
		Parent = NotifyHolder,
	})
	local card = Panel({
		Position = UDim2.new(1, 40, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = slot,
	}, 10, 3)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 16),
		Parent = card,
	})
	New("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 60, 0, 5),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		ZIndex = 2,
		Parent = card,
	}, { Corner(UDim.new(1, 0)), Stroke(1.5, 0, true) })
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	Text({
		Name = "Title",
		Text = opts.Title or "Notice",
		TextColor3 = Library.Theme.Header,
		TextSize = 20,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		Parent = card,
	}, 2, false)
	Text({
		Name = "Content",
		Text = opts.Content or "",
		FontFace = Library.Fonts.Body,
		TextColor3 = Library.Theme.SubText,
		TextSize = 17,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = card,
	}, 1.2, false)
	local timerBack = New("Frame", {
		Name = "Timer",
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		ZIndex = 2,
		Parent = card,
	}, { Corner(UDim.new(1, 0)) })
	local timer = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = timerBack,
	}, { Corner(UDim.new(1, 0)) })
	local hit = New("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = slot,
	})

	Library:PlaySound(opts.Sound or "Notify")
	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back)
	Tween(timer, { Size = UDim2.fromScale(0, 1) }, duration, Enum.EasingStyle.Linear)

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		Tween(card, { Position = UDim2.new(1, 40, 0, 0) }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.26, function()
			slot:Destroy()
		end)
	end
	hit.MouseButton1Click:Connect(function()
		Library:PlaySound("Click")
		close()
	end)
	task.delay(duration, close)
	return { Close = close }
end

-- Big floating text in the middle of the screen, like the game's DisplayMessage / ErrorMessage.
-- DandysUI:Message("Not enough Ichor!", { Error = true, Duration = 2 })
function Library:Message(text: string, opts: { [string]: any }?)
	local o = opts or {}
	local label = Text({
		Name = "Message",
		Text = text,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.22),
		Size = UDim2.new(0.6, 0, 0, 50),
		TextScaled = false,
		TextSize = 38,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = o.Error and Library.Theme.Error or (o.Color or WHITE),
		ZIndex = 200,
		Parent = Root,
	}, 3, not o.Error)
	local scale = New("UIScale", { Scale = 0.6, Parent = label })
	Library:PlaySound(o.Error and "Error" or (o.Sound or "Notify"))
	Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	task.delay(o.Duration or 2, function()
		local stroke = label:FindFirstChildOfClass("UIStroke")
		Tween(label, { TextTransparency = 1, Position = UDim2.fromScale(0.5, 0.18) }, 0.4)
		if stroke then
			Tween(stroke, { Transparency = 1 }, 0.4)
		end
		task.delay(0.45, function()
			label:Destroy()
		end)
	end)
end

-- Purchase-style confirmation pop-up.
-- DandysUI:Dialog({ Title = "Purchase Medkit?", Content = "...", ConfirmText = "Buy", CancelText = "Cancel", Callback = function(ok) end })
-- or Buttons = { { Text = "A", Color = "Green", Callback = fn }, ... }
function Library:Dialog(opts: { [string]: any })
	opts = opts or {}
	local overlay = New("TextButton", {
		Name = "Dialog",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 150,
		Parent = Root,
	})
	local card = Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Theme.Dialog,
		ZIndex = 151,
		Parent = overlay,
	}, 14, 3)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 22),
		PaddingRight = UDim.new(0, 22),
		PaddingTop = UDim.new(0, 18),
		PaddingBottom = UDim.new(0, 22),
		Parent = card,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = card,
	})
	local scale = New("UIScale", { Scale = 0.7, Parent = card })
	Text({
		Name = "Title",
		Text = opts.Title or "Are you sure?",
		TextSize = 30,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		ZIndex = 153,
		Parent = card,
	}, 2.5)
	if opts.Content and opts.Content ~= "" then
		Text({
			Name = "Description",
			Text = opts.Content,
			TextSize = 18,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = 153,
			Parent = card,
		}, 2)
	end
	local row = New("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 50),
		LayoutOrder = 3,
		ZIndex = 152,
		Parent = card,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 16),
		}),
	})

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		Library:PlaySound("Close")
		Tween(scale, { Scale = 0.7 }, 0.15)
		Tween(overlay, { BackgroundTransparency = 1 }, 0.15)
		task.delay(0.16, function()
			overlay:Destroy()
		end)
	end

	local buttons = opts.Buttons
	if not buttons then
		buttons = {
			{ Text = opts.ConfirmText or "Confirm", Color = "Green", Sound = opts.ConfirmSound or "Purchase", Callback = function()
				SafeCall(opts.Callback, true)
			end },
			{ Text = opts.CancelText or "Cancel", Color = "Red", Callback = function()
				SafeCall(opts.Callback, false)
			end },
		}
	end
	local width = math.min(170, (396 - 16 * (#buttons - 1)) / #buttons)
	for _, info in ipairs(buttons) do
		local b = Chunky({ Size = UDim2.fromOffset(width, 44), ZIndex = 152, Parent = row }, info.Color or "Grey", 10)
		b.Label.Text = info.Text or "OK"
		b.Label.TextSize = 22
		for _, d in ipairs(b.Holder:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.ZIndex += 152
			end
		end
		b.Button.MouseButton1Click:Connect(function()
			if closed then
				return
			end
			Library:PlaySound(info.Sound or "Click")
			SafeCall(info.Callback)
			close()
		end)
	end
	for _, d in ipairs(card:GetDescendants()) do
		if d:IsA("GuiObject") and d.ZIndex < 151 then
			d.ZIndex += 151
		end
	end

	Library:PlaySound("Open")
	Tween(overlay, { BackgroundTransparency = 0.5 }, 0.2)
	Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	return { Close = close }
end

--------------------------------------------------------------------------------
-- Elements (shared by every tab)
--------------------------------------------------------------------------------

local Elements = {}
Elements.__index = Elements

function Elements:_order(): number
	self._count += 1
	return self._count
end

-- Striped settings row: name on the left, "Property" area on the right.
function Elements:_row(opts: { [string]: any }, height: number?): any
	local row = New("TextButton", {
		Name = opts.Name or "Row",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Library.Theme.Row,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -6, 0, height or 46),
		LayoutOrder = self:_order(),
		ClipsDescendants = false,
		Parent = self.Container,
	}, {
		Corner(8),
		Stroke(2, 0.2, true),
		Shade(Library.Theme.RowShade),
	})
	Stripes(row, 8, 0.95, hex("d3d3d3"))
	local title = Text({
		Name = "Title",
		Text = opts.Name or "",
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0.45, -14, 0, height or 46),
		TextSize = 20,
		Parent = row,
	})
	local property = New("Frame", {
		Name = "Property",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0.55, -10, 0, height or 46),
		ZIndex = 2,
		Parent = row,
	})
	local window = self.Window
	track(row.MouseEnter:Connect(function()
		if window then
			window:_info(opts.Name, opts.Description)
		end
	end))
	return row, title, property
end

local function SetFlag(opts: { [string]: any }, value: any)
	if opts.Flag then
		Library.Flags[opts.Flag] = value
	end
end

local function HList(parent: Instance, padding: number?, align: Enum.HorizontalAlignment?)
	return New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

-- Small square -/+ or arrow button.
local function SmallButton(parent: Instance, order: number, text: string?, image: string?): TextButton
	local b = New("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 28),
		LayoutOrder = order,
		ZIndex = 3,
		Parent = parent,
	})
	if image then
		New("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 4,
			Parent = b,
		})
	else
		Field({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.2, ZIndex = 3, Parent = b })
		Text({
			Text = text or "",
			FontFace = Library.Fonts.Value,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			Parent = b,
		}, 1.6)
	end
	Bounce(b, nil, 0.12)
	return b
end

-- Tab:CreateSection("GAMEPLAY")  -- yellow header like the game's settings pages
function Elements:CreateSection(name: string)
	local holder = New("Frame", {
		Name = "Section",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 0, 36),
		LayoutOrder = self:_order(),
		Parent = self.Container,
	})
	local label = Text({
		Text = string.upper(name or "Section"),
		TextColor3 = Library.Theme.Header,
		TextSize = 24,
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 1, -4),
		Parent = holder,
	}, 2.2, false)
	return {
		Set = function(_, text: string)
			label.Text = string.upper(text)
		end,
	}
end

function Elements:CreateLabel(text: string)
	local label = Text({
		Name = "Label",
		Text = text or "",
		FontFace = Library.Fonts.Body,
		TextSize = 18,
		TextColor3 = Library.Theme.SubText,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_order(),
		Parent = self.Container,
	}, 1.2, false)
	return {
		Set = function(_, t: string)
			label.Text = t
		end,
	}
end

function Elements:CreateParagraph(opts: { [string]: any })
	local card = New("Frame", {
		Name = "Paragraph",
		BackgroundColor3 = Library.Theme.Row,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -6, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_order(),
		Parent = self.Container,
	}, {
		Corner(8),
		Stroke(2, 0.2, true),
		Shade(Library.Theme.RowShade),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 10),
		}),
		New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Stripes(card, 8, 0.95, hex("d3d3d3"))
	local title = Text({
		Text = opts.Title or "",
		TextColor3 = Library.Theme.Header,
		TextSize = 20,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		Parent = card,
	}, 2, false)
	local content = Text({
		Text = opts.Content or "",
		FontFace = Library.Fonts.Body,
		TextColor3 = Library.Theme.SubText,
		TextSize = 17,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = card,
	}, 1.2, false)
	return {
		Set = function(_, o: { [string]: any })
			title.Text = o.Title or title.Text
			content.Text = o.Content or content.Text
		end,
	}
end

-- Tab:CreateButton({ Name = "Reset Default", Color = "Red", Callback = function() end })
function Elements:CreateButton(opts: { [string]: any })
	local holder = New("Frame", {
		Name = opts.Name or "Button",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 0, 48),
		LayoutOrder = self:_order(),
		Parent = self.Container,
	})
	local b = Chunky({ Size = UDim2.new(1, 0, 0, 40), Parent = holder }, opts.Color or "Grey", 8)
	b.Label.Text = string.upper(opts.Name or "Button")
	local window = self.Window
	track(b.Button.MouseEnter:Connect(function()
		if window then
			window:_info(opts.Name, opts.Description)
		end
	end))
	track(b.Button.MouseButton1Click:Connect(function()
		Library:PlaySound(opts.Sound or "Click")
		SafeCall(opts.Callback)
	end))
	return {
		Button = b.Button,
		SetText = function(_, t: string)
			b.Label.Text = string.upper(t)
		end,
		SetColor = function(_, c: any)
			b.Face.BackgroundColor3 = GetColor(c)
		end,
	}
end

-- Tab:CreateToggle({ Name = "Dust Particles", Default = true, Flag = "Dust", Callback = function(on) end })
-- Shown the game's way:  ◀  ON  ▶
function Elements:CreateToggle(opts: { [string]: any })
	local row, _, property = self:_row(opts)
	HList(property, 4)
	local prev = SmallButton(property, 1, nil, Library.Images.ArrowPrev)
	local value = Text({
		Name = "Value",
		FontFace = Library.Fonts.Value,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(56, 30),
		LayoutOrder = 2,
		Parent = property,
	}, 2, false)
	local nextB = SmallButton(property, 3, nil, Library.Images.ArrowNext)
	local valueScale = New("UIScale", { Parent = value })

	local toggle = { Value = nil }
	function toggle:Set(on: boolean, silent: boolean?)
		on = on and true or false
		if self.Value == on then
			return
		end
		self.Value = on
		value.Text = on and "ON" or "OFF"
		value.TextColor3 = on and Library.Theme.On or Library.Theme.Off
		valueScale.Scale = 1.25
		Tween(valueScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
		SetFlag(opts, on)
		if not silent then
			SafeCall(opts.Callback, on)
		end
	end
	function toggle:Get(): boolean
		return self.Value
	end
	local function flip()
		Library:PlaySound("Toggle")
		toggle:Set(not toggle.Value)
	end
	track(row.MouseButton1Click:Connect(flip))
	track(prev.MouseButton1Click:Connect(flip))
	track(nextB.MouseButton1Click:Connect(flip))
	toggle:Set(opts.Default == true, true)
	SetFlag(opts, toggle.Value)
	return toggle
end

-- Tab:CreateSlider({ Name = "Music", Min = 0, Max = 100, Default = 40, Increment = 1, Suffix = "%", Callback = function(v) end })
function Elements:CreateSlider(opts: { [string]: any })
	local min, max = opts.Min or 0, opts.Max or 100
	local inc = opts.Increment or 1
	local _, _, property = self:_row(opts)
	property.Size = UDim2.new(0.58, -10, 0, 46)
	HList(property, 6)
	local value = Text({
		Name = "Value",
		FontFace = Library.Fonts.Value,
		TextColor3 = Library.Theme.Value,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.fromOffset(58, 30),
		LayoutOrder = 1,
		Parent = property,
	}, 2, false)
	local minus = SmallButton(property, 2, "—")
	local trackFrame = New("Frame", {
		Name = "Scrolling",
		BackgroundColor3 = Library.Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(100, 12),
		LayoutOrder = 3,
		ZIndex = 3,
		Parent = property,
	}, { Corner(UDim.new(1, 0)), Stroke(2, 0, true) })
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = trackFrame })
	local fill = New("Frame", {
		Name = "Fill",
		BackgroundColor3 = Library.Theme.Fill,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.5, 1),
		ZIndex = 4,
		Parent = trackFrame,
	}, { Corner(UDim.new(1, 0)), Shade({ { 0, 1 }, { 1, 0.75 } }) })
	local thumb = New("Frame", {
		Name = "Thumb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = hex("f8f8f8"),
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = trackFrame,
	}, { Corner(UDim.new(1, 0)), Stroke(2.5, 0, true), Shade(Library.Theme.KnobShade) })
	local thumbScale = New("UIScale", { Parent = thumb })
	local hit = New("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -8, 0.5, 0),
		Size = UDim2.new(1, 16, 0, 34),
		ZIndex = 7,
		Parent = trackFrame,
	})
	local plus = SmallButton(property, 4, "+")

	local decimals = 0
	local s = tostring(inc)
	if s:find("%.") then
		decimals = #s - s:find("%.")
	end
	local function format(v: number): string
		return string.format("%." .. decimals .. "f", v) .. (opts.Suffix or "")
	end

	local slider = { Value = nil }
	function slider:Set(v: number, silent: boolean?)
		v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
		local alpha = max > min and (v - min) / (max - min) or 0
		Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, 0.08)
		Tween(thumb, { Position = UDim2.fromScale(alpha, 0.5) }, 0.08)
		value.Text = format(v)
		if self.Value == v then
			return
		end
		local first = self.Value == nil
		self.Value = v
		SetFlag(opts, v)
		if not first then
			Library:PlaySound("Tick")
		end
		if not silent then
			SafeCall(opts.Callback, v)
		end
	end
	function slider:Get(): number
		return self.Value
	end
	DragBar(hit, trackFrame, function(alpha)
		Tween(thumbScale, { Scale = 1.2 }, 0.1)
		slider:Set(min + (max - min) * alpha)
	end, function()
		Tween(thumbScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
	end)
	track(minus.MouseButton1Click:Connect(function()
		Library:PlaySound("Click")
		slider:Set(slider.Value - inc)
	end))
	track(plus.MouseButton1Click:Connect(function()
		Library:PlaySound("Click")
		slider:Set(slider.Value + inc)
	end))
	slider:Set(opts.Default or min, true)
	return slider
end

-- Tab:CreateDropdown({ Name = "Quality", Options = {"Low","High"}, Default = "High", Multi = false, Callback = function(v) end })
function Elements:CreateDropdown(opts: { [string]: any })
	local row, _, property = self:_row(opts)
	row.ClipsDescendants = true
	local box = Field({ Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 7), ZIndex = 3, Parent = property })
	local selected = Text({
		Text = "",
		TextSize = 18,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -40, 1, 0),
		ZIndex = 5,
		Parent = box,
	}, 1.6)
	local arrow = Text({
		Text = "▼",
		FontFace = Library.Fonts.Value,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 0),
		Size = UDim2.new(0, 26, 1, 0),
		ZIndex = 5,
		Parent = box,
	}, 1.6)
	local open = New("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = box })
	Bounce(open, box, 0.03)
	local list = New("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 50),
		Size = UDim2.new(1, -20, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 3,
		Parent = row,
	}, {
		New("UIGridLayout", {
			CellSize = UDim2.new(0.5, -4, 0, 32),
			CellPadding = UDim2.fromOffset(8, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local dropdown = { Value = nil, Options = {}, Open = false }
	local items: { [string]: any } = {}
	local multi = opts.Multi == true

	local function isSelected(option: string): boolean
		if multi then
			return table.find(dropdown.Value, option) ~= nil
		end
		return dropdown.Value == option
	end
	local function refreshVisuals()
		for option, item in pairs(items) do
			local on = isSelected(option)
			item.Face.BackgroundColor3 = on and Library.Colors.Green or Library.Colors.Grey
		end
		if multi then
			selected.Text = #dropdown.Value > 0 and table.concat(dropdown.Value, ", ") or "None"
		else
			selected.Text = dropdown.Value ~= nil and tostring(dropdown.Value) or "None"
		end
	end
	local function height(): number
		local rows = math.ceil(#dropdown.Options / 2)
		return dropdown.Open and (58 + rows * 38) or 46
	end
	function dropdown:SetOpen(state: boolean)
		self.Open = state
		Library:PlaySound(state and "Open" or "Close")
		Tween(row, { Size = UDim2.new(1, -6, 0, height()) }, 0.25, Enum.EasingStyle.Quint)
		Tween(arrow, { Rotation = state and 180 or 0 }, 0.25)
	end
	function dropdown:Set(v: any, silent: boolean?)
		if multi then
			self.Value = typeof(v) == "table" and table.clone(v) or { v }
		else
			self.Value = v
		end
		refreshVisuals()
		SetFlag(opts, self.Value)
		if not silent then
			SafeCall(opts.Callback, self.Value)
		end
	end
	function dropdown:Get()
		return self.Value
	end
	function dropdown:Refresh(options: { string }, keepValue: boolean?)
		for _, item in pairs(items) do
			item.Button:Destroy()
		end
		table.clear(items)
		self.Options = options
		for i, option in ipairs(options) do
			local b = Chunky({ LayoutOrder = i, Size = UDim2.new(1, 0, 0, 30), ZIndex = 4, Parent = list }, "Grey", 6)
			b.Label.Text = tostring(option)
			b.Label.TextSize = 17
			items[option] = b
			track(b.Button.MouseButton1Click:Connect(function()
				Library:PlaySound("Click")
				if multi then
					local value = table.clone(dropdown.Value)
					local idx = table.find(value, option)
					if idx then
						table.remove(value, idx)
					else
						table.insert(value, option)
					end
					dropdown:Set(value)
				else
					dropdown:Set(option)
					dropdown:SetOpen(false)
				end
			end))
		end
		if not keepValue then
			self.Value = multi and {} or nil
		end
		refreshVisuals()
		if self.Open then
			row.Size = UDim2.new(1, -6, 0, height())
		end
	end
	track(open.MouseButton1Click:Connect(function()
		dropdown:SetOpen(not dropdown.Open)
	end))
	dropdown:Refresh(opts.Options or {})
	if opts.Default ~= nil then
		dropdown:Set(opts.Default, true)
	elseif not multi and opts.Options and opts.Options[1] then
		dropdown:Set(opts.Options[1], true)
	end
	return dropdown
end

-- Tab:CreateTextbox({ Name = "Code", Placeholder = "Enter code...", NumbersOnly = false, ClearOnSubmit = false, Callback = function(text, enter) end })
function Elements:CreateTextbox(opts: { [string]: any })
	local _, _, property = self:_row(opts)
	local back = New("Frame", {
		Name = "Background",
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 7),
		Size = UDim2.new(1, 0, 0, 32),
		ZIndex = 3,
		Parent = property,
	}, { Corner(6), Stroke(2, 0.2, true), Shade(Library.Theme.RowShade) })
	Stripes(back, 6, 0.95, hex("d3d3d3"))
	local box = New("TextBox", {
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		FontFace = Library.Fonts.Title,
		PlaceholderText = opts.Placeholder or "Type here...",
		PlaceholderColor3 = hex("b5b5b5"),
		Text = opts.Default or "",
		TextColor3 = WHITE,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		ZIndex = 5,
		Parent = back,
	}, { Stroke(1.6) })
	local stroke = back:FindFirstChildOfClass("UIStroke")
	local textbox = { Value = box.Text }
	track(box.Focused:Connect(function()
		Library:PlaySound("Click")
		Tween(stroke, { Color = Library.Theme.Fill, Transparency = 0 }, 0.15)
	end))
	if opts.NumbersOnly then
		track(box:GetPropertyChangedSignal("Text"):Connect(function()
			local filtered = box.Text:gsub("[^%d%.%-]", "")
			if filtered ~= box.Text then
				box.Text = filtered
			end
		end))
	end
	track(box.FocusLost:Connect(function(enter)
		Tween(stroke, { Color = BLACK, Transparency = 0.2 }, 0.15)
		textbox.Value = box.Text
		SetFlag(opts, box.Text)
		SafeCall(opts.Callback, box.Text, enter)
		if enter and opts.ClearOnSubmit then
			box.Text = ""
		end
	end))
	function textbox:Set(t: string)
		box.Text = t
		self.Value = t
		SetFlag(opts, t)
	end
	function textbox:Get(): string
		return box.Text
	end
	SetFlag(opts, box.Text)
	return textbox
end

-- Tab:CreateKeybind({ Name = "Sprint", Default = Enum.KeyCode.LeftShift, Callback = function(key) end, Changed = function(key) end })
function Elements:CreateKeybind(opts: { [string]: any })
	local row, _, property = self:_row(opts)
	local box = Field({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 7),
		Size = UDim2.fromOffset(120, 32),
		ZIndex = 3,
		Parent = property,
	})
	local label = Text({
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = box,
	}, 1.6)
	local keybind = { Value = opts.Default, Listening = false }
	local function show()
		label.Text = keybind.Listening and "..." or (keybind.Value and keybind.Value.Name or "None")
		label.TextColor3 = keybind.Listening and Library.Theme.Header or WHITE
	end
	function keybind:Set(key: Enum.KeyCode?)
		self.Value = key
		self.Listening = false
		show()
		SetFlag(opts, key)
		SafeCall(opts.Changed, key)
	end
	function keybind:Get()
		return self.Value
	end
	track(row.MouseButton1Click:Connect(function()
		Library:PlaySound("Click")
		keybind.Listening = true
		show()
	end))
	track(UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if keybind.Listening then
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				keybind:Set(nil)
			else
				keybind:Set(input.KeyCode)
			end
			Library:PlaySound("Toggle")
		elseif not processed and keybind.Value and input.KeyCode == keybind.Value then
			SafeCall(opts.Callback, keybind.Value)
		end
	end))
	show()
	SetFlag(opts, keybind.Value)
	return keybind
end

-- Tab:CreateColorPicker({ Name = "Highlight", Default = Color3.fromRGB(255, 220, 60), Callback = function(color) end })
function Elements:CreateColorPicker(opts: { [string]: any })
	local row, _, property = self:_row(opts)
	row.ClipsDescendants = true
	local swatch = New("Frame", {
		Name = "Swatch",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 8),
		Size = UDim2.fromOffset(64, 30),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = property,
	}, { Corner(6), Stroke(2.5, 0, true), Shade({ { 0, 1 }, { 1, 0.7 } }) })
	local hexLabel = Text({
		FontFace = Library.Fonts.Value,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -74, 0, 0),
		Size = UDim2.new(1, -74, 1, 0),
		Parent = property,
	}, 1.6, false)

	local picker = { Value = opts.Default or Color3.fromRGB(255, 183, 16), Open = false }
	local channels = {}
	local panel = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 50),
		Size = UDim2.new(1, -28, 0, 3 * 30),
		ZIndex = 3,
		Parent = row,
	}, { New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local function apply(silent: boolean?)
		local c = picker.Value
		swatch.BackgroundColor3 = c
		hexLabel.Text = "#" .. c:ToHex():upper()
		for i, ch in ipairs(channels) do
			local v = ({ c.R, c.G, c.B })[i]
			ch.Fill.Size = UDim2.fromScale(v, 1)
			ch.Knob.Position = UDim2.fromScale(v, 0.5)
			ch.Value.Text = tostring(math.floor(v * 255 + 0.5))
		end
		SetFlag(opts, c)
		if not silent then
			SafeCall(opts.Callback, c)
		end
	end
	for i, info in ipairs({ { "R", hex("ff5050") }, { "G", hex("6cff64") }, { "B", hex("4fa3ff") } }) do
		local line = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = i, ZIndex = 3, Parent = panel })
		Text({ Text = info[1], TextColor3 = info[2], TextSize = 18, Size = UDim2.fromOffset(20, 24), Parent = line }, 1.6, false)
		local bar = New("Frame", {
			BackgroundColor3 = Library.Theme.Panel,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 30, 0.5, 0),
			Size = UDim2.new(1, -86, 0, 10),
			ZIndex = 3,
			Parent = line,
		}, { Corner(UDim.new(1, 0)), Stroke(2, 0, true) })
		local fill = New("Frame", { BackgroundColor3 = info[2], BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 4, Parent = bar }, { Corner(UDim.new(1, 0)) })
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = hex("f8f8f8"),
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = bar,
		}, { Corner(UDim.new(1, 0)), Stroke(2, 0, true), Shade(Library.Theme.KnobShade) })
		local value = Text({
			FontFace = Library.Fonts.Value,
			TextSize = 18,
			TextColor3 = Library.Theme.Value,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(44, 24),
			Parent = line,
		}, 1.6, false)
		local hit = New("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -6, 0.5, 0),
			Size = UDim2.new(1, 12, 0, 26),
			ZIndex = 7,
			Parent = bar,
		})
		channels[i] = { Fill = fill, Knob = knob, Value = value }
		DragBar(hit, bar, function(alpha)
			local c = picker.Value
			local rgb = { c.R, c.G, c.B }
			rgb[i] = alpha
			picker.Value = Color3.new(rgb[1], rgb[2], rgb[3])
			apply()
		end, function()
			Library:PlaySound("Tick")
		end)
	end

	function picker:Set(c: Color3, silent: boolean?)
		self.Value = c
		apply(silent)
	end
	function picker:Get(): Color3
		return self.Value
	end
	track(row.MouseButton1Click:Connect(function()
		picker.Open = not picker.Open
		Library:PlaySound(picker.Open and "Open" or "Close")
		Tween(row, { Size = UDim2.new(1, -6, 0, picker.Open and 150 or 46) }, 0.25, Enum.EasingStyle.Quint)
	end))
	apply(true)
	return picker
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local Window = {}
Window.__index = Window

--[[
	DandysUI:CreateWindow({
		Title = "Settings",
		Subtitle = "v1.0",
		Footer = "Made with DandysUI",
		Size = UDim2.fromOffset(760, 480),
		ToggleKey = Enum.KeyCode.RightShift,
		InfoPanel = true,            -- right-hand "hover to see what it does" panel
		InfoText = "Hover a setting to learn more.",
		OpenButton = true,           -- MENU button shown while the window is hidden
	})
]]
function Library.CreateWindow(_: any, opts: { [string]: any })
	opts = opts or {}
	local size: UDim2 = opts.Size or UDim2.fromOffset(760, 480)
	local w, h = size.X.Offset, size.Y.Offset
	local showInfo = opts.InfoPanel ~= false
	local infoWidth = showInfo and 230 or 0

	local self = setmetatable({
		Tabs = {},
		Visible = true,
		ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
		_defaultInfo = opts.InfoText or "Hover over a setting to see what it does.",
	}, Window)

	local frame = New("Frame", {
		Name = opts.Title or "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundTransparency = 1,
		Parent = Root,
	})
	local fit = New("UIScale", { Name = "Fit", Parent = frame })
	local main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	local pop = New("UIScale", { Name = "Pop", Scale = 0.85, Parent = main })
	New("Frame", {
		Name = "FrameBG",
		Position = UDim2.fromOffset(0, 7),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = main,
	}, { Corner(16) })
	local body = Panel({ Name = "Body", Size = UDim2.fromScale(1, 1), Parent = main }, 16, 4)
	self.Frame, self.Main, self.Body = frame, main, body

	-- Title bar (also the drag handle)
	local drag = New("Frame", {
		Name = "DragHandle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -110, 0, 58),
		ZIndex = 2,
		Parent = body,
	})
	local titleRow = New("Frame", {
		Name = "TitleRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 10),
		Size = UDim2.new(1, -140, 0, 42),
		ZIndex = 3,
		Parent = body,
	})
	HList(titleRow, 12, Enum.HorizontalAlignment.Left).VerticalAlignment = Enum.VerticalAlignment.Bottom
	local titleLabel = Text({
		Name = "Title",
		Text = opts.Title or "Settings",
		TextSize = 36,
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 1,
		Parent = titleRow,
	}, 3)
	Text({
		Name = "Subtitle",
		Text = opts.Subtitle or "",
		TextSize = 18,
		TextColor3 = hex("bdbdbd"),
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		Size = UDim2.new(0, 0, 0, 28),
		LayoutOrder = 2,
		Parent = titleRow,
	}, 1.8, false)
	self.TitleLabel = titleLabel

	local close = Chunky({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.fromOffset(38, 38),
		ZIndex = 4,
		Parent = body,
	}, hex("ff6a6c"), 8)
	close.Face:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, hex("bf7c7d")),
		ColorSequenceKeypoint.new(0.28, hex("fbfcfb")),
		ColorSequenceKeypoint.new(0.72, WHITE),
		ColorSequenceKeypoint.new(1, hex("bf7c7d")),
	})
	close.Label.Text = "X"
	close.Label.TextSize = 24
	close.Label.TextColor3 = hex("7f3031")
	close.Label:FindFirstChildOfClass("UIGradient"):Destroy()
	close.Label:FindFirstChildOfClass("UIStroke").Thickness = 0

	local minimize = Chunky({
		Name = "Minimize",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -64, 0, 14),
		Size = UDim2.fromOffset(38, 38),
		ZIndex = 4,
		Parent = body,
	}, "Grey", 8)
	minimize.Label.Text = "–"
	minimize.Label.TextSize = 26

	-- Navigation tabs
	local nav = New("ScrollingFrame", {
		Name = "Navigation",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(18, 62),
		Size = UDim2.new(1, -36, 0, 50),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		ZIndex = 3,
		Parent = body,
	}, {
		New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
	})
	HList(nav, 10, Enum.HorizontalAlignment.Left)
	self.Nav = nav

	-- Pages
	local pages = New("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 120),
		Size = UDim2.new(1, -36 - infoWidth - (showInfo and 14 or 0), 1, -158),
		ZIndex = 2,
		Parent = body,
	})
	self.Pages = pages

	-- Info side panel (like the game's description panel)
	if showInfo then
		local info = New("Frame", {
			Name = "InfoPanel",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -18, 0, 120),
			Size = UDim2.new(0, infoWidth, 1, -158),
			BackgroundColor3 = BLACK,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = body,
		}, {
			Corner(10),
			Stroke(2, 0.2, true),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),
			New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		self._infoTitle = Text({
			Name = "Title",
			Text = "INFO",
			TextSize = 22,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
			Parent = info,
		}, 2)
		New("Frame", {
			Name = "Divider",
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 2),
			LayoutOrder = 2,
			ZIndex = 3,
			Parent = info,
		})
		self._infoText = Text({
			Name = "Description",
			Text = self._defaultInfo,
			FontFace = Library.Fonts.Body,
			TextColor3 = Library.Theme.SubText,
			TextSize = 18,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			Parent = info,
		}, 1.2, false)
	end

	Text({
		Name = "Footer",
		Text = opts.Footer or ("DandysUI v" .. Library.Version),
		TextSize = 15,
		TextColor3 = hex("a8a8a8"),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 22, 1, -8),
		Size = UDim2.new(1, -44, 0, 22),
		Parent = body,
	}, 1.4, false)

	-- Re-open button shown while hidden
	local openButton
	if opts.OpenButton ~= false then
		openButton = Chunky({
			Name = "OpenButton",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 18, 0.5, 0),
			Size = UDim2.fromOffset(70, 54),
			Visible = false,
			Parent = Root,
		}, "Grey", 10)
		openButton.Label.Text = opts.OpenText or "MENU"
		openButton.Label.TextSize = 20
		local moved = 0
		MakeDraggable(openButton.Button, openButton.Button, function(d)
			moved = d
		end)
		track(openButton.Button.MouseButton1Click:Connect(function()
			if moved > 6 then
				moved = 0
				return
			end
			self:SetVisible(true)
		end))
	end
	self._openButton = openButton

	MakeDraggable(drag, frame)

	track(close.Button.MouseButton1Click:Connect(function()
		Library:PlaySound("Click")
		Library:Dialog({
			Title = "Close " .. (opts.Title or "UI") .. "?",
			Content = "You won't be able to open it again until you re-run the script.",
			ConfirmText = "Close",
			ConfirmSound = "Close",
			CancelText = "Back",
			Callback = function(ok)
				if ok then
					self:Destroy()
				end
			end,
		})
	end))
	track(minimize.Button.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end))
	track(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self.ToggleKey and self.Frame.Parent then
			self:Toggle()
		end
	end))

	local function refit()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local vp = camera.ViewportSize
		fit.Scale = math.clamp(math.min((vp.X - 30) / math.max(w, 1), (vp.Y - 30) / math.max(h, 1)), 0.4, 1)
	end
	refit()
	if workspace.CurrentCamera then
		track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit))
	end

	Library:PlaySound("Open")
	Tween(pop, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
	table.insert(Library.Windows, self)
	return self
end

function Window:_info(title: string?, description: string?)
	if not self._infoTitle then
		return
	end
	self._infoTitle.Text = title or "INFO"
	self._infoText.Text = description or self._defaultInfo
end

function Window:SetVisible(visible: boolean)
	if self.Visible == visible or not self.Frame.Parent then
		return
	end
	self.Visible = visible
	local pop = self.Main:FindFirstChild("Pop")
	if visible then
		self.Frame.Visible = true
		if self._openButton then
			self._openButton.Button.Visible = false
		end
		Library:PlaySound("Open")
		pop.Scale = 0.85
		Tween(pop, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	else
		Library:PlaySound("Close")
		Tween(pop, { Scale = 0.85 }, 0.12)
		task.delay(0.12, function()
			if not self.Visible then
				self.Frame.Visible = false
				if self._openButton then
					self._openButton.Button.Visible = true
				end
			end
		end)
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:SetTitle(text: string)
	self.TitleLabel.Text = text
end

function Window:Destroy()
	if self._openButton then
		self._openButton.Button:Destroy()
	end
	self.Frame:Destroy()
	local idx = table.find(Library.Windows, self)
	if idx then
		table.remove(Library.Windows, idx)
	end
end

function Window:Notify(opts: { [string]: any })
	return Library:Notify(opts)
end

function Window:Dialog(opts: { [string]: any })
	return Library:Dialog(opts)
end

function Window:Message(text: string, opts: { [string]: any }?)
	return Library:Message(text, opts)
end

-- Window:CreateTab({ Name = "General", Icon = "rbxassetid://..." })  or  Window:CreateTab("General")
function Window:CreateTab(opts: any)
	if typeof(opts) == "string" then
		opts = { Name = opts }
	end
	opts = opts or {}

	local button = New("TextButton", {
		Name = opts.Name or "Tab",
		AutoButtonColor = false,
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = #self.Tabs + 1,
		ZIndex = 3,
		Parent = self.Nav,
	})
	local holder = New("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 3,
		Parent = button,
	})
	local back = New("Frame", {
		Name = "BackgroundOG",
		BackgroundColor3 = Library.Theme.Tab,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = holder,
	}, { Corner(8), Stroke(2.5, 0, true) })
	New("Frame", {
		Name = "InnerBackground",
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = back,
	}, {
		Corner(8),
		Shade({ { 0, 1 }, { 0.447, 0.541 }, { 0.789, 0.263 }, { 1, 0 } }),
	})
	Stripes(back, 8, 0.94)
	local selectedImage = New("ImageLabel", {
		Name = "Selected",
		BackgroundTransparency = 1,
		Image = Library.Images.Selected,
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = holder,
	}, { Corner(8) })
	local content = New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 5,
		Parent = holder,
	}, {
		New("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	if opts.Icon then
		New("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = opts.Icon,
			Size = UDim2.fromOffset(24, 24),
			ZIndex = 5,
			Parent = content,
		})
	end
	local label = Text({
		Name = "Label",
		Text = opts.Name or "Tab",
		TextSize = 21,
		AutomaticSize = Enum.AutomaticSize.X,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		ZIndex = 5,
		Parent = content,
	}, 2.2)
	Bounce(button, holder, 0.06)

	local page = New("ScrollingFrame", {
		Name = opts.Name or "Page",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = hex("1a1a1a"),
		ScrollBarImageTransparency = 0.1,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Visible = false,
		ZIndex = 2,
		Parent = self.Pages,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 3),
			PaddingRight = UDim.new(0, 3),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 10),
		}),
	})

	local tab = setmetatable({
		Name = opts.Name,
		Window = self,
		Container = page,
		Button = button,
		_label = label,
		_selected = selectedImage,
		_count = 0,
	}, Elements)
	table.insert(self.Tabs, tab)

	track(button.MouseButton1Click:Connect(function()
		if self.SelectedTab ~= tab then
			Library:PlaySound("Tab")
			self:SelectTab(tab)
		end
	end))

	if #self.Tabs == 1 then
		self:SelectTab(tab)
	else
		label.TextTransparency = 0.35
	end
	return tab
end

function Window:SelectTab(tab: any)
	if typeof(tab) == "string" then
		for _, t in ipairs(self.Tabs) do
			if t.Name == tab then
				tab = t
				break
			end
		end
	end
	if typeof(tab) ~= "table" then
		return
	end
	self.SelectedTab = tab
	for _, t in ipairs(self.Tabs) do
		local on = t == tab
		t.Container.Visible = on
		Tween(t._selected, { ImageTransparency = on and 0 or 1 }, 0.2)
		Tween(t._label, { TextTransparency = on and 0 or 0.35 }, 0.2)
	end
	tab.Container.CanvasPosition = Vector2.zero
	self:_info(nil, nil)
end

function Library:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self.Windows)
	Root:Destroy()
end

return Library
