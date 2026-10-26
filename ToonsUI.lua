-- ToonsUniverseUI
-- A reusable, mobile-friendly UI library based on the actual Settings GUI, control art, icons, and UI sounds in the supplied Toons Universe place.
-- Place this ModuleScript in ReplicatedStorage and require it from a LocalScript.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Library = {}
Library.__index = Library
Library.Name = "ToonsUniverseUI"
Library.Version = "1.1.0"

-- Image and audio IDs were read from the supplied Toons universe ui.rbxl file.
Library.Assets = {
    Images = {
        PanelBackground = "rbxassetid://133729654246207",
        PanelBorder = "rbxassetid://94570426533034",
        HeaderRibbon = "rbxassetid://88382242978995",
        CloseButton = "rbxassetid://86426826644038",
        PrimaryButton = "rbxassetid://100843560366796",
        SearchIcon = "rbxassetid://106335688597254",
        CurrencyIcon = "rbxassetid://73471738048358",
        MalachorIcon = "rbxassetid://116331302570531",
        MenuBackground = "rbxassetid://113938705574088",
        SettingsBackground = "rbxassetid://133562809418400",
        SettingsTop = "rbxassetid://138150442966040",
        SettingsBottom = "rbxassetid://122422355955588",
        SettingsClose = "rbxassetid://82377754130625",
        SettingsRightPanel = "rbxassetid://112646356261411",
        SettingsRow = "rbxassetid://104898743379633",
        ToggleBase = "rbxassetid://124495542960751",
        ToggleOnIcon = "rbxassetid://113816159248667",
        ToggleOffIcon = "rbxassetid://112294722979305",
        SliderTrack = "rbxassetid://124176682464681",
        SliderKnob = "rbxassetid://74470957879899",
        KeybindRow = "rbxassetid://129413506791669",
        CardBorder = "rbxassetid://92558603652197",
        TabIcons = {
            Agents = "rbxassetid://124313917711594",
            Emblems = "rbxassetid://128979422162991",
            Shop = "rbxassetid://85943852445208",
            Quests = "rbxassetid://137962547326759",
            Infected = "rbxassetid://93451474877498",
            Files = "rbxassetid://73143982303880",
            Menu = "rbxassetid://92879333399542",
        },
        TabButtons = {
            Agents = "rbxassetid://92138416177094",
            Emblems = "rbxassetid://111975621835104",
            Shop = "rbxassetid://73102377740819",
            Quests = "rbxassetid://127527281211632",
            Infected = "rbxassetid://100843560366796",
            Files = "rbxassetid://129389604554965",
            Menu = "rbxassetid://125590539510579",
        },
    },
    Sounds = {
        BubblyClick = "rbxassetid://15675032796",
        Click = "rbxassetid://113015951282811",
        DialogueHover = "rbxassetid://6972108033",
        Hover = "rbxassetid://114349858671788",
        LogoFadeIn = "rbxassetid://87348942592279",
        LogoFadeOut = "rbxassetid://72228643839851",
        Open = "rbxassetid://6874964659",
        PlayersTabClose = "rbxassetid://102378262791241",
        PlayersTabOpen = "rbxassetid://75778731670006",
        QuestNotification = "rbxassetid://18595195017",
        Switch1 = "rbxassetid://139335603235739",
        Switch2 = "rbxassetid://136147895742602",
        Switch3 = "rbxassetid://98193363534716",
        Switch4 = "rbxassetid://115226718025566",
        Switch5 = "rbxassetid://100777690496135",
        Writer = "rbxassetid://876939830",
        Writer2 = "rbxassetid://15675032796",
        Announcement = "rbxassetid://6988710942",
    },
}

local UbuntuRegular = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Regular)
local UbuntuBold = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold)

Library.Theme = {
    -- The original Settings UI uses white Ubuntu text, a blue-grey title tint,
    -- a dark textured panel, and a bright green slider fill.
    Panel = Color3.fromRGB(12, 17, 31),
    Surface = Color3.fromRGB(14, 23, 39),
    Card = Color3.fromRGB(19, 30, 45),
    Option = Color3.fromRGB(29, 43, 55),
    Accent = Color3.fromRGB(138, 228, 105),
    Accent2 = Color3.fromRGB(158, 184, 211),
    Border = Color3.fromRGB(48, 65, 78),
    Text = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(190, 205, 218),
    Off = Color3.fromRGB(63, 76, 87),
    Danger = Color3.fromRGB(246, 82, 82),
    Success = Color3.fromRGB(138, 228, 105),
    Gold = Color3.fromRGB(229, 239, 218),
    TitleFont = Enum.Font.Ubuntu,
    BodyFont = Enum.Font.Ubuntu,
    TitleFontFace = UbuntuBold,
    BodyFontFace = UbuntuRegular,
}

local function create(className, parent, properties)
    local object = Instance.new(className)
    if properties then
        for property, value in pairs(properties) do
            object[property] = value
        end
    end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    return create("UICorner", object, { CornerRadius = UDim.new(0, radius or 8) })
end

