--[[
    UniversalUI v2.0.0
    A responsive, reusable Roblox Luau UI library.

    Works in a LocalScript / ModuleScript and in common executor environments.
    Executor-only features (filesystem and clipboard) are detected at runtime.
    They are never assumed to exist.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Library = {}
Library.__index = Library
Library.Version = "2.0.0"

Library.Themes = {
    Dark = {
        Background = Color3.fromRGB(14, 16, 23),
        Panel = Color3.fromRGB(22, 25, 35),
        Panel2 = Color3.fromRGB(29, 33, 45),
        Input = Color3.fromRGB(18, 21, 30),
        Accent = Color3.fromRGB(135, 92, 255),
        Accent2 = Color3.fromRGB(91, 144, 255),
        Text = Color3.fromRGB(245, 246, 255),
        Muted = Color3.fromRGB(155, 163, 184),
        Stroke = Color3.fromRGB(55, 61, 79),
        Success = Color3.fromRGB(72, 196, 130),
        Danger = Color3.fromRGB(235, 83, 102),
    },
    Midnight = {
        Background = Color3.fromRGB(10, 17, 31),
        Panel = Color3.fromRGB(16, 27, 48),
        Panel2 = Color3.fromRGB(23, 38, 65),
        Input = Color3.fromRGB(12, 22, 39),
        Accent = Color3.fromRGB(0, 171, 255),
        Accent2 = Color3.fromRGB(99, 102, 241),
        Text = Color3.fromRGB(238, 247, 255),
        Muted = Color3.fromRGB(142, 164, 193),
        Stroke = Color3.fromRGB(43, 66, 99),
        Success = Color3.fromRGB(55, 205, 151),
        Danger = Color3.fromRGB(244, 91, 112),
    },
    Light = {
        Background = Color3.fromRGB(239, 242, 249),
        Panel = Color3.fromRGB(255, 255, 255),
        Panel2 = Color3.fromRGB(245, 247, 252),
        Input = Color3.fromRGB(235, 239, 247),
        Accent = Color3.fromRGB(111, 76, 230),
        Accent2 = Color3.fromRGB(64, 125, 226),
        Text = Color3.fromRGB(32, 36, 49),
        Muted = Color3.fromRGB(105, 113, 132),
        Stroke = Color3.fromRGB(211, 217, 230),
        Success = Color3.fromRGB(39, 157, 102),
        Danger = Color3.fromRGB(215, 68, 91),
    },
}

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        local success, message = pcall(function()
            object[property] = value
        end)
        if not success then
            warn("[UniversalUI] Could not set " .. tostring(property) .. ": " .. tostring(message))
        end
    end
    if parent then
        object.Parent = parent
    end
    return object
end

local function addCorner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function addStroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or Color3.new(1, 1, 1),
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    }, parent)
end

local function addPadding(parent, left, right, top, bottom)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function addList(parent, direction, gap, horizontalAlignment)
    return make("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 0),
        HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
    }, parent)
end

local function tween(object, duration, properties)
    local success, result = pcall(function()
        local animation = TweenService:Create(
            object,
            TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            properties
        )
        animation:Play()
        return animation
    end)
    if success then
        return result
    end
    return nil
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return true
    end

    local args = table.pack(...)
    local trace = tostring
    if type(debug) == "table" and type(debug.traceback) == "function" then
        trace = debug.traceback
    end
    local success, result = xpcall(function()
        return callback(table.unpack(args, 1, args.n))
    end, trace)

    if not success then
        warn("[UniversalUI callback error]\n" .. tostring(result))
    end
    return success, result
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function roundToStep(value, step)
    if not step or step <= 0 then
        return value
    end
    return math.floor((value / step) + 0.5) * step
end

local function formatNumber(value)
    if math.abs(value - math.floor(value)) < 0.000001 then
        return tostring(math.floor(value))
    end
    return string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function getEnvironment()
    -- Executor globals are not standardized. Prefer getgenv() when it exists,
    -- then fall back to the current Luau environment and finally _G.
    local currentEnvironment = nil

    if type(getfenv) == "function" then
        local success, result = pcall(getfenv)
        if success and type(result) == "table" then
            currentEnvironment = result
        end
    end

    local getgenvFunction = currentEnvironment and rawget(currentEnvironment, "getgenv")
    if type(getgenvFunction) ~= "function" then
        getgenvFunction = rawget(_G, "getgenv")
    end

    if type(getgenvFunction) == "function" then
        local success, result = pcall(getgenvFunction)
        if success and type(result) == "table" then
            return result
        end
    end

    if currentEnvironment then
        return currentEnvironment
    end

    return _G
end

local function getOptionalFunction(name)
    local environment = getEnvironment()
    local value = rawget(environment, name)
    if type(value) ~= "function" then
        value = rawget(_G, name)
    end
    if type(value) == "function" then
        return value
    end
    return nil
end

local function getGuiParent(screenGui)
    local getHui = getOptionalFunction("gethui")
    if getHui then
        local success, result = pcall(getHui)
        if success and result then
            return result
        end
    end

    local player = Players.LocalPlayer
    if player then
        local success, playerGui = pcall(function()
            return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
        end)
        if success and playerGui then
            return playerGui
        end
    end

    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success then
        return coreGui
    end
    return nil
end

local function sanitizeName(name)
    local safe = tostring(name or "Default")
    safe = safe:gsub("[^%w%-%_ ]", "_"):gsub("%s+", "_")
    if safe == "" then
        safe = "Default"
    end
    return safe
end

local function serializeValue(value)
    if typeof(value) == "Color3" then
        return {
            __type = "Color3",
            r = value.R,
            g = value.G,
            b = value.B,
        }
    end

    if typeof(value) == "EnumItem" then
        return {
            __type = "EnumItem",
            enum = tostring(value.EnumType),
            name = value.Name,
        }
    end

    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do
            if type(key) == "string" or type(key) == "number" then
                result[key] = serializeValue(item)
            end
        end
        return result
    end

    if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
        return value
    end
    return nil
end

local function deserializeValue(value)
    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Color3" then
        return Color3.new(
            clamp(tonumber(value.r) or 1, 0, 1),
            clamp(tonumber(value.g) or 1, 0, 1),
            clamp(tonumber(value.b) or 1, 0, 1)
        )
    end

    if value.__type == "EnumItem" and value.enum == "KeyCode" then
        local success, keyCode = pcall(function()
            return Enum.KeyCode[value.name]
        end)
        if success then
            return keyCode
        end
        return Enum.KeyCode.Unknown
    end

    local result = {}
    for key, item in pairs(value) do
        result[key] = deserializeValue(item)
    end
    return result
end

local function makeText(parent, text, size, color, font, properties)
    local settings = {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextSize = size or 13,
        TextColor3 = color or Color3.new(1, 1, 1),
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for key, value in pairs(properties or {}) do
        settings[key] = value
    end
    return make("TextLabel", settings, parent)
end

-- Public compatibility layer -------------------------------------------------
-- Only capability-detected APIs are called. Executor APIs are deliberately
-- kept separate from official Roblox engine APIs.
local function getRequestFunction()
    local requestFunction = getOptionalFunction("request")
        or getOptionalFunction("http_request")
    if requestFunction then
        return requestFunction
    end

    local environment = getEnvironment()
    local synTable = rawget(environment, "syn")
    if type(synTable) == "table" and type(synTable.request) == "function" then
        return synTable.request
    end

    return nil
end

local function canCreateClass(className)
    local success, object = pcall(Instance.new, className)
    if success and object then
        object:Destroy()
        return true
    end
    return false
end

local function colorKey(color)
    local r = math.floor(color.R * 255 / 16 + 0.5) * 16
    local g = math.floor(color.G * 255 / 16 + 0.5) * 16
    local b = math.floor(color.B * 255 / 16 + 0.5) * 16
    return string.format("%02x%02x%02x", clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255))
end

local function detectGameTheme(excludedGuiName)
    local player = Players.LocalPlayer
    if not player then
        return nil, "LocalPlayer is not available"
    end

    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        local success, result = pcall(function()
            return player:WaitForChild("PlayerGui", 4)
        end)
        if success then
            playerGui = result
        end
    end
    if not playerGui then
        return nil, "PlayerGui is not available"
    end

    local samples = {}
    local sampleCount = 0
    local descendants = playerGui:GetDescendants()

    for _, object in ipairs(descendants) do
        if object:IsA("GuiObject") then
            local ignored = false
            local ancestor = object
            while ancestor and ancestor ~= playerGui do
                if excludedGuiName and ancestor.Name == excludedGuiName then
                    ignored = true
                    break
                end
                ancestor = ancestor.Parent
            end

            if not ignored then
                local success, background, transparency, absoluteSize = pcall(function()
                    return object.BackgroundColor3, object.BackgroundTransparency, object.AbsoluteSize
                end)
                if success and typeof(background) == "Color3" and transparency < 0.58 then
                    local area = math.max(1, absoluteSize.X * absoluteSize.Y)
                    if area >= 900 then
                        local key = colorKey(background)
                        local weight = math.min(4, 1 + math.sqrt(area) / 300)
                        local current = samples[key]
                        if current then
                            current.Weight += weight
                            current.Count += 1
                        else
                            samples[key] = {
                                Color = background,
                                Weight = weight,
                                Count = 1,
                            }
                        end
                        sampleCount += 1
                    end
                end
            end
        end
    end

    if sampleCount < 2 then
        return nil, "Not enough visible game UI colors were found"
    end

    local ordered = {}
    for _, sample in pairs(samples) do
        table.insert(ordered, sample)
    end
    table.sort(ordered, function(a, b)
        return a.Weight > b.Weight
    end)

    local panel = ordered[1] and ordered[1].Color or Color3.fromRGB(25, 28, 38)
    local panelLuminance = panel.R * 0.2126 + panel.G * 0.7152 + panel.B * 0.0722
    local isLight = panelLuminance > 0.56
    local opposite = isLight and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
    local accent = nil
    local bestSaturation = 0

    for _, sample in ipairs(ordered) do
        local _, saturation, value = sample.Color:ToHSV()
        local score = saturation * (0.35 + math.min(value, 1) * 0.65)
        if score > bestSaturation and saturation >= 0.24 then
            bestSaturation = score
            accent = sample.Color
        end
    end

    accent = accent or Library.Themes.Dark.Accent
    local background = panel:Lerp(opposite, isLight and 0.12 or 0.18)
    local panel2 = panel:Lerp(opposite, isLight and 0.055 or 0.12)
    local input = panel:Lerp(opposite, isLight and 0.18 or 0.08)
    local accent2 = accent:Lerp(opposite, isLight and 0.2 or 0.24)
    local text = isLight and Color3.fromRGB(28, 30, 38) or Color3.fromRGB(245, 247, 255)
    local muted = text:Lerp(panel, 0.4)
    local stroke = panel:Lerp(opposite, isLight and 0.22 or 0.26)

    return {
        Background = background,
        Panel = panel,
        Panel2 = panel2,
        Input = input,
        Accent = accent,
        Accent2 = accent2,
        Text = text,
        Muted = muted,
        Stroke = stroke,
        Success = Library.Themes.Dark.Success,
        Danger = Library.Themes.Dark.Danger,
    }
end

Library.Executor = {}

function Library.Executor:GetCapabilities()
    local environment = getEnvironment()
    local drawing = rawget(environment, "Drawing")
    local synTable = rawget(environment, "syn")
    local requestAvailable = getRequestFunction() ~= nil

    return {
        Executor = {
            GetHui = getOptionalFunction("gethui") ~= nil,
            GetGenv = getOptionalFunction("getgenv") ~= nil,
            ReadFile = getOptionalFunction("readfile") ~= nil,
            WriteFile = getOptionalFunction("writefile") ~= nil,
            ListFiles = getOptionalFunction("listfiles") ~= nil,
            MakeFolder = getOptionalFunction("makefolder") ~= nil,
            IsFolder = getOptionalFunction("isfolder") ~= nil,
            IsFile = getOptionalFunction("isfile") ~= nil,
            DeleteFile = getOptionalFunction("delfile") ~= nil,
            ClipboardWrite = getOptionalFunction("setclipboard") ~= nil
                or getOptionalFunction("toclipboard") ~= nil,
            ClipboardRead = getOptionalFunction("getclipboard") ~= nil,
            CustomAsset = getOptionalFunction("getcustomasset") ~= nil
                or getOptionalFunction("getsynasset") ~= nil,
            HttpRequest = requestAvailable,
            WebSocket = type(rawget(environment, "WebSocket")) == "table"
                or (type(synTable) == "table" and type(synTable.websocket) == "table"),
            Drawing = type(drawing) == "table" and type(drawing.new) == "function",
            Loadstring = type(rawget(environment, "loadstring")) == "function",
        },
        Roblox = {
            IsStudio = RunService:IsStudio(),
            TouchEnabled = UserInputService.TouchEnabled,
            KeyboardEnabled = UserInputService.KeyboardEnabled,
            MouseEnabled = UserInputService.MouseEnabled,
            GamepadEnabled = UserInputService.GamepadEnabled,
            VideoFrame = canCreateClass("VideoFrame"),
            VideoPlayer = canCreateClass("VideoPlayer"),
            VideoDisplay = canCreateClass("VideoDisplay"),
            Wire = canCreateClass("Wire"),
        },
    }
