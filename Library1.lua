--[[
=====================================================================
	NEBULA UI  •  v1.0.0
	A modern, lightweight, executor-friendly UI library for Roblox.

	Repo:  https://github.com/YOUR_NAME/NebulaUI
	Load:  local Nebula = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_NAME/NebulaUI/main/src/NebulaUI.lua"))()

	Features
	  - Draggable, resizable-free window with tab sidebar
	  - Button, Toggle, Slider, Dropdown (single/multi), Input,
	    Keybind, ColorPicker, Label, Paragraph, Section, Divider
	  - Notifications, 4 built-in themes, live theme switching
	  - Config saving/loading via flags (writefile/readfile)
	  - Mobile / touch support, UI toggle keybind
	  - Zero external assets (all visuals are code-drawn)
=====================================================================
]]

local Nebula = {
	Version = "1.0.0",
	Flags = {},
	Windows = {},
	ConfigFolder = "NebulaUI",
	_registry = {},
	_connections = {},
}

--=================================================================--
-- SERVICES / ENVIRONMENT
--=================================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local function randomName(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local out = {}
	for i = 1, (len or 12) do
		local n = math.random(1, #chars)
		out[#out + 1] = string.sub(chars, n, n)
	end
	return table.concat(out)
end

-- Safely read a global that only exists inside executors
local function env(name)
	local ok, value = pcall(function()
		return (getgenv and getgenv() or _G)[name]
	end)
	if ok and value ~= nil then return value end
	ok, value = pcall(function()
		return getfenv(0)[name]
	end)
	if ok then return value end
	return nil
end

-- Best-effort filesystem wrappers (executors expose these, Studio does not)
local fs = {
	write = env("writefile"),
	read = env("readfile"),
	isFile = env("isfile"),
	isFolder = env("isfolder"),
	makeFolder = env("makefolder"),
	delete = env("delfile"),
}
local hasFS = (fs.write and fs.read and fs.isFile) and true or false

local function getGuiParent()
	local hui = env("gethui")
	if hui then
		local ok, res = pcall(hui)
		if ok and res then return res end
	end
	local ok, cg = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and cg then return cg end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
	local syn = env("syn")
	if type(syn) == "table" and syn.protect_gui then pcall(syn.protect_gui, gui) end
	local pg = env("protectgui")
	if pg then pcall(pg, gui) end
end

--=================================================================--
-- THEMES
--=================================================================--

Nebula.Themes = {
	Dark = {
		Background = Color3.fromRGB(15, 15, 19),
		Secondary = Color3.fromRGB(21, 21, 27),
		Element = Color3.fromRGB(30, 30, 38),
		ElementHover = Color3.fromRGB(41, 41, 52),
		Stroke = Color3.fromRGB(46, 46, 58),
		Text = Color3.fromRGB(240, 240, 246),
		SubText = Color3.fromRGB(146, 146, 162),
		Accent = Color3.fromRGB(124, 112, 255),
		AccentText = Color3.fromRGB(255, 255, 255),
	},
	Midnight = {
		Background = Color3.fromRGB(12, 17, 28),
		Secondary = Color3.fromRGB(17, 24, 39),
		Element = Color3.fromRGB(24, 33, 52),
		ElementHover = Color3.fromRGB(33, 45, 70),
		Stroke = Color3.fromRGB(38, 52, 79),
		Text = Color3.fromRGB(233, 240, 250),
		SubText = Color3.fromRGB(133, 152, 178),
		Accent = Color3.fromRGB(56, 189, 248),
		AccentText = Color3.fromRGB(4, 18, 28),
	},
	Neon = {
		Background = Color3.fromRGB(10, 12, 10),
		Secondary = Color3.fromRGB(16, 20, 16),
		Element = Color3.fromRGB(24, 30, 24),
		ElementHover = Color3.fromRGB(34, 44, 34),
		Stroke = Color3.fromRGB(44, 58, 44),
		Text = Color3.fromRGB(235, 245, 235),
		SubText = Color3.fromRGB(140, 165, 140),
		Accent = Color3.fromRGB(57, 255, 136),
		AccentText = Color3.fromRGB(6, 24, 14),
	},
	Rose = {
		Background = Color3.fromRGB(22, 14, 18),
		Secondary = Color3.fromRGB(30, 19, 25),
		Element = Color3.fromRGB(41, 26, 34),
		ElementHover = Color3.fromRGB(55, 35, 45),
		Stroke = Color3.fromRGB(66, 42, 54),
		Text = Color3.fromRGB(250, 240, 244),
		SubText = Color3.fromRGB(180, 148, 162),
		Accent = Color3.fromRGB(244, 114, 182),
		AccentText = Color3.fromRGB(32, 10, 20),
	},
	Light = {
		Background = Color3.fromRGB(246, 247, 250),
		Secondary = Color3.fromRGB(255, 255, 255),
		Element = Color3.fromRGB(238, 240, 245),
		ElementHover = Color3.fromRGB(228, 231, 238),
		Stroke = Color3.fromRGB(214, 218, 226),
		Text = Color3.fromRGB(24, 26, 32),
		SubText = Color3.fromRGB(110, 116, 130),
		Accent = Color3.fromRGB(88, 80, 236),
		AccentText = Color3.fromRGB(255, 255, 255),
	},
}

Nebula.ThemeName = "Dark"
Nebula.Theme = Nebula.Themes.Dark

--=================================================================--
-- UTILITIES
--=================================================================--

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function new(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then inst.Parent = parent end
	return inst
end

-- Registers an instance property so live theme switching works
local function themed(inst, prop, key)
	table.insert(Nebula._registry, { inst = inst, prop = prop, key = key })
	inst[prop] = Nebula.Theme[key]
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function stroke(parent, thickness, key, transparency)
	local s = new("UIStroke", {
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = transparency or 0,
		Parent = parent,
	})
	themed(s, "Color", key or "Stroke")
	return s
end

local function padding(parent, all, l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or all or 0),
		PaddingRight = UDim.new(0, r or all or 0),
		PaddingTop = UDim.new(0, t or all or 0),
		PaddingBottom = UDim.new(0, b or all or 0),
		Parent = parent,
	})
end

local function list(parent, pad, dir)
	return new("UIListLayout", {
		Padding = UDim.new(0, pad or 8),
		FillDirection = dir or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local QUICK = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function tween(inst, props, info)
	local t = TweenService:Create(inst, info or QUICK, props)
	t:Play()
	return t
end

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Nebula._connections, c)
	return c
end

local function inputPos(input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		local inset = GuiService:GetGuiInset()
		return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
	end
	return UserInputService:GetMouseLocation()
end

local function clamp01(n)
	if n < 0 then return 0 end
	if n > 1 then return 1 end
	return n
end

local function round(n, step)
	step = step or 1
	return math.floor(n / step + 0.5) * step
end

local function decimals(n, places)
	local mult = 10 ^ (places or 2)
	return math.floor(n * mult + 0.5) / mult
end

-- Hover + click ripple feedback for any frame
local function interactive(frame, baseKey, hoverKey)
	baseKey = baseKey or "Element"
	hoverKey = hoverKey or "ElementHover"
	connect(frame.MouseEnter, function()
		tween(frame, { BackgroundColor3 = Nebula.Theme[hoverKey] })
	end)
	connect(frame.MouseLeave, function()
		tween(frame, { BackgroundColor3 = Nebula.Theme[baseKey] })
	end)
end

function Nebula:SetTheme(name)
	local theme = Nebula.Themes[name]
	if not theme then return false end
	Nebula.ThemeName = name
	Nebula.Theme = theme
	for _, entry in ipairs(Nebula._registry) do
		if entry.inst and entry.inst.Parent ~= nil then
			pcall(function()
				tween(entry.inst, { [entry.prop] = theme[entry.key] }, QUICK)
			end)
		end
	end
	return true
end

--=================================================================--
-- NOTIFICATIONS
--=================================================================--

local notifyGui, notifyHolder

local function ensureNotifyGui()
	if notifyGui and notifyGui.Parent then return end
	notifyGui = new("ScreenGui", {
		Name = randomName(10),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
	})
	protect(notifyGui)
	notifyGui.Parent = getGuiParent()

	notifyHolder = new("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.new(0, 300, 1, -36),
		BackgroundTransparency = 1,
		Parent = notifyGui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifyHolder,
	})
end

local NOTIFY_COLORS = {
	info = Color3.fromRGB(96, 165, 250),
	success = Color3.fromRGB(52, 211, 153),
	warning = Color3.fromRGB(251, 191, 36),
	error = Color3.fromRGB(248, 113, 113),
}

--[[ Nebula:Notify({ Title, Content, Duration, Type = "info"|"success"|"warning"|"error" }) ]]
function Nebula:Notify(opts)
	opts = opts or {}
	ensureNotifyGui()

	local accent = NOTIFY_COLORS[string.lower(opts.Type or "info")] or NOTIFY_COLORS.info
	local duration = opts.Duration or 4

	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Nebula.Theme.Secondary,
		BackgroundTransparency = 1,
		Parent = notifyHolder,
	})
	themed(card, "BackgroundColor3", "Secondary")
	corner(card, 10)
	local cardStroke = stroke(card, 1, "Stroke")
	padding(card, 12, 14, 14, 11, 12)

	new("Frame", {
		Name = "Bar",
		Size = UDim2.new(0, 3, 1, -4),
		Position = UDim2.new(0, -10, 0, 2),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = card,
	}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	list(card, 3)

	local title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = tostring(opts.Title or "Notification"),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		Parent = card,
	})
	themed(title, "TextColor3", "Text")

	local body = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = FONT,
		Text = tostring(opts.Content or ""),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		Parent = card,
	})
	themed(body, "TextColor3", "SubText")

	tween(card, { BackgroundTransparency = 0 }, SMOOTH)
	tween(title, { TextTransparency = 0 }, SMOOTH)
	tween(body, { TextTransparency = 0 }, SMOOTH)

	task.delay(duration, function()
		if not card or not card.Parent then return end
		tween(card, { BackgroundTransparency = 1 }, QUICK)
		tween(cardStroke, { Transparency = 1 }, QUICK)
		tween(title, { TextTransparency = 1 }, QUICK)
		tween(body, { TextTransparency = 1 }, QUICK)
		task.wait(0.2)
		if card then card:Destroy() end
	end)

	return card