local function outline(object, color, thickness, transparency)
    return create("UIStroke", object, {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function gradient(object, firstColor, secondColor, rotation)
    return create("UIGradient", object, {
        Color = ColorSequence.new(firstColor, secondColor),
        Rotation = rotation or 0,
    })
end

local function tween(object, properties, duration)
    local info = TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local animation = TweenService:Create(object, info, properties)
    animation:Play()
    return animation
end

local function label(parent, text, properties)
    properties = properties or {}
    properties.BackgroundTransparency = properties.BackgroundTransparency or 1
    properties.Text = text or ""
    if properties.FontFace then
        properties.Font = nil
    else
        properties.Font = properties.Font or Enum.Font.Ubuntu
    end
    properties.TextColor3 = properties.TextColor3 or Color3.new(1, 1, 1)
    properties.TextSize = properties.TextSize or 14
    properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
    properties.TextYAlignment = properties.TextYAlignment or Enum.TextYAlignment.Center
    return create("TextLabel", parent, properties)
end

local function normalizeImage(image)
    if typeof(image) == "number" then
        return "rbxassetid://" .. tostring(image)
    end
    if typeof(image) == "string" and image ~= "" and not string.find(image, "rbxasset", 1, true) then
        return "rbxassetid://" .. image
    end
    return image
end

local function roundedValue(value, rounding)
    rounding = math.max(0, math.floor(tonumber(rounding) or 0))
    local power = 10 ^ rounding
    return math.floor(value * power + 0.5) / power
end

function Library:CreateWindow(options)
    options = options or {}
    local player = Players.LocalPlayer
    assert(player, "ToonsUniverseUI must be created on the client from a LocalScript.")

    local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
    local parent = options.Parent or playerGui
    local useSounds = options.UseSounds ~= false
    local useGameAssets = options.UseGameAssets ~= false
    local theme = {}
    for key, value in pairs(Library.Theme) do theme[key] = value end
    if type(options.Theme) == "table" then
        for key, value in pairs(options.Theme) do theme[key] = value end
    end

    local defaultSize = UDim2.fromOffset(760, 600)
    local screen = create("ScreenGui", parent, {
        Name = options.Name or "ToonsUniverseUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 50,
    })

    local main = create("Frame", screen, {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = options.Size or defaultSize,
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = useGameAssets and 1 or 0,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 1,
    })

    if useGameAssets then
        -- These are the actual settings-window layers from the uploaded place.
        create("ImageLabel", main, {
            Name = "SettingsArtwork",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5008, 0, 0.5069, 0),
            Size = UDim2.new(1.0124, 0, 0.8790, 0),
            Image = Library.Assets.Images.SettingsBackground,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
        })
        create("ImageLabel", main, {
            Name = "SettingsTopArtwork",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5007, 0, -0.0108, 0),
            Size = UDim2.new(1, 0, 0.1572, 0),
            Image = Library.Assets.Images.SettingsTop,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 2,
        })
        create("ImageLabel", main, {
            Name = "SettingsBottomArtwork",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 1.02, 0),
            Size = UDim2.new(1, 0, 0.1436, 0),
            Image = Library.Assets.Images.SettingsBottom,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 2,
        })
        create("ImageLabel", main, {
            Name = "SettingsRightArtwork",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.7412, 0, 0.5427, 0),
            Size = UDim2.new(0.4925, 0, 0.9674, 0),
            Image = Library.Assets.Images.SettingsRightPanel,
            ScaleType = Enum.ScaleType.Stretch,
            ImageTransparency = 0.04,
            ZIndex = 1,
        })
    else
        corner(main, 4)
        outline(main, theme.Border, 2)
    end

    local scale = create("UIScale", main, { Scale = 1 })
    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local width = (options.Size and options.Size.X.Offset > 0 and options.Size.X.Offset) or 760
        local height = (options.Size and options.Size.Y.Offset > 0 and options.Size.Y.Offset) or 600
        local factor = math.min(1, math.max(0.45, (viewport.X - 18) / width), math.max(0.45, (viewport.Y - 18) / height))
        scale.Scale = factor
    end
    updateScale()

    local window = {
        ScreenGui = screen,
        Main = main,
        Theme = theme,
        Tabs = {},
        Connections = {},
        UseSounds = useSounds,
        UseGameAssets = useGameAssets,
        _soundIds = options.SoundIds or {},
        _switchIndex = 0,
        _destroyed = false,
        _activeTab = nil,
    }

    local function track(connection)
        table.insert(window.Connections, connection)
        return connection
    end

    local function playSound(soundName, volume)
        if not window.UseSounds or window._destroyed then return end
        local soundId = window._soundIds[soundName] or Library.Assets.Sounds[soundName]
        if not soundId then return end
        local sound = Instance.new("Sound")
        sound.Name = "ToonsUI_" .. soundName
        sound.SoundId = soundId
        sound.Volume = volume or 0.35
        sound.Parent = SoundService
        sound:Play()
        Debris:AddItem(sound, 5)
    end
    window.PlaySound = playSound

    local topbar = create("Frame", main, {
        Name = "TopBar",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 64),
        Active = true,
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = useGameAssets and 1 or 0,
        BorderSizePixel = 0,
        ZIndex = 3,
    })

    local title = label(topbar, options.Title or "Toons Universe UI.exe", {
        Name = "Title",
        Position = UDim2.new(0.163, 0, 0, 1),
        Size = UDim2.new(0.59, 0, 0, options.Subtitle and 27 or 42),
        FontFace = theme.TitleFontFace,
        TextSize = 22,
        TextColor3 = useGameAssets and Color3.fromRGB(158, 184, 211) or theme.Text,
        TextStrokeTransparency = 1,
        ZIndex = 4,
    })
    local subtitle = label(topbar, options.Subtitle or "", {
        Name = "Subtitle",
        Position = UDim2.new(0.165, 0, 0, 30),
        Size = UDim2.new(0.59, 0, 0, 18),
        FontFace = theme.BodyFontFace,
        TextSize = 11,
        TextColor3 = theme.Muted,
        Visible = (options.Subtitle ~= nil and options.Subtitle ~= ""),
        ZIndex = 4,
    })

    local closeButton = create("ImageButton", main, {
        Name = "CloseButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = useGameAssets and UDim2.new(0.9473, 0, 0.025, 0) or UDim2.new(1, -25, 0, 25),
        Size = useGameAssets and UDim2.new(0.0426, 0, 0.0813, 0) or UDim2.fromOffset(34, 34),
        BackgroundColor3 = theme.Danger,
        BackgroundTransparency = useGameAssets and 1 or 0,
        Image = useGameAssets and Library.Assets.Images.SettingsClose or "",
        ImageColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    if not useGameAssets then
        corner(closeButton, 3)
        outline(closeButton, theme.Border, 1.5)
        label(closeButton, "×", {
            Name = "CloseGlyph",
            Size = UDim2.fromScale(1, 1),
            FontFace = theme.TitleFontFace,
            TextSize = 26,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 9,
        })
    end
    closeButton.MouseEnter:Connect(function()
        playSound("Hover", 0.15)
        if not useGameAssets then tween(closeButton, { BackgroundColor3 = Color3.fromRGB(255, 110, 115) }, 0.1) end
    end)
    closeButton.MouseLeave:Connect(function()
        if not useGameAssets then tween(closeButton, { BackgroundColor3 = theme.Danger }, 0.1) end
    end)

    local sidebar = create("Frame", main, {
        Name = "TabsPanel",
        Position = UDim2.new(0, 11, 0, 59),
        Size = UDim2.new(0, 137, 1, -70),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = useGameAssets and 1 or 0.08,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    if not useGameAssets then
        corner(sidebar, 4)
        outline(sidebar, theme.Border, 1.4, 0.1)
    end
    create("UIPadding", sidebar, {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
    })
    create("UIListLayout", sidebar, {
        Name = "TabsLayout",
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local contentPanel = create("Frame", main, {
        Name = "ContentPanel",
        Position = UDim2.new(0, 157, 0, 59),
        Size = UDim2.new(1, -168, 1, -70),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = useGameAssets and 1 or 0.08,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    })
    if not useGameAssets then
        corner(contentPanel, 4)
        outline(contentPanel, theme.Border, 1.4, 0.1)
    end

    local toastHolder = create("Frame", screen, {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.fromOffset(292, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 50,
    })
    create("UIListLayout", toastHolder, {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
    })

    local dragState = { Active = false, Start = nil, Position = nil }
    track(topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragState.Active = true
            dragState.Start = input.Position
            dragState.Position = main.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragState.Active then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragState.Start
            main.Position = UDim2.new(
                dragState.Position.X.Scale,
                dragState.Position.X.Offset + delta.X,
                dragState.Position.Y.Scale,
                dragState.Position.Y.Offset + delta.Y
            )
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragState.Active = false
        end
    end))

    local camera = workspace.CurrentCamera
    if camera then
        track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end

    function window:SetTitle(newTitle, newSubtitle)
        title.Text = tostring(newTitle or "")
        if newSubtitle ~= nil then
            subtitle.Text = tostring(newSubtitle)
            subtitle.Visible = subtitle.Text ~= ""
            title.Size = UDim2.new(0.59, 0, 0, subtitle.Visible and 27 or 42)
        end
    end

    function window:SetVisible(visible)
        if self._destroyed then return end
        main.Visible = visible == true
        playSound(main.Visible and "Open" or "PlayersTabClose", 0.3)
    end

    function window:Toggle()
        self:SetVisible(not main.Visible)
    end

    function window:Notify(notification)
        if type(notification) == "string" then
            notification = { Content = notification }
        end
        notification = notification or {}
        playSound("QuestNotification", 0.35)

        local toast = create("Frame", toastHolder, {
            Name = "Notification",
            Size = UDim2.fromOffset(284, 70),
            BackgroundColor3 = theme.Card,
            BorderSizePixel = 0,
            Position = UDim2.new(1, 320, 0, 0),
            ZIndex = 51,
        })
        corner(toast, 9)
        outline(toast, theme.Accent, 1.6)
        create("Frame", toast, {
            Name = "AccentStrip",
            Size = UDim2.new(0, 4, 1, -10),
            Position = UDim2.fromOffset(5, 5),
            BackgroundColor3 = theme.Accent2,
            BorderSizePixel = 0,
            ZIndex = 52,
        })
        local notificationTitle = label(toast, notification.Title or "Notification", {
            Position = UDim2.fromOffset(16, 7),
            Size = UDim2.new(1, -24, 0, 22),
            FontFace = theme.TitleFontFace,
            TextSize = 15,
            TextColor3 = theme.Text,
            ZIndex = 52,
        })
        local notificationContent = label(toast, notification.Content or notification.Description or "", {
            Position = UDim2.fromOffset(16, 31),
            Size = UDim2.new(1, -24, 0, 31),
            FontFace = theme.BodyFontFace,
            TextSize = 12,
            TextWrapped = true,
            TextColor3 = theme.Muted,
            ZIndex = 52,
        })
        tween(toast, { Position = UDim2.new(1, 0, 0, 0) }, 0.22)
        task.delay(math.max(1, tonumber(notification.Duration) or 3), function()
            if toast.Parent then
                local animation = tween(toast, { Position = UDim2.new(1, 320, 0, 0), BackgroundTransparency = 1 }, 0.2)
                animation.Completed:Connect(function()
                    if toast.Parent then toast:Destroy() end
                end)
                tween(notificationTitle, { TextTransparency = 1 }, 0.15)
                tween(notificationContent, { TextTransparency = 1 }, 0.15)
            end
        end)
        return toast
    end

    function window:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        for _, connection in ipairs(self.Connections) do
            pcall(function() connection:Disconnect() end)
        end
        self.Connections = {}
        if screen.Parent then screen:Destroy() end
    end
    window.Close = window.Destroy

    local function selectTab(tabToSelect, playTabSound)
        window._activeTab = tabToSelect
        for _, tab in ipairs(window.Tabs) do
            local selected = (tab == tabToSelect)
            tab.Page.Visible = selected
            tween(tab.Button, {
                BackgroundColor3 = selected and theme.Accent or theme.Card,
                BackgroundTransparency = useGameAssets and 1 or (selected and 0 or 0.08),
            }, 0.12)
            if tab.Texture then
                tween(tab.Texture, {
                    ImageTransparency = selected and 0 or 0.16,
                    ImageColor3 = selected and theme.Accent or Color3.new(1, 1, 1),
                }, 0.12)
            end
            tab.Button.TextColor3 = selected and theme.Text or theme.Muted
            if tab.Icon then
                tab.Icon.ImageColor3 = selected and theme.Text or theme.Muted
            end
        end
        if playTabSound then playSound("PlayersTabOpen", 0.3) end
    end
    window._selectTab = selectTab

    function window:CreateTab(tabName, iconImage)
        assert(not self._destroyed, "Cannot create a tab after the window is destroyed.")
        tabName = tostring(tabName or ("Tab " .. tostring(#self.Tabs + 1)))
        local tabIndex = #self.Tabs + 1
        local button = create("TextButton", sidebar, {
            Name = "Tab_" .. tabName:gsub("%W", ""),
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = theme.Card,
            BackgroundTransparency = useGameAssets and 1 or 0.08,
            Text = tabName,
            TextColor3 = theme.Muted,
            TextSize = 13,
            FontFace = theme.BodyFontFace,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            TextXAlignment = iconImage and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
            LayoutOrder = tabIndex,
            ZIndex = 3,
        })
        local tabTexture
        if useGameAssets then
            tabTexture = create("ImageLabel", button, {
                Name = "GameTabTexture",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = Library.Assets.Images.SettingsRow,
                ImageColor3 = Color3.new(1, 1, 1),
                ImageTransparency = 0.16,
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 2,
            })
        else
            corner(button, 4)
            outline(button, theme.Border, 1)
        end
        local icon
        if iconImage then
            icon = create("ImageLabel", button, {
                Name = "Icon",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 7),
                Size = UDim2.fromOffset(24, 24),
                Image = normalizeImage(iconImage),
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 4,
            })
            button.Text = "        " .. tabName
            button.TextXAlignment = Enum.TextXAlignment.Left
        end

        local page = create("ScrollingFrame", contentPanel, {
            Name = "Page_" .. tabName:gsub("%W", ""),
            Position = UDim2.fromOffset(7, 7),
            Size = UDim2.new(1, -14, 1, -14),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = theme.Accent2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            ZIndex = 3,
        })
        create("UIPadding", page, {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 7),
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 5),
        })
        create("UIListLayout", page, {
            Name = "ControlsLayout",
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local tab = {
            Name = tabName,
            Button = button,
            Icon = icon,
            Texture = tabTexture,
            Page = page,
            Window = self,
            LayoutOrder = tabIndex,
        }
        table.insert(self.Tabs, tab)

        button.Activated:Connect(function()
            selectTab(tab, true)
        end)
        button.MouseEnter:Connect(function()
            if self._activeTab ~= tab then tween(button, { BackgroundColor3 = theme.Option }, 0.1) end
            playSound("Hover", 0.15)
        end)
        button.MouseLeave:Connect(function()
            if self._activeTab ~= tab then tween(button, { BackgroundColor3 = theme.Card }, 0.1) end
        end)

        local function applyRowTexture(parentObject, image, zIndex)
            if not useGameAssets then return nil end
            return create("ImageLabel", parentObject, {
                Name = "GameRowTexture",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = image or Library.Assets.Images.SettingsRow,
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = zIndex or 3,
            })
        end

        local function card(height, parentObject, textureImage)
            local object = create("Frame", parentObject or page, {
                BackgroundColor3 = theme.Card,
                BackgroundTransparency = useGameAssets and 1 or 0.04,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -5, 0, height),
                ClipsDescendants = false,
                ZIndex = 3,
            })
            if useGameAssets then
                applyRowTexture(object, textureImage or Library.Assets.Images.SettingsRow, 3)
            else
                corner(object, 4)
                outline(object, theme.Border, 1.1, 0.05)
            end
            return object
        end

        local function setControlNameAndDescription(parentObject, name, description, labelWidth)
            label(parentObject, name or "Control", {
                Position = UDim2.fromOffset(11, 5),
                Size = UDim2.new(1, -(labelWidth or 80), 0, 22),
                FontFace = theme.BodyFontFace,
                TextSize = 14,
                TextColor3 = theme.Text,
                ZIndex = 4,
            })
            if description and description ~= "" then
                label(parentObject, description, {
                    Position = UDim2.fromOffset(11, 28),
                    Size = UDim2.new(1, -(labelWidth or 80), 0, 21),
                    FontFace = theme.BodyFontFace,
                    TextSize = 12,
                    TextColor3 = theme.Muted,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 4,
                })
            end
        end

        function tab:Select()
            selectTab(self, true)
        end

        function tab:CreateSection(sectionName)
            local section = create("Frame", page, {
                Name = "Section",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -5, 0, 29),
                ZIndex = 3,
            })
            local sectionTitle = label(section, string.upper(tostring(sectionName or "SECTION")), {
                Position = UDim2.fromOffset(3, 0),
                Size = UDim2.new(1, -6, 0, 22),
                FontFace = theme.TitleFontFace,
                TextSize = 15,
                TextColor3 = theme.Text,
                TextStrokeTransparency = 1,
                ZIndex = 4,
            })
            create("Frame", section, {
                Position = UDim2.new(0, 3, 1, -3),
                Size = UDim2.new(1, -8, 0, 2),
                BackgroundColor3 = theme.Accent2,
                BorderSizePixel = 0,
                ZIndex = 4,
            })
            return sectionTitle
        end

        function tab:CreateDivider()
            return create("Frame", page, {
                Name = "Divider",
                Size = UDim2.new(1, -8, 0, 2),
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                ZIndex = 3,
            })
        end

        function tab:CreateLabel(textValue)
            local textObject = label(page, tostring(textValue or ""), {
                Name = "Label",
                Size = UDim2.new(1, -8, 0, 28),
                FontFace = theme.BodyFontFace,
                TextSize = 14,
                TextColor3 = theme.Text,
                TextWrapped = true,
                ZIndex = 3,
            })
            local control = {}
            function control:SetText(newText) textObject.Text = tostring(newText or "") end
            control.Instance = textObject
            return control
        end

        function tab:CreateParagraph(paragraphTitle, paragraphContent)
            if type(paragraphTitle) == "table" then
                paragraphContent = paragraphTitle.Content or paragraphTitle.Description
                paragraphTitle = paragraphTitle.Title
            end
            local wrapper = create("Frame", page, {
                Name = "Paragraph",
                Size = UDim2.new(1, -5, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.Card,
                BackgroundTransparency = useGameAssets and 1 or 0.04,
                BorderSizePixel = 0,
                ZIndex = 3,
            })
            if useGameAssets then
                applyRowTexture(wrapper, Library.Assets.Images.SettingsRow, 3)
            else
                corner(wrapper, 4)
                outline(wrapper, theme.Border, 1.1, 0.05)
            end
            local paragraphHeader = label(wrapper, tostring(paragraphTitle or "Information"), {
                Position = UDim2.fromOffset(11, 7),
                Size = UDim2.new(1, -22, 0, 23),
                FontFace = theme.TitleFontFace,
                TextSize = 15,
                TextColor3 = theme.Text,
                ZIndex = 4,
            })
            local body = label(wrapper, tostring(paragraphContent or ""), {
                Position = UDim2.fromOffset(11, 33),
                Size = UDim2.new(1, -22, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                FontFace = theme.BodyFontFace,
                TextSize = 13,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextColor3 = theme.Muted,
                ZIndex = 4,
            })
            create("UIPadding", wrapper, { PaddingBottom = UDim.new(0, 10) })
            local control = { Instance = wrapper }
            function control:SetText(newTitle, newContent)
                paragraphHeader.Text = tostring(newTitle or "")
                body.Text = tostring(newContent or "")
            end
            return control
        end

        function tab:CreateToggle(config)
            config = config or {}
            local current = config.CurrentValue == true or config.Default == true
            local row = card(58)
            row.Name = "Toggle"
            setControlNameAndDescription(row, config.Name or "Toggle", config.Description, 75)
            local switch = create("ImageButton", row, {
                Name = "Switch",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -11, 0.5, 0),
                Size = useGameAssets and UDim2.fromOffset(58, 34) or UDim2.fromOffset(44, 24),
                BackgroundColor3 = current and theme.Accent or theme.Off,
                BackgroundTransparency = useGameAssets and 1 or 0,
                Image = useGameAssets and Library.Assets.Images.ToggleBase or "",
                ImageColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                ZIndex = 4,
            })
            local knob
            local stateIcon
            if useGameAssets then
                stateIcon = create("ImageLabel", switch, {
                    Name = "StateIcon",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.58, 0.58),
                    BackgroundTransparency = 1,
                    Image = current and Library.Assets.Images.ToggleOnIcon or Library.Assets.Images.ToggleOffIcon,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 5,
                })
            else
                corner(switch, 12)
                outline(switch, theme.Border, 1)
                knob = create("Frame", switch, {
                    Name = "Knob",
                    Position = current and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(18, 18),
                    BackgroundColor3 = theme.Text,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                })
                corner(knob, 9)
            end
            local control = { Instance = row, Button = switch }
            local function setValue(value, silent)
                current = value == true
                if stateIcon then
                    stateIcon.Image = current and Library.Assets.Images.ToggleOnIcon or Library.Assets.Images.ToggleOffIcon
                    tween(stateIcon, { ImageTransparency = 0 }, 0.1)
                else
                    tween(switch, { BackgroundColor3 = current and theme.Accent or theme.Off }, 0.13)
                    tween(knob, { Position = current and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3) }, 0.13)
                end
                if not silent then
                    window._switchIndex = (window._switchIndex % 5) + 1
                    playSound("Switch" .. tostring(window._switchIndex), 0.3)
                    if type(config.Callback) == "function" then config.Callback(current) end
                end
            end
            switch.Activated:Connect(function() setValue(not current, false) end)
            switch.MouseEnter:Connect(function() playSound("Hover", 0.12) end)
            function control:SetValue(value, silent) setValue(value, silent == true) end
            control.Set = control.SetValue
            function control:GetValue() return current end
            setValue(current, true)
            return control
        end

        function tab:CreateSlider(config)
            config = config or {}
            local minimum = tonumber(config.Min) or 0
            local maximum = tonumber(config.Max) or 100
            if maximum < minimum then minimum, maximum = maximum, minimum end
            local rounding = tonumber(config.Rounding) or 0
            local increment = tonumber(config.Increment) or 0
            local value = math.clamp(tonumber(config.Default) or minimum, minimum, maximum)
            value = roundedValue(value, rounding)
            local row = card(72)
            row.Name = "Slider"
            label(row, config.Name or "Slider", {
                Position = UDim2.fromOffset(11, 5),
                Size = UDim2.new(1, -100, 0, 22),
                FontFace = theme.BodyFontFace,
                TextSize = 14,
                TextColor3 = theme.Text,
                ZIndex = 4,
            })
            local valueLabel = label(row, tostring(value), {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -11, 0, 5),
                Size = UDim2.fromOffset(90, 22),
                FontFace = theme.TitleFontFace,
                TextSize = 14,
                TextColor3 = theme.Gold,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 4,
            })
            local sliderTrackClass = useGameAssets and "ImageLabel" or "Frame"
            local sliderTrackProperties = {
                Name = "Track",
                Position = UDim2.new(0, 12, 0, 39),
                Size = UDim2.new(1, -24, 0, 21),
                BackgroundColor3 = theme.Off,
                BackgroundTransparency = useGameAssets and 1 or 0,
                BorderSizePixel = 0,
                Active = true,
                ZIndex = 4,
            }
            if useGameAssets then
                sliderTrackProperties.Image = Library.Assets.Images.SliderTrack
                sliderTrackProperties.ScaleType = Enum.ScaleType.Stretch
            end
            local sliderTrack = create(sliderTrackClass, row, sliderTrackProperties)
            if not useGameAssets then corner(sliderTrack, 4) end
            local initialRatio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
            local fill = create("Frame", sliderTrack, {
                Name = "Fill",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0.02, 0, 0.5, 0),
                Size = UDim2.new(initialRatio * 0.96, 0, useGameAssets and 0 or 1, useGameAssets and 4 or 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 5,
            })
            if not useGameAssets then corner(fill, 4) end
            local knobClass = useGameAssets and "ImageLabel" or "Frame"
            local knobProperties = {
                Name = "Knob",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(useGameAssets and (0.02 + initialRatio * 0.96) or initialRatio, 0, 0.5, 0),
                Size = useGameAssets and UDim2.fromOffset(14, 23) or UDim2.fromOffset(17, 17),
                BackgroundColor3 = theme.Text,
                BackgroundTransparency = useGameAssets and 1 or 0,
                BorderSizePixel = 0,
                ZIndex = 6,
            }
            if useGameAssets then
                knobProperties.Image = Library.Assets.Images.SliderKnob
                knobProperties.ScaleType = Enum.ScaleType.Fit
            end
            local knob = create(knobClass, sliderTrack, knobProperties)
            if not useGameAssets then
                corner(knob, 9)
                outline(knob, theme.Border, 1.5)
            end
            local dragging = false
            local control = { Instance = row }
            local function setValue(newValue, silent)
                newValue = math.clamp(tonumber(newValue) or minimum, minimum, maximum)
                if increment > 0 then newValue = minimum + math.floor(((newValue - minimum) / increment) + 0.5) * increment end
                newValue = roundedValue(math.clamp(newValue, minimum, maximum), rounding)
                value = newValue
                local ratio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
                valueLabel.Text = tostring(value)
                tween(fill, {
                    Position = UDim2.new(0.02, 0, 0.5, 0),
                    Size = UDim2.new(ratio * 0.96, 0, useGameAssets and 0 or 1, useGameAssets and 4 or 0),
                }, 0.08)
                tween(knob, { Position = UDim2.new(useGameAssets and (0.02 + ratio * 0.96) or ratio, 0, 0.5, 0) }, 0.08)
                if not silent and type(config.Callback) == "function" then config.Callback(value) end
            end
            local function valueFromInput(input)
                local width = sliderTrack.AbsoluteSize.X
                if width <= 0 then return end
                local inset = useGameAssets and 0.02 or 0
                local usableWidth = width * (1 - inset * 2)
                local ratio = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X - width * inset) / usableWidth, 0, 1)
                setValue(minimum + (maximum - minimum) * ratio, false)
            end
            local function beginDrag(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    valueFromInput(input)
                    playSound("Click", 0.2)
                end
            end
            sliderTrack.InputBegan:Connect(beginDrag)
            knob.InputBegan:Connect(beginDrag)
            sliderTrack.MouseEnter:Connect(function() playSound("Hover", 0.12) end)
            sliderTrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                local ratio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
                fill.Position = UDim2.new(0.02, 0, 0.5, 0)
                fill.Size = UDim2.new(ratio * 0.96, 0, useGameAssets and 0 or 1, useGameAssets and 4 or 0)
                knob.Position = UDim2.new(useGameAssets and (0.02 + ratio * 0.96) or ratio, 0, 0.5, 0)
            end)
            local moveConnection = UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    valueFromInput(input)
                end
            end)
            local endConnection = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            track(moveConnection)
            track(endConnection)
            row.Destroying:Connect(function()
                dragging = false
                moveConnection:Disconnect()
                endConnection:Disconnect()
            end)
            function control:SetValue(newValue, silent) setValue(newValue, silent == true) end
            control.Set = control.SetValue
            function control:GetValue() return value end
            setValue(value, true)
            return control
        end

        function tab:CreateButton(config)
            config = config or {}
            local row = create("TextButton", page, {
                Name = "Button",
                Size = UDim2.new(1, -5, 0, config.Description and 58 or 43),
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = useGameAssets and 1 or 0,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 3,
            })
            if useGameAssets then
                create("ImageLabel", row, {
                    Name = "PrimaryButtonTexture",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = Library.Assets.Images.PrimaryButton,
                    ScaleType = Enum.ScaleType.Stretch,
                    ZIndex = 3,
                })
            else
                corner(row, 4)
                outline(row, theme.Border, 1.5)
                gradient(row, theme.Accent, theme.Accent2, 0)
            end
            label(row, config.Name or "Button", {
                Position = UDim2.fromOffset(12, config.Description and 6 or 0),
                Size = UDim2.new(1, -24, 0, config.Description and 23 or 43),
                FontFace = theme.TitleFontFace,
                TextSize = 15,
                TextColor3 = theme.Text,
                TextStrokeColor3 = theme.Border,
                TextStrokeTransparency = 0.7,
                ZIndex = 4,
            })
            if config.Description and config.Description ~= "" then
                label(row, config.Description, {
                    Position = UDim2.fromOffset(12, 30),
                    Size = UDim2.new(1, -24, 0, 20),
                    FontFace = theme.BodyFontFace,
                    TextSize = 12,
                    TextColor3 = theme.Muted,
                    ZIndex = 4,
                })
            end
            row.Activated:Connect(function()
                playSound("BubblyClick", 0.35)
                if type(config.Callback) == "function" then config.Callback() end
            end)
            row.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = theme.Accent2 }, 0.1); playSound("Hover", 0.12) end)
            row.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = theme.Accent }, 0.1) end)
            return { Instance = row }
        end

        function tab:CreateDropdown(config)
            config = config or {}
            local optionsList = config.Options or {}
            local multiple = config.Multiple == true
            local expanded = false
            local selected = nil
            local selectedSet = {}
            if multiple then
                if type(config.CurrentOption) == "table" then
                    for _, item in ipairs(config.CurrentOption) do selectedSet[item] = true end
                end
            else
                selected = config.CurrentOption
                if selected == nil then selected = optionsList[1] end
            end

            local outer = create("Frame", page, {
                Name = "Dropdown",
                Size = UDim2.new(1, -5, 0, 47),
                BackgroundColor3 = theme.Card,
                BackgroundTransparency = useGameAssets and 1 or 0.04,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 3,
            })
            if useGameAssets then
                applyRowTexture(outer, Library.Assets.Images.SettingsRow, 3)
            else
                corner(outer, 4)
                outline(outer, theme.Border, 1.1, 0.05)
            end
            local header = create("TextButton", outer, {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 47),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 4,
            })
            local nameLabel = label(header, config.Name or "Dropdown", {
                Position = UDim2.fromOffset(11, 4),
                Size = UDim2.new(1, -35, 0, 20),
                FontFace = theme.BodyFontFace,
                TextSize = 14,
                TextColor3 = theme.Text,
                ZIndex = 5,
            })
            local valueLabel = label(header, "", {
                Position = UDim2.fromOffset(11, 23),
                Size = UDim2.new(1, -38, 0, 17),
                FontFace = theme.BodyFontFace,
                TextSize = 12,
                TextColor3 = theme.Gold,
                ZIndex = 5,
            })
            local arrow = label(header, "⌄", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(20, 24),
                FontFace = theme.TitleFontFace,
                TextSize = 22,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 5,
            })
            local listFrame = create("ScrollingFrame", outer, {
                Name = "Options",
                Position = UDim2.fromOffset(7, 49),
                Size = UDim2.new(1, -14, 0, 0),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = theme.Accent2,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
                ZIndex = 5,
            })
            corner(listFrame, 6)
            create("UIPadding", listFrame, {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            })
            create("UIListLayout", listFrame, {
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            local optionButtons = {}
            local control = { Instance = outer }

            local function currentDisplay()
                if multiple then
                    local picked = {}
                    for _, item in ipairs(optionsList) do
                        if selectedSet[item] then table.insert(picked, tostring(item)) end
                    end
                    if #picked == 0 then return "Select options" end
                    if #picked > 2 then return tostring(#picked) .. " selected" end
                    return table.concat(picked, ", ")
                end
                return selected == nil and "Select an option" or tostring(selected)
            end
            local function updateHeader()
                valueLabel.Text = currentDisplay()
                arrow.Text = expanded and "⌃" or "⌄"
            end
            local function updateExpandedSize()
                local shown = math.min(#optionsList, 5)
                local height = expanded and (47 + (shown > 0 and shown * 31 + 7 or 0)) or 47
                outer.Size = UDim2.new(1, -5, 0, height)
                listFrame.Size = UDim2.new(1, -14, 0, expanded and shown * 31 + 4 or 0)
                listFrame.Visible = expanded and shown > 0
                updateHeader()
            end
            local function fireCallback(silent)
                if silent or type(config.Callback) ~= "function" then return end
                if multiple then
                    local values = {}
                    for _, item in ipairs(optionsList) do
                        if selectedSet[item] then table.insert(values, item) end
                    end
                    config.Callback(values)
                else
                    config.Callback(selected)
                end
            end
            local function renderOptions()
                for _, buttonObject in ipairs(optionButtons) do buttonObject:Destroy() end
                optionButtons = {}
                for index, option in ipairs(optionsList) do
                    local optionButton = create("TextButton", listFrame, {
                        Name = "Option_" .. tostring(index),
                        Size = UDim2.new(1, -2, 0, 28),
                        BackgroundColor3 = ((multiple and selectedSet[option]) or ((not multiple) and selected == option)) and theme.Accent or theme.Option,
                        BorderSizePixel = 0,
                        Text = tostring(option),
                        TextColor3 = theme.Text,
                        TextSize = 13,
                        FontFace = theme.BodyFontFace,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false,
                        LayoutOrder = index,
                        ZIndex = 6,
                    })
                    corner(optionButton, 5)
                    create("UIPadding", optionButton, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) })
                    optionButton.Activated:Connect(function()
                        if multiple then
                            if selectedSet[option] then
                                selectedSet[option] = nil
                            else
                                selectedSet[option] = true
                            end
                        else
                            selected = option
                            expanded = false
                        end
                        for i, buttonObject in ipairs(optionButtons) do
                            local item = optionsList[i]
                            local isSelected = multiple and selectedSet[item] or (not multiple and selected == item)
                            tween(buttonObject, { BackgroundColor3 = isSelected and theme.Accent or theme.Option }, 0.1)
                        end
                        updateExpandedSize()
                        fireCallback(false)
                        playSound("BubblyClick", 0.25)
                    end)
                    optionButton.MouseEnter:Connect(function() playSound("Hover", 0.1) end)
                    table.insert(optionButtons, optionButton)
                end
                updateExpandedSize()
            end
            header.Activated:Connect(function()
                expanded = not expanded
                updateExpandedSize()
                playSound("Open", 0.25)
            end)
            function control:Set(value, silent)
                if multiple then
                    selectedSet = {}
                    local values = type(value) == "table" and value or { value }
                    for _, item in ipairs(values) do selectedSet[item] = true end
                else
                    selected = value
                end
                renderOptions()
                fireCallback(silent == true)
            end
            control.SetValue = control.Set
            function control:Get()
                if multiple then
                    local values = {}
                    for _, item in ipairs(optionsList) do if selectedSet[item] then table.insert(values, item) end end
                    return values
                end
                return selected
            end
            control.GetValue = control.Get
            function control:Refresh(newOptions, preserveSelection)
                optionsList = newOptions or {}
                if not preserveSelection then
                    selectedSet = {}
                    if multiple then
                        selected = nil
                    else
                        selected = optionsList[1]
                    end
                end
                renderOptions()
            end
            renderOptions()
            if config.FireOnInit == true then fireCallback(false) end
            return control
        end

        function tab:CreateInput(config)
            config = config or {}
            local row = card(52)
            row.Name = "Input"
            label(row, config.Name or "Input", {
                Position = UDim2.fromOffset(11, 0),
                Size = UDim2.new(0.42, -8, 1, 0),
                FontFace = theme.BodyFontFace,
                TextSize = 14,
                TextColor3 = theme.Text,
                ZIndex = 4,
            })
            local inputBox = create("TextBox", row, {
                Name = "TextBox",
                Position = UDim2.new(0.42, 0, 0.5, -15),
                Size = UDim2.new(0.58, -11, 0, 30),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Text = tostring(config.Default or ""),
                PlaceholderText = config.Placeholder or "Type here...",
                PlaceholderColor3 = theme.Muted,
                TextColor3 = theme.Text,
                TextSize = 13,
                FontFace = theme.BodyFontFace,
                ClearTextOnFocus = config.ClearTextOnFocus == true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4,
            })
            if not useGameAssets then
                corner(inputBox, 3)
                outline(inputBox, theme.Border, 1)
            else
                inputBox.BackgroundColor3 = theme.Surface
                inputBox.BackgroundTransparency = 0.15
            end
            create("UIPadding", inputBox, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) })
            inputBox.FocusLost:Connect(function(enterPressed)
                if enterPressed and type(config.Callback) == "function" then config.Callback(inputBox.Text) end
            end)
            inputBox.Focused:Connect(function() playSound("Click", 0.15) end)
            local control = { Instance = row, TextBox = inputBox }
            function control:GetValue() return inputBox.Text end
            function control:SetValue(value) inputBox.Text = tostring(value or "") end
            control.Set = control.SetValue
            return control
        end

        function tab:CreateKeybind(config)
            config = config or {}
            local currentKey = config.Default or config.Key or Enum.KeyCode.RightShift
            if type(currentKey) == "string" then
                currentKey = Enum.KeyCode[currentKey] or Enum.KeyCode.RightShift
            end
            local listening = false
            local row = card(49, nil, Library.Assets.Images.KeybindRow)
            row.Name = "Keybind"
            label(row, config.Name or "Keybind", {
                Position = UDim2.fromOffset(11, 0),
                Size = UDim2.new(1, -130, 1, 0),
                FontFace = theme.BodyFontFace,
                TextSize = 14,
                TextColor3 = theme.Text,
                ZIndex = 4,
            })
            local keyButton = create("TextButton", row, {
                Name = "KeyButton",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -9, 0.5, 0),
                Size = UDim2.fromOffset(108, 30),
                BackgroundColor3 = theme.Option,
                BorderSizePixel = 0,
                Text = tostring(currentKey):gsub("Enum%.KeyCode%.", ""),
                TextColor3 = theme.Gold,
                TextSize = 13,
                FontFace = theme.TitleFontFace,
                AutoButtonColor = false,
                ZIndex = 4,
            })
            if not useGameAssets then
                corner(keyButton, 3)
                outline(keyButton, theme.Border, 1)
            else
                keyButton.BackgroundColor3 = theme.Surface
                keyButton.BackgroundTransparency = 0.15
            end
            local control = { Instance = row, Button = keyButton }
            keyButton.Activated:Connect(function()
                listening = true
                keyButton.Text = "Press a key..."
                tween(keyButton, { BackgroundColor3 = theme.Accent }, 0.1)
                playSound("Click", 0.2)
            end)
            track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if listening then
                    if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Escape then
                        currentKey = input.KeyCode
                        keyButton.Text = tostring(currentKey):gsub("Enum%.KeyCode%.", "")
                        if type(config.ChangedCallback) == "function" then config.ChangedCallback(currentKey) end
                    else
                        keyButton.Text = tostring(currentKey):gsub("Enum%.KeyCode%.", "")
                    end
                    listening = false
                    tween(keyButton, { BackgroundColor3 = theme.Option }, 0.1)
                    return
                end
                if not gameProcessed and input.KeyCode == currentKey then
                    if type(config.Callback) == "function" then config.Callback(currentKey) end
                end
            end))
            function control:GetValue() return currentKey end
            function control:SetValue(value)
                if type(value) == "string" then value = Enum.KeyCode[value] end
                if typeof(value) == "EnumItem" then
                    currentKey = value
                    keyButton.Text = tostring(currentKey):gsub("Enum%.KeyCode%.", "")
                end
            end
            control.Set = control.SetValue
            return control
        end

        if tabIndex == 1 then
            selectTab(tab, false)
        end
        return tab
    end

    closeButton.Activated:Connect(function()
        playSound("LogoFadeOut", 0.25)
        window:Destroy()
    end)
    if options.StartVisible == false then main.Visible = false end
    return window
end

return Library
