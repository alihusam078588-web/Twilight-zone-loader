--[[
    ToonsUI  -  Roblox UI library styled after the "Toon's Universe" game UI
    ---------------------------------------------------------------------------
    Extracted from the game file:
      * Palette      : navy panels, royal-blue accents, light-blue outlines,
                       green ON / red OFF, green slider fill, cream button text
      * Fonts        : GothamSSm Bold / SemiBold / Medium
      * Text style   : white text with a coloured UIStroke
      * Toggle       : pill with a sliding knob + ON/OFF text (0.2s Quad Out)
      * Slider       : dark capsule track, green fill, knob, "%" value text
      * Button pop   : hover 1.05 / press 0.95 (Back easing), Hover + Click sounds
      * Window pop   : UIScale 0 -> 1, Back easing, 0.3s
      * Sounds       : the game's own UI sound ids (see Library.Sounds)

    Elements : Tabs, Sections, Toggle, Slider, Button, Dropdown (single/multi),
               TextBox, Keybind, ColorPicker, Label, Paragraph, Divider
    Extras   : Notify (toasts), Dialog (confirm / cancel), config save/load,
               floating open button (mobile), draggable window, themes, sounds

    Usage:
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/ToonsUI.lua"))()
        local Window  = Library:CreateWindow({ Title = "My Hub", Subtitle = "v1.0" })
        local Tab     = Window:AddTab("Main")
        Tab:AddToggle({ Name = "Auto Farm", Flag = "AutoFarm", Callback = function(v) end })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.ToonsUI and type(env.ToonsUI.Unload) == "function" then
	pcall(function()
		env.ToonsUI:Unload()
	end)
end

local Library = {
	Version = "1.0.0",
	Flags = {},
	Options = {},
	Windows = {},
	Connections = {},
	ConfigFolder = "ToonsUI",
	SoundsEnabled = true,
	SoundVolume = 1, -- master multiplier on top of every sound's own volume
	Scale = 1, -- extra UI scale multiplier
}

--------------------------------------------------------------------------------
-- Theme (values sampled from the game's StarterGui)
--------------------------------------------------------------------------------
Library.Theme = {
	Window = Color3.fromRGB(12, 20, 58),
	WindowBottom = Color3.fromRGB(3, 7, 28),
	Sidebar = Color3.fromRGB(0, 1, 21),
	Content = Color3.fromRGB(10, 14, 30),
	Row = Color3.fromRGB(17, 28, 72),
	RowHover = Color3.fromRGB(24, 38, 92),
	RowStroke = Color3.fromRGB(42, 79, 136),

	Accent = Color3.fromRGB(80, 119, 246),
	AccentDark = Color3.fromRGB(29, 92, 218),
	AccentDeep = Color3.fromRGB(21, 45, 130),
	Outline = Color3.fromRGB(80, 119, 246),
	OutlineLight = Color3.fromRGB(107, 170, 248),
	OutlineDark = Color3.fromRGB(9, 35, 85),

	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(199, 221, 255),
	Muted = Color3.fromRGB(129, 150, 190),
	DarkText = Color3.fromRGB(13, 14, 67),
	Cream = Color3.fromRGB(255, 251, 202),

	On = Color3.fromRGB(91, 178, 83),
	OnStroke = Color3.fromRGB(65, 102, 48),
	Off = Color3.fromRGB(178, 68, 68),
	OffStroke = Color3.fromRGB(115, 43, 58),
	Fill = Color3.fromRGB(138, 228, 105),
	Warning = Color3.fromRGB(255, 210, 45),

	InputBG = Color3.fromRGB(222, 234, 255),
	InputText = Color3.fromRGB(59, 98, 157),

	Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	FontSemi = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
	FontMed = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
}

function Library:SetTheme(overrides)
	for k, v in pairs(overrides or {}) do
		self.Theme[k] = v
	end
end

-- button pop animation values straight from the game's UIEffects module
Library.Effects = {
	HoverScale = 1.05,
	ClickScale = 0.95,
	ReturnTime = 0.05,
	ClickTime = 0.035,
}

--------------------------------------------------------------------------------
-- Sounds (ids + volumes + speeds copied from ReplicatedStorage.Assets.SFX)
--------------------------------------------------------------------------------
Library.Sounds = {
	Click = { Id = "rbxassetid://113015951282811", Volume = 0.15, Speed = 1 },
	Hover = { Id = "rbxassetid://114349858671788", Volume = 0.3, Speed = 2 },
	Open = { Id = "rbxassetid://6874964659", Volume = 0.06, Speed = 1 },
	BubblyClick = { Id = "rbxassetid://15675032796", Volume = 0.5, Speed = 1 },
	DialogueHover = { Id = "rbxassetid://6972108033", Volume = 0.5, Speed = 0.94 },
	PlayersTabOpen = { Id = "rbxassetid://75778731670006", Volume = 0.1, Speed = 2 },
	PlayersTabClose = { Id = "rbxassetid://102378262791241", Volume = 0.1, Speed = 1 },
	QuestNotification = { Id = "rbxassetid://18595195017", Volume = 0.5, Speed = 1 },
	Announcement = { Id = "rbxassetid://6988710942", Volume = 0.5, Speed = 1 },
	Switch1 = { Id = "rbxassetid://139335603235739", Volume = 1.4, Speed = 1 },
	Switch2 = { Id = "rbxassetid://136147895742602", Volume = 1.4, Speed = 1 },
	Switch3 = { Id = "rbxassetid://98193363534716", Volume = 1.4, Speed = 1 },
	Switch4 = { Id = "rbxassetid://115226718025566", Volume = 1.4, Speed = 1 },
	Switch5 = { Id = "rbxassetid://100777690496135", Volume = 1.4, Speed = 1 },
	Writer = { Id = "rbxassetid://876939830", Volume = 0.1, Speed = 1 },
	Equip = { Id = "rbxassetid://75778731670006", Volume = 0.15, Speed = 1 },
	Unequip = { Id = "rbxassetid://102378262791241", Volume = 0.15, Speed = 1 },
	Collect = { Id = "rbxassetid://82357128779870", Volume = 0.5, Speed = 1 },
	PurchasePrompt = { Id = "rbxassetid://6647897822", Volume = 0.5, Speed = 1 },
	DoomOffer = { Id = "rbxassetid://7107161936", Volume = 0.5, Speed = 1 },
	DeepImpact = { Id = "rbxassetid://9125402735", Volume = 0.105, Speed = 1 },
}

-- which sound is used for which UI action (edit freely, a table = random pick)
Library.SoundMap = {
	Hover = "Hover",
	Click = "Click",
	Open = "Open",
	Close = "PlayersTabClose",
	ToggleOn = "Equip",
	ToggleOff = "Unequip",
	Tab = { "Switch1", "Switch2", "Switch3", "Switch4", "Switch5" },
	DropdownOpen = "PlayersTabOpen",
	DropdownClose = "PlayersTabClose",
	Select = "Click",
	Slider = "Hover",
	Notify = "Announcement",
	NotifySuccess = "Collect",
	NotifyWarning = "QuestNotification",
	NotifyError = "DoomOffer",
	Dialog = "PurchasePrompt",
}

function Library:PlaySound(key)
	if not self.SoundsEnabled then
		return
	end
	local name = self.SoundMap[key] or key
	if type(name) == "table" then
		name = name[math.random(1, #name)]
	end
	local def = self.Sounds[name]
	if not def then
		return
	end
	task.spawn(function()
		local ok = pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = def.Id
			s.Volume = def.Volume * self.SoundVolume
			s.PlaybackSpeed = def.Speed or 1
			s.Parent = SoundService
			s.Ended:Once(function()
				s:Destroy()
			end)
			s:Play()
			task.delay(10, function()
				if s.Parent then
					s:Destroy()
				end
			end)
		end)
		return ok
	end)
end

function Library:SetSound(name, id, volume, speed)
	local old = self.Sounds[name] or { Volume = 0.5, Speed = 1 }
	self.Sounds[name] = {
		Id = type(id) == "number" and ("rbxassetid://" .. id) or id,
		Volume = volume or old.Volume,
		Speed = speed or old.Speed,
	}
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function New(class, props, children)
	local inst = Instance.new(class)
	props = props or {}
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
		if inst:IsA("GuiButton") then
			inst.AutoButtonColor = false
			if inst:IsA("TextButton") and props.Text == nil then
				inst.Text = ""
			end
		end
		if props.BackgroundTransparency == nil and not inst:IsA("Frame") then
			inst.BackgroundTransparency = 1
		end
	end
	local parent = props.Parent
	for k, v in pairs(props) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Corner(parent, radius)
	local r = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 10)
	return New("UICorner", { CornerRadius = r, Parent = parent })
end

local function Stroke(parent, color, thickness)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function TextStroke(parent, color, thickness)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

local function Gradient(parent, c0, c1, rotation)
	return New("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rotation or 90, Parent = parent })
end

local function Padding(parent, l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or l or 0),
		PaddingRight = UDim.new(0, r or l or 0),
		PaddingBottom = UDim.new(0, b or t or l or 0),
		Parent = parent,
	})
end

local function List(parent, padding)
	return New("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function Label(parent, text, size, color, font, props)
	local l = New("TextLabel", {
		Text = text,
		TextSize = size or 14,
		TextColor3 = color or Library.Theme.Text,
		FontFace = font or Library.Theme.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

local function Tween(obj, time, props, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function Apply(obj, props, animate, time)
	if animate then
		Tween(obj, time or 0.2, props)
	else
		for k, v in pairs(props) do
			obj[k] = v
		end
	end
end

local function Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Library.Connections, c)
	return c
end

local function IsPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

-- screen-space position that matches AbsolutePosition (gui is created with IgnoreGuiInset)
local function ScreenPos(input)
	local inset = GuiService:GetGuiInset()
	return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
end

local function RandomName()
	local chars = {}
	for i = 1, 12 do
		chars[i] = string.char(math.random(97, 122))
	end
	return table.concat(chars)
end

-- the pop / bounce behaviour from the game's UIEffects.ApplyButtonEffect
local function ButtonEffect(btn, silentClick)
	local scale = btn:FindFirstChildOfClass("UIScale") or New("UIScale", { Parent = btn })
	local hover = false
	local function pop(target, time)
		Tween(scale, time, { Scale = target }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	Connect(btn.MouseEnter, function()
		hover = true
		pop(Library.Effects.HoverScale, Library.Effects.ReturnTime)
		Library:PlaySound("Hover")
	end)
	Connect(btn.MouseLeave, function()
		hover = false
		pop(1, Library.Effects.ReturnTime)
	end)
	Connect(btn.MouseButton1Down, function()
		pop(Library.Effects.ClickScale, Library.Effects.ClickTime)
	end)
	Connect(btn.MouseButton1Up, function()
		pop(hover and Library.Effects.HoverScale or 1, Library.Effects.ReturnTime)
	end)
	if not silentClick then
		Connect(btn.Activated, function()
			Library:PlaySound("Click")
		end)
	end
end

local function MakeDraggable(handle, target, onDrop)
	local dragging, dragStart, startPos = false, nil, nil
	local moved = 0
	Connect(handle.InputBegan, function(input)
		if IsPress(input) then
			dragging = true
			moved = 0
			dragStart = input.Position
			startPos = target.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if c then
						c:Disconnect()
					end
					if onDrop then
						onDrop(moved)
					end
				end
			end)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if dragging and IsMove(input) then
			local d = input.Position - dragStart
			moved = math.max(moved, d.Magnitude)
			target.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

--------------------------------------------------------------------------------
-- Root gui
--------------------------------------------------------------------------------
local Gui

local function GetGui()
	if Gui and Gui.Parent then
		return Gui
	end
	Gui = New("ScreenGui", {
		Name = RandomName(),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, Gui)
	end
	local parented = false
	if gethui then
		parented = pcall(function()
			Gui.Parent = gethui()
		end) and Gui.Parent ~= nil
	end
	if not parented then
		parented = pcall(function()
			Gui.Parent = CoreGui
		end) and Gui.Parent ~= nil
	end
	if not parented then
		Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	return Gui
end

local function ViewportFit(w, h)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.min(1, (vp.X - 16) / w, (vp.Y - 16) / h)
end

--------------------------------------------------------------------------------
-- Element mixin (shared by Tabs and Sections)
--------------------------------------------------------------------------------
local Elements = {}

local function NextOrder(self)
	self._order = (self._order or 0) + 1
	return self._order
end

local function MakeRow(self, height)
	local T = Library.Theme
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = T.Row,
		Parent = self.Container,
	})
	Corner(row, 10)
	row.LayoutOrder = NextOrder(self)
	local stroke = Stroke(row, T.RowStroke, 1.5)
	return row, stroke
end

local function AddTitle(row, name, desc, rightPad)
	local T = Library.Theme
	local w = UDim2.new(1, -((rightPad or 0) + 24), 0, desc and 20 or 42)
	local title = Label(row, name, 15, T.Text, T.Font, {
		Position = UDim2.new(0, 12, 0, desc and 7 or 0),
		Size = desc and w or UDim2.new(1, -((rightPad or 0) + 24), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local d
	if desc then
		d = Label(row, desc, 12, T.Muted, T.FontMed, {
			Position = UDim2.new(0, 12, 0, 28),
			Size = UDim2.new(1, -((rightPad or 0) + 24), 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	return title, d
end

local function HoverRow(hit, row, stroke)
	local T = Library.Theme
	Connect(hit.MouseEnter, function()
		Tween(row, 0.12, { BackgroundColor3 = T.RowHover })
		Tween(stroke, 0.12, { Color = T.Outline })
		Library:PlaySound("Hover")
	end)
	Connect(hit.MouseLeave, function()
		Tween(row, 0.12, { BackgroundColor3 = T.Row })
		Tween(stroke, 0.12, { Color = T.RowStroke })
	end)
end

local function Register(obj, cfg)
	obj.Flag = cfg.Flag
	obj.Callback = cfg.Callback or function() end
	if cfg.Flag then
		Library.Options[cfg.Flag] = obj
	end
end

local function Commit(obj, silent)
	if obj.Flag then
		Library.Flags[obj.Flag] = obj.Value
	end
	if not silent then
		task.spawn(obj.Callback, obj.Value)
	end
end

local function CommonMethods(obj, row)
	obj.Row = row
	function obj:SetVisible(v)
		row.Visible = v
	end
	function obj:Destroy()
		if self.Flag then
			Library.Options[self.Flag] = nil
			Library.Flags[self.Flag] = nil
		end
		row:Destroy()
	end
	function obj:Get()
		return self.Value
	end
end

---------------------------------------------------------------- Label / Paragraph
function Elements:AddLabel(text)
	local T = Library.Theme
	local obj = { Type = "Label" }
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(self),
		Parent = self.Container,
	})
	local l = Label(row, text, 14, T.SubText, T.FontSemi, {
		Size = UDim2.new(1, -8, 0, 0),
		Position = UDim2.fromOffset(4, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
	})
	Padding(l, 0, 4, 0, 4)
	CommonMethods(obj, row)
	function obj:Set(t)
		l.Text = t
	end
	return obj
end

function Elements:AddParagraph(cfg)
	cfg = cfg or {}
	local T = Library.Theme
	local obj = { Type = "Paragraph" }
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Row,
		LayoutOrder = NextOrder(self),
		Parent = self.Container,
	})
	Corner(row, 10)
	Stroke(row, T.RowStroke, 1.5)
	Padding(row, 12, 10, 12, 10)
	List(row, 4)
	local ptitle = Label(row, cfg.Title or "Paragraph", 15, T.Text, T.Font, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
	})
	ptitle.LayoutOrder = 1
	local body = Label(row, cfg.Content or "", 13, T.SubText, T.FontMed, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	body.LayoutOrder = 2
	CommonMethods(obj, row)
	function obj:Set(t, c)
		if t then
			ptitle.Text = t
		end
		if c then
			body.Text = c
		end
	end
	return obj
end

function Elements:AddDivider()
	local T = Library.Theme
	local d = New("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = T.OutlineDark,
		LayoutOrder = NextOrder(self),
		Parent = self.Container,
	})
	Corner(d, 2)
	return { Row = d, SetVisible = function(_, v) d.Visible = v end }
end

---------------------------------------------------------------- Button
local ButtonVariants = {
	Primary = function(T)
		return T.Accent, T.AccentDark, T.OutlineDark
	end,
	Success = function(T)
		return T.On, Color3.fromRGB(60, 130, 60), T.OnStroke
	end,
	Danger = function(T)
		return T.Off, Color3.fromRGB(130, 45, 55), T.OffStroke
	end,
	Secondary = function(T)
		return T.Row, Color3.fromRGB(10, 18, 50), T.RowStroke
	end,
}

local function BuildButton(parent, text, variant, height)
	local T = Library.Theme
	local c0, c1, edge = (ButtonVariants[variant] or ButtonVariants.Primary)(T)
	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 0, height or 40),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local btn = New("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		Parent = holder,
	})
	Corner(btn, 10)
	Stroke(btn, edge, 2)
	Gradient(btn, c0, c1, 90)
	-- the game draws its button text twice (dark shadow + white top copy)
	local shadow = Label(btn, text, 16, edge, T.Font, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 2),
		Size = UDim2.new(1, -16, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local top = Label(btn, text, 16, T.Text, T.Font, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -16, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	TextStroke(top, edge, 1.5)
	ButtonEffect(btn)
	return holder, btn, function(t)
		shadow.Text = t
		top.Text = t
	end
end

function Elements:AddButton(cfg)
	cfg = cfg or {}
	local obj = { Type = "Button" }
	local holder, btn, setText = BuildButton(self.Container, cfg.Name or "Button", cfg.Variant, cfg.Height)
	holder.LayoutOrder = NextOrder(self)
	Register(obj, cfg)
	CommonMethods(obj, holder)
	Connect(btn.Activated, function()
		task.spawn(obj.Callback)
	end)
	function obj:SetText(t)
		setText(t)
	end
	return obj
end

---------------------------------------------------------------- Toggle
function Elements:AddToggle(cfg)
	cfg = cfg or {}
	local T = Library.Theme
	local obj = { Type = "Toggle", Value = cfg.Default == true }
	local row, rowStroke = MakeRow(self, cfg.Description and 54 or 42)
	local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = row })
	AddTitle(row, cfg.Name or "Toggle", cfg.Description, 78)

	local track = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(68, 28),
		BackgroundColor3 = T.Off,
		Parent = row,
	})
	Corner(track, UDim.new(1, 0))
	local tStroke = Stroke(track, T.OffStroke, 2)
	local state = Label(track, "OFF", 12, T.Text, T.Font, {
		Size = UDim2.fromScale(0.5, 1),
		Position = UDim2.fromScale(0.5, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	TextStroke(state, T.OffStroke, 1)
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.24, 0.5),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	})
	Corner(knob, UDim.new(1, 0))
	local kStroke = Stroke(knob, T.OffStroke, 1.5)

	local function render(animate)
		local on = obj.Value
		Apply(track, { BackgroundColor3 = on and T.On or T.Off }, animate)
		Apply(tStroke, { Color = on and T.OnStroke or T.OffStroke }, animate)
		Apply(kStroke, { Color = on and T.OnStroke or T.OffStroke }, animate)
		Apply(knob, { Position = UDim2.fromScale(on and 0.76 or 0.24, 0.5) }, animate)
		Apply(state, { Position = UDim2.fromScale(on and 0 or 0.5, 0) }, animate)
		state.Text = on and "ON" or "OFF"
		state.UIStroke.Color = on and T.OnStroke or T.OffStroke
	end

	Register(obj, cfg)
	CommonMethods(obj, row)
	function obj:Set(v, silent)
		self.Value = v == true
		render(true)
		Commit(self, silent)
	end
	render(false)
	Commit(obj, true)
	HoverRow(hit, row, rowStroke)
	Connect(hit.Activated, function()
		Library:PlaySound(obj.Value and "ToggleOff" or "ToggleOn")
		obj:Set(not obj.Value)
	end)
	if cfg.Default then
		task.defer(function()
			task.spawn(obj.Callback, obj.Value)
		end)
	end
	return obj
end

---------------------------------------------------------------- Slider
function Elements:AddSlider(cfg)
	cfg = cfg or {}
	local T = Library.Theme
	local min, max = cfg.Min or 0, cfg.Max or 100
	local inc = cfg.Increment or 1
	local decimals = 0
	local incStr = tostring(inc)
	local dot = incStr:find("%.")
	if dot then
		decimals = #incStr - dot
	end
	local function snap(v)
		v = math.clamp(v, min, max)
		v = math.floor((v - min) / inc + 0.5) * inc + min
		return tonumber(string.format("%." .. decimals .. "f", math.clamp(v, min, max)))
	end
	local obj = { Type = "Slider", Value = snap(cfg.Default or min) }
	local row, rowStroke = MakeRow(self, cfg.Description and 74 or 60)
	local titleY = 7
	Label(row, cfg.Name or "Slider", 15, T.Text, T.Font, {
		Position = UDim2.new(0, 12, 0, titleY),
		Size = UDim2.new(1, -110, 0, 20),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	if cfg.Description then
		Label(row, cfg.Description, 12, T.Muted, T.FontMed, {
			Position = UDim2.new(0, 12, 0, 27),
			Size = UDim2.new(1, -24, 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	local valueLabel = Label(row, "", 15, T.Text, T.Font, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, titleY),
		Size = UDim2.fromOffset(90, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	TextStroke(valueLabel, T.OutlineLight, 1)

	local track = New("TextButton", {
		Position = UDim2.new(0, 12, 1, -24),
		Size = UDim2.new(1, -24, 0, 14),
		BackgroundColor3 = T.OutlineDark,
		BackgroundTransparency = 0,
		Parent = row,
	})
	Corner(track, UDim.new(1, 0))
	Stroke(track, T.OutlineLight, 1.5)
	local fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = T.Fill,
		Parent = track,
	})
	Corner(fill, UDim.new(1, 0))
	Gradient(fill, Color3.fromRGB(176, 245, 140), T.Fill, 90)
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = track,
	})
	Corner(knob, UDim.new(1, 0))
	Stroke(knob, T.OutlineLight, 2)

	local function render(animate)
		local a = (obj.Value - min) / math.max(max - min, 1e-9)
		Apply(fill, { Size = UDim2.fromScale(a, 1) }, animate, 0.08)
		Apply(knob, { Position = UDim2.fromScale(a, 0.5) }, animate, 0.08)
		valueLabel.Text = string.format("%." .. decimals .. "f", obj.Value) .. (cfg.Suffix or "")
	end

	Register(obj, cfg)
	CommonMethods(obj, row)
	function obj:Set(v, silent)
		v = snap(tonumber(v) or min)
		local changed = v ~= self.Value
		self.Value = v
		render(true)
		if changed or not silent then
			Commit(self, silent)
		end
	end
	render(false)
	Commit(obj, true)
	HoverRow(track, row, rowStroke)

	local dragging = false
	local function lockScroll(b)
		if self.Scroller then
			self.Scroller.ScrollingEnabled = not b
		end
	end
	local function fromInput(input)
		local x = ScreenPos(input).X
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		obj:Set(min + (max - min) * a)
	end
	Connect(track.InputBegan, function(input)
		if IsPress(input) then
			dragging = true
			lockScroll(true)
			Tween(knob, 0.1, { Size = UDim2.fromOffset(24, 24) }, Enum.EasingStyle.Back)
			fromInput(input)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if dragging and IsMove(input) then
			fromInput(input)
		end
	end)
	Connect(UserInputService.InputEnded, function(input)
		if dragging and IsPress(input) then
			dragging = false
			lockScroll(false)
			Tween(knob, 0.1, { Size = UDim2.fromOffset(20, 20) }, Enum.EasingStyle.Back)
			Library:PlaySound("Click")
		end
	end)
	if cfg.Default then
		task.defer(function()
			task.spawn(obj.Callback, obj.Value)
		end)
	end
	return obj
end

---------------------------------------------------------------- Dropdown
function Elements:AddDropdown(cfg)
	cfg = cfg or {}
	local T = Library.Theme
	local HEADER, ITEM = 42, 30
	local multi = cfg.Multi == true
	local options = table.clone(cfg.Options or {})
	local maxVisible = cfg.MaxVisible or 5
	local obj = { Type = "Dropdown", Open = false }
	local selected = {} -- set of option -> true

	local row, rowStroke = MakeRow(self, HEADER)
	row.ClipsDescendants = true
	local hit = New("TextButton", { Size = UDim2.new(1, 0, 0, HEADER), Parent = row })
	AddTitle(row, cfg.Name or "Dropdown", nil, 160)
	local valueLabel = Label(row, "", 13, T.SubText, T.FontSemi, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -32, 0, 0),
		Size = UDim2.new(0, 150, 0, HEADER),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local arrow = Label(row, "▼", 12, T.OutlineLight, T.Font, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -18, 0, HEADER / 2),
		Size = UDim2.fromOffset(16, 16),
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local listFrame = New("ScrollingFrame", {
		Position = UDim2.new(0, 8, 0, HEADER + 2),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundColor3 = T.Sidebar,
		BackgroundTransparency = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		Parent = row,
	})
	Corner(listFrame, 8)
	Stroke(listFrame, T.OutlineDark, 1.5)
	Padding(listFrame, 4)
	List(listFrame, 3)

	local buttons = {}
	local function listHeight()
		return math.min(#options, maxVisible) * (ITEM + 3) + 8 + (#options > 0 and -3 or 0)
	end

	local function displayText()
		if multi then
			local names = {}
			for _, o in ipairs(options) do
				if selected[o] then
					table.insert(names, tostring(o))
				end
			end
			if #names == 0 then
				return cfg.Placeholder or "None"
			end
			return table.concat(names, ", ")
		end
		for o in pairs(selected) do
			return tostring(o)
		end
		return cfg.Placeholder or "None"
	end

	local function currentValue()
		if multi then
			local arr = {}
			for _, o in ipairs(options) do
				if selected[o] then
					table.insert(arr, o)
				end
			end
			return arr
		end
		for o in pairs(selected) do
			return o
		end
		return nil
	end

	local function restyle(animate)
		for opt, b in pairs(buttons) do
			local on = selected[opt] == true
			Apply(b, { BackgroundColor3 = on and T.Accent or T.Row }, animate, 0.12)
			Apply(b.Label, { TextColor3 = on and T.Text or T.SubText }, animate, 0.12)
		end
		valueLabel.Text = displayText()
	end

	local function resize(animate)
		local h = obj.Open and (HEADER + 4 + listHeight() + 8) or HEADER
		Apply(row, { Size = UDim2.new(1, 0, 0, h) }, animate, 0.22)
		Apply(listFrame, { Size = UDim2.new(1, -16, 0, listHeight()) }, animate, 0.22)
		Apply(arrow, { Rotation = obj.Open and 180 or 0 }, animate, 0.2)
	end

	local function build()
		for _, b in pairs(buttons) do
			b:Destroy()
		end
		table.clear(buttons)
		for i, opt in ipairs(options) do
			local b = New("TextButton", {
				Size = UDim2.new(1, -4, 0, ITEM),
				BackgroundColor3 = T.Row,
				BackgroundTransparency = 0,
				LayoutOrder = i,
				Parent = listFrame,
			})
			Corner(b, 7)
			Label(b, tostring(opt), 14, T.SubText, T.FontSemi, {
				Name = "Label",
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -20, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			buttons[opt] = b
			Connect(b.MouseEnter, function()
				Library:PlaySound("Hover")
			end)
			Connect(b.Activated, function()
				Library:PlaySound("Select")
				if multi then
					selected[opt] = not selected[opt] or nil
					obj:_changed()
				else
					obj:Set(opt)
					obj:Toggle(false)
				end
			end)
		end
		restyle(false)
		resize(false)
	end

	function obj:_changed()
		self.Value = currentValue()
		restyle(true)
		Commit(self)
	end

	Register(obj, cfg)
	CommonMethods(obj, row)
	function obj:Toggle(state)
		if state == nil then
			state = not self.Open
		end
		self.Open = state
		Library:PlaySound(state and "DropdownOpen" or "DropdownClose")
		resize(true)
	end
	function obj:Set(v, silent)
		table.clear(selected)
		if multi then
			for _, o in ipairs(type(v) == "table" and v or {}) do
				selected[o] = true
			end
		elseif v ~= nil then
			selected[v] = true
		end
		self.Value = currentValue()
		restyle(true)
		Commit(self, silent)
	end
	function obj:Refresh(newOptions, keep)
		options = table.clone(newOptions or {})
		if keep then
			for o in pairs(table.clone(selected)) do
				if not table.find(options, o) then
					selected[o] = nil
				end
			end
		else
			table.clear(selected)
		end
		build()
		self.Value = currentValue()
		Commit(self, true)
	end

	if multi then
		for _, o in ipairs(type(cfg.Default) == "table" and cfg.Default or {}) do
			selected[o] = true
		end
	elseif cfg.Default ~= nil then
		selected[cfg.Default] = true
	end
	obj.Value = currentValue()
	build()
	Commit(obj, true)
	HoverRow(hit, row, rowStroke)
	Connect(hit.Activated, function()
		obj:Toggle()
	end)
	if cfg.Default ~= nil then
		task.defer(function()
			task.spawn(obj.Callback, obj.Value)
		end)
	end
	return obj
end

---------------------------------------------------------------- TextBox
function Elements:AddTextBox(cfg)
	cfg = cfg or {}
	local T = Library.Theme
	local obj = { Type = "TextBox", Value = cfg.Default or "" }
	local row, rowStroke = MakeRow(self, cfg.Description and 54 or 42)
	AddTitle(row, cfg.Name or "TextBox", cfg.Description, 170)
	local holder = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(150, 28),
		BackgroundColor3 = T.InputBG,
		Parent = row,
	})
	Corner(holder, 8)
	local hStroke = Stroke(holder, T.OutlineLight, 1.5)
	local box = New("TextBox", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		Text = obj.Value,
		PlaceholderText = cfg.Placeholder or "INPUT HERE",
		PlaceholderColor3 = T.Muted,
		TextColor3 = T.InputText,
		TextSize = 13,
		FontFace = T.FontSemi,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = holder,
	})
	Register(obj, cfg)
	CommonMethods(obj, row)
	function obj:Set(v, silent)
		self.Value = tostring(v or "")
		box.Text = self.Value
		Commit(self, silent)
	end
	Commit(obj, true)
	Connect(box.Focused, function()
		Tween(hStroke, 0.12, { Color = T.Accent })
		Tween(rowStroke, 0.12, { Color = T.Outline })
	end)
	Connect(box.FocusLost, function()
		Tween(hStroke, 0.12, { Color = T.OutlineLight })
		Tween(rowStroke, 0.12, { Color = T.RowStroke })
		local text = box.Text
		if cfg.Numeric then
			local n = tonumber(text)
			if not n then
				box.Text = obj.Value
				return
			end
			text = tostring(n)
		end
		obj:Set(text)
	end)
	if cfg.Default then
		task.defer(function()
			task.spawn(obj.Callback, obj.Value)
		end)
	end
	return obj
end

---------------------------------------------------------------- Keybind
function Elements:AddKeybind(cfg)
	cfg = cfg or {}
	local T = Library.Theme
	local obj = { Type = "Keybind", Value = cfg.Default }
	local row, rowStroke = MakeRow(self, 42)
	AddTitle(row, cfg.Name or "Keybind", nil, 110)
	local hit = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = row })
	local holder = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(90, 28),
		BackgroundColor3 = T.OutlineDark,
		Parent = row,
	})
	Corner(holder, 8)
	local hStroke = Stroke(holder, T.OutlineLight, 1.5)
	local text = Label(holder, "", 13, T.Text, T.Font, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local listening = false
	local function show()
		text.Text = listening and "..." or (obj.Value and obj.Value.Name or "None")
	end
	Register(obj, cfg)
	CommonMethods(obj, row)
	function obj:Set(key, silent)
		if type(key) == "string" then
			key = Enum.KeyCode[key]
		end
		self.Value = key
		show()
		Commit(self, true)
		if not silent and cfg.ChangedCallback then
			task.spawn(cfg.ChangedCallback, key)
		end
	end
	show()
	Commit(obj, true)
	HoverRow(hit, row, rowStroke)
	Connect(hit.Activated, function()
		listening = true
		Library:PlaySound("Click")
		Tween(hStroke, 0.12, { Color = T.Warning })
		show()
	end)
	Connect(UserInputService.InputBegan, function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				Tween(hStroke, 0.12, { Color = T.OutlineLight })
				if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
					obj:Set(nil)
				else
					obj:Set(input.KeyCode)
				end
				Library:PlaySound("Select")
			end
			return
		end
		if not processed and obj.Value and input.KeyCode == obj.Value then
			task.spawn(obj.Callback, obj.Value)
		end
	end)
	return obj
end

---------------------------------------------------------------- ColorPicker
function Elements:AddColorPicker(cfg)
	cfg = cfg or {}
	local T = Library.Theme
	local HEADER, PANEL = 42, 136
	local obj = { Type = "ColorPicker", Value = cfg.Default or Color3.fromRGB(255, 255, 255), Open = false }
	local h, s, v = obj.Value:ToHSV()

	local row, rowStroke = MakeRow(self, HEADER)
	row.ClipsDescendants = true
	local hit = New("TextButton", { Size = UDim2.new(1, 0, 0, HEADER), Parent = row })
	AddTitle(row, cfg.Name or "Color", nil, 70)
	local swatch = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, HEADER / 2),
		Size = UDim2.fromOffset(48, 24),
		BackgroundColor3 = obj.Value,
		Parent = row,
	})
	Corner(swatch, 8)
	Stroke(swatch, Color3.new(1, 1, 1), 2)

	local panel = New("Frame", {
		Position = UDim2.new(0, 10, 0, HEADER + 4),
		Size = UDim2.new(1, -20, 0, PANEL - 10),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local sv = New("TextButton", {
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BackgroundTransparency = 0,
		Parent = panel,
	})
	Corner(sv, 8)
	Stroke(sv, T.OutlineLight, 1.5)
	local white = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv })
	Corner(white, 8)
	New("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Parent = white,
	})
	local black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv })
	Corner(black, 8)
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
		Parent = black,
	})
	local svKnob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = sv,
	})
	Corner(svKnob, UDim.new(1, 0))
	Stroke(svKnob, Color3.new(1, 1, 1), 2)

	local hue = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 26, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		Parent = panel,
	})
	Corner(hue, 8)
	Stroke(hue, T.OutlineLight, 1.5)
	local seq = {}
	for i = 0, 6 do
		table.insert(seq, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.9999), 1, 1)))
	end
	seq[#seq] = ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1))
	New("UIGradient", { Rotation = 90, Color = ColorSequence.new(seq), Parent = hue })
	local hueKnob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 6, 0, 6),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = hue,
	})
	Corner(hueKnob, 3)
	Stroke(hueKnob, T.OutlineDark, 1.5)

	local function render()
		obj.Value = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = obj.Value
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svKnob.Position = UDim2.fromScale(s, 1 - v)
		hueKnob.Position = UDim2.fromScale(0.5, h)
	end

	Register(obj, cfg)
	CommonMethods(obj, row)
	function obj:Set(c, silent)
		if typeof(c) == "table" then
			c = Color3.new(c[1] or c.r or 1, c[2] or c.g or 1, c[3] or c.b or 1)
		end
		h, s, v = c:ToHSV()
		render()
		Commit(self, silent)
	end
	function obj:Toggle(state)
		if state == nil then
			state = not self.Open
		end
		self.Open = state
		Library:PlaySound(state and "DropdownOpen" or "DropdownClose")
		Tween(row, 0.22, { Size = UDim2.new(1, 0, 0, state and (HEADER + PANEL) or HEADER) })
	end
	render()
	Commit(obj, true)
	HoverRow(hit, row, rowStroke)
	Connect(hit.Activated, function()
		obj:Toggle()
	end)

	local mode
	local function lockScroll(b)
		if self.Scroller then
			self.Scroller.ScrollingEnabled = not b
		end
	end
	local function update(input)
		local p = ScreenPos(input)
		if mode == "sv" then
			s = math.clamp((p.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			v = 1 - math.clamp((p.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
		elseif mode == "hue" then
			h = math.clamp((p.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 0.9999)
		end
		render()
		Commit(obj)
	end
	Connect(sv.InputBegan, function(input)
		if IsPress(input) then
			mode = "sv"
			lockScroll(true)
			update(input)
		end
	end)
	Connect(hue.InputBegan, function(input)
		if IsPress(input) then
			mode = "hue"
			lockScroll(true)
			update(input)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if mode and IsMove(input) then
			update(input)
		end
	end)
	Connect(UserInputService.InputEnded, function(input)
		if mode and IsPress(input) then
			mode = nil
			lockScroll(false)
		end
	end)
	return obj
end

--------------------------------------------------------------------------------
-- Sections
--------------------------------------------------------------------------------
local function NewContainerObject(window, container, scroller)
	local o = { Window = window, Container = container, Scroller = scroller }
	for k, f in pairs(Elements) do
		o[k] = f
	end
	return o
end

local function BuildSection(parent, window, scroller, name)
	local T = Library.Theme
	local frame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	})
	List(frame, 8)
	local header = Label(frame, string.upper(name or "SECTION"), 17, T.Text, T.Font, {
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 0,
	})
	TextStroke(header, T.OutlineLight, 1.2)
	return NewContainerObject(window, frame, scroller), frame
end

--------------------------------------------------------------------------------
-- Window / Tabs
--------------------------------------------------------------------------------
function Library:CreateWindow(cfg)
	if type(cfg) == "string" then
		cfg = { Title = cfg }
	end
	cfg = cfg or {}
	local T = self.Theme
	local gui = GetGui()
	local Window = { Tabs = {}, Visible = true, Library = self }

	local width, height = cfg.Width or 600, cfg.Height or 400
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if touchOnly and not cfg.Width then
		width, height = 520, 330
	end
	local sidebarW = cfg.SidebarWidth or 132
	local fit = ViewportFit(width, height)

	local main = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local scaler = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = main,
	})
	local uiScale = New("UIScale", { Scale = 0, Parent = scaler })

	-- soft drop shadow
	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 46, 1, 46),
		Image = "rbxassetid://1316045217",
		ImageColor3 = T.OutlineDark,
		ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = 0,
		Parent = scaler,
	})

	local panel = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ClipsDescendants = true,
		Parent = scaler,
	})
	Corner(panel, 16)
	Stroke(panel, T.Outline, 3)
	Gradient(panel, T.Window, T.WindowBottom, 90)

	-- title bar
	local bar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	local hasIcon = cfg.Icon ~= nil
	if hasIcon then
		New("ImageLabel", {
			Position = UDim2.fromOffset(12, 9),
			Size = UDim2.fromOffset(30, 30),
			Image = type(cfg.Icon) == "number" and ("rbxassetid://" .. cfg.Icon) or cfg.Icon,
			Parent = bar,
		})
	end
	local textX = hasIcon and 50 or 16
	local title = Label(bar, cfg.Title or "ToonsUI", 21, T.Text, T.Font, {
		Position = UDim2.new(0, textX, 0, cfg.Subtitle and 5 or 0),
		Size = UDim2.new(1, -(textX + 56), 0, cfg.Subtitle and 26 or 48),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	TextStroke(title, T.OutlineLight, 1.4)
	local subtitle = Label(bar, cfg.Subtitle or "", 12, T.SubText, T.FontMed, {
		Position = UDim2.new(0, textX, 0, 28),
		Size = UDim2.new(1, -(textX + 56), 0, 16),
		Visible = cfg.Subtitle ~= nil,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	New("Frame", {
		Position = UDim2.new(0, 10, 1, -2),
		Size = UDim2.new(1, -20, 0, 2),
		BackgroundColor3 = T.OutlineDark,
		Parent = bar,
	})

	-- close button (red, like the game's X buttons)
	local close = New("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -28, 0, 24),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		Parent = bar,
	})
	Corner(close, 10)
	Stroke(close, T.OffStroke, 2)
	Gradient(close, Color3.fromRGB(230, 90, 90), T.Off, 90)
	local x = Label(close, "X", 17, T.Text, T.Font, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	TextStroke(x, T.OffStroke, 1.4)
	ButtonEffect(close, true)

	-- sidebar + content
	local sidebar = New("Frame", {
		Position = UDim2.fromOffset(10, 56),
		Size = UDim2.new(0, sidebarW, 1, -66),
		BackgroundColor3 = T.Sidebar,
		BackgroundTransparency = 0.1,
		Parent = panel,
	})
	Corner(sidebar, 12)
	Stroke(sidebar, T.OutlineDark, 2)
	local tabScroll = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	Padding(tabScroll, 8)
	List(tabScroll, 6)

	local content = New("Frame", {
		Position = UDim2.new(0, sidebarW + 20, 0, 56),
		Size = UDim2.new(1, -(sidebarW + 30), 1, -66),
		BackgroundColor3 = T.Content,
		BackgroundTransparency = 0.05,
		ClipsDescendants = true,
		Parent = panel,
	})
	Corner(content, 12)
	Stroke(content, T.OutlineDark, 2)

	Window.Main = main
	Window.Panel = panel

	function Window:Open()
		if self.Visible and main.Visible then
			return
		end
		self.Visible = true
		main.Visible = true
		Library:PlaySound("Open")
		Tween(uiScale, 0.3, { Scale = fit * (self.UserScale or Library.Scale) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	function Window:SetScale(v)
		self.UserScale = v
		if self.Visible then
			Tween(uiScale, 0.15, { Scale = fit * v })
		end
	end
	function Window:Close()
		if not self.Visible then
			return
		end
		self.Visible = false
		Library:PlaySound("Close")
		local t = Tween(uiScale, 0.22, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		t.Completed:Once(function()
			if not self.Visible then
				main.Visible = false
			end
		end)
	end
	function Window:Toggle()
		if self.Visible then
			self:Close()
		else
			self:Open()
		end
	end
	function Window:SetTitle(t, sub)
		title.Text = t or title.Text
		if sub then
			subtitle.Text = sub
			subtitle.Visible = true
		end
	end
	function Window:Destroy()
		main:Destroy()
		if self.FloatButton then
			self.FloatButton:Destroy()
		end
	end

	Connect(close.Activated, function()
		Window:Close()
	end)
	MakeDraggable(bar, main)

	-- toggle key
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	Connect(UserInputService.InputBegan, function(input, processed)
		if not processed and input.KeyCode == toggleKey then
			Window:Toggle()
		end
	end)

	-- floating open button (handy on mobile, draggable)
	if cfg.FloatButton ~= false then
		local fb = New("TextButton", {
			Name = "OpenButton",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 34, 0.5, 0),
			Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			Parent = gui,
		})
		Corner(fb, UDim.new(1, 0))
		Stroke(fb, T.OutlineLight, 3)
		Gradient(fb, T.Accent, T.AccentDeep, 90)
		local glyph = Label(fb, "☰", 22, T.Text, T.Font, {
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		TextStroke(glyph, T.OutlineDark, 1.4)
		ButtonEffect(fb, true)
		MakeDraggable(fb, fb, function(moved)
			if moved < 8 then
				Library:PlaySound("Click")
				Window:Toggle()
			end
		end)
		Window.FloatButton = fb
	end

	-- tabs ---------------------------------------------------------------
	function Window:SelectTab(tab)
		for _, t in ipairs(self.Tabs) do
			local on = t == tab
			t.Page.Visible = on
			Tween(t.Button, 0.15, { BackgroundColor3 = on and Color3.new(1, 1, 1) or T.Row })
			t.ButtonGradient.Enabled = on
			Tween(t.ButtonStroke, 0.15, { Color = on and T.OutlineLight or T.RowStroke })
			Tween(t.ButtonLabel, 0.15, { TextColor3 = on and T.Text or T.SubText })
		end
		self.ActiveTab = tab
	end

	function Window:AddTab(tcfg)
		if type(tcfg) == "string" then
			tcfg = { Name = tcfg }
		end
		tcfg = tcfg or {}
		local holder = New("Frame", {
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundTransparency = 1,
			LayoutOrder = #self.Tabs,
			Parent = tabScroll,
		})
		local btn = New("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = T.Row,
			BackgroundTransparency = 0,
			Parent = holder,
		})
		Corner(btn, 10)
		local bStroke = Stroke(btn, T.RowStroke, 2)
		local bGrad = Gradient(btn, T.Accent, T.AccentDark, 90)
		bGrad.Enabled = false
		local labelX = 10
		if tcfg.Icon then
			New("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
				Image = type(tcfg.Icon) == "number" and ("rbxassetid://" .. tcfg.Icon) or tcfg.Icon,
				Parent = btn,
			})
			labelX = 34
		end
		local lbl = Label(btn, tcfg.Name or "Tab", 14, T.SubText, T.Font, {
			Position = UDim2.fromOffset(labelX, 0),
			Size = UDim2.new(1, -(labelX + 6), 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		TextStroke(lbl, T.OutlineDark, 1)
		ButtonEffect(btn, true)

		local page = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = T.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			Visible = false,
			Parent = content,
		})
		Padding(page, 10, 10, 14, 10)
		List(page, 8)

		local tab = NewContainerObject(self, page, page)
		tab.Page = page
		tab.Button = btn
		tab.ButtonStroke = bStroke
		tab.ButtonGradient = bGrad
		tab.ButtonLabel = lbl
		table.insert(self.Tabs, tab)

		function tab:Select(silent)
			if not silent then
				Library:PlaySound("Tab")
			end
			Window:SelectTab(self)
		end
		function tab:AddSection(name)
			local section = BuildSection(page, Window, page, name)
			return section
		end
		Connect(btn.Activated, function()
			if Window.ActiveTab ~= tab then
				tab:Select()
			end
		end)
		if #self.Tabs == 1 then
			tab:Select(true)
		end
		return tab
	end

	table.insert(self.Windows, Window)
	task.defer(function()
		Tween(uiScale, 0.3, { Scale = fit * (Window.UserScale or Library.Scale) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		Library:PlaySound("Open")
	end)
	return Window
end

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------
local notifHolder
local notifCount = 0

local function GetNotifHolder()
	if notifHolder and notifHolder.Parent then
		return notifHolder
	end
	notifHolder = New("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 64),
		Size = UDim2.fromOffset(270, 600),
		BackgroundTransparency = 1,
		Parent = GetGui(),
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = notifHolder,
	})
	return notifHolder
end

function Library:Notify(cfg)
	if type(cfg) == "string" then
		cfg = { Content = cfg }
	end
	cfg = cfg or {}
	local T = self.Theme
	local kind = cfg.Type or "Info"
	local color = ({ Info = T.Accent, Success = T.On, Warning = T.Warning, Error = T.Off })[kind] or T.Accent
	notifCount += 1
	local holder = GetNotifHolder()
	local width = 270
	local content = cfg.Content or ""
	local textH = TextService:GetTextSize(content, 13, Enum.Font.GothamMedium, Vector2.new(width - 30, 1000)).Y
	local height = 22 + (cfg.Title and 22 or 0) + textH + 22

	local wrap = New("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = notifCount,
		Parent = holder,
	})
	local card = New("TextButton", {
		Position = UDim2.new(1, 320, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Content,
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Parent = wrap,
	})
	Corner(card, 12)
	Stroke(card, color, 2)
	Gradient(card, T.Row, T.Sidebar, 90)
	local y = 10
	if cfg.Title then
		local tl = Label(card, cfg.Title, 15, T.Text, T.Font, {
			Position = UDim2.fromOffset(14, y),
			Size = UDim2.new(1, -28, 0, 20),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		TextStroke(tl, color, 1)
		y += 22
	end
	Label(card, content, 13, T.SubText, T.FontMed, {
		Position = UDim2.fromOffset(14, y),
		Size = UDim2.new(1, -28, 0, textH),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	local bar = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = color,
		Parent = card,
	})

	local duration = cfg.Duration or 4
	self:PlaySound(kind == "Success" and "NotifySuccess"
		or kind == "Warning" and "NotifyWarning"
		or kind == "Error" and "NotifyError"
		or "Notify")
	Tween(card, 0.4, { Position = UDim2.new() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	Tween(bar, duration, { Size = UDim2.new(0, 0, 0, 4) }, Enum.EasingStyle.Linear)

	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		local t = Tween(card, 0.3, { Position = UDim2.new(1, 320, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		t.Completed:Once(function()
			wrap:Destroy()
		end)
	end
	card.Activated:Connect(dismiss)
	task.delay(duration, dismiss)
end

--------------------------------------------------------------------------------
-- Dialog (like the game's "Do you wish to purchase?" confirmation)
--------------------------------------------------------------------------------
function Library:Dialog(cfg)
	cfg = cfg or {}
	local T = self.Theme
	local gui = GetGui()
	local overlay = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	})
	Tween(overlay, 0.2, { BackgroundTransparency = 0.45 })
	local box = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(330, 190),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 51,
		Parent = overlay,
	})
	Corner(box, 16)
	Stroke(box, T.Outline, 3)
	Gradient(box, T.Window, T.WindowBottom, 90)
	local scale = New("UIScale", { Scale = 0, Parent = box })
	Tween(scale, 0.3, { Scale = math.min(1, ViewportFit(330, 190)) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local title = Label(box, cfg.Title or "Confirm", 20, T.Text, T.Font, {
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -32, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 52,
	})
	TextStroke(title, T.OutlineLight, 1.4)
	Label(box, cfg.Content or "Do you wish to continue?", 14, T.SubText, T.FontSemi, {
		Position = UDim2.fromOffset(18, 46),
		Size = UDim2.new(1, -36, 0, 62),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 52,
	})
	local btnRow = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -28, 0, 42),
		BackgroundTransparency = 1,
		ZIndex = 52,
		Parent = box,
	})
	local function close(result)
		Tween(overlay, 0.2, { BackgroundTransparency = 1 })
		local t = Tween(scale, 0.22, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		t.Completed:Once(function()
			overlay:Destroy()
		end)
		if cfg.Callback then
			task.spawn(cfg.Callback, result)
		end
	end
	local confirmHolder, confirmBtn = BuildButton(btnRow, cfg.ConfirmText or "Confirm", "Success", 42)
	confirmHolder.Size = UDim2.new(0.5, -6, 1, 0)
	local cancelHolder, cancelBtn = BuildButton(btnRow, cfg.CancelText or "Cancel", "Danger", 42)
	cancelHolder.Size = UDim2.new(0.5, -6, 1, 0)
	cancelHolder.Position = UDim2.new(0.5, 6, 0, 0)
	for _, d in ipairs(btnRow:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = 53
		end
	end
	self:PlaySound("Dialog")
	confirmBtn.Activated:Connect(function()
		close(true)
	end)
	cancelBtn.Activated:Connect(function()
		close(false)
	end)
end

--------------------------------------------------------------------------------
-- Config save / load
--------------------------------------------------------------------------------
local function Serialize(opt)
	local v = opt.Value
	if opt.Type == "ColorPicker" then
		return { v.R, v.G, v.B }
	elseif opt.Type == "Keybind" then
		return v and v.Name or "None"
	end
	return v
end

local function Deserialize(opt, v)
	if opt.Type == "ColorPicker" then
		return Color3.new(v[1], v[2], v[3])
	elseif opt.Type == "Keybind" then
		return v ~= "None" and Enum.KeyCode[v] or nil
	end
	return v
end

function Library:SaveConfig(name)
	if not (writefile and makefolder and isfolder) then
		return false, "executor has no file functions"
	end
	local data = {}
	for flag, opt in pairs(self.Options) do
		if opt.Type ~= "Button" then
			data[flag] = Serialize(opt)
		end
	end
	if not isfolder(self.ConfigFolder) then
		makefolder(self.ConfigFolder)
	end
	local ok, err = pcall(function()
		writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
	end)
	return ok, err
end

function Library:LoadConfig(name)
	if not (readfile and isfile) then
		return false, "executor has no file functions"
	end
	local path = self.ConfigFolder .. "/" .. name .. ".json"
	if not isfile(path) then
		return false, "config not found"
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok then
		return false, "config is corrupted"
	end
	for flag, value in pairs(data) do
		local opt = self.Options[flag]
		if opt and opt.Set then
			pcall(opt.Set, opt, Deserialize(opt, value))
		end
	end
	return true
end

function Library:ListConfigs()
	local out = {}
	if listfiles and isfolder and isfolder(self.ConfigFolder) then
		for _, f in ipairs(listfiles(self.ConfigFolder)) do
			local n = f:match("([^/\\]+)%.json$")
			if n then
				table.insert(out, n)
			end
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- Unload
--------------------------------------------------------------------------------
function Library:Unload()
	for _, c in ipairs(self.Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(self.Connections)
	if Gui then
		Gui:Destroy()
		Gui = nil
	end
	table.clear(self.Flags)
	table.clear(self.Options)
	table.clear(self.Windows)
	if env.ToonsUI == self then
		env.ToonsUI = nil
	end
end

env.ToonsUI = Library
return Library