end

--=================================================================--
-- CONFIG SAVING
--=================================================================--

local function encode(tbl)
	local parts = {}
	for k, v in pairs(tbl) do
		local t = type(v)
		local val
		if t == "boolean" then
			val = tostring(v)
		elseif t == "number" then
			val = tostring(v)
		elseif t == "string" then
			val = "s:" .. v
		elseif t == "table" then
			local sub = {}
			for _, item in ipairs(v) do sub[#sub + 1] = tostring(item) end
			val = "t:" .. table.concat(sub, "\30")
		else
			val = "s:"
		end
		parts[#parts + 1] = tostring(k) .. "\31" .. val
	end
	return table.concat(parts, "\n")
end

local function decode(str)
	local out = {}
	for line in string.gmatch(str, "[^\n]+") do
		local key, val = string.match(line, "^(.-)\31(.*)$")
		if key then
			if val == "true" then
				out[key] = true
			elseif val == "false" then
				out[key] = false
			elseif string.sub(val, 1, 2) == "s:" then
				out[key] = string.sub(val, 3)
			elseif string.sub(val, 1, 2) == "t:" then
				local items = {}
				for item in string.gmatch(string.sub(val, 3), "[^\30]+") do
					items[#items + 1] = item
				end
				out[key] = items
			else
				out[key] = tonumber(val) or val
			end
		end
	end
	return out
end

--=================================================================--
-- WINDOW
--=================================================================--

local Window = {}
Window.__index = Window

--[[
	Nebula:CreateWindow({
		Name = "My Hub",
		Subtitle = "v1.0",
		Theme = "Dark",
		Size = UDim2.fromOffset(620, 430),
		ToggleKey = Enum.KeyCode.RightShift,
		ConfigName = "myhub",     -- enables config saving
		AutoSave = true,
	})
]]
function Nebula:CreateWindow(opts)
	opts = opts or {}
	if opts.Theme then Nebula:SetTheme(opts.Theme) end

	local self = setmetatable({}, Window)
	self.Name = opts.Name or "Nebula UI"
	self.Subtitle = opts.Subtitle or ("v" .. Nebula.Version)
	self.Tabs = {}
	self.Elements = {}
	self.Open = true
	self.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	self.ConfigName = opts.ConfigName
	self.AutoSave = opts.AutoSave ~= false
	self.MinSize = opts.Size or UDim2.fromOffset(620, 430)

	local gui = new("ScreenGui", {
		Name = randomName(11),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9998,
	})
	protect(gui)
	gui.Parent = getGuiParent()
	self.Gui = gui

	-- Main window ------------------------------------------------------
	local main = new("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Nebula.Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = gui,
	})
	themed(main, "BackgroundColor3", "Background")
	corner(main, 12)
	stroke(main, 1, "Stroke")
	self.Main = main

	tween(main, { Size = self.MinSize }, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))

	-- Top bar ----------------------------------------------------------
	local top = new("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		Parent = main,
	})
	self.TopBar = top

	local titleLabel = new("TextLabel", {
		Position = UDim2.new(0, 18, 0, 9),
		Size = UDim2.new(0.6, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = self.Name,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})
	themed(titleLabel, "TextColor3", "Text")

	local subLabel = new("TextLabel", {
		Position = UDim2.new(0, 18, 0, 26),
		Size = UDim2.new(0.6, 0, 0, 13),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = self.Subtitle,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})
	themed(subLabel, "TextColor3", "SubText")

	self.TitleLabel = titleLabel
	self.SubLabel = subLabel

	local function topButton(order, symbol, callback)
		local btn = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14 - (order * 30), 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = Nebula.Theme.Element,
			AutoButtonColor = false,
			Font = FONT_BOLD,
			Text = symbol,
			TextSize = 13,
			Parent = top,
		})
		themed(btn, "BackgroundColor3", "Element")
		themed(btn, "TextColor3", "SubText")
		corner(btn, 6)
		interactive(btn)
		connect(btn.MouseButton1Click, callback)
		return btn
	end

	topButton(0, "✕", function()
		self:Destroy()
	end)
	topButton(1, "—", function()
		self:Toggle(false)
	end)

	-- Sidebar ----------------------------------------------------------
	local sidebar = new("Frame", {
		Name = "Sidebar",
		Position = UDim2.new(0, 12, 0, 46),
		Size = UDim2.new(0, 152, 1, -58),
		BackgroundColor3 = Nebula.Theme.Secondary,
		BorderSizePixel = 0,
		Parent = main,
	})
	themed(sidebar, "BackgroundColor3", "Secondary")
	corner(sidebar, 10)

	local tabHolder = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	list(tabHolder, 6)
	padding(tabHolder, 8)
	self.TabHolder = tabHolder

	-- Pages ------------------------------------------------------------
	local pages = new("Frame", {
		Name = "Pages",
		Position = UDim2.new(0, 172, 0, 46),
		Size = UDim2.new(1, -184, 1, -58),
		BackgroundTransparency = 1,
		Parent = main,
	})
	self.Pages = pages

	-- Dragging ---------------------------------------------------------
	do
		local dragging, dragStart, startPos = false, nil, nil
		connect(top.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	-- Toggle key + mobile reopen button --------------------------------
	local reopen = new("TextButton", {
		Name = "Reopen",
		Position = UDim2.new(0, 16, 0, 16),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Nebula.Theme.Accent,
		AutoButtonColor = false,
		Font = FONT_BOLD,
		Text = string.upper(string.sub(self.Name, 1, 1)),
		TextSize = 18,
		Visible = false,
		Parent = gui,
	})
	themed(reopen, "BackgroundColor3", "Accent")
	themed(reopen, "TextColor3", "AccentText")
	corner(reopen, 12)
	connect(reopen.MouseButton1Click, function()
		self:Toggle(true)
	end)
	self.Reopen = reopen

	connect(UserInputService.InputBegan, function(input, gpe)
		if gpe then return end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end)

	Nebula.Windows[#Nebula.Windows + 1] = self
	return self
end

function Window:Toggle(state)
	if state == nil then state = not self.Open end
	self.Open = state
	if state then
		self.Main.Visible = true
		self.Reopen.Visible = false
		self.Main.Size = UDim2.fromOffset(self.MinSize.X.Offset * 0.9, self.MinSize.Y.Offset * 0.9)
		tween(self.Main, { Size = self.MinSize }, SMOOTH)
	else
		tween(self.Main, {
			Size = UDim2.fromOffset(self.MinSize.X.Offset * 0.92, self.MinSize.Y.Offset * 0.92),
		}, QUICK)
		task.delay(0.15, function()
			if not self.Open then
				self.Main.Visible = false
				self.Reopen.Visible = true
			end
		end)
	end
end

function Window:SetTitle(title, subtitle)
	if title then
		self.Name = title
		self.TitleLabel.Text = title
	end
	if subtitle then
		self.Subtitle = subtitle
		self.SubLabel.Text = subtitle
	end
end

function Window:Destroy()
	for _, c in ipairs(Nebula._connections) do
		pcall(function() c:Disconnect() end)
	end
	Nebula._connections = {}
	if self.Gui then self.Gui:Destroy() end
	if notifyGui then notifyGui:Destroy() end
	notifyGui = nil
end

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------

function Window:_configPath()
	if not self.ConfigName then return nil end
	return Nebula.ConfigFolder .. "/" .. self.ConfigName .. ".nebula"
end

function Window:SaveConfig()
	if not hasFS then return false, "no filesystem" end
	local path = self:_configPath()
	if not path then return false, "no ConfigName" end
	if fs.isFolder and fs.makeFolder and not fs.isFolder(Nebula.ConfigFolder) then
		fs.makeFolder(Nebula.ConfigFolder)
	end
	local data = {}
	for flag, element in pairs(self.Elements) do
		if element.Get then
			local ok, value = pcall(element.Get)
			if ok then
				if typeof(value) == "Color3" then
					data[flag] = "s:#" .. string.format("%02X%02X%02X",
						math.floor(value.R * 255), math.floor(value.G * 255), math.floor(value.B * 255))
				elseif typeof(value) == "EnumItem" then
					data[flag] = "s:@" .. tostring(value.Name)
				else
					data[flag] = value
				end
			end
		end
	end
	local ok = pcall(fs.write, path, encode(data))
	return ok
end

function Window:LoadConfig()
	if not hasFS then return false, "no filesystem" end
	local path = self:_configPath()
	if not path or not fs.isFile(path) then return false, "no config file" end
	local ok, raw = pcall(fs.read, path)
	if not ok or not raw then return false, "read failed" end
	local data = decode(raw)
	for flag, value in pairs(data) do
		local element = self.Elements[flag]
		if element and element.Set then
			if type(value) == "string" and string.sub(value, 1, 1) == "#" then
				local hex = string.sub(value, 2)
				value = Color3.fromRGB(
					tonumber(string.sub(hex, 1, 2), 16) or 255,
					tonumber(string.sub(hex, 3, 4), 16) or 255,
					tonumber(string.sub(hex, 5, 6), 16) or 255
				)
			elseif type(value) == "string" and string.sub(value, 1, 1) == "@" then
				value = Enum.KeyCode[string.sub(value, 2)] or value
			end
			pcall(element.Set, value)
		end
	end
	return true
end

function Window:_autosave()
	if self.AutoSave and self.ConfigName and hasFS then
		task.spawn(function() self:SaveConfig() end)
	end
end

function Window:_register(flag, getter, setter)
	if not flag then return end
	self.Elements[flag] = { Get = getter, Set = setter }
end

--=================================================================--
-- TABS
--=================================================================--

local Tab = {}
Tab.__index = Tab

function Window:CreateTab(name, icon)
	local self_ = self
	local tab = setmetatable({ Window = self, Name = name or "Tab" }, Tab)

	local button = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Nebula.Theme.Element,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = self.TabHolder,
	})
	corner(button, 7)

	local label = new("TextLabel", {
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -14, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = (icon and (tostring(icon) .. "  ") or "") .. tab.Name,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})
	themed(label, "TextColor3", "SubText")

	local page = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.Pages,
	})
	themed(page, "ScrollBarImageColor3", "Stroke")
	list(page, 8)
	padding(page, 0, 2, 10, 2, 12)

	tab.Button = button
	tab.Label = label
	tab.Page = page

	connect(button.MouseEnter, function()
		if self_.ActiveTab ~= tab then
			tween(button, { BackgroundTransparency = 0.55, BackgroundColor3 = Nebula.Theme.ElementHover })
		end
	end)
	connect(button.MouseLeave, function()
		if self_.ActiveTab ~= tab then
			tween(button, { BackgroundTransparency = 1 })
		end
	end)
	connect(button.MouseButton1Click, function()
		tab:Select()
	end)

	self.Tabs[#self.Tabs + 1] = tab
	if not self.ActiveTab then tab:Select() end
	return tab
end

function Tab:Select()
	local win = self.Window
	for _, other in ipairs(win.Tabs) do
		if other ~= self then
			other.Page.Visible = false
			tween(other.Button, { BackgroundTransparency = 1 })
			tween(other.Label, { TextColor3 = Nebula.Theme.SubText })
		end
	end
	win.ActiveTab = self
	self.Page.Visible = true
	self.Page.CanvasPosition = Vector2.new()
	tween(self.Button, { BackgroundTransparency = 0, BackgroundColor3 = Nebula.Theme.Accent })
	tween(self.Label, { TextColor3 = Nebula.Theme.AccentText })
end

--=================================================================--
-- ELEMENT BASE
--=================================================================--

local function baseElement(tab, height, noBg)
	local frame = new("Frame", {
		Size = UDim2.new(1, 0, 0, height or 38),
		BackgroundColor3 = Nebula.Theme.Element,
		BackgroundTransparency = noBg and 1 or 0,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = tab.Page,
	})
	if not noBg then
		themed(frame, "BackgroundColor3", "Element")
		corner(frame, 8)
		stroke(frame, 1, "Stroke", 0.4)
	end
	return frame
end

local function elementTitle(parent, text, xOffset)
	local label = new("TextLabel", {
		Position = UDim2.new(0, xOffset or 12, 0, 0),
		Size = UDim2.new(1, -(xOffset or 12) - 60, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = text,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
	themed(label, "TextColor3", "Text")
	return label
end

--=================================================================--
-- SECTION / LABEL / PARAGRAPH / DIVIDER
--=================================================================--

function Tab:CreateSection(name)
	local frame = baseElement(self, 24, true)
	local label = new("TextLabel", {
		Position = UDim2.new(0, 4, 0, 6),
		Size = UDim2.new(1, -8, 0, 16),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = string.upper(tostring(name or "Section")),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	themed(label, "TextColor3", "SubText")
	return {
		Instance = frame,
		Set = function(text) label.Text = string.upper(tostring(text)) end,
	}
end

function Tab:CreateDivider()
	local frame = baseElement(self, 9, true)
	local line = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -8, 0, 1),
		BorderSizePixel = 0,
		Parent = frame,
	})
	themed(line, "BackgroundColor3", "Stroke")
	return { Instance = frame }
end

function Tab:CreateLabel(text)
	local frame = baseElement(self, 32)
	local label = elementTitle(frame, tostring(text or ""))
	label.Size = UDim2.new(1, -24, 1, 0)
	return {
		Instance = frame,
		Set = function(newText) label.Text = tostring(newText) end,
	}
end

function Tab:CreateParagraph(opts)
	opts = opts or {}
	local frame = baseElement(self, 0)
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	padding(frame, 12, 14, 14, 11, 12)
	list(frame, 4)

	local title = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = tostring(opts.Title or "Paragraph"),
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	themed(title, "TextColor3", "Text")

	local body = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = FONT,
		Text = tostring(opts.Content or ""),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	themed(body, "TextColor3", "SubText")

	return {
		Instance = frame,
		Set = function(newTitle, newBody)
			if newTitle then title.Text = tostring(newTitle) end
			if newBody then body.Text = tostring(newBody) end
		end,
	}
end

--=================================================================--
-- BUTTON
--=================================================================--

function Tab:CreateButton(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local frame = baseElement(self, 38)
	interactive(frame)

	elementTitle(frame, tostring(opts.Name or "Button"))

	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = "›",
		TextSize = 16,
		Parent = frame,
	})
	themed(arrow, "TextColor3", "SubText")

	local hit = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = frame,
	})

	connect(hit.MouseButton1Click, function()
		tween(frame, { BackgroundColor3 = Nebula.Theme.Accent }, TweenInfo.new(0.08))
		task.delay(0.12, function()
			tween(frame, { BackgroundColor3 = Nebula.Theme.Element })
		end)
		task.spawn(function()
			local ok, err = pcall(callback)
			if not ok then
				Nebula:Notify({ Title = "Script Error", Content = tostring(err), Type = "error", Duration = 6 })
			end
		end)
	end)

	return { Instance = frame, Fire = function() task.spawn(callback) end }