end

function Library.Executor:ReadFile(path)
    local api = getOptionalFunction("readfile")
    if not api then
        return false, "readfile is not available in this environment"
    end
    local success, result = pcall(api, tostring(path))
    if not success then
        return false, tostring(result)
    end
    return true, result
end

function Library.Executor:WriteFile(path, contents)
    local api = getOptionalFunction("writefile")
    if not api then
        return false, "writefile is not available in this environment"
    end
    local success, result = pcall(api, tostring(path), tostring(contents or ""))
    if not success then
        return false, tostring(result)
    end
    return true, result
end

function Library.Executor:ListFiles(path)
    local api = getOptionalFunction("listfiles")
    if not api then
        return false, "listfiles is not available in this environment"
    end
    local success, result = pcall(api, tostring(path or ""))
    if not success then
        return false, tostring(result)
    end
    if type(result) ~= "table" then
        return false, "listfiles returned an unexpected value"
    end
    return true, result
end

function Library.Executor:MakeFolder(path)
    local api = getOptionalFunction("makefolder")
    if not api then
        return false, "makefolder is not available in this environment"
    end
    local success, result = pcall(api, tostring(path))
    return success, success and result or tostring(result)
end

function Library.Executor:IsFile(path)
    local api = getOptionalFunction("isfile")
    if not api then
        return false, "isfile is not available in this environment"
    end
    local success, result = pcall(api, tostring(path))
    if not success then
        return false, tostring(result)
    end
    return true, result == true
end

function Library.Executor:IsFolder(path)
    local api = getOptionalFunction("isfolder")
    if not api then
        return false, "isfolder is not available in this environment"
    end
    local success, result = pcall(api, tostring(path))
    if not success then
        return false, tostring(result)
    end
    return true, result == true
end

function Library.Executor:DeleteFile(path)
    local api = getOptionalFunction("delfile")
    if not api then
        return false, "delfile is not available in this environment"
    end
    local success, result = pcall(api, tostring(path))
    return success, success and result or tostring(result)
end

function Library.Executor:SetClipboard(contents)
    local api = getOptionalFunction("setclipboard") or getOptionalFunction("toclipboard")
    if not api then
        return false, "No clipboard write API is available"
    end
    local success, result = pcall(api, tostring(contents or ""))
    return success, success and result or tostring(result)
end

function Library.Executor:GetClipboard()
    local api = getOptionalFunction("getclipboard")
    if not api then
        return false, "getclipboard is not available in this environment"
    end
    local success, result = pcall(api)
    if not success then
        return false, tostring(result)
    end
    return true, result
end

function Library.Executor:GetCustomAsset(path)
    local api = getOptionalFunction("getcustomasset") or getOptionalFunction("getsynasset")
    if not api then
        return false, "No custom-asset API is available"
    end
    local success, result = pcall(api, tostring(path))
    if not success then
        return false, tostring(result)
    end
    return true, result
end

function Library.Executor:Request(options)
    local api = getRequestFunction()
    if not api then
        return false, "No executor HTTP request API is available"
    end
    local success, result = pcall(api, options)
    if not success then
        return false, tostring(result)
    end
    return true, result
end

function Library:GetCapabilities()
    return Library.Executor:GetCapabilities()
end

function Library:SuggestGameTheme()
    return detectGameTheme(nil)
end

function Library.new(options)
    options = options or {}

    local self = setmetatable({}, Library)
    self.Options = options
    self.Windows = {}
    self._destroyed = false
    self._errorCount = 0
    return self
end