end

--=================================================================--
-- TOGGLE
--=================================================================--

function Tab:CreateToggle(opts)
	opts = opts or {}
	local win = self.Window
	local callback = opts.Callback or function() end
	local value = opts.Default and true or false

	local frame = baseElement(self, 38)
	interactive(frame)
	elementTitle(frame, tostring(opts.Name or "Toggle"))

	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = Nebula.Theme.Stroke,
		BorderSizePixel = 0,
		Parent = frame,
	})
	corner(track, 10)

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.fromRGB(230, 230, 235),
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(knob, 7)

	local element
	local function apply(state, fire)
		value = state and true or false
		Nebula.Flags[opts.Flag or ""] = value
		tween(track, { BackgroundColor3 = value and Nebula.Theme.Accent or Nebula.Theme.Stroke })
		tween(knob, { Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, SMOOTH)
		if fire ~= false then
			task.spawn(function()
				local ok, err = pcall(callback, value)
				if not ok then
					Nebula:Notify({ Title = "Script Error", Content = tostring(err), Type = "error", Duration = 6 })
				end
			end)
		end
	end

	local hit = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = frame,
	})
	connect(hit.MouseButton1Click, function()
		apply(not value, true)
		win:_autosave()
	end)

	apply(value, false)

	element = {
		Instance = frame,
		Set = function(state) apply(state, true) end,
		Get = function() return value end,
	}
	win:_register(opts.Flag, element.Get, function(v) apply(v, true) end)
	return element
end

--=================================================================--
-- SLIDER
--=================================================================--

function Tab:CreateSlider(opts)
	opts = opts or {}
	local win = self.Window
	local callback = opts.Callback or function() end
	local min = opts.Min or 0
	local max = opts.Max or 100
	local step = opts.Increment or 1
	local suffix = opts.Suffix or ""
	local value = opts.Default or min

	local frame = baseElement(self, 52)
	interactive(frame)

	local label = elementTitle(frame, tostring(opts.Name or "Slider"))
	label.Position = UDim2.new(0, 12, 0, 7)
	label.Size = UDim2.new(1, -90, 0, 16)

	local valueBox = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 7),
		Size = UDim2.fromOffset(70, 16),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = "0",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})
	themed(valueBox, "TextColor3", "Accent")

	local bar = new("Frame", {
		Position = UDim2.new(0, 12, 0, 34),
		Size = UDim2.new(1, -24, 0, 6),
		BackgroundColor3 = Nebula.Theme.Stroke,
		BorderSizePixel = 0,
		Parent = frame,
	})
	themed(bar, "BackgroundColor3", "Stroke")
	corner(bar, 3)

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BorderSizePixel = 0,
		Parent = bar,
	})
	themed(fill, "BackgroundColor3", "Accent")
	corner(fill, 3)

	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = bar,
	})
	corner(knob, 6)

	local function apply(n, fire, animate)
		n = math.clamp(round(tonumber(n) or min, step), min, max)
		value = decimals(n, 3)
		Nebula.Flags[opts.Flag or ""] = value
		local alpha = (max - min) == 0 and 0 or (value - min) / (max - min)
		local info = animate == false and TweenInfo.new(0.05) or QUICK
		tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, info)
		tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, info)
		valueBox.Text = tostring(value) .. suffix
		if fire ~= false then
			task.spawn(function()
				local ok, err = pcall(callback, value)
				if not ok then
					Nebula:Notify({ Title = "Script Error", Content = tostring(err), Type = "error", Duration = 6 })
				end
			end)
		end
	end

	local dragging = false
	local function updateFromInput(input)
		local pos = inputPos(input)
		local alpha = clamp01((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1))
		apply(min + (max - min) * alpha, true, false)
	end

	local barHit = new("TextButton", {
		Size = UDim2.new(1, 0, 3, 0),
		Position = UDim2.new(0, 0, -1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = bar,
	})

	connect(barHit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			tween(knob, { Size = UDim2.fromOffset(16, 16) })
			updateFromInput(input)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			tween(knob, { Size = UDim2.fromOffset(12, 12) })
			win:_autosave()
		end
	end)

	apply(value, false)

	local element = {
		Instance = frame,
		Set = function(n) apply(n, true) end,
		Get = function() return value end,
	}
	win:_register(opts.Flag, element.Get, function(v) apply(v, true) end)
	return element
end

--=================================================================--
-- DROPDOWN
--=================================================================--

function Tab:CreateDropdown(opts)
	opts = opts or {}
	local win = self.Window
	local callback = opts.Callback or function() end
	local options = opts.Options or {}
	local multi = opts.Multi and true or false
	local open = false

	local selected = {}
	if multi then
		for _, v in ipairs(opts.Default or {}) do selected[tostring(v)] = true end
	elseif opts.Default ~= nil then
		selected[tostring(opts.Default)] = true
	end

	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Nebula.Theme.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Page,
	})
	themed(holder, "BackgroundColor3", "Element")
	corner(holder, 8)
	stroke(holder, 1, "Stroke", 0.4)
	list(holder, 0)

	local header = new("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	elementTitle(header, tostring(opts.Name or "Dropdown"))

	local valueLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -30, 0.5, 0),
		Size = UDim2.new(0.45, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = "None",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	themed(valueLabel, "TextColor3", "SubText")

	local chevron = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = "⌄",
		TextSize = 15,
		Parent = header,
	})
	themed(chevron, "TextColor3", "SubText")

	local listFrame = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = holder,
	})
	padding(listFrame, 0, 8, 8, 0, 8)
	list(listFrame, 4)

	local rows = {}

	local function selectedList()
		local out = {}
		for _, opt in ipairs(options) do
			if selected[tostring(opt)] then out[#out + 1] = opt end
		end
		return out
	end

	local function refreshVisual()
		local chosen = selectedList()
		if #chosen == 0 then
			valueLabel.Text = "None"
		elseif multi then
			valueLabel.Text = table.concat(chosen, ", ")
		else
			valueLabel.Text = tostring(chosen[1])
		end
		for name, row in pairs(rows) do
			local active = selected[name] and true or false
			tween(row.frame, { BackgroundColor3 = active and Nebula.Theme.Accent or Nebula.Theme.Secondary })
			tween(row.label, { TextColor3 = active and Nebula.Theme.AccentText or Nebula.Theme.SubText })
		end
	end

	local function fire()
		local chosen = selectedList()
		task.spawn(function()
			local ok, err = pcall(callback, multi and chosen or chosen[1])
			if not ok then
				Nebula:Notify({ Title = "Script Error", Content = tostring(err), Type = "error", Duration = 6 })
			end
		end)
		Nebula.Flags[opts.Flag or ""] = multi and chosen or chosen[1]
	end

	local function buildRows()
		for _, row in pairs(rows) do row.frame:Destroy() end
		rows = {}
		for _, opt in ipairs(options) do
			local name = tostring(opt)
			local row = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = Nebula.Theme.Secondary,
				AutoButtonColor = false,
				Text = "",
				Parent = listFrame,
			})
			corner(row, 6)
			local rowLabel = new("TextLabel", {
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = name,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
			rows[name] = { frame = row, label = rowLabel }

			connect(row.MouseButton1Click, function()
				if multi then
					selected[name] = not selected[name] or nil
				else
					selected = { [name] = true }
				end
				refreshVisual()
				fire()
				win:_autosave()
				if not multi then
					open = false
					listFrame.Visible = false
					tween(chevron, { Rotation = 0 })
				end
			end)
		end
		refreshVisual()
	end

	local hit = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = header,
	})
	connect(hit.MouseButton1Click, function()
		open = not open
		listFrame.Visible = open
		tween(chevron, { Rotation = open and 180 or 0 }, SMOOTH)
	end)
	connect(header.MouseEnter, function()
		tween(holder, { BackgroundColor3 = Nebula.Theme.ElementHover })
	end)
	connect(header.MouseLeave, function()
		tween(holder, { BackgroundColor3 = Nebula.Theme.Element })
	end)

	buildRows()
	if next(selected) then fire() end

	local element = {
		Instance = holder,
		Get = function()
			local chosen = selectedList()
			if multi then return chosen end
			return chosen[1]
		end,
		Set = function(v)
			selected = {}
			if type(v) == "table" then
				for _, item in ipairs(v) do selected[tostring(item)] = true end
			elseif v ~= nil then
				selected[tostring(v)] = true
			end
			refreshVisual()
			fire()
		end,
		Refresh = function(newOptions, keepSelection)
			options = newOptions or {}
			if not keepSelection then selected = {} end
			buildRows()
		end,
	}
	win:_register(opts.Flag, element.Get, element.Set)
	return element