function Library:CreateWindow(options)
    options = options or {}
    local library = self
    local window = {}

    window.Library = library
    window.Options = options
    window.Title = options.Title or "UniversalUI"
    window.Subtitle = options.Subtitle or "Universal Roblox UI"
    window.ToggleKey = options.ToggleKey
    local requestedTheme = options.Theme or "Dark"
    local initialTheme = nil
    if requestedTheme == "Game" or options.AutoMatchGameUI == true then
        initialTheme = detectGameTheme(nil)
    end
    window.Theme = table.clone(initialTheme or Library.Themes[requestedTheme] or Library.Themes.Dark)
    window.Executor = Library.Executor
    window._tabs = {}
    window._controls = {}
    window._values = {}
    window._themeBindings = {}
    window._connections = {}
    window._notifications = {}
    window._popup = nil
    window._keybindCapture = nil
    window._dragging = false
    window._destroyed = false
    window._configOptions = options.Config or {}
    window._configFolder = sanitizeName(window._configOptions.Folder or "UniversalUI")
    window._configWindow = sanitizeName(window.Title)

    local screenGui = make("ScreenGui", {
        Name = "UniversalUI_" .. sanitizeName(window.Title),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 100,
    })
    window.ScreenGui = screenGui

    local parent = getGuiParent(screenGui)
    if not parent then
        error("UniversalUI could not find a valid GUI parent. Use this from a LocalScript or a supported client environment.")
    end
    screenGui.Parent = parent

    local oldGui = parent:FindFirstChild(screenGui.Name)
    if oldGui and oldGui ~= screenGui then
        pcall(function()
            oldGui:Destroy()
        end)
    end

    local root = make("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(760, 540),
        BackgroundColor3 = window.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, screenGui)
    window.Main = root
    addCorner(root, 15)
    window._rootStroke = addStroke(root, window.Theme.Stroke, 0.15, 1)

    local topbar = make("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = window.Theme.Panel,
        BorderSizePixel = 0,
    }, root)
    window.Topbar = topbar

    local topbarTitle = makeText(topbar, window.Title, 16, window.Theme.Text, Enum.Font.GothamBold, {
        Position = UDim2.fromOffset(17, 4),
        Size = UDim2.new(1, -145, 0, 21),
    })
    window.TitleLabel = topbarTitle

    local subtitle = makeText(topbar, window.Subtitle, 10, window.Theme.Muted, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(18, 25),
        Size = UDim2.new(1, -145, 0, 15),
    })
    window.SubtitleLabel = subtitle

    local topActions = make("Frame", {
        Name = "Actions",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(78, 32),
        BackgroundTransparency = 1,
    }, topbar)
    addList(topActions, Enum.FillDirection.Horizontal, 7, Enum.HorizontalAlignment.Right)

    local minimizeButton = make("TextButton", {
        Name = "Minimize",
        Size = UDim2.fromOffset(32, 30),
        BackgroundColor3 = window.Theme.Panel2,
        Text = "—",
        TextSize = 18,
        TextColor3 = window.Theme.Text,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, topActions)
    addCorner(minimizeButton, 8)

    local closeButton = make("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(32, 30),
        BackgroundColor3 = window.Theme.Danger,
        Text = "×",
        TextSize = 20,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, topActions)
    addCorner(closeButton, 8)

    local body = make("Frame", {
        Name = "Body",
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 1, -48),
        BackgroundTransparency = 1,
    }, root)
    window.Body = body

    local sidebar = make("Frame", {
        Name = "Navigation",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 154, 1, 0),
        BackgroundColor3 = window.Theme.Panel,
        BorderSizePixel = 0,
    }, body)
    window.Sidebar = sidebar

    local navScroll = make("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = window.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, sidebar)
    window.NavScroll = navScroll
    local navLayout = addList(navScroll, Enum.FillDirection.Vertical, 7, Enum.HorizontalAlignment.Center)
    window.NavLayout = navLayout
    addPadding(navScroll, 2, 2, 2, 2)

    local pageHolder = make("Frame", {
        Name = "PageHolder",
        Position = UDim2.fromOffset(162, 0),
        Size = UDim2.new(1, -162, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, body)
    window.PageHolder = pageHolder

    local launcher = make("TextButton", {
        Name = "OpenButton",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = window.Theme.Accent,
        Text = "UI",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Visible = false,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, screenGui)
    addCorner(launcher, 15)
    addStroke(launcher, window.Theme.Stroke, 0.35, 1)
    window.Launcher = launcher

    local notificationHolder = make("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -14, 1, -14),
        Size = UDim2.fromOffset(290, 360),
        BackgroundTransparency = 1,
    }, screenGui)
    window.NotificationHolder = notificationHolder
    local notificationLayout = addList(notificationHolder, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right)
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local function registerTheme(object, property, key)
        table.insert(window._themeBindings, {
            Object = object,
            Property = property,
            Key = key,
        })
    end

    registerTheme(root, "BackgroundColor3", "Background")
    registerTheme(topbar, "BackgroundColor3", "Panel")
    registerTheme(sidebar, "BackgroundColor3", "Panel")
    registerTheme(window._rootStroke, "Color", "Stroke")
    registerTheme(navScroll, "ScrollBarImageColor3", "Accent")
    registerTheme(notificationHolder, "BackgroundColor3", "Background")

    function window:_reportError(message, title)
        self.Library._errorCount += 1
        warn("[UniversalUI] " .. tostring(title or "Error") .. ": " .. tostring(message))
        if self.Options.ShowErrors ~= false and not self._destroyed then
            self:Notify({
                Title = title or "Something went wrong",
                Content = tostring(message),
                Duration = 5,
                Type = "Error",
            })
        end
    end

    function window:_callback(callback, ...)
        local success, result = safeCall(callback, ...)
        if not success then
            self:_reportError(result, "Callback error")
        end
        return success, result
    end

    function window:_addTheme(object, property, key)
        registerTheme(object, property, key)
    end

    function window:_removeThemeBindings(rootObject)
        if not rootObject then
            return
        end
        for index = #self._themeBindings, 1, -1 do
            local object = self._themeBindings[index].Object
            local shouldRemove = object == rootObject
            if not shouldRemove and object then
                local success, isDescendant = pcall(function()
                    return object:IsDescendantOf(rootObject)
                end)
                shouldRemove = success and isDescendant
            end
            if shouldRemove then
                table.remove(self._themeBindings, index)
            end
        end
    end

    function window:SetTheme(theme)
        local nextTheme
        if type(theme) == "string" then
            if theme == "Game" then
                nextTheme = detectGameTheme(self.ScreenGui and self.ScreenGui.Name or nil)
            else
                nextTheme = Library.Themes[theme]
            end
        elseif type(theme) == "table" then
            nextTheme = table.clone(self.Theme)
            for key, value in pairs(theme) do
                if nextTheme[key] ~= nil and typeof(value) == "Color3" then
                    nextTheme[key] = value
                end
            end
        end
        if not nextTheme then
            return false, "Unknown theme"
        end

        self.Theme = table.clone(nextTheme)
        for _, binding in ipairs(self._themeBindings) do
            if binding.Object and binding.Object.Parent then
                pcall(function()
                    binding.Object[binding.Property] = self.Theme[binding.Key]
                end)
            end
        end

        for _, tab in ipairs(self._tabs) do
            if tab.Button and tab.Button.Parent then
                local selected = tab == self.ActiveTab
                tab.Button.TextColor3 = selected and self.Theme.Text or self.Theme.Muted
                tab.Button.BackgroundColor3 = self.Theme.Accent
                tab.Button.BackgroundTransparency = selected and 0 or 1
            end
        end
        self:_closePopup()
        for flag in pairs(self._controls) do
            self:_setControlValue(flag, self._values[flag], true)
        end
        return true
    end

    function window:ApplyGameTheme()
        local theme, reason = detectGameTheme(self.ScreenGui and self.ScreenGui.Name or nil)
        if not theme then
            return false, reason
        end
        return self:SetTheme(theme)
    end

    function window:_newFlag(prefix)
        self._flagCounter = (self._flagCounter or 0) + 1
        return (prefix or "Control") .. "_" .. tostring(self._flagCounter)
    end

    function window:_registerControl(flag, defaultValue, apply, callback)
        flag = (type(flag) == "string" and flag ~= "") and flag or self:_newFlag()
        if self._controls[flag] then
            self:_reportError("Duplicate control flag '" .. flag .. "'. A unique flag was generated.", "Duplicate flag")
            flag = self:_newFlag(flag)
        end

        local entry = {
            Apply = apply,
            Callback = callback,
        }
        self._controls[flag] = entry
        self._values[flag] = defaultValue

        local control = {}
        control.Flag = flag
        control.Window = self

        function control:SetValue(value, silent)
            return self.Window:_setControlValue(self.Flag, value, silent)
        end

        function control:GetValue()
            return self.Window._values[self.Flag]
        end

        function control:SetCallback(nextCallback)
            local current = self.Window._controls[self.Flag]
            if current then
                current.Callback = nextCallback
            end
        end

        function control:SetVisible(visible)
            if self.Frame then
                self.Frame.Visible = visible == true
            end
        end

        function control:SetDisabled(disabled)
            local isDisabled = disabled == true
            if self.Instance then
                if self.Instance:IsA("GuiButton") then
                    self.Instance.Active = not isDisabled
                    self.Instance.AutoButtonColor = not isDisabled
                elseif self.Instance:IsA("TextBox") then
                    self.Instance.Active = not isDisabled
                    self.Instance.TextEditable = not isDisabled
                elseif self.Instance:IsA("GuiObject") then
                    self.Instance.Active = not isDisabled
                end
            end
            if self.Frame then
                self.Frame:SetAttribute("UniversalUIDisabled", isDisabled)
            end
        end

        function control:Destroy()
            self.Window._controls[self.Flag] = nil
            self.Window._values[self.Flag] = nil
            if self.Frame then
                self.Window:_removeThemeBindings(self.Frame)
                pcall(function()
                    self.Frame:Destroy()
                end)
            end
        end

        entry.Control = control
        local success, normalized = pcall(apply, defaultValue)
        if success and normalized ~= nil then
            self._values[flag] = normalized
        elseif not success then
            self:_reportError(normalized, "Control setup error")
        end
        return control
    end

    function window:_setControlValue(flag, value, silent)
        local entry = self._controls[flag]
        if not entry then
            return false, "Control not found"
        end

        local success, normalized = pcall(entry.Apply, value)
        if not success then
            self:_reportError(normalized, "Control update error")
            return false, normalized
        end
        if normalized ~= nil then
            self._values[flag] = normalized
        else
            self._values[flag] = value
        end

        if not silent then
            self:_callback(entry.Callback, self._values[flag], flag)
        end
        return true, self._values[flag]
    end

    function window:_closePopup()
        if self._popup then
            pcall(function()
                self._popup:Destroy()
            end)
            self._popup = nil
        end
    end

    function window:_openPopup(anchor, popup, width, height)
        self:_closePopup()
        self._popup = popup
        popup.Parent = self.ScreenGui
        popup.ZIndex = 40
        local popupWidth = width or 190
        local popupHeight = height or 180
        popup.Size = UDim2.fromOffset(popupWidth, popupHeight)

        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local position = anchor.AbsolutePosition
        local anchorSize = anchor.AbsoluteSize
        local x = clamp(position.X, 8, math.max(8, viewport.X - popupWidth - 8))
        local y = position.Y + anchorSize.Y + 5
        if y + popupHeight > viewport.Y - 8 then
            y = position.Y - popupHeight - 5
        end
        y = clamp(y, 8, math.max(8, viewport.Y - popupHeight - 8))
        popup.Position = UDim2.fromOffset(x, y)
    end

    function window:Notify(notification)
        if self._destroyed then
            return
        end
        if type(notification) == "string" then
            notification = { Content = notification }
        end
        notification = notification or {}

        local kind = notification.Type or "Info"
        local accent = self.Theme.Accent
        if kind == "Error" then
            accent = self.Theme.Danger
        elseif kind == "Success" then
            accent = self.Theme.Success
        end

        local card = make("Frame", {
            Size = UDim2.new(1, 0, 0, 76),
            BackgroundColor3 = self.Theme.Panel,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.04,
        }, self.NotificationHolder)
        addCorner(card, 10)
        addStroke(card, self.Theme.Stroke, 0.2, 1)
        make("Frame", {
            Size = UDim2.new(0, 4, 1, -14),
            Position = UDim2.fromOffset(0, 7),
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
        }, card)

        makeText(card, notification.Title or "Notification", 13, self.Theme.Text, Enum.Font.GothamBold, {
            Position = UDim2.fromOffset(14, 8),
            Size = UDim2.new(1, -24, 0, 20),
        })
        makeText(card, notification.Content or "", 11, self.Theme.Muted, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(14, 30),
            Size = UDim2.new(1, -25, 0, 36),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate = Enum.TextTruncate.None,
        })

        table.insert(self._notifications, card)
        card.Position = UDim2.new(0, 16, 0, 0)
        card.BackgroundTransparency = 1
        tween(card, 0.18, {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0.04,
        })

        local duration = tonumber(notification.Duration) or 3
        task.delay(math.max(1, duration), function()
            if card and card.Parent then
                tween(card, 0.16, { BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 0) })
                task.wait(0.18)
                pcall(function()
                    card:Destroy()
                end)
                for index, item in ipairs(self._notifications) do
                    if item == card then
                        table.remove(self._notifications, index)
                        break
                    end
                end
            end
        end)
    end

    function window:_layout()
        if self._destroyed or not self.Main then
            return
        end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1024, 768)
        local compact = viewport.X < 680 or viewport.Y < 470

        local width
        local height
        if compact then
            width = math.max(180, math.min(900, viewport.X - 12))
            height = math.max(180, math.min(760, viewport.Y - 18))
        else
            width = math.max(420, math.min(820, viewport.X - 80))
            height = math.max(340, math.min(600, viewport.Y - 80))
        end

        self.Main.Size = UDim2.fromOffset(width, height)
        self.Main.Position = UDim2.fromScale(0.5, 0.5)
        self.NotificationHolder.Size = UDim2.fromOffset(math.min(290, math.max(180, viewport.X - 24)), 360)

        if compact then
            self.Sidebar.Position = UDim2.fromOffset(0, 0)
            self.Sidebar.Size = UDim2.new(1, 0, 0, 52)
            self.NavScroll.Position = UDim2.fromOffset(8, 5)
            self.NavScroll.Size = UDim2.new(1, -16, 1, -10)
            self.NavLayout.FillDirection = Enum.FillDirection.Horizontal
            self.NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            self.NavScroll.ScrollingDirection = Enum.ScrollingDirection.X
            self.NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
            for _, tab in ipairs(self._tabs) do
                tab.Button.Size = UDim2.fromOffset(112, 38)
            end
            self.PageHolder.Position = UDim2.fromOffset(0, 58)
            self.PageHolder.Size = UDim2.new(1, 0, 1, -58)
        else
            self.Sidebar.Position = UDim2.fromOffset(0, 0)
            self.Sidebar.Size = UDim2.new(0, 154, 1, 0)
            self.NavScroll.Position = UDim2.fromOffset(8, 8)
            self.NavScroll.Size = UDim2.new(1, -16, 1, -16)
            self.NavLayout.FillDirection = Enum.FillDirection.Vertical
            self.NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            self.NavScroll.ScrollingDirection = Enum.ScrollingDirection.Y
            self.NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            for _, tab in ipairs(self._tabs) do
                tab.Button.Size = UDim2.new(1, -2, 0, 38)
            end
            self.PageHolder.Position = UDim2.fromOffset(162, 0)
            self.PageHolder.Size = UDim2.new(1, -162, 1, 0)
        end
    end

    function window:Toggle()
        if self._destroyed then
            return
        end
        self.Main.Visible = not self.Main.Visible
        self.Launcher.Visible = not self.Main.Visible
    end

    function window:SetToggleKey(key)
        if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
            self.ToggleKey = key
        elseif type(key) == "string" then
            if key == "" or key == "None" then
                self.ToggleKey = nil
            else
                local success, result = pcall(function()
                    return Enum.KeyCode[key]
                end)
                if not success or not result then
                    return false, "Unknown KeyCode: " .. key
                end
                self.ToggleKey = result
            end
        elseif key == nil then
            self.ToggleKey = nil
        else
            return false, "Toggle key must be a KeyCode, key name, or nil"
        end
        return true
    end

    function window:Destroy()
        if self._destroyed then
            return
        end
        self._destroyed = true
        self:_closePopup()
        for _, connection in ipairs(self._connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        self._connections = {}
        if self._cameraConnection then
            pcall(function()
                self._cameraConnection:Disconnect()
            end)
            self._cameraConnection = nil
        end
        pcall(function()
            self.ScreenGui:Destroy()
        end)
        self.Library.Windows[self] = nil
    end

    function window:GetValue(flag)
        return self._values[flag]
    end

    function window:SetValue(flag, value, silent)
        return self:_setControlValue(flag, value, silent)
    end

    function window:GetControl(flag)
        local entry = self._controls[flag]
        return entry and entry.Control or nil
    end

    -- Config support. The default file backend is executor-specific; custom adapters
    -- can be supplied in CreateWindow({ Config = { Adapter = ... } }).
    function window:_filePath(name)
        return self._configFolder .. "/" .. self._configWindow .. "/" .. sanitizeName(name) .. ".json"
    end

    function window:_getConfigAdapter()
        local adapter = self._configOptions.Adapter
        if type(adapter) == "table" then
            return adapter
        end
        return nil
    end

    function window:GetConfigJSON()
        local payload = {
            Library = "UniversalUI",
            Version = Library.Version,
            Window = self.Title,
            Values = {},
        }
        for flag, value in pairs(self._values) do
            payload.Values[flag] = serializeValue(value)
        end
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(payload)
        end)
        if not success then
            return nil, encoded
        end
        return encoded
    end

    function window:LoadConfigJSON(json, fireCallbacks)
        if type(json) ~= "string" then
            return false, "Config JSON must be a string"
        end
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if not success then
            return false, "Invalid config JSON: " .. tostring(decoded)
        end
        if type(decoded) ~= "table" or type(decoded.Values) ~= "table" then
            return false, "Config file has an invalid format"
        end

        local loaded = 0
        for flag, value in pairs(decoded.Values) do
            if self._controls[flag] then
                local ok = self:_setControlValue(flag, deserializeValue(value), fireCallbacks == false)
                if ok then
                    loaded += 1
                end
            end
        end
        return true, loaded
    end

    function window:SaveConfig(name)
        name = sanitizeName(name or self._configOptions.Name or "Default")
        local json, encodeError = self:GetConfigJSON()
        if not json then
            return false, tostring(encodeError)
        end

        local adapter = self:_getConfigAdapter()
        if adapter and type(adapter.Save) == "function" then
            local success, result = pcall(adapter.Save, name, json)
            if success and result ~= false then
                self:Notify({ Title = "Config saved", Content = name, Type = "Success" })
                return true
            end
            local reason = success and "Config adapter rejected the save" or tostring(result)
            self:_reportError(reason, "Config save failed")
            return false, reason
        end

        local makefolderFn = getOptionalFunction("makefolder")
        local isfolderFn = getOptionalFunction("isfolder")
        local writefileFn = getOptionalFunction("writefile")
        local isfileFn = getOptionalFunction("isfile")
        if not writefileFn then
            return false, "No file storage API is available. Use a custom Config.Adapter or save GetConfigJSON() yourself."
        end

        local folderA = self._configFolder
        local folderB = folderA .. "/" .. self._configWindow
        if makefolderFn then
            local folderAExists = false
            local folderBExists = false
            if isfolderFn then
                local checkA, resultA = pcall(isfolderFn, folderA)
                local checkB, resultB = pcall(isfolderFn, folderB)
                folderAExists = checkA and resultA == true
                folderBExists = checkB and resultB == true
            end
            if not folderAExists then
                pcall(makefolderFn, folderA)
            end
            if not folderBExists then
                pcall(makefolderFn, folderB)
            end
        end

        local path = self:_filePath(name)
        local success, result = pcall(writefileFn, path, json)
        if not success then
            self:_reportError(result, "Config save failed")
            return false, tostring(result)
        end
        if isfileFn then
            local existsOk, exists = pcall(isfileFn, path)
            if existsOk and not exists then
                return false, "The file was not created. Check the executor's file API."
            end
        end
        self:Notify({ Title = "Config saved", Content = name, Type = "Success" })
        return true
    end

    function window:LoadConfig(name, fireCallbacks)
        name = sanitizeName(name or self._configOptions.Name or "Default")
        local adapter = self:_getConfigAdapter()
        local json

        if adapter and type(adapter.Load) == "function" then
            local success, result = pcall(adapter.Load, name)
            if not success then
                self:_reportError(result, "Config load failed")
                return false, tostring(result)
            end
            json = result
        else
            local readfileFn = getOptionalFunction("readfile")
            local isfileFn = getOptionalFunction("isfile")
            if not readfileFn then
                return false, "No file read API is available. Use a custom Config.Adapter or LoadConfigJSON()."
            end
            local path = self:_filePath(name)
            if isfileFn then
                local existsOk, exists = pcall(isfileFn, path)
                if existsOk and not exists then
                    return false, "Config does not exist: " .. name
                end
            end
            local success, result = pcall(readfileFn, path)
            if not success then
                self:_reportError(result, "Config load failed")
                return false, tostring(result)
            end
            json = result
        end

        if type(json) ~= "string" then
            return false, "The config adapter did not return JSON text"
        end
        local success, loaded = self:LoadConfigJSON(json, fireCallbacks)
        if success then
            self:Notify({ Title = "Config loaded", Content = name .. " · " .. tostring(loaded) .. " values", Type = "Success" })
        else
            self:_reportError(loaded, "Config load failed")
        end
        return success, loaded
    end

    function window:ListConfigs()
        local adapter = self:_getConfigAdapter()
        if adapter and type(adapter.List) == "function" then
            local success, result = pcall(adapter.List)
            if success and type(result) == "table" then
                return result
            end
            return {}, success and "Config adapter returned an invalid list" or tostring(result)
        end

        local listfilesFn = getOptionalFunction("listfiles")
        if not listfilesFn then
            return {}, "The current environment does not support listing config files"
        end
        local success, files = pcall(listfilesFn, self._configFolder .. "/" .. self._configWindow)
        if not success or type(files) ~= "table" then
            return {}, success and "No config files found" or tostring(files)
        end

        local names = {}
        for _, path in ipairs(files) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then
                table.insert(names, name)
            end
        end
        table.sort(names)
        return names
    end

    function window:DeleteConfig(name)
        name = sanitizeName(name)
        local adapter = self:_getConfigAdapter()
        if adapter and type(adapter.Delete) == "function" then
            local success, result = pcall(adapter.Delete, name)
            if success and result ~= false then
                self:Notify({ Title = "Config deleted", Content = name, Type = "Success" })
                return true
            end
            return false, success and "Config adapter rejected delete" or tostring(result)
        end

        local delfileFn = getOptionalFunction("delfile")
        if not delfileFn then
            return false, "The current environment does not support deleting config files"
        end
        local path = self:_filePath(name)
        local success, result = pcall(delfileFn, path)
        if not success then
            self:_reportError(result, "Config delete failed")
            return false, tostring(result)
        end
        self:Notify({ Title = "Config deleted", Content = name, Type = "Success" })
        return true
    end

    function window:CreateConfigTab(tabName)
        local tab = self:CreateTab({ Name = tabName or "Configs", Icon = "⚙" })
        local section = tab:CreateSection("Config manager")
        section:CreateParagraph({
            Title = "Save your setup",
            Content = "Save, load, list, or delete your UI settings. The default file system requires executor file APIs; custom adapters are supported too.",
        })
        local nameInput = section:CreateInput({ Name = "Config name", Placeholder = "MyConfig", Default = "Default", Flag = "__UniversalUI_ConfigName", Callback = function() end })
        section:CreateButton({ Name = "Save config", Callback = function()
            local success, reason = self:SaveConfig(nameInput:GetValue())
            if not success then
                self:Notify({ Title = "Save unavailable", Content = reason, Type = "Error" })
            end
        end })
        section:CreateButton({ Name = "Load config", Callback = function()
            local success, reason = self:LoadConfig(nameInput:GetValue())
            if not success then
                self:Notify({ Title = "Load failed", Content = reason, Type = "Error" })
            end
        end })
        section:CreateButton({ Name = "Refresh config list", Callback = function()
            local names, reason = self:ListConfigs()
            if #names == 0 then
                self:Notify({ Title = "No configs", Content = reason or "No saved configs were found.", Type = "Info" })
            else
                self:Notify({ Title = "Saved configs", Content = table.concat(names, ", "), Type = "Success", Duration = 6 })
            end
        end })
        section:CreateButton({ Name = "Delete config", Callback = function()
            local success, reason = self:DeleteConfig(nameInput:GetValue())
            if not success then
                self:Notify({ Title = "Delete failed", Content = reason, Type = "Error" })
            end
        end })
        return tab
    end

    function window:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        local name = tostring(tabOptions.Name or ("Tab " .. tostring(#self._tabs + 1)))
        local tab = {
            Window = self,
            Name = name,
            Sections = {},
        }

        local button = make("TextButton", {
            Name = sanitizeName(name) .. "TabButton",
            Size = UDim2.new(1, -2, 0, 38),
            BackgroundColor3 = self.Theme.Panel2,
            BackgroundTransparency = 1,
            Text = (tabOptions.Icon and (tostring(tabOptions.Icon) .. "   ") or "") .. name,
            TextColor3 = self.Theme.Muted,
            TextSize = 12,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            BorderSizePixel = 0,
        }, self.NavScroll)
        addCorner(button, 9)
        addPadding(button, 11, 8, 0, 0)
        tab.Button = button

        local page = make("ScrollingFrame", {
            Name = sanitizeName(name) .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, self.PageHolder)
        addPadding(page, 12, 12, 12, 14)
        local pageLayout = addList(page, Enum.FillDirection.Vertical, 11)
        tab.Page = page
        tab.PageLayout = pageLayout
        self:_addTheme(page, "ScrollBarImageColor3", "Accent")

        function tab:CreateSection(sectionName)
            local section = {
                Window = self.Window,
                Tab = self,
                Name = sectionName or "Section",
                Controls = {},
            }
            local card = make("Frame", {
                Name = sanitizeName(section.Name) .. "Section",
                Size = UDim2.new(1, -2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = self.Window.Theme.Panel,
                BorderSizePixel = 0,
            }, self.Page)
            addCorner(card, 11)
            local cardStroke = addStroke(card, self.Window.Theme.Stroke, 0.4, 1)
            self.Window:_addTheme(card, "BackgroundColor3", "Panel")
            self.Window:_addTheme(cardStroke, "Color", "Stroke")
            addPadding(card, 12, 12, 10, 11)
            addList(card, Enum.FillDirection.Vertical, 9)
            section.Frame = card

            local heading = makeText(card, section.Name, 12, self.Window.Theme.Accent2, Enum.Font.GothamBold, {
                Size = UDim2.new(1, 0, 0, 20),
            })
            section.TitleLabel = heading
            self.Window:_addTheme(heading, "TextColor3", "Accent2")

            local controlsFrame = make("Frame", {
                Name = "Controls",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
            }, card)
            addList(controlsFrame, Enum.FillDirection.Vertical, 7)
            section.ControlsFrame = controlsFrame

            function section:SetTitle(nextName)
                self.Name = tostring(nextName)
                self.TitleLabel.Text = self.Name
            end

            function section:SetVisible(visible)
                self.Frame.Visible = visible == true
            end

            function section:Clear()
                for flag, registered in pairs(self.Window._controls) do
                    local control = registered.Control
                    if control and control.Frame and control.Frame.Parent == self.ControlsFrame then
                        self.Window._controls[flag] = nil
                        self.Window._values[flag] = nil
                        if self.Window._keybindCapture == control then
                            self.Window._keybindCapture = nil
                        end
                    end
                end
                for _, child in ipairs(self.ControlsFrame:GetChildren()) do
                    if child:IsA("GuiObject") then
                        self.Window:_removeThemeBindings(child)
                        child:Destroy()
                    end
                end
                table.clear(self.Controls)
            end

            function section:_row(height, name)
                local row = make("Frame", {
                    Name = sanitizeName(name or "Control"),
                    Size = UDim2.new(1, 0, 0, height or 42),
                    BackgroundTransparency = 1,
                }, self.ControlsFrame)
                return row
            end

            function section:CreateButton(controlOptions)
                controlOptions = controlOptions or {}
                local row = self:_row(controlOptions.Height or 40, controlOptions.Name)
                local buttonObject = make("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = self.Window.Theme.Panel2,
                    Text = tostring(controlOptions.Name or "Button"),
                    TextColor3 = self.Window.Theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamSemibold,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(buttonObject, 8)
                local buttonStroke = addStroke(buttonObject, self.Window.Theme.Stroke, 0.55, 1)
                self.Window:_addTheme(buttonObject, "BackgroundColor3", "Panel2")
                self.Window:_addTheme(buttonObject, "TextColor3", "Text")
                self.Window:_addTheme(buttonStroke, "Color", "Stroke")
                buttonObject.MouseEnter:Connect(function()
                    tween(buttonObject, 0.12, { BackgroundColor3 = self.Window.Theme.Accent })
                end)
                buttonObject.MouseLeave:Connect(function()
                    tween(buttonObject, 0.12, { BackgroundColor3 = self.Window.Theme.Panel2 })
                end)
                buttonObject.Activated:Connect(function()
                    self.Window:_callback(controlOptions.Callback)
                end)
                table.insert(self.Controls, { Frame = row, Object = buttonObject })
                return {
                    Frame = row,
                    Button = buttonObject,
                    SetText = function(_, text)
                        buttonObject.Text = tostring(text)
                    end,
                }
            end

            function section:CreateToggle(controlOptions)
                controlOptions = controlOptions or {}
                local row = self:_row(43, controlOptions.Name)
                local title = makeText(row, controlOptions.Name or "Toggle", 12, self.Window.Theme.Text, Enum.Font.GothamMedium, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(1, -76, 1, 0),
                })
                local toggleButton = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -1, 0.5, 0),
                    Size = UDim2.fromOffset(45, 25),
                    BackgroundColor3 = self.Window.Theme.Input,
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(toggleButton, 20)
                self.Window:_addTheme(title, "TextColor3", "Text")
                self.Window:_addTheme(toggleButton, "BackgroundColor3", "Input")
                local knob = make("Frame", {
                    Position = UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(19, 19),
                    BackgroundColor3 = self.Window.Theme.Muted,
                    BorderSizePixel = 0,
                }, toggleButton)
                addCorner(knob, 20)
                self.Window:_addTheme(knob, "BackgroundColor3", "Muted")

                local function apply(value)
                    local enabled = value == true
                    tween(toggleButton, 0.13, { BackgroundColor3 = enabled and self.Window.Theme.Accent or self.Window.Theme.Input })
                    tween(knob, 0.13, {
                        Position = enabled and UDim2.new(1, -22, 0, 3) or UDim2.fromOffset(3, 3),
                        BackgroundColor3 = enabled and Color3.new(1, 1, 1) or self.Window.Theme.Muted,
                    })
                    return enabled
                end

                local control = self.Window:_registerControl(controlOptions.Flag, controlOptions.Default or false, apply, controlOptions.Callback)
                control.Frame = row
                control.Instance = toggleButton
                toggleButton.Activated:Connect(function()
                    control:SetValue(not control:GetValue())
                end)
                table.insert(self.Controls, { Frame = row, Object = toggleButton, Label = title })
                return control
            end

            function section:CreateSlider(controlOptions)
                controlOptions = controlOptions or {}
                local minimum = tonumber(controlOptions.Min) or 0
                local maximum = tonumber(controlOptions.Max) or 100
                if maximum < minimum then
                    minimum, maximum = maximum, minimum
                end
                local step = tonumber(controlOptions.Step) or 1
                local row = self:_row(58, controlOptions.Name)
                local title = makeText(row, controlOptions.Name or "Slider", 12, self.Window.Theme.Text, Enum.Font.GothamMedium, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(1, -80, 0, 22),
                })
                local valueLabel = makeText(row, "", 11, self.Window.Theme.Accent2, Enum.Font.GothamBold, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.fromOffset(70, 22),
                    TextXAlignment = Enum.TextXAlignment.Right,
                })
                local bar = make("TextButton", {
                    Position = UDim2.fromOffset(2, 34),
                    Size = UDim2.new(1, -4, 0, 7),
                    BackgroundColor3 = self.Window.Theme.Input,
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(bar, 8)
                self.Window:_addTheme(title, "TextColor3", "Text")
                self.Window:_addTheme(valueLabel, "TextColor3", "Accent2")
                self.Window:_addTheme(bar, "BackgroundColor3", "Input")
                local fill = make("Frame", {
                    Size = UDim2.fromScale(0, 1),
                    BackgroundColor3 = self.Window.Theme.Accent,
                    BorderSizePixel = 0,
                }, bar)
                addCorner(fill, 8)
                self.Window:_addTheme(fill, "BackgroundColor3", "Accent")
                local knob = make("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(15, 15),
                    BackgroundColor3 = self.Window.Theme.Text,
                    BorderSizePixel = 0,
                }, bar)
                addCorner(knob, 20)
                self.Window:_addTheme(knob, "BackgroundColor3", "Text")

                local function apply(value)
                    local number = clamp(tonumber(value) or minimum, minimum, maximum)
                    number = clamp(roundToStep(number, step), minimum, maximum)
                    local alpha = maximum == minimum and 0 or (number - minimum) / (maximum - minimum)
                    valueLabel.Text = formatNumber(number)
                    tween(fill, 0.08, { Size = UDim2.fromScale(alpha, 1) })
                    tween(knob, 0.08, { Position = UDim2.fromScale(alpha, 0.5) })
                    return number
                end

                local control = self.Window:_registerControl(controlOptions.Flag, controlOptions.Default or minimum, apply, controlOptions.Callback)
                control.Frame = row
                control.Instance = bar
                local activeInput = nil
                local function updateFromX(x)
                    local width = math.max(1, bar.AbsoluteSize.X)
                    local alpha = clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
                    control:SetValue(minimum + (maximum - minimum) * alpha)
                end
                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        activeInput = input
                        updateFromX(input.Position.X)
                    end
                end)
                table.insert(self.Window._connections, UserInputService.InputChanged:Connect(function(input)
                    if not activeInput then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input == activeInput then
                        updateFromX(input.Position.X)
                    end
                end))
                table.insert(self.Window._connections, UserInputService.InputEnded:Connect(function(input)
                    if activeInput and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
                        activeInput = nil
                    end
                end))
                table.insert(self.Controls, { Frame = row, Object = bar, Label = title })
                return control
            end

            function section:CreateProgressBar(controlOptions)
                controlOptions = controlOptions or {}
                local minimum = tonumber(controlOptions.Min) or 0
                local maximum = tonumber(controlOptions.Max) or 100
                if maximum < minimum then
                    minimum, maximum = maximum, minimum
                end
                local row = self:_row(52, controlOptions.Name or "Progress")
                local title = makeText(row, controlOptions.Name or "Progress", 11, self.Window.Theme.Text, Enum.Font.GothamMedium, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(1, -70, 0, 20),
                })
                local valueLabel = makeText(row, "", 10, self.Window.Theme.Muted, Enum.Font.GothamBold, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.fromOffset(65, 20),
                    TextXAlignment = Enum.TextXAlignment.Right,
                })
                local track = make("Frame", {
                    Position = UDim2.fromOffset(2, 29),
                    Size = UDim2.new(1, -4, 0, 8),
                    BackgroundColor3 = self.Window.Theme.Input,
                    BorderSizePixel = 0,
                }, row)
                addCorner(track, 8)
                local fill = make("Frame", {
                    Size = UDim2.fromScale(0, 1),
                    BackgroundColor3 = self.Window.Theme.Accent,
                    BorderSizePixel = 0,
                }, track)
                addCorner(fill, 8)
                self.Window:_addTheme(title, "TextColor3", "Text")
                self.Window:_addTheme(valueLabel, "TextColor3", "Muted")
                self.Window:_addTheme(track, "BackgroundColor3", "Input")
                self.Window:_addTheme(fill, "BackgroundColor3", "Accent")

                local function apply(value)
                    local number = clamp(tonumber(value) or minimum, minimum, maximum)
                    local alpha = maximum == minimum and 0 or (number - minimum) / (maximum - minimum)
                    valueLabel.Text = formatNumber(number)
                    tween(fill, 0.12, { Size = UDim2.fromScale(alpha, 1) })
                    return number
                end
                local control = self.Window:_registerControl(controlOptions.Flag, controlOptions.Default or minimum, apply, controlOptions.Callback)
                control.Frame = row
                control.Instance = track
                return control
            end

            function section:CreateInput(controlOptions)
                controlOptions = controlOptions or {}
                local row = self:_row(43, controlOptions.Name)
                local title = makeText(row, controlOptions.Name or "Input", 12, self.Window.Theme.Text, Enum.Font.GothamMedium, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(0.42, -5, 1, 0),
                })
                local textBox = make("TextBox", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -1, 0.5, 0),
                    Size = UDim2.new(0.58, -4, 0, 33),
                    BackgroundColor3 = self.Window.Theme.Input,
                    Text = tostring(controlOptions.Default or ""),
                    PlaceholderText = controlOptions.Placeholder or "Enter a value...",
                    PlaceholderColor3 = self.Window.Theme.Muted,
                    TextColor3 = self.Window.Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                }, row)
                addCorner(textBox, 7)
                addPadding(textBox, 9, 8, 0, 0)

                self.Window:_addTheme(title, "TextColor3", "Text")
                self.Window:_addTheme(textBox, "BackgroundColor3", "Input")
                self.Window:_addTheme(textBox, "TextColor3", "Text")
                self.Window:_addTheme(textBox, "PlaceholderColor3", "Muted")
                local function apply(value)
                    local result = value
                    if controlOptions.InputType == "number" then
                        result = tonumber(value)
                        if result == nil then
                            result = tonumber(controlOptions.Default) or 0
                        end
                        textBox.Text = tostring(result)
                        return result
                    end
                    result = tostring(value == nil and "" or value)
                    textBox.Text = result
                    return result
                end
                local inputDefault = controlOptions.Default or (controlOptions.InputType == "number" and 0 or "")
                if controlOptions.InputType == "number" then
                    inputDefault = tonumber(inputDefault) or 0
                end
                local control = self.Window:_registerControl(controlOptions.Flag, inputDefault, apply, controlOptions.Callback)
                control.Frame = row
                control.Instance = textBox
                textBox.FocusLost:Connect(function(enterPressed)
                    if not enterPressed and controlOptions.FireOnFocusLost == false then
                        return
                    end
                    local value = textBox.Text
                    if controlOptions.InputType == "number" then
                        local number = tonumber(value)
                        if number == nil then
                            self.Window:Notify({ Title = "Invalid number", Content = "Please enter a valid number.", Type = "Error" })
                            textBox.Text = tostring(control:GetValue())
                            return
                        end
                        value = number
                    end
                    control:SetValue(value)
                end)
                table.insert(self.Controls, { Frame = row, Object = textBox, Label = title })
                return control
            end

            function section:CreateDropdown(controlOptions)
                controlOptions = controlOptions or {}
                local optionsList = controlOptions.Options or {}
                local multi = controlOptions.Multi == true
                local row = self:_row(43, controlOptions.Name)
                local title = makeText(row, controlOptions.Name or "Dropdown", 12, self.Window.Theme.Text, Enum.Font.GothamMedium, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(0.44, -5, 1, 0),
                })
                local selectedLabel = makeText(row, "Select...", 11, self.Window.Theme.Muted, Enum.Font.Gotham, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -29, 0.5, 0),
                    Size = UDim2.new(0.56, -4, 0, 32),
                    TextXAlignment = Enum.TextXAlignment.Right,
                })
                local dropButton = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -1, 0.5, 0),
                    Size = UDim2.fromOffset(25, 32),
                    BackgroundColor3 = self.Window.Theme.Input,
                    Text = "⌄",
                    TextColor3 = self.Window.Theme.Text,
                    TextSize = 16,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(dropButton, 7)
                self.Window:_addTheme(title, "TextColor3", "Text")
                self.Window:_addTheme(dropButton, "BackgroundColor3", "Input")
                self.Window:_addTheme(dropButton, "TextColor3", "Text")
                self.Window:_addTheme(selectedLabel, "TextColor3", "Text")

                local function normalize(value)
                    if multi then
                        local selected = {}
                        if type(value) == "table" then
                            for _, item in ipairs(value) do
                                if table.find(optionsList, item) then
                                    table.insert(selected, item)
                                end
                            end
                        end
                        return selected
                    end
                    if table.find(optionsList, value) then
                        return value
                    end
                    return optionsList[1]
                end

                local function display(value)
                    if multi then
                        selectedLabel.Text = #value > 0 and table.concat(value, ", ") or "Select..."
                    else
                        selectedLabel.Text = value ~= nil and tostring(value) or "Select..."
                    end
                    local hasValue = (multi and #value > 0) or (not multi and value ~= nil)
                    selectedLabel.TextColor3 = hasValue and self.Window.Theme.Text or self.Window.Theme.Muted
                end

                local control = self.Window:_registerControl(controlOptions.Flag, normalize(controlOptions.Default), function(value)
                    local normalized = normalize(value)
                    display(normalized)
                    return normalized
                end, controlOptions.Callback)
                control.Frame = row
                control.Instance = dropButton

                local function openOptions()
                    local popup = make("Frame", {
                        BackgroundColor3 = self.Window.Theme.Panel,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                    })
                    addCorner(popup, 9)
                    addStroke(popup, self.Window.Theme.Stroke, 0.1, 1)
                    local list = make("ScrollingFrame", {
                        Position = UDim2.fromOffset(5, 5),
                        Size = UDim2.new(1, -10, 1, -10),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 3,
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    }, popup)
                    addList(list, Enum.FillDirection.Vertical, 4)
                    for _, option in ipairs(optionsList) do
                        local optionButton = make("TextButton", {
                            Size = UDim2.new(1, -2, 0, 31),
                            BackgroundColor3 = self.Window.Theme.Panel2,
                            BackgroundTransparency = 0.15,
                            Text = tostring(option),
                            TextColor3 = self.Window.Theme.Text,
                            TextSize = 11,
                            Font = Enum.Font.Gotham,
                            AutoButtonColor = false,
                            BorderSizePixel = 0,
                        }, list)
                        addCorner(optionButton, 6)
                        optionButton.Activated:Connect(function()
                            if multi then
                                local current = table.clone(control:GetValue() or {})
                                local index = table.find(current, option)
                                if index then
                                    table.remove(current, index)
                                else
                                    table.insert(current, option)
                                end
                                control:SetValue(current)
                            else
                                control:SetValue(option)
                                self.Window:_closePopup()
                            end
                        end)
                    end
                    local popupHeight = math.min(220, math.max(42, #optionsList * 35 + 10))
                    self.Window:_openPopup(dropButton, popup, 210, popupHeight)
                end
                dropButton.Activated:Connect(openOptions)
                selectedLabel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        openOptions()
                    end
                end)

                control.SetOptions = function(_, newOptions)
                    optionsList = type(newOptions) == "table" and newOptions or {}
                    control:SetValue(multi and {} or optionsList[1], true)
                end
                table.insert(self.Controls, { Frame = row, Object = dropButton, Label = title })
                return control
            end

            function section:CreateKeybind(controlOptions)
                controlOptions = controlOptions or {}
                local row = self:_row(43, controlOptions.Name)
                local title = makeText(row, controlOptions.Name or "Keybind", 12, self.Window.Theme.Text, Enum.Font.GothamMedium, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(1, -105, 1, 0),
                })
                local keyButton = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -1, 0.5, 0),
                    Size = UDim2.fromOffset(92, 32),
                    BackgroundColor3 = self.Window.Theme.Input,
                    Text = tostring(controlOptions.Default or "None"),
                    TextColor3 = self.Window.Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamSemibold,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(keyButton, 7)
                self.Window:_addTheme(title, "TextColor3", "Text")
                self.Window:_addTheme(keyButton, "BackgroundColor3", "Input")
                self.Window:_addTheme(keyButton, "TextColor3", "Text")

                local function apply(value)
                    local name = "None"
                    if typeof(value) == "EnumItem" then
                        name = value.Name
                    elseif type(value) == "string" then
                        name = value
                    end
                    keyButton.Text = name == "" and "None" or name
                    return name
                end
                local control = self.Window:_registerControl(controlOptions.Flag, controlOptions.Default or "None", apply, controlOptions.Callback)
                control.Frame = row
                control.Instance = keyButton
                self.Window._controls[control.Flag].IsKeybind = true
                keyButton.Activated:Connect(function()
                    self.Window._keybindCapture = control
                    keyButton.Text = "Press key..."
                end)
                table.insert(self.Controls, { Frame = row, Object = keyButton, Label = title })
                return control
            end

            function section:CreateColorPicker(controlOptions)
                controlOptions = controlOptions or {}
                local row = self:_row(43, controlOptions.Name)
                local title = makeText(row, controlOptions.Name or "Color", 12, self.Window.Theme.Text, Enum.Font.GothamMedium, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(1, -75, 1, 0),
                })
                local swatch = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -1, 0.5, 0),
                    Size = UDim2.fromOffset(55, 28),
                    BackgroundColor3 = typeof(controlOptions.Default) == "Color3" and controlOptions.Default or Color3.fromRGB(135, 92, 255),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(swatch, 7)
                local swatchStroke = addStroke(swatch, self.Window.Theme.Stroke, 0.2, 1)
                self.Window:_addTheme(title, "TextColor3", "Text")
                self.Window:_addTheme(swatchStroke, "Color", "Stroke")

                local control = self.Window:_registerControl(controlOptions.Flag, controlOptions.Default or Color3.fromRGB(135, 92, 255), function(value)
                    if typeof(value) ~= "Color3" then
                        return swatch.BackgroundColor3
                    end
                    swatch.BackgroundColor3 = value
                    return value
                end, controlOptions.Callback)
                control.Frame = row
                control.Instance = swatch

                local palette = controlOptions.Palette or {
                    Color3.fromRGB(135, 92, 255), Color3.fromRGB(91, 144, 255), Color3.fromRGB(0, 190, 170),
                    Color3.fromRGB(72, 196, 130), Color3.fromRGB(255, 190, 75), Color3.fromRGB(255, 115, 95),
                    Color3.fromRGB(235, 83, 102), Color3.fromRGB(245, 105, 180), Color3.fromRGB(245, 246, 255),
                    Color3.fromRGB(25, 27, 35), Color3.fromRGB(105, 113, 132), Color3.fromRGB(80, 115, 170),
                }

                swatch.Activated:Connect(function()
                    local popup = make("Frame", {
                        BackgroundColor3 = self.Window.Theme.Panel,
                        BorderSizePixel = 0,
                    })
                    addCorner(popup, 9)
                    addStroke(popup, self.Window.Theme.Stroke, 0.1, 1)
                    local grid = make("Frame", {
                        Position = UDim2.fromOffset(8, 8),
                        Size = UDim2.new(1, -16, 1, -16),
                        BackgroundTransparency = 1,
                    }, popup)
                    make("UIGridLayout", {
                        CellSize = UDim2.fromOffset(32, 32),
                        CellPadding = UDim2.fromOffset(7, 7),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }, grid)
                    for _, color in ipairs(palette) do
                        local colorButton = make("TextButton", {
                            BackgroundColor3 = color,
                            Text = "",
                            AutoButtonColor = false,
                            BorderSizePixel = 0,
                        }, grid)
                        addCorner(colorButton, 7)
                        colorButton.Activated:Connect(function()
                            control:SetValue(color)
                            self.Window:_closePopup()
                        end)
                    end
                    self.Window:_openPopup(swatch, popup, 190, 145)
                end)
                table.insert(self.Controls, { Frame = row, Object = swatch, Label = title })
                return control
            end

            function section:CreateTextArea(controlOptions)
                controlOptions = controlOptions or {}
                local row = self:_row(controlOptions.Height or 120, controlOptions.Name or "TextArea")
                local title = makeText(row, controlOptions.Name or "Text area", 11, self.Window.Theme.Muted, Enum.Font.GothamSemibold, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(1, 0, 0, 18),
                })
                local box = make("TextBox", {
                    Position = UDim2.fromOffset(0, 21),
                    Size = UDim2.new(1, 0, 1, -21),
                    BackgroundColor3 = self.Window.Theme.Input,
                    TextColor3 = self.Window.Theme.Text,
                    PlaceholderColor3 = self.Window.Theme.Muted,
                    PlaceholderText = controlOptions.Placeholder or "Enter text...",
                    Text = tostring(controlOptions.Default or ""),
                    TextSize = controlOptions.TextSize or 12,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = controlOptions.TextWrapped == true,
                    ClearTextOnFocus = false,
                    MultiLine = true,
                    TextEditable = controlOptions.ReadOnly ~= true,
                    BorderSizePixel = 0,
                }, row)
                addCorner(box, 8)
                addPadding(box, 9, 9, 7, 7)
                self.Window:_addTheme(title, "TextColor3", "Muted")
                self.Window:_addTheme(box, "BackgroundColor3", "Input")
                self.Window:_addTheme(box, "TextColor3", "Text")
                self.Window:_addTheme(box, "PlaceholderColor3", "Muted")

                local control = self.Window:_registerControl(
                    controlOptions.Flag,
                    tostring(controlOptions.Default or ""),
                    function(value)
                        local text = tostring(value or "")
                        box.Text = text
                        return text
                    end,
                    controlOptions.Callback
                )
                control.Frame = row
                control.Instance = box
                box.FocusLost:Connect(function(enterPressed)
                    control:SetValue(box.Text)
                    if enterPressed and type(controlOptions.OnSubmit) == "function" then
                        self.Window:_callback(controlOptions.OnSubmit, box.Text)
                    end
                end)
                table.insert(self.Controls, { Frame = row, Object = box, Label = title })
                control.TextBox = box
                return control
            end

            function section:CreateSearchBox(controlOptions)
                controlOptions = controlOptions or {}
                controlOptions.Name = controlOptions.Name or "Search"
                controlOptions.Placeholder = controlOptions.Placeholder or "Type to search..."
                controlOptions.Height = controlOptions.Height or 43
                controlOptions.InputType = "text"
                local row = self:_row(controlOptions.Height, controlOptions.Name)
                local title = makeText(row, controlOptions.Name, 11, self.Window.Theme.Muted, Enum.Font.GothamSemibold, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(1, 0, 0, 16),
                })
                local box = make("TextBox", {
                    Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 27),
                    BackgroundColor3 = self.Window.Theme.Input,
                    TextColor3 = self.Window.Theme.Text,
                    PlaceholderColor3 = self.Window.Theme.Muted,
                    PlaceholderText = controlOptions.Placeholder,
                    Text = tostring(controlOptions.Default or ""),
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    ClearTextOnFocus = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(box, 7)
                addPadding(box, 8, 8, 0, 0)
                self.Window:_addTheme(title, "TextColor3", "Muted")
                self.Window:_addTheme(box, "BackgroundColor3", "Input")
                self.Window:_addTheme(box, "TextColor3", "Text")
                self.Window:_addTheme(box, "PlaceholderColor3", "Muted")

                local control = self.Window:_registerControl(
                    controlOptions.Flag,
                    tostring(controlOptions.Default or ""),
                    function(value)
                        local text = tostring(value or "")
                        if box.Text ~= text then
                            box.Text = text
                        end
                        return text
                    end,
                    controlOptions.Callback
                )
                control.Frame = row
                control.Instance = box
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    control:SetValue(box.Text)
                end)
                table.insert(self.Controls, { Frame = row, Object = box, Label = title })
                control.TextBox = box
                return control
            end

            function section:CreateTable(tableOptions)
                tableOptions = tableOptions or {}
                local headers = type(tableOptions.Headers) == "table" and tableOptions.Headers or { "Name", "Value" }
                local columnCount = math.max(1, #headers)
                local rowHeight = math.max(120, tonumber(tableOptions.Height) or 190)
                local row = self:_row(rowHeight, tableOptions.Name or "Table")
                local title = makeText(row, tableOptions.Name or "Table", 11, self.Window.Theme.Muted, Enum.Font.GothamBold, {
                    Position = UDim2.fromOffset(1, 0),
                    Size = UDim2.new(1, 0, 0, 18),
                })
                local content = make("ScrollingFrame", {
                    Position = UDim2.fromOffset(0, 21),
                    Size = UDim2.new(1, 0, 1, -21),
                    BackgroundColor3 = self.Window.Theme.Input,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = self.Window.Theme.Accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                }, row)
                addCorner(content, 8)
                addPadding(content, 5, 5, 5, 5)
                local layout = addList(content, Enum.FillDirection.Vertical, 4)
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                self.Window:_addTheme(title, "TextColor3", "Muted")
                self.Window:_addTheme(content, "BackgroundColor3", "Input")
                self.Window:_addTheme(content, "ScrollBarImageColor3", "Accent")

                local tableObject = {
                    Frame = row,
                    Content = content,
                    Headers = table.clone(headers),
                    Rows = {},
                }

                local function makeCells(parent, values, isHeader)
                    local cells = make("Frame", {
                        Size = UDim2.new(1, 0, 0, isHeader and 27 or 25),
                        BackgroundColor3 = isHeader and self.Window.Theme.Panel2 or self.Window.Theme.Panel,
                        BackgroundTransparency = isHeader and 0 or 0.22,
                        BorderSizePixel = 0,
                    }, parent)
                    addCorner(cells, 5)
                    self.Window:_addTheme(cells, "BackgroundColor3", isHeader and "Panel2" or "Panel")
                    for index = 1, columnCount do
                        local cellValue = values[index]
                        local cell = makeText(cells, cellValue == nil and "" or tostring(cellValue), 9,
                            isHeader and self.Window.Theme.Text or self.Window.Theme.Muted,
                            isHeader and Enum.Font.GothamBold or Enum.Font.Gotham,
                            {
                                Position = UDim2.new((index - 1) / columnCount, 0, 0, 0),
                                Size = UDim2.new(1 / columnCount, -4, 1, 0),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextTruncate = Enum.TextTruncate.AtEnd,
                            }
                        )
                        addPadding(cell, 4, 2, 0, 0)
                        self.Window:_addTheme(cell, "TextColor3", isHeader and "Text" or "Muted")
                    end
                    return cells
                end

                tableObject.HeaderFrame = makeCells(content, headers, true)

                function tableObject:Clear()
                    for _, item in ipairs(self.Rows) do
                        if item and item.Parent then
                            section.Window:_removeThemeBindings(item)
                            item:Destroy()
                        end
                    end
                    table.clear(self.Rows)
                end

                function tableObject:AddRow(values)
                    values = type(values) == "table" and values or { values }
                    local item = makeCells(content, values, false)
                    table.insert(self.Rows, item)
                    return item
                end

                function tableObject:SetRows(rows)
                    self:Clear()
                    for _, values in ipairs(type(rows) == "table" and rows or {}) do
                        self:AddRow(values)
                    end
                end

                function tableObject:SetHeaders(nextHeaders)
                    if type(nextHeaders) ~= "table" or #nextHeaders == 0 then
                        return false, "Headers must be a non-empty array"
                    end
                    self.Headers = table.clone(nextHeaders)
                    columnCount = #self.Headers
                    if self.HeaderFrame and self.HeaderFrame.Parent then
                        section.Window:_removeThemeBindings(self.HeaderFrame)
                        self.HeaderFrame:Destroy()
                    end
                    self:Clear()
                    self.HeaderFrame = makeCells(content, self.Headers, true)
                    return true
                end

                tableObject:SetRows(tableOptions.Rows or {})
                table.insert(self.Controls, { Frame = row, Object = content })
                return tableObject
            end

            function section:CreateConsole(consoleOptions)
                consoleOptions = consoleOptions or {}
                local rowHeight = tonumber(consoleOptions.Height) or 190
                local maxLines = math.max(10, math.floor(tonumber(consoleOptions.MaxLines) or 80))
                local row = self:_row(rowHeight, consoleOptions.Name or "Console")
                local header = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundTransparency = 1,
                }, row)
                local title = makeText(header, consoleOptions.Name or "Console", 11, self.Window.Theme.Muted, Enum.Font.GothamBold, {
                    Position = UDim2.fromOffset(1, 0),
                    Size = UDim2.new(1, -72, 1, 0),
                })
                local clearButton = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(58, 22),
                    BackgroundColor3 = self.Window.Theme.Panel2,
                    Text = "Clear",
                    TextColor3 = self.Window.Theme.Text,
                    TextSize = 9,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, header)
                addCorner(clearButton, 6)
                local panel = make("ScrollingFrame", {
                    Position = UDim2.fromOffset(0, 28),
                    Size = UDim2.new(1, 0, 1, -28),
                    BackgroundColor3 = self.Window.Theme.Input,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = self.Window.Theme.Accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                }, row)
                addCorner(panel, 8)
                addPadding(panel, 8, 8, 6, 7)
                local layout = addList(panel, Enum.FillDirection.Vertical, 3)
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                self.Window:_addTheme(title, "TextColor3", "Muted")
                self.Window:_addTheme(clearButton, "BackgroundColor3", "Panel2")
                self.Window:_addTheme(clearButton, "TextColor3", "Text")
                self.Window:_addTheme(panel, "BackgroundColor3", "Input")
                self.Window:_addTheme(panel, "ScrollBarImageColor3", "Accent")

                local entries = {}
                local destroyed = false
                local console = {
                    Frame = row,
                    Panel = panel,
                    Lines = entries,
                    MaxLines = maxLines,
                }

                local levelColors = {
                    Info = self.Window.Theme.Text,
                    Success = self.Window.Theme.Success,
                    Warn = Color3.fromRGB(245, 190, 85),
                    Error = self.Window.Theme.Danger,
                }

                function console:Append(message, level)
                    if destroyed then
                        return false
                    end
                    level = tostring(level or "Info")
                    local normalizedLevel = level:sub(1, 1):upper() .. level:sub(2):lower()
                    local color = levelColors[normalizedLevel] or self.WindowTheme or Color3.new(1, 1, 1)
                    local line = make("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Text = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), normalizedLevel, tostring(message)),
                        TextColor3 = color,
                        TextSize = 10,
                        Font = Enum.Font.Code,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        TextWrapped = true,
                    }, panel)
                    table.insert(entries, line)
                    while #entries > self.MaxLines do
                        local oldest = table.remove(entries, 1)
                        if oldest and oldest.Parent then
                            oldest:Destroy()
                        end
                    end
                    task.defer(function()
                        if not destroyed and panel.Parent then
                            panel.CanvasPosition = Vector2.new(0, math.max(0, panel.AbsoluteCanvasSize.Y - panel.AbsoluteSize.Y))
                        end
                    end)
                    return true
                end

                function console:Print(message)
                    return self:Append(message, "Info")
                end

                function console:Warn(message)
                    return self:Append(message, "Warn")
                end

                function console:Error(message)
                    return self:Append(message, "Error")
                end

                function console:Success(message)
                    return self:Append(message, "Success")
                end

                function console:Clear()
                    for _, line in ipairs(entries) do
                        if line and line.Parent then
                            line:Destroy()
                        end
                    end
                    table.clear(entries)
                end

                function console:SetMaxLines(value)
                    self.MaxLines = math.max(10, math.floor(tonumber(value) or 80))
                    while #entries > self.MaxLines do
                        local oldest = table.remove(entries, 1)
                        if oldest and oldest.Parent then
                            oldest:Destroy()
                        end
                    end
                end

                function console:GetLines()
                    local result = {}
                    for _, line in ipairs(entries) do
                        table.insert(result, line.Text)
                    end
                    return result
                end

                function console:Destroy()
                    destroyed = true
                    self:Clear()
                    if row and row.Parent then
                        section.Window:_removeThemeBindings(row)
                        row:Destroy()
                    end
                end

                console.WindowTheme = self.Window.Theme.Text
                clearButton.Activated:Connect(function()
                    console:Clear()
                end)

                table.insert(self.Controls, { Frame = row, Object = panel })
                for _, message in ipairs(consoleOptions.Lines or {}) do
                    console:Append(message, "Info")
                end
                return console
            end

            function section:CreateImage(imageOptions)
                imageOptions = imageOptions or {}
                local imageHeight = tonumber(imageOptions.Height) or 150
                local row = self:_row(imageHeight, imageOptions.Name or "Image")
                local image = make("ImageLabel", {
                    Name = "Image",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = self.Window.Theme.Input,
                    BackgroundTransparency = 0,
                    Image = "",
                    ScaleType = imageOptions.ScaleType or Enum.ScaleType.Fit,
                    BorderSizePixel = 0,
                }, row)
                addCorner(image, 9)
                self.Window:_addTheme(image, "BackgroundColor3", "Input")

                local function resolveImage(source)
                    local value = tostring(source or "")
                    if value == "" then
                        return ""
                    end
                    if not value:match("^rbxassetid://") and not value:match("^rbxasset://") then
                        local success, asset = Library.Executor:GetCustomAsset(value)
                        if success and type(asset) == "string" then
                            return asset
                        end
                    end
                    return value
                end

                local function setImage(source)
                    local imageValue = resolveImage(source)
                    local success, reason = pcall(function()
                        image.Image = imageValue
                    end)
                    if not success then
                        self.Window:_reportError(reason, "Image load failed")
                        return false, tostring(reason)
                    end
                    return true
                end

                local ok, reason = setImage(imageOptions.Image or imageOptions.Source)
                if not ok then
                    self.Window:Notify({ Title = "Image unavailable", Content = tostring(reason), Type = "Error" })
                end

                local object = {
                    Frame = row,
                    ImageLabel = image,
                    SetImage = function(_, source)
                        return setImage(source)
                    end,
                    Destroy = function()
                        if row and row.Parent then
                            self.Window:_removeThemeBindings(row)
                            row:Destroy()
                        end
                    end,
                }
                table.insert(self.Controls, { Frame = row, Object = image })
                return object
            end

            function section:CreateVideoPlayer(videoOptions)
                videoOptions = videoOptions or {}
                local window = self.Window
                local row = self:_row(videoOptions.Height or 262, videoOptions.Name or "VideoPlayer")
                local preview = make("Frame", {
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 158),
                    BackgroundColor3 = Color3.fromRGB(5, 7, 12),
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                }, row)
                addCorner(preview, 9)
                local hint = makeText(preview, "Enter a Roblox video asset ID or use a video adapter", 11, Color3.fromRGB(205, 211, 224), Enum.Font.Gotham, {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.new(1, -24, 0, 42),
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Center,
                })
                local videoFrame = nil
                local adapterPlayer = nil
                local adapter = videoOptions.Adapter or window.Options.VideoAdapter
                local status = makeText(row, "No video loaded", 10, window.Theme.Muted, Enum.Font.Gotham, {
                    Position = UDim2.fromOffset(1, 162),
                    Size = UDim2.new(1, -2, 0, 16),
                })
                window:_addTheme(status, "TextColor3", "Muted")

                local playButton = make("TextButton", {
                    Position = UDim2.fromOffset(0, 182),
                    Size = UDim2.fromOffset(62, 27),
                    BackgroundColor3 = window.Theme.Accent,
                    Text = "Play",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, row)
                addCorner(playButton, 7)
                window:_addTheme(playButton, "BackgroundColor3", "Accent")
                local loopButton = make("TextButton", {
                    Position = UDim2.fromOffset(68, 182),
                    Size = UDim2.fromOffset(62, 27),
                    BackgroundColor3 = window.Theme.Panel2,
                    Text = videoOptions.Looped == false and "Loop: Off" or "Loop: On",
                    TextColor3 = window.Theme.Text,
                    TextSize = 9,
                    Font = Enum.Font.GothamSemibold,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, row)
                addCorner(loopButton, 7)
                window:_addTheme(loopButton, "BackgroundColor3", "Panel2")
                window:_addTheme(loopButton, "TextColor3", "Text")

                local sourceBox = make("TextBox", {
                    Position = UDim2.fromOffset(0, 215),
                    Size = UDim2.new(1, -68, 0, 30),
                    BackgroundColor3 = window.Theme.Input,
                    TextColor3 = window.Theme.Text,
                    PlaceholderColor3 = window.Theme.Muted,
                    PlaceholderText = "rbxassetid://123456789  or  local.webm",
                    Text = tostring(videoOptions.Source or videoOptions.Video or ""),
                    TextSize = 10,
                    Font = Enum.Font.Code,
                    ClearTextOnFocus = false,
                    BorderSizePixel = 0,
                }, row)
                addCorner(sourceBox, 7)
                addPadding(sourceBox, 7, 7, 0, 0)
                window:_addTheme(sourceBox, "BackgroundColor3", "Input")
                window:_addTheme(sourceBox, "TextColor3", "Text")
                window:_addTheme(sourceBox, "PlaceholderColor3", "Muted")

                local loadButton = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 215),
                    Size = UDim2.fromOffset(62, 30),
                    BackgroundColor3 = window.Theme.Accent2,
                    Text = "Load",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, row)
                addCorner(loadButton, 7)
                window:_addTheme(loadButton, "BackgroundColor3", "Accent2")

                local looped = videoOptions.Looped ~= false
                local destroyed = false
                local heartbeatConnection = nil

                local function setStatus(message)
                    status.Text = tostring(message)
                end

                local function pauseVideo()
                    if adapterPlayer and type(adapterPlayer.Pause) == "function" then
                        pcall(adapterPlayer.Pause, adapterPlayer)
                    elseif videoFrame then
                        pcall(function()
                            videoFrame:Pause()
                        end)
                    end
                    playButton.Text = "Play"
                end

                local function playVideo()
                    if adapterPlayer and type(adapterPlayer.Play) == "function" then
                        local success, reason = pcall(adapterPlayer.Play, adapterPlayer)
                        if not success then
                            setStatus("Adapter play error: " .. tostring(reason))
                            return false, reason
                        end
                        playButton.Text = "Pause"
                        return true
                    end
                    if videoFrame then
                        local success, reason = pcall(function()
                            videoFrame:Play()
                        end)
                        if not success then
                            setStatus("Playback error: " .. tostring(reason))
                            return false, reason
                        end
                        playButton.Text = "Pause"
                        setStatus("Playing");
                        return true
                    end
                    setStatus("Load a supported video source first")
                    return false, "No video is loaded"
                end

                local function clearPlayer()
                    if heartbeatConnection then
                        heartbeatConnection:Disconnect()
                        heartbeatConnection = nil
                    end
                    if videoFrame then
                        pcall(function()
                            videoFrame:Pause()
                            videoFrame:Destroy()
                        end)
                        videoFrame = nil
                    end
                    if adapterPlayer then
                        pcall(function()
                            if type(adapterPlayer.Destroy) == "function" then
                                adapterPlayer:Destroy()
                            end
                        end)
                        adapterPlayer = nil
                    end
                    hint.Visible = true
                    playButton.Text = "Play"
                end

                local function loadSource(source)
                    source = tostring(source or ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if source == "" then
                        setStatus("Enter a video source")
                        return false, "Video source is empty"
                    end

                    clearPlayer()
                    local isWebM = source:lower():match("%.webm([%?#].*)?$") ~= nil

                    if type(adapter) == "table" and type(adapter.Create) == "function" then
                        local success, result = pcall(adapter.Create, {
                            Parent = preview,
                            Source = source,
                            Looped = looped,
                            Window = window,
                            Row = row,
                        })
                        if success and type(result) == "table" then
                            adapterPlayer = result
                            hint.Visible = false
                            setStatus("Loaded through custom video adapter")
                            return true
                        end
                        local reason = success and "Adapter.Create must return a player table" or tostring(result)
                        setStatus("Video adapter error: " .. reason)
                        return false, reason
                    end

                    if isWebM then
                        setStatus("WEBM needs a custom decoder adapter; Roblox VideoFrame cannot play local WEBM files")
                        hint.Text = "WEBM is not supported by the built-in Roblox player. Add VideoAdapter.Create() to connect a compatible decoder."
                        hint.Visible = true
                        return false, "No WEBM adapter is configured"
                    end

                    local assetId = source
                    if assetId:match("^%d+$") then
                        assetId = "rbxassetid://" .. assetId
                    end
                    if not assetId:match("^rbxassetid://%d+$") then
                        setStatus("Use a Roblox video asset ID or configure a custom adapter")
                        return false, "Unsupported source format"
                    end

                    local success, newVideo = pcall(Instance.new, "VideoFrame")
                    if not success then
                        setStatus("VideoFrame is unavailable in this client")
                        return false, tostring(newVideo)
                    end
                    videoFrame = newVideo
                    videoFrame.Name = "UniversalUIVideo"
                    videoFrame.Size = UDim2.fromScale(1, 1)
                    videoFrame.BackgroundTransparency = 1
                    videoFrame.BorderSizePixel = 0
                    videoFrame.Looped = looped
                    videoFrame.Volume = clamp(tonumber(videoOptions.Volume) or 1, 0, 1)
                    videoFrame.Video = assetId
                    videoFrame.Parent = preview
                    hint.Visible = false
                    setStatus("Loading Roblox video asset...")

                    local loadedConnection
                    loadedConnection = videoFrame.Loaded:Connect(function()
                        if loadedConnection then
                            loadedConnection:Disconnect()
                            loadedConnection = nil
                        end
                        if not destroyed and videoFrame then
                            setStatus("Video loaded · " .. tostring(math.floor(videoFrame.TimeLength)) .. "s")
                            playVideo()
                        end
                    end)
                    local statusAccumulator = 0
                    heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
                        if destroyed or not videoFrame or not videoFrame.Parent then
                            if heartbeatConnection then
                                heartbeatConnection:Disconnect()
                                heartbeatConnection = nil
                            end
                            return
                        end
                        if videoFrame.Playing then
                            statusAccumulator += deltaTime
                            if statusAccumulator >= 0.5 then
                                statusAccumulator = 0
                                setStatus(string.format("Playing · %d / %d sec", math.floor(videoFrame.TimePosition), math.floor(videoFrame.TimeLength)))
                            end
                        end
                    end)
                    table.insert(window._connections, heartbeatConnection)

                    local endedConnection = videoFrame.Ended:Connect(function()
                        if not looped then
                            playButton.Text = "Play"
                            setStatus("Playback ended")
                        end
                    end)
                    table.insert(window._connections, endedConnection)
                    return true
                end

                playButton.Activated:Connect(function()
                    local currentlyPlaying = videoFrame and videoFrame.Playing
                    if adapterPlayer and type(adapterPlayer.IsPlaying) == "boolean" then
                        currentlyPlaying = adapterPlayer.IsPlaying
                    end
                    if currentlyPlaying then
                        pauseVideo()
                    else
                        playVideo()
                    end
                end)

                loopButton.Activated:Connect(function()
                    looped = not looped
                    loopButton.Text = looped and "Loop: On" or "Loop: Off"
                    if videoFrame then
                        videoFrame.Looped = looped
                    end
                    if adapterPlayer and type(adapterPlayer.SetLooped) == "function" then
                        pcall(adapterPlayer.SetLooped, adapterPlayer, looped)
                    end
                end)

                loadButton.Activated:Connect(function()
                    local ok, reason = loadSource(sourceBox.Text)
                    if not ok then
                        window:Notify({ Title = "Video not loaded", Content = tostring(reason), Type = "Info", Duration = 5 })
                    end
                end)

                local player = {
                    Frame = row,
                    Preview = preview,
                    SourceBox = sourceBox,
                    VideoFrame = function()
                        return videoFrame
                    end,
                    Play = playVideo,
                    Pause = pauseVideo,
                    Load = function(_, source)
                        return loadSource(source)
                    end,
                    SetSource = function(_, source)
                        sourceBox.Text = tostring(source or "")
                        return loadSource(source)
                    end,
                    Destroy = function()
                        if destroyed then
                            return
                        end
                        destroyed = true
                        clearPlayer()
                        if row and row.Parent then
                            window:_removeThemeBindings(row)
                            row:Destroy()
                        end
                    end,
                }

                table.insert(self.Controls, { Frame = row, Object = preview })
                if videoOptions.Source or videoOptions.Video then
                    task.defer(function()
                        if not destroyed then
                            local ok, reason = loadSource(sourceBox.Text)
                            if not ok then
                                setStatus(tostring(reason))
                            end
                        end
                    end)
                end
                return player
            end

            function section:CreateLabel(text)
                local row = self:_row(26, "Label")
                local label = makeText(row, text or "Label", 12, self.Window.Theme.Muted, Enum.Font.Gotham, {
                    Size = UDim2.fromScale(1, 1),
                })
                self.Window:_addTheme(label, "TextColor3", "Muted")
                table.insert(self.Controls, { Frame = row, Object = label })
                return {
                    Frame = row,
                    Label = label,
                    SetText = function(_, value)
                        label.Text = tostring(value)
                    end,
                }
            end

            function section:CreateParagraph(paragraphOptions)
                paragraphOptions = paragraphOptions or {}
                local row = self:_row(52, "Paragraph")
                local titleLabel = makeText(row, paragraphOptions.Title or "Information", 12, self.Window.Theme.Text, Enum.Font.GothamBold, {
                    Position = UDim2.fromOffset(1, 0),
                    Size = UDim2.new(1, -2, 0, 19),
                })
                local bodyLabel = makeText(row, paragraphOptions.Content or "", 11, self.Window.Theme.Muted, Enum.Font.Gotham, {
                    Position = UDim2.fromOffset(1, 20),
                    Size = UDim2.new(1, -2, 0, 32),
                    TextWrapped = true,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextTruncate = Enum.TextTruncate.None,
                })
                self.Window:_addTheme(titleLabel, "TextColor3", "Text")
                self.Window:_addTheme(bodyLabel, "TextColor3", "Muted")
                table.insert(self.Controls, { Frame = row, Object = bodyLabel })
                return {
                    Frame = row,
                    SetTitle = function(_, value)
                        titleLabel.Text = tostring(value)
                    end,
                    SetText = function(_, value)
                        bodyLabel.Text = tostring(value)
                    end,
                }
            end

            function section:CreateDivider()
                local row = self:_row(9, "Divider")
                local divider = make("Frame", {
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = self.Window.Theme.Stroke,
                    BorderSizePixel = 0,
                }, row)
                self.Window:_addTheme(divider, "BackgroundColor3", "Stroke")
                return row
            end

            function section:CreateCodeBlock(codeOptions)
                codeOptions = codeOptions or {}
                local code = tostring(codeOptions.Code or "-- Add code here")
                local lineCount = 1
                for _ in code:gmatch("\n") do
                    lineCount += 1
                end
                local row = self:_row(math.min(300, math.max(100, lineCount * 17 + 42)), "CodeBlock")
                local codePanel = make("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = self.Window.Theme.Input,
                    BorderSizePixel = 0,
                }, row)
                addCorner(codePanel, 8)
                self.Window:_addTheme(codePanel, "BackgroundColor3", "Input")
                local header = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = self.Window.Theme.Panel2,
                    BorderSizePixel = 0,
                }, codePanel)
                addCorner(header, 8)
                self.Window:_addTheme(header, "BackgroundColor3", "Panel2")
                local codeTitle = makeText(header, codeOptions.Title or "Code", 10, self.Window.Theme.Muted, Enum.Font.GothamSemibold, {
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -86, 1, 0),
                })
                self.Window:_addTheme(codeTitle, "TextColor3", "Muted")
                local copyButton = make("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -7, 0.5, 0),
                    Size = UDim2.fromOffset(62, 22),
                    BackgroundColor3 = self.Window.Theme.Accent,
                    Text = "Copy",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, header)
                addCorner(copyButton, 6)
                self.Window:_addTheme(copyButton, "BackgroundColor3", "Accent")
                local codeScroll = make("ScrollingFrame", {
                    Position = UDim2.fromOffset(7, 35),
                    Size = UDim2.new(1, -14, 1, -42),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    ScrollingDirection = Enum.ScrollingDirection.XY,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.XY,
                }, codePanel)
                local codeLabel = makeText(codeScroll, code, 11, self.Window.Theme.Text, Enum.Font.Code, {
                    Position = UDim2.fromOffset(2, 0),
                    Size = UDim2.new(0, 0, 0, math.max(60, lineCount * 17 + 8)),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = false,
                    TextTruncate = Enum.TextTruncate.None,
                })
                copyButton.Activated:Connect(function()
                    local success, result = Library.Executor:SetClipboard(code)
                    if success then
                        self.Window:Notify({ Title = "Copied", Content = "Code copied to clipboard.", Type = "Success" })
                    else
                        self.Window:Notify({ Title = "Clipboard unavailable", Content = tostring(result), Type = "Info", Duration = 5 })
                    end
                end)
                self.Window:_addTheme(codeLabel, "TextColor3", "Text")
                local codeObject = {
                    Frame = row,
                    SetCode = function(_, nextCode)
                        code = tostring(nextCode or "")
                        lineCount = 1
                        for _ in code:gmatch("\n") do
                            lineCount += 1
                        end
                        codeLabel.Text = code
                        codeLabel.Size = UDim2.new(0, 0, 0, math.max(60, lineCount * 17 + 8))
                        row.Size = UDim2.new(1, 0, 0, math.min(300, math.max(100, lineCount * 17 + 42)))
                    end,
                    GetCode = function()
                        return code
                    end,
                }
                table.insert(self.Controls, { Frame = row, Object = codeLabel })
                return codeObject
            end

            table.insert(self.Sections, section)
            return section
        end

        function tab:Select()
            for _, other in ipairs(self.Window._tabs) do
                local selected = other == self
                other.Page.Visible = selected
                tween(other.Button, 0.13, {
                    BackgroundTransparency = selected and 0 or 1,
                    BackgroundColor3 = self.Window.Theme.Accent,
                    TextColor3 = selected and self.Window.Theme.Text or self.Window.Theme.Muted,
                })
            end
            self.Window.ActiveTab = self
        end

        button.Activated:Connect(function()
            tab:Select()
        end)

        table.insert(self._tabs, tab)
        if #self._tabs == 1 or tabOptions.Selected then
            tab:Select()
        end
        return tab
    end

    function window:CreateCodeTab(name, code)
        local tab = self:CreateTab({ Name = name or "Code", Icon = "</>" })
        local section = tab:CreateSection("Code viewer")
        section:CreateCodeBlock({ Title = name or "Code", Code = code or "-- Your code goes here" })
        return tab
    end

    function window:CreateDiagnosticsTab(tabName)
        local tab = self:CreateTab({ Name = tabName or "Diagnostics", Icon = "◇" })
        local section = tab:CreateSection("Environment capabilities")
        section:CreateParagraph({
            Title = "Detected features",
            Content = "These values are capability checks, not guarantees that every executor behaves the same way. Unsupported APIs are left disabled.",
        })

        local labels = {}
        local capabilities = Library.Executor:GetCapabilities()
        for groupName, group in pairs(capabilities) do
            section:CreateLabel(groupName)
            for key, value in pairs(group) do
                local label = section:CreateLabel(key .. ": " .. tostring(value))
                labels[#labels + 1] = { Label = label, Group = groupName, Key = key }
            end
        end

        section:CreateButton({
            Name = "Refresh capabilities",
            Callback = function()
                local refreshed = Library.Executor:GetCapabilities()
                for _, entry in ipairs(labels) do
                    local group = refreshed[entry.Group]
                    if group then
                        entry.Label:SetText(entry.Key .. ": " .. tostring(group[entry.Key]))
                    end
                end
                self:Notify({ Title = "Diagnostics refreshed", Content = "Capability checks completed.", Type = "Success" })
            end,
        })

        section:CreateButton({
            Name = "Match game UI colors",
            Callback = function()
                local success, reason = self:ApplyGameTheme()
                if success then
                    self:Notify({ Title = "Theme updated", Content = "Sampled visible colors from the game's PlayerGui.", Type = "Success" })
                else
                    self:Notify({ Title = "Theme not changed", Content = tostring(reason), Type = "Info" })
                end
            end,
        })
        return tab
    end

    -- Keybind processing is centralized so only one InputBegan connection is needed.
    table.insert(window._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if window._destroyed then
            return
        end
        if window._popup and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local popup = window._popup
            local point = input.Position
            local popupPosition = popup.AbsolutePosition
            local popupSize = popup.AbsoluteSize
            local inside = point.X >= popupPosition.X and point.X <= popupPosition.X + popupSize.X
                and point.Y >= popupPosition.Y and point.Y <= popupPosition.Y + popupSize.Y
            if not inside then
                window:_closePopup()
            end
        end
        if window._keybindCapture then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local control = window._keybindCapture
                window._keybindCapture = nil
                local keyName = input.KeyCode == Enum.KeyCode.Escape and "None" or input.KeyCode.Name
                control:SetValue(keyName)
            end
            return
        end
        if gameProcessed or UserInputService:GetFocusedTextBox() then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        local toggleKey = window.ToggleKey
        if type(toggleKey) == "string" then
            if toggleKey == input.KeyCode.Name then
                window:Toggle()
                return
            end
        elseif typeof(toggleKey) == "EnumItem" and toggleKey == input.KeyCode then
            window:Toggle()
            return
        end

        for flag, entry in pairs(window._controls) do
            local keyName = window._values[flag]
            if entry.IsKeybind and type(keyName) == "string" and keyName ~= "None" and keyName == input.KeyCode.Name then
                window:_callback(entry.Callback, input.KeyCode, flag)
            end
        end
    end))

    minimizeButton.Activated:Connect(function()
        window:Toggle()
    end)
    closeButton.Activated:Connect(function()
        window:Toggle()
    end)
    launcher.Activated:Connect(function()
        window:Toggle()
    end)

    -- Dragging supports both mouse and touch input.
    local dragInput
    local dragStart
    local startPosition
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            window._dragging = true
            dragInput = input
            dragStart = input.Position
            startPosition = root.Position
        end
    end)

    table.insert(window._connections, UserInputService.InputChanged:Connect(function(input)
        if not window._dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))

    table.insert(window._connections, UserInputService.InputEnded:Connect(function(input)
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            window._dragging = false
            dragInput = nil
        end
    end))

    local function bindCamera()
        if window._cameraConnection then
            window._cameraConnection:Disconnect()
            window._cameraConnection = nil
        end
        local camera = workspace.CurrentCamera
        if camera then
            window._cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                window:_layout()
            end)
        end
    end
    bindCamera()
    table.insert(window._connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        bindCamera()
        window:_layout()
    end))
    local insetSuccess, insetConnection = pcall(function()
        return GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
            window:_layout()
        end)
    end)
    if insetSuccess and insetConnection then
        table.insert(window._connections, insetConnection)
    end

    window:_layout()
    library.Windows[window] = true
    if options.ShowWelcome ~= false then
        task.defer(function()
            if not window._destroyed then
                window:Notify({
                    Title = window.Title,
                    Content = "UniversalUI " .. Library.Version .. " is ready.",
                    Type = "Success",
                    Duration = 3,
                })
            end
        end)
    end

    return window
end

function Library:Destroy()
    for window in pairs(self.Windows) do
        if type(window) == "table" and window.Destroy then
            pcall(function()
                window:Destroy()
            end)
        end
    end
    self._destroyed = true
end

return Library