end

--=================================================================--
-- INPUT (TEXTBOX)
--=================================================================--

function Tab:CreateInput(opts)
	opts = opts or {}
	local win = self.Window
	local callback = opts.Callback or function() end

	local frame = baseElement(self, 38)
	interactive(frame)
	local label = elementTitle(frame, tostring(opts.Name or "Input"))
	label.Size = UDim2.new(0.45, 0, 1, 0)

	local boxHolder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.45, 0, 0, 26),
		BackgroundColor3 = Nebula.Theme.Secondary,
		BorderSizePixel = 0,
		Parent = frame,
	})
	themed(boxHolder, "BackgroundColor3", "Secondary")
	corner(boxHolder, 6)

	local box = new("TextBox", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		Text = tostring(opts.Default or ""),
		PlaceholderText = tostring(opts.Placeholder or "Type here..."),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = opts.ClearOnFocus and true or false,
		Parent = boxHolder,
	})
	themed(box, "TextColor3", "Text")
	themed(box, "PlaceholderColor3", "SubText")

	connect(box.FocusLost, function(enter)
		if opts.OnlyOnEnter and not enter then return end
		task.spawn(function()
			local ok, err = pcall(callback, box.Text)
			if not ok then
				Nebula:Notify({ Title = "Script Error", Content = tostring(err), Type = "error", Duration = 6 })
			end
		end)
		Nebula.Flags[opts.Flag or ""] = box.Text
		win:_autosave()
	end)

	Nebula.Flags[opts.Flag or ""] = box.Text

	local element = {
		Instance = frame,
		Get = function() return box.Text end,
		Set = function(text)
			box.Text = tostring(text)
			Nebula.Flags[opts.Flag or ""] = box.Text
			task.spawn(function() pcall(callback, box.Text) end)
		end,
	}
	win:_register(opts.Flag, element.Get, element.Set)
	return element
end

--=================================================================--
-- KEYBIND
--=================================================================--

function Tab:CreateKeybind(opts)
	opts = opts or {}
	local win = self.Window
	local callback = opts.Callback or function() end
	local key = opts.Default or Enum.KeyCode.F
	if type(key) == "string" then key = Enum.KeyCode[key] or Enum.KeyCode.F end
	local listening = false

	local frame = baseElement(self, 38)
	interactive(frame)
	elementTitle(frame, tostring(opts.Name or "Keybind"))

	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(84, 26),
		BackgroundColor3 = Nebula.Theme.Secondary,
		AutoButtonColor = false,
		Font = FONT_BOLD,
		Text = key.Name,
		TextSize = 11.5,
		Parent = frame,
	})
	themed(btn, "BackgroundColor3", "Secondary")
	themed(btn, "TextColor3", "Text")
	corner(btn, 6)

	connect(btn.MouseButton1Click, function()
		listening = true
		btn.Text = "..."
		tween(btn, { BackgroundColor3 = Nebula.Theme.Accent })
	end)

	connect(UserInputService.InputBegan, function(input, gpe)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					listening = false
					btn.Text = key.Name
					tween(btn, { BackgroundColor3 = Nebula.Theme.Secondary })
					return
				end
				key = input.KeyCode
				listening = false
				btn.Text = key.Name
				Nebula.Flags[opts.Flag or ""] = key
				tween(btn, { BackgroundColor3 = Nebula.Theme.Secondary })
				win:_autosave()
			end
			return
		end
		if gpe then return end
		if input.KeyCode == key then
			task.spawn(function() pcall(callback, key) end)
		end
	end)

	Nebula.Flags[opts.Flag or ""] = key

	local element = {
		Instance = frame,
		Get = function() return key end,
		Set = function(newKey)
			if type(newKey) == "string" then newKey = Enum.KeyCode[newKey] end
			if newKey then
				key = newKey
				btn.Text = key.Name
				Nebula.Flags[opts.Flag or ""] = key
			end
		end,
	}
	win:_register(opts.Flag, element.Get, element.Set)
	return element
end

--=================================================================--
-- COLOR PICKER
--=================================================================--

function Tab:CreateColorPicker(opts)
	opts = opts or {}
	local win = self.Window
	local callback = opts.Callback or function() end
	local color = opts.Default or Color3.fromRGB(255, 90, 120)
	local h, s, v = color:ToHSV()
	local open = false

	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Nebula.Theme.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Page,
	})
	themed(holder, "BackgroundColor3", "Element")
	corner(holder, 8)
	stroke(holder, 1, "Stroke", 0.4)
	list(holder, 0)

	local header = new("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	elementTitle(header, tostring(opts.Name or "Color"))

	local preview = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = header,
	})
	corner(preview, 6)
	stroke(preview, 1, "Stroke")

	local body = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = holder,
	})
	padding(body, 0, 12, 12, 0, 12)
	list(body, 8)

	-- Saturation / Value area
	local svBox = new("Frame", {
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0,
		Parent = body,
	})
	corner(svBox, 6)

	new("Frame", { -- white -> transparent (saturation)
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = svBox,
	}, {
		new("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
		new("UICorner", { CornerRadius = UDim.new(0, 6) }),
	})

	new("Frame", { -- transparent -> black (value)
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = svBox,
	}, {
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(0, 0, 0)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}),
		new("UICorner", { CornerRadius = UDim.new(0, 6) }),
	})

	local svCursor = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = svBox,
	}, {
		new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),
	})

	-- Hue slider
	local hueBar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = body,
	})
	corner(hueBar, 7)
	new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueBar,
	})

	local hueCursor = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(6, 20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = hueBar,
	})
	corner(hueCursor, 3)
	stroke(hueCursor, 1, "Stroke")

	local hexLabel = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		Text = "#FFFFFF",
		TextSize = 11.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = body,
	})
	themed(hexLabel, "TextColor3", "SubText")

	local function refresh(fire)
		color = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = color
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
		hexLabel.Text = string.format("#%02X%02X%02X",
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5))
		Nebula.Flags[opts.Flag or ""] = color
		if fire ~= false then
			task.spawn(function() pcall(callback, color) end)
		end
	end

	local function bindDrag(target, handler)
		local dragging = false
		connect(target.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				handler(input)
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				handler(input)
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				win:_autosave()
			end
		end)
	end

	-- Transparent hit areas so the gradient overlays don't swallow input
	local svHit = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 6,
		Parent = svBox,
	})
	local hueHit = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 6,
		Parent = hueBar,
	})

	bindDrag(svHit, function(input)
		local pos = inputPos(input)
		s = clamp01((pos.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1))
		v = 1 - clamp01((pos.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1))
		refresh(true)
	end)

	bindDrag(hueHit, function(input)
		local pos = inputPos(input)
		h = clamp01((pos.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1))
		refresh(true)
	end)

	local hit = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = header,
	})
	connect(hit.MouseButton1Click, function()
		open = not open
		body.Visible = open
	end)
	connect(header.MouseEnter, function()
		tween(holder, { BackgroundColor3 = Nebula.Theme.ElementHover })
	end)
	connect(header.MouseLeave, function()
		tween(holder, { BackgroundColor3 = Nebula.Theme.Element })
	end)

	refresh(false)

	local element = {
		Instance = holder,
		Get = function() return color end,
		Set = function(newColor)
			if typeof(newColor) == "Color3" then
				h, s, v = newColor:ToHSV()
				refresh(true)
			end
		end,
	}
	win:_register(opts.Flag, element.Get, element.Set)
	return element
end

--=================================================================--
-- THEME PICKER HELPER (drop-in settings tab)
--=================================================================--

function Window:CreateSettingsTab(name)
	local tab = self:CreateTab(name or "Settings", "⚙")
	tab:CreateSection("Interface")

	local themeNames = {}
	for themeName in pairs(Nebula.Themes) do
		themeNames[#themeNames + 1] = themeName
	end
	table.sort(themeNames)

	tab:CreateDropdown({
		Name = "Theme",
		Options = themeNames,
		Default = Nebula.ThemeName,
		Flag = "nebula_theme",
		Callback = function(value)
			if value then Nebula:SetTheme(value) end
		end,
	})

	tab:CreateKeybind({
		Name = "Toggle UI",
		Default = self.ToggleKey,
		Flag = "nebula_togglekey",
		Callback = function() end,
	})

	if self.ConfigName then
		tab:CreateSection("Configuration")
		tab:CreateButton({
			Name = "Save Config",
			Callback = function()
				local ok = self:SaveConfig()
				Nebula:Notify({
					Title = ok and "Config Saved" or "Save Failed",
					Content = ok and "Your settings were written to disk." or "Executor has no file access.",
					Type = ok and "success" or "error",
				})
			end,
		})
		tab:CreateButton({
			Name = "Load Config",
			Callback = function()
				local ok = self:LoadConfig()
				Nebula:Notify({
					Title = ok and "Config Loaded" or "Load Failed",
					Content = ok and "Settings restored." or "No saved config found.",
					Type = ok and "success" or "warning",
				})
			end,
		})
	end

	tab:CreateSection("About")
	tab:CreateParagraph({
		Title = "Nebula UI v" .. Nebula.Version,
		Content = "Lightweight UI library for Roblox executors. Press "
			.. self.ToggleKey.Name .. " to hide or show this window.",
	})

	return tab
end

--=================================================================--
-- ALIASES (Rayfield/Orion-style naming)
--=================================================================--

local aliases = {
	AddButton = "CreateButton",
	AddToggle = "CreateToggle",
	AddSlider = "CreateSlider",
	AddDropdown = "CreateDropdown",
	AddInput = "CreateInput",
	AddTextbox = "CreateInput",
	AddKeybind = "CreateKeybind",
	AddColorPicker = "CreateColorPicker",
	AddLabel = "CreateLabel",
	AddParagraph = "CreateParagraph",
	AddSection = "CreateSection",
	AddDivider = "CreateDivider",
}
for alias, target in pairs(aliases) do
	Tab[alias] = function(self, ...)
		return Tab[target](self, ...)
	end
end

Window.AddTab = function(self, ...) return Window.CreateTab(self, ...) end
Nebula.MakeWindow = function(self, ...) return Nebula.CreateWindow(self, ...) end
Nebula.Notification = function(self, ...) return Nebula.Notify(self, ...) end

function Nebula:Destroy()
	for _, win in ipairs(Nebula.Windows) do
		pcall(function() win:Destroy() end)
	end
	Nebula.Windows = {}
end

return Nebula
