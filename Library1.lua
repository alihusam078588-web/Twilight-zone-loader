--!strict
-- Dandy's World UI Reconstruction Library
-- UI/property data is stored separately in DandysWorldUIData.json.
-- It includes captured ScreenGui trees, templates, image references and a sound catalog.
-- Use the included Example.client.lua for an executor loader or store the JSON as a ModuleScript/data asset in Studio.

local Library = {}
Library.__index = Library
Library.Version = "2.0.0"
Library.DumpFormat = "RobloxUIExport"
Library.DefaultDataURL = "https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/DandysWorldUIData.json"
Library.Theme = {
    Font = Enum.Font.FredokaOne,
    Text = Color3.fromRGB(255, 255, 255),
    Ink = Color3.fromRGB(0, 13, 76),
    Panel = Color3.fromRGB(255, 255, 255),
    PanelDark = Color3.fromRGB(22, 22, 22),
    Pink = Color3.fromRGB(255, 33, 103),
    Yellow = Color3.fromRGB(255, 225, 0),
    Mint = Color3.fromRGB(180, 248, 107),
    Border = Color3.fromRGB(0, 13, 76),
}

Library._Data = nil
Library.SoundCatalog = {}
Library.Images = {}
Library.TemplateIndex = {}

local function lastEnumToken(value: any): string
    local str = tostring(value)
    return string.match(str, "([^%.]+)$") or str
end

local function decodeValue(value: any): any
    if type(value) ~= "table" then return value end
    local kind = value.type
    if type(kind) ~= "string" then return nil end

    if kind == "Color3" then
        if value.r ~= nil and value.g ~= nil and value.b ~= nil then
            return Color3.new(value.r, value.g, value.b)
        end
    elseif kind == "UDim" then
        return UDim.new(value.scale or 0, value.offset or 0)
    elseif kind == "UDim2" then
        return UDim2.new(value.xScale or 0, value.xOffset or 0, value.yScale or 0, value.yOffset or 0)
    elseif kind == "Vector2" then
        return Vector2.new(value.x or 0, value.y or 0)
    elseif kind == "Vector3" then
        return Vector3.new(value.x or 0, value.y or 0, value.z or 0)
    elseif kind == "Rect" then
        local minimum, maximum = decodeValue(value.min), decodeValue(value.max)
        if typeof(minimum) == "Vector2" and typeof(maximum) == "Vector2" then
            return Rect.new(minimum, maximum)
        end
    elseif kind == "EnumItem" then
        local ok, result = pcall(function()
            local enumType = Enum[lastEnumToken(value.enum)]
            return enumType[value.name]
        end)
        if ok then return result end
    elseif kind == "NumberRange" then
        return NumberRange.new(value.min or 0, value.max or 0)
    elseif kind == "NumberSequence" then
        local points = {}
        for _, point in ipairs(value.keypoints or {}) do
            table.insert(points, NumberSequenceKeypoint.new(point.time or 0, point.value or 0, point.envelope or 0))
        end
        if #points >= 2 then
            local ok, result = pcall(NumberSequence.new, points)
            if ok then return result end
        end
    elseif kind == "ColorSequence" then
        local points = {}
        for _, point in ipairs(value.keypoints or {}) do
            local color = decodeValue(point.color)
            if typeof(color) == "Color3" then
                table.insert(points, ColorSequenceKeypoint.new(point.time or 0, color))
            end
        end
        if #points >= 2 then
            local ok, result = pcall(ColorSequence.new, points)
            if ok then return result end
        end
    elseif kind == "Font" then
        local ok, result = pcall(function()
            local weightName = lastEnumToken(value.weight or "Regular")
            local styleName = lastEnumToken(value.style or "Normal")
            local weight = Enum.FontWeight[weightName] or Enum.FontWeight.Regular
            local style = Enum.FontStyle[styleName] or Enum.FontStyle.Normal
            return Font.new(value.family or "", weight, style)
        end)
        if ok then return result end
    elseif kind == "CFrame" then
        if type(value.components) == "table" and #value.components >= 12 then
            local ok, result = pcall(function() return CFrame.new(table.unpack(value.components)) end)
            if ok then return result end
        end
    elseif kind == "BrickColor" then
        local ok, result = pcall(BrickColor.new, value.name or "Institutional white")
        if ok then return result end
    elseif kind == "Instance" then
        return { __uiInstanceReference = value.path }
    end
    return nil
end

local function makeProgressGui(parent: Instance): (Instance?, ((string, number, number, string) -> ())?)
    local ok, screen, updater = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "UIReconstructionProgress"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 1000000
        gui.Parent = parent

        local panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Size = UDim2.fromOffset(330, 116)
        panel.Position = UDim2.new(0.5, -165, 0.5, -58)
        panel.BackgroundColor3 = Color3.fromRGB(28, 27, 40)
        panel.BorderSizePixel = 0
        panel.Parent = gui
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 225, 0)
        stroke.Thickness = 1
        stroke.Parent = panel

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, -24, 0, 25)
        title.Position = UDim2.fromOffset(12, 8)
        title.Font = Enum.Font.FredokaOne
        title.Text = "DANDY'S WORLD UI"
        title.TextSize = 16
        title.TextColor3 = Color3.new(1, 1, 1)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = panel

        local stage = Instance.new("TextLabel")
        stage.Name = "Stage"
        stage.BackgroundTransparency = 1
        stage.Size = UDim2.new(1, -24, 0, 20)
        stage.Position = UDim2.fromOffset(12, 35)
        stage.Font = Enum.Font.Gotham
        stage.Text = "Preparing..."
        stage.TextSize = 11
        stage.TextColor3 = Color3.fromRGB(210, 210, 225)
        stage.TextXAlignment = Enum.TextXAlignment.Left
        stage.Parent = panel

        local background = Instance.new("Frame")
        background.Name = "BarBackground"
        background.Size = UDim2.new(1, -24, 0, 8)
        background.Position = UDim2.fromOffset(12, 64)
        background.BackgroundColor3 = Color3.fromRGB(55, 54, 72)
        background.BorderSizePixel = 0
        background.Parent = panel
        Instance.new("UICorner", background).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Name = "BarFill"
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 225, 0)
        fill.BorderSizePixel = 0
        fill.Parent = background
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local detail = Instance.new("TextLabel")
        detail.Name = "Detail"
        detail.BackgroundTransparency = 1
        detail.Size = UDim2.new(1, -24, 0, 20)
        detail.Position = UDim2.fromOffset(12, 82)
        detail.Font = Enum.Font.Gotham
        detail.Text = "Starting..."
        detail.TextSize = 10
        detail.TextColor3 = Color3.fromRGB(175, 175, 195)
        detail.TextXAlignment = Enum.TextXAlignment.Left
        detail.Parent = panel

        local function update(stageText: string, done: number, total: number, detailText: string)
            if not gui.Parent then return end
            stage.Text, detail.Text = stageText, detailText
            local fraction = if total > 0 then math.clamp(done / total, 0, 1) else 0
            fill.Size = UDim2.new(fraction, 0, 1, 0)
        end
        return gui, update
    end)
    if not ok then return nil, nil end
    return screen, updater
end

local function createInstance(className: string): Instance?
    local ok, instance = pcall(Instance.new, className)
    if ok then return instance end
    return nil
end

local function isSkipped(node: any, options: {[string]: any}): boolean
    if options.SkipNames and options.SkipNames[node.name] then return true end
    if options.SkipClasses and options.SkipClasses[node.className] then return true end
    return false
end

function Library.Reconstruct(dump: any, targetParent: Instance?, options: {[string]: any}?)
    options = options or {}
    assert(type(dump) == "table", "Reconstruct expects a decoded dump table")
    assert(dump.format == Library.DumpFormat, "Unexpected dump format")

    if not targetParent then
        local player = game:GetService("Players").LocalPlayer
        assert(player, "Pass targetParent when running outside a LocalScript")
        targetParent = player:WaitForChild("PlayerGui")
    end

    local yieldEvery = math.max(1, tonumber(options.YieldEvery) or 40)
    local maxInstances = math.max(1, tonumber(options.MaxInstances) or 15000)
    local progressGui, progressUpdate
    if options.ProgressGui ~= false then progressGui, progressUpdate = makeProgressGui(targetParent) end

    local nodesByInstance, pathMap, createdRoots, allRecords = {}, {}, {}, {}
    local stats = {
        created = 0, skipped = 0, propertyErrors = 0, creationErrors = 0,
        unresolvedReferences = 0, attributesRestored = 0,
        truncatedByLimit = false,
        sourceWasTruncated = dump.summary and (dump.summary.sourceRuntimeDumpTruncated == true or dump.summary.truncated == true) or false,
    }

    local function notify(stage: string, done: number, total: number, detail: string)
        if progressUpdate then progressUpdate(stage, done, total, detail) end
        if type(options.OnProgress) == "function" then pcall(options.OnProgress, stage, done, total, detail, stats) end
    end

    local function addNode(node: any, parent: Instance, isTop: boolean): Instance?
        if not node or type(node) ~= "table" then return nil end
        if isSkipped(node, options) then stats.skipped += 1; return nil end
        if stats.created >= maxInstances then stats.truncatedByLimit = true; return nil end

        local instance = createInstance(node.className or "Folder")
        if not instance then
            stats.creationErrors += 1
            for _, child in ipairs(node.children or {}) do addNode(child, parent, false) end
            return nil
        end
        instance.Name = node.name or node.className or "UIObject"
        instance.Parent = parent
        stats.created += 1
        if node.path then pathMap[node.path] = instance end
        table.insert(allRecords, {node = node, instance = instance})
        if isTop then table.insert(createdRoots, instance) end

        if stats.created % yieldEvery == 0 then
            notify("Building UI tree", stats.created, maxInstances, instance.Name .. " (" .. instance.ClassName .. ")")
            task.wait()
        end
        for _, child in ipairs(node.children or {}) do
            if stats.created >= maxInstances then stats.truncatedByLimit = true; break end
            addNode(child, instance, false)
        end
        return instance
    end

    for _, rootEntry in ipairs(dump.roots or {}) do
        local tree = rootEntry.tree
        if tree then
            local before = stats.created
            addNode(tree, targetParent, true)
            if stats.created > before and stats.created % yieldEvery ~= 0 then task.wait() end
        end
    end

    local totalRecords = #allRecords
    for index, record in ipairs(allRecords) do
        local node, instance = record.node, record.instance
        for propertyName, encodedValue in pairs(node.properties or {}) do
            if propertyName ~= "Parent" and propertyName ~= "Archivable" and propertyName ~= "Name" then
                local decoded = decodeValue(encodedValue)
                if type(decoded) == "table" and decoded.__uiInstanceReference then
                    local referenced = pathMap[decoded.__uiInstanceReference]
                    if referenced then
                        local ok = pcall(function() instance[propertyName] = referenced end)
                        if not ok then stats.propertyErrors += 1 end
                    else
                        stats.unresolvedReferences += 1
                    end
                elseif decoded ~= nil then
                    local ok = pcall(function() instance[propertyName] = decoded end)
                    if not ok then stats.propertyErrors += 1 end
                end
            end
        end
        for attributeName, encodedValue in pairs(node.attributes or {}) do
            local decoded = decodeValue(encodedValue)
            if decoded ~= nil and not (type(decoded) == "table" and decoded.__uiInstanceReference) then
                local ok = pcall(function() instance:SetAttribute(attributeName, decoded) end)
                if ok then stats.attributesRestored += 1 end
            end
        end
        if options.RestoreTags and type(node.tags) == "table" then
            local collectionService = game:GetService("CollectionService")
            for _, tag in ipairs(node.tags) do pcall(function() collectionService:AddTag(instance, tag) end) end
        end
        if index % yieldEvery == 0 or index == totalRecords then
            notify("Applying properties", index, totalRecords, instance.Name .. " (" .. instance.ClassName .. ")")
            task.wait()
        end
    end

    if progressUpdate then
        progressUpdate("Reconstruction complete", 1, 1,
            string.format("%d objects | %d property errors", stats.created, stats.propertyErrors))
    end
    if options.AutoCloseProgress ~= false and progressGui then
        task.delay(2, function() if progressGui and progressGui.Parent then progressGui:Destroy() end end)
    end

    local result = {
        Roots = createdRoots,
        Root = createdRoots[1],
        ByPath = pathMap,
        Stats = stats,
        SourceSummary = dump.summary,
        ProgressGui = progressGui,
    }
    function result:Destroy()
        for _, root in ipairs(self.Roots) do pcall(function() root:Destroy() end) end
        if self.ProgressGui then pcall(function() self.ProgressGui:Destroy() end) end
    end
    return result
end

local function fetchText(url: string): string
    local ok, result = pcall(function() return game:HttpGet(url) end)
    if ok and type(result) == "string" then return result end
    error("Could not download UI data. In an executor, check game:HttpGet support and the URL. Details: " .. tostring(result))
end

function Library.LoadJSON(jsonText: any, targetParent: Instance?, options: {[string]: any}?)
    local http = game:GetService("HttpService")
    local dump = if type(jsonText) == "string" then http:JSONDecode(jsonText) else jsonText
    assert(type(dump) == "table" and dump.format == Library.DumpFormat, "Invalid UI data")
    Library._Data = dump
    Library.SoundCatalog = dump.soundCatalog or {}
    Library.Images = dump.images or dump.assets or {}
    Library.TemplateIndex = dump.templateIndex or {}

    options = options or {}
    if options.Screen then
        local selected
        for _, entry in ipairs(dump.roots or {}) do
            if entry.rootName == options.Screen then selected = entry; break end
        end
        if not selected then error("Screen not found in data: " .. tostring(options.Screen)) end
        local subset = {
            format = dump.format, version = dump.version, game = dump.game,
            summary = dump.summary, assets = dump.assets, images = dump.images,
            soundCatalog = dump.soundCatalog,
            roots = {selected},
        }
        return Library.Reconstruct(subset, targetParent, options)
    end
    return Library.Reconstruct(dump, targetParent, options)
end

function Library.LoadFromURL(url: string, targetParent: Instance?, options: {[string]: any}?)
    return Library.LoadJSON(fetchText(url), targetParent, options)
end

function Library.LoadDefault(targetParent: Instance?, options: {[string]: any}?)
    options = options or {}
    local url = options.DataURL or Library.DefaultDataURL
    local text
    if options.JSONText then
        text = options.JSONText
    elseif type(readfile) == "function" and options.UseLocalFile ~= false then
        local ok, result = pcall(readfile, options.DataFile or "DandysWorldUIData.json")
        if ok and type(result) == "string" and #result > 0 then text = result end
    end
    if not text then text = fetchText(url) end
    return Library.LoadJSON(text, targetParent, options)
end

local function findNode(data: any, pathSuffix: string): any
    local clean = string.gsub(pathSuffix, "^%.+", "")
    local exact, suffix
    local function walk(node: any)
        if not node then return end
        local path = node.path or ""
        if path == clean or path:sub(-#clean) == clean or path:sub(-#clean - 1) == "." .. clean then
            if node.className == "ScreenGui" and pathSuffix == node.name then exact = exact or node end
            suffix = suffix or node
        end
        for _, child in ipairs(node.children or {}) do walk(child) end
    end
    for _, entry in ipairs(data.roots or {}) do walk(entry.tree) end
    if exact then return exact end
    return suffix
end

function Library.LoadScreen(screenName: string, targetParent: Instance?, options: {[string]: any}?)
    assert(Library._Data, "Load data first with Library.LoadDefault or Library.LoadJSON")
    options = options or {}
    options.Screen = screenName
    local dump = Library._Data
    local entry
    for _, item in ipairs(dump.roots or {}) do if item.rootName == screenName then entry = item; break end end
    if not entry then error("Screen not found: " .. screenName) end
    local subset = {format=dump.format, version=dump.version, game=dump.game, summary=dump.summary, roots={entry}, assets=dump.assets, images=dump.images, soundCatalog=dump.soundCatalog}
    local result = Library.Reconstruct(subset, targetParent, options)
    options.Screen = nil
    return result
end

function Library.CreateTemplate(templateName: string, targetParent: Instance, options: {[string]: any}?)
    assert(Library._Data, "Load data first with Library.LoadDefault or Library.LoadJSON")
    assert(targetParent, "CreateTemplate requires a parent GuiObject or ScreenGui")
    local data = Library._Data
    local templateRecord = data.templates and data.templates[templateName]
    local templateNode = templateRecord and templateRecord.tree or nil
    if not templateNode then
        local path = Library.TemplateIndex[templateName] or templateName
        templateNode = findNode(data, path)
    end
    if not templateNode then error("Template not found: " .. templateName) end
    local subset = {format=data.format, version=data.version, game=data.game, summary=data.summary, roots={{rootName=templateName, tree=templateNode}}, assets=data.assets, images=data.images, soundCatalog=data.soundCatalog}
    local result = Library.Reconstruct(subset, targetParent, options or {})
    return result
end

function Library.GetScreens()
    local result = {}
    for _, entry in ipairs((Library._Data and Library._Data.roots) or {}) do table.insert(result, entry.rootName) end
    return result
end

function Library.GetTemplates()
    local result = {}
    for name in pairs(Library.TemplateIndex) do table.insert(result, name) end
    table.sort(result)
    return result
end

function Library.GetImageReferences()
    local result = {}
    for _, image in ipairs(Library.Images) do table.insert(result, image) end
    return result
end

function Library.GetSoundCatalog()
    local result = {}
    for _, sound in ipairs(Library.SoundCatalog) do table.insert(result, sound) end
    return result
end

local function findSound(query: any): any
    if type(query) == "table" then
        for _, sound in ipairs(Library.SoundCatalog) do
            if query.path and sound.path == query.path then return sound end
            if query.name and sound.name == query.name and (not query.path or sound.path == query.path) then return sound end
        end
    elseif type(query) == "string" then
        for _, sound in ipairs(Library.SoundCatalog) do if sound.path == query then return sound end end
        for _, sound in ipairs(Library.SoundCatalog) do if sound.name == query then return sound end end
        local queryLower = string.lower(query)
        for _, sound in ipairs(Library.SoundCatalog) do
            if string.find(string.lower(sound.name or ""), queryLower, 1, true) then return sound end
        end
    end
    return nil
end

function Library.CreateSound(soundNameOrPath: any, parent: Instance, overrides: {[string]: any}?)
    assert(parent, "CreateSound requires a parent")
    local record = findSound(soundNameOrPath)
    assert(record, "Sound not found: " .. tostring(soundNameOrPath))
    local sound = Instance.new("Sound")
    sound.Name = record.name or "GameSound"
    sound.SoundId = record.SoundId or ""
    sound.Volume = tonumber(record.Volume) or 0.5
    sound.PlaybackSpeed = tonumber(record.PlaybackSpeed) or 1
    sound.Looped = record.Looped == true
    if record.RollOffMaxDistance then pcall(function() sound.RollOffMaxDistance = record.RollOffMaxDistance end) end
    for key, value in pairs(overrides or {}) do pcall(function() sound[key] = value end) end
    sound.Parent = parent
    return sound
end

function Library.PlaySound(soundNameOrPath: any, parent: Instance, overrides: {[string]: any}?)
    local sound = Library.CreateSound(soundNameOrPath, parent, overrides)
    sound:Play()
    if not sound.Looped then
        sound.Ended:Connect(function()
            if sound and sound.Parent then sound:Destroy() end
        end)
    end
    return sound
end

-- Simple creator helpers for building new controls in the captured game's broad style.
Library.Components = {}
function Library.Components.Create(className: string, parent: Instance?, properties: {[string]: any}?)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do pcall(function() instance[key] = value end) end
    if parent then instance.Parent = parent end
    return instance
end
function Library.Components.Corner(parent: Instance, radius: number?)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = parent
    return corner
end
function Library.Components.Stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Library.Theme.Border
    stroke.Thickness = thickness or 2
    stroke.Transparency = transparency or 0
    stroke.Parent = parent
    return stroke
end
function Library.Components.Gradient(parent: Instance, colorA: Color3?, colorB: Color3?, rotation: number?)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colorA or Library.Theme.Pink, colorB or Library.Theme.Yellow)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end
function Library.Components.Frame(parent: Instance, name: string, properties: {[string]: any}?)
    local props = {Name=name, BackgroundColor3=Library.Theme.Panel, BorderSizePixel=0}
    for key, value in pairs(properties or {}) do props[key] = value end
    local frame = Library.Components.Create("Frame", parent, props)
    Library.Components.Corner(frame, 10)
    return frame
end
function Library.Components.Label(parent: Instance, text: string, properties: {[string]: any}?)
    local props = {Name="Label", BackgroundTransparency=1, Text=text, TextColor3=Library.Theme.Ink, Font=Library.Theme.Font, TextSize=18, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center}
    for key, value in pairs(properties or {}) do props[key] = value end
    return Library.Components.Create("TextLabel", parent, props)
end
function Library.Components.Button(parent: Instance, text: string, callback: (() -> ())?, properties: {[string]: any}?)
    local props = {Name="Button", Text=text, AutoButtonColor=true, BackgroundColor3=Library.Theme.Pink, BorderSizePixel=0, TextColor3=Color3.new(1,1,1), Font=Library.Theme.Font, TextSize=18, Size=UDim2.fromOffset(150,42)}
    for key, value in pairs(properties or {}) do props[key] = value end
    local button = Library.Components.Create("TextButton", parent, props)
    Library.Components.Corner(button, 9)
    Library.Components.Stroke(button, Library.Theme.Ink, 1)
    if callback then button.Activated:Connect(callback) end
    return button
end
function Library.Components.Image(parent: Instance, image: string, properties: {[string]: any}?)
    local props = {Name="Image", BackgroundTransparency=1, Image=image, ScaleType=Enum.ScaleType.Fit}
    for key, value in pairs(properties or {}) do props[key] = value end
    return Library.Components.Create("ImageLabel", parent, props)
end

--============================================================
-- Dandy's World-style control library
-- Functional window + tabs + buttons + toggles + sliders + more.
--============================================================

local UserInputService = game:GetService("UserInputService")

Library.ControlTheme = {
    Font = Enum.Font.FredokaOne,
    BodyFont = Enum.Font.GothamMedium,
    Ink = Color3.fromRGB(0, 13, 76),
    Text = Color3.fromRGB(255, 255, 255),
    Panel = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(255, 248, 235),
    Soft = Color3.fromRGB(255, 239, 244),
    Muted = Color3.fromRGB(100, 103, 128),
    Pink = Color3.fromRGB(255, 33, 103),
    PinkDark = Color3.fromRGB(219, 20, 83),
    Yellow = Color3.fromRGB(255, 225, 0),
    Mint = Color3.fromRGB(180, 248, 107),
    Border = Color3.fromRGB(0, 13, 76),
    Track = Color3.fromRGB(230, 229, 237),
}

local function mergeTables(base, overrides)
    local result = {}
    for key, value in pairs(base or {}) do result[key] = value end
    for key, value in pairs(overrides or {}) do result[key] = value end
    return result
end

local function make(className, parent, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        pcall(function() object[key] = value end)
    end
    if parent then object.Parent = parent end
    return object
end

local function round(parent, radius)
    return make("UICorner", parent, {CornerRadius = UDim.new(0, radius or 10)})
end

local function outline(parent, color, thickness, transparency)
    return make("UIStroke", parent, {
        Color = color or Library.ControlTheme.Border,
        Thickness = thickness or 1.5,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function safeCall(callback, ...)
    if type(callback) == "function" then
        local ok, err = pcall(callback, ...)
        if not ok then warn("[DandysWorldUI] Callback error: " .. tostring(err)) end
    end
end

local function playControlSound(window, soundKind)
    local sounds = window and window.Sounds
    local soundId = sounds and (sounds[soundKind] or sounds.Default)
    if type(soundId) ~= "string" or soundId == "" or not window.ScreenGui then return end
    local ok, sound = pcall(function()
        local created = Instance.new("Sound")
        created.Name = "UI_" .. tostring(soundKind or "Click")
        created.SoundId = soundId
        created.Volume = window.SoundVolume or 0.35
        created.Parent = window.ScreenGui
        return created
    end)
    if not ok or not sound then return end
    sound:Play()
    if not sound.Looped then
        sound.Ended:Connect(function()
            if sound.Parent then sound:Destroy() end
        end)
    end
end

local function normalizeConfig(config, callback)
    if type(config) == "string" then
        return {Name = config, Callback = callback}
    end
    config = config or {}
    if callback ~= nil and config.Callback == nil then config.Callback = callback end
    return config
end

local function createText(parent, name, text, position, size, color, font, textSize, align)
    return make("TextLabel", parent, {
        Name = name,
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Text = tostring(text or ""),
        TextColor3 = color,
        Font = font,
        TextSize = textSize,
        TextWrapped = true,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
end

local function trackConnection(window, connection)
    table.insert(window._connections, connection)
    return connection
end

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

function Library.CreateWindow(selfOrConfig, maybeConfig)
    local config = selfOrConfig == Library and maybeConfig or selfOrConfig
    config = config or {}

    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local parent = config.Parent

    if not parent and config.UseHiddenUI == true and type(gethui) == "function" then
        local ok, hidden = pcall(gethui)
        if ok then parent = hidden end
    end
    if not parent then
        assert(localPlayer, "Pass config.Parent outside a LocalScript")
        parent = localPlayer:WaitForChild("PlayerGui")
    end

    local window = setmetatable({}, Window)
    window.Theme = mergeTables(Library.ControlTheme, config.Theme)
    window.Title = config.Title or "Dandy's World"
    window.Subtitle = config.Subtitle or "UI Library"
    window._connections = {}
    window._tabs = {}
    window._destroyed = false
    window._minimized = false
    if config.ToggleKey == false then
        window.ToggleKey = nil
    else
        window.ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    end
    window.Sounds = config.Sounds or {}
    window.SoundVolume = math.clamp(tonumber(config.SoundVolume) or 0.35, 0, 10)

    local theme = window.Theme
    local screenGui = make("ScreenGui", parent, {
        Name = config.Name or "DandysWorldUILibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = config.DisplayOrder or 80,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    window.ScreenGui = screenGui

    local main = make("Frame", screenGui, {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.88, 0, 0.78, 0),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    window.Main = main
    round(main, 14)
    outline(main, theme.Ink, 2)
    make("UISizeConstraint", main, {
        MinSize = Vector2.new(330, 300),
        MaxSize = Vector2.new(860, 620),
    })

    local top = make("Frame", main, {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.Pink,
        BorderSizePixel = 0,
    })
    -- A yellow accent stripe mimics the playful high-contrast game styling.
    make("Frame", top, {
        Name = "AccentStripe",
        Position = UDim2.new(0, 0, 1, -4),
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = theme.Yellow,
        BorderSizePixel = 0,
    })

    createText(top, "WindowTitle", window.Title,
        UDim2.fromOffset(16, 4), UDim2.new(1, -110, 0, 25), theme.Text,
        theme.Font, 19, Enum.TextXAlignment.Left)
    local subtitle = createText(top, "WindowSubtitle", window.Subtitle,
        UDim2.fromOffset(17, 26), UDim2.new(1, -110, 0, 16), theme.Text,
        theme.BodyFont, 10, Enum.TextXAlignment.Left)
    subtitle.TextTransparency = 0.12
    window._titleLabel = top:FindFirstChild("WindowTitle")

    local close = make("TextButton", top, {
        Name = "CloseButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -9, 0.5, -1),
        Size = UDim2.fromOffset(30, 29),
        BackgroundColor3 = theme.Yellow,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = theme.Ink,
        TextSize = 24,
        Font = theme.Font,
        AutoButtonColor = true,
    })
    round(close, 8)
    outline(close, theme.Ink, 1.2)
    trackConnection(window, close.Activated:Connect(function()
        playControlSound(window, "Close")
        window:Destroy()
    end))

    local minimize = make("TextButton", top, {
        Name = "MinimizeButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -45, 0.5, -1),
        Size = UDim2.fromOffset(27, 27),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
        Text = "−",
        TextColor3 = theme.Ink,
        TextSize = 23,
        Font = theme.Font,
        AutoButtonColor = true,
    })
    round(minimize, 8)
    outline(minimize, theme.Ink, 1.1)

    local body = make("Frame", main, {
        Name = "Body",
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 1, -48),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
    })

    local sidebar = make("Frame", body, {
        Name = "Sidebar",
        Size = UDim2.new(0, 145, 1, 0),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
    })
    make("Frame", sidebar, {
        Name = "Divider",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = theme.Ink,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
    })
    createText(sidebar, "MenuLabel", "MENU", UDim2.fromOffset(12, 10),
        UDim2.new(1, -24, 0, 22), theme.Muted, theme.BodyFont, 10, Enum.TextXAlignment.Left)

    local tabList = make("ScrollingFrame", sidebar, {
        Name = "TabList",
        Position = UDim2.fromOffset(8, 37),
        Size = UDim2.new(1, -16, 1, -45),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Pink,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    make("UIListLayout", tabList, {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local content = make("Frame", body, {
        Name = "Content",
        Position = UDim2.new(0, 147, 0, 0),
        Size = UDim2.new(1, -147, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    local pageTitle = createText(content, "PageTitle", "Choose a tab",
        UDim2.fromOffset(17, 10), UDim2.new(1, -34, 0, 31), theme.Ink,
        theme.Font, 21, Enum.TextXAlignment.Left)
    local pageSubtitle = createText(content, "PageSubtitle", "Settings and controls",
        UDim2.fromOffset(18, 39), UDim2.new(1, -36, 0, 19), theme.Muted,
        theme.BodyFont, 10, Enum.TextXAlignment.Left)

    local pages = make("Frame", content, {
        Name = "Pages",
        Position = UDim2.fromOffset(10, 64),
        Size = UDim2.new(1, -20, 1, -74),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    window._tabList = tabList
    window._pages = pages
    window._pageTitle = pageTitle
    window._pageSubtitle = pageSubtitle
    window._body = body

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    trackConnection(window, top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
            dragInput = input
        end
    end))
    trackConnection(window, top.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    trackConnection(window, UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart and startPosition and
            (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end))
    trackConnection(window, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragInput = nil
        end
    end))

    trackConnection(window, minimize.Activated:Connect(function()
        playControlSound(window, "Click")
        window._minimized = not window._minimized
        body.Visible = not window._minimized
        main.Size = if window._minimized then UDim2.new(0.72, 0, 0, 48) else UDim2.new(0.88, 0, 0.78, 0)
        minimize.Text = if window._minimized then "+" else "−"
    end))

    if window.ToggleKey then
        trackConnection(window, UserInputService.InputBegan:Connect(function(input, processed)
            if processed or UserInputService:GetFocusedTextBox() then return end
            if input.KeyCode == window.ToggleKey then
                screenGui.Enabled = not screenGui.Enabled
            end
        end))
    end

    function window:SetTitle(title, subtitleText)
        self.Title = tostring(title or self.Title)
        if self._titleLabel then self._titleLabel.Text = self.Title end
        local sub = self.Main.TitleBar:FindFirstChild("WindowSubtitle")
        if sub and subtitleText ~= nil then sub.Text = tostring(subtitleText) end
    end

    function window:SelectTab(tabOrName)
        local target = tabOrName
        if type(tabOrName) == "string" then
            target = nil
            for _, tabObject in ipairs(self._tabs) do
                if tabObject.Name == tabOrName then target = tabObject break end
            end
        end
        if not target then return false end
        for _, tabObject in ipairs(self._tabs) do
            local selected = tabObject == target
            tabObject.Page.Visible = selected
            tabObject.Button.BackgroundColor3 = selected and theme.Yellow or theme.Panel
            tabObject.Button.TextColor3 = theme.Ink
            tabObject.ButtonStroke.Transparency = selected and 0 or 0.8
        end
        self._pageTitle.Text = target.Name
        self._pageSubtitle.Text = target.Description or "Settings and controls"
        self.ActiveTab = target
        return true
    end

    function window:CreateTab(name, tabConfig)
        tabConfig = tabConfig or {}
        name = tostring(name or tabConfig.Name or ("Tab " .. tostring(#self._tabs + 1)))
        local tabObject = setmetatable({}, Tab)
        tabObject.Window = self
        tabObject.Name = name
        tabObject.Description = tabConfig.Description or "Settings and controls"
        tabObject._order = #self._tabs + 1

        local tabButton = make("TextButton", tabList, {
            Name = "Tab_" .. string.gsub(name, "%W", ""),
            Size = UDim2.new(1, -2, 0, 38),
            BackgroundColor3 = theme.Panel,
            BorderSizePixel = 0,
            Text = (tabConfig.Icon and (tostring(tabConfig.Icon) .. "   ") or "") .. name,
            TextColor3 = theme.Ink,
            Font = theme.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = tabObject._order,
        })
        round(tabButton, 8)
        local tabStroke = outline(tabButton, theme.Ink, 1.2, 0.82)
        make("UIPadding", tabButton, {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 5),
        })

        local page = make("ScrollingFrame", pages, {
            Name = "Page_" .. string.gsub(name, "%W", ""),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = theme.Pink,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        })
        make("UIPadding", page, {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 7),
        })
        make("UIListLayout", page, {
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        tabObject.Button = tabButton
        tabObject.ButtonStroke = tabStroke
        tabObject.Page = page
        table.insert(self._tabs, tabObject)
        trackConnection(self, tabButton.Activated:Connect(function()
            playControlSound(self, "Tab")
            self:SelectTab(tabObject)
        end))
        if #self._tabs == 1 or tabConfig.Selected == true then self:SelectTab(tabObject) end
        return tabObject
    end

    function window:Notify(title, message, duration)
        local toast = make("Frame", screenGui, {
            Name = "Toast",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 16),
            Size = UDim2.fromOffset(270, 72),
            BackgroundColor3 = theme.Panel,
            BorderSizePixel = 0,
            ZIndex = 50,
        })
        round(toast, 10)
        outline(toast, theme.Ink, 1.5)
        make("Frame", toast, {
            Size = UDim2.new(0, 6, 1, 0),
            BackgroundColor3 = theme.Pink,
            BorderSizePixel = 0,
            ZIndex = 51,
        })
        make("TextLabel", toast, {
            Name = "Title",
            Position = UDim2.fromOffset(17, 8),
            Size = UDim2.new(1, -27, 0, 23),
            BackgroundTransparency = 1,
            Text = tostring(title or "Notice"),
            TextColor3 = theme.Ink,
            TextSize = 15,
            Font = theme.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 51,
        })
        make("TextLabel", toast, {
            Name = "Message",
            Position = UDim2.fromOffset(17, 32),
            Size = UDim2.new(1, -27, 0, 30),
            BackgroundTransparency = 1,
            Text = tostring(message or ""),
            TextColor3 = theme.Muted,
            TextSize = 11,
            Font = theme.BodyFont,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 51,
        })
        task.delay(tonumber(duration) or 3, function()
            if toast.Parent then toast:Destroy() end
        end)
        return toast
    end

    function window:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
        self._connections = {}
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end

    return window
end

function Tab:_nextOrder()
    self._controlOrder = (self._controlOrder or 0) + 1
    return self._controlOrder
end

function Tab:_card(name, height)
    local theme = self.Window.Theme
    local card = make("Frame", self.Page, {
        Name = string.gsub(tostring(name or "Control"), "%W", "") .. "Control",
        Size = UDim2.new(1, -2, 0, height),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder(),
    })
    round(card, 10)
    outline(card, theme.Ink, 1.1, 0.86)
    return card
end

function Tab:CreateSection(name)
    local theme = self.Window.Theme
    local section = make("Frame", self.Page, {
        Name = "Section",
        Size = UDim2.new(1, -2, 0, 25),
        BackgroundTransparency = 1,
        LayoutOrder = self:_nextOrder(),
    })
    createText(section, "Title", tostring(name or "SECTION"), UDim2.fromOffset(2, 0),
        UDim2.new(1, -4, 1, 0), theme.Pink, theme.Font, 14, Enum.TextXAlignment.Left)
    return section
end

function Tab:CreateDivider()
    local theme = self.Window.Theme
    local frame = make("Frame", self.Page, {
        Name = "Divider",
        Size = UDim2.new(1, -4, 0, 2),
        BackgroundColor3 = theme.Yellow,
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder(),
    })
    round(frame, 1)
    return frame
end

function Tab:CreateLabel(text, labelConfig)
    labelConfig = labelConfig or {}
    local theme = self.Window.Theme
    local card = self:_card(labelConfig.Name or "Label", labelConfig.Height or 38)
    createText(card, "Text", tostring(text or labelConfig.Text or ""),
        UDim2.fromOffset(12, 2), UDim2.new(1, -24, 1, -4),
        labelConfig.Color or theme.Ink, labelConfig.Font or theme.BodyFont,
        labelConfig.TextSize or 12, Enum.TextXAlignment.Left)
    return card
end

function Tab:CreateParagraph(config)
    config = normalizeConfig(config)
    local theme = self.Window.Theme
    local card = self:_card(config.Name or config.Title or "Paragraph", config.Height or 74)
    createText(card, "Title", config.Title or "Information",
        UDim2.fromOffset(12, 5), UDim2.new(1, -24, 0, 23), theme.Ink,
        theme.Font, 14, Enum.TextXAlignment.Left)
    local body = createText(card, "Content", config.Content or config.Text or "",
        UDim2.fromOffset(12, 28), UDim2.new(1, -24, 1, -32), theme.Muted,
        theme.BodyFont, 11, Enum.TextXAlignment.Left)
    body.TextYAlignment = Enum.TextYAlignment.Top
    return card
end

function Tab:CreateButton(config, callback)
    config = normalizeConfig(config, callback)
    local theme = self.Window.Theme
    local card = self:_card(config.Name or "Button", config.Height or 61)
    local name = tostring(config.Name or config.Text or "Button")
    createText(card, "Label", name, UDim2.fromOffset(12, 4),
        UDim2.new(1, -139, 0, if config.Description then 25 else 52), theme.Ink,
        theme.Font, 14, Enum.TextXAlignment.Left)
    if config.Description then
        local desc = createText(card, "Description", config.Description,
            UDim2.fromOffset(12, 29), UDim2.new(1, -140, 0, 24), theme.Muted,
            theme.BodyFont, 10, Enum.TextXAlignment.Left)
        desc.TextTruncate = Enum.TextTruncate.AtEnd
    end
    local button = make("TextButton", card, {
        Name = "Action",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(config.ButtonWidth or 112, 36),
        BackgroundColor3 = config.Color or theme.Pink,
        BorderSizePixel = 0,
        Text = config.ButtonText or "RUN",
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = theme.Font,
        AutoButtonColor = true,
    })
    round(button, 8)
    outline(button, theme.Ink, 1.2)
    trackConnection(self.Window, button.Activated:Connect(function()
        playControlSound(self.Window, "Click")
        safeCall(config.Callback, button)
    end))
    return {Instance = card, Button = button}
end

function Tab:CreateToggle(config, callback)
    config = normalizeConfig(config, callback)
    local theme = self.Window.Theme
    local card = self:_card(config.Name or "Toggle", config.Height or 61)
    createText(card, "Label", config.Name or "Toggle", UDim2.fromOffset(12, 4),
        UDim2.new(1, -100, 0, if config.Description then 25 else 52), theme.Ink,
        theme.Font, 14, Enum.TextXAlignment.Left)
    if config.Description then
        local desc = createText(card, "Description", config.Description,
            UDim2.fromOffset(12, 29), UDim2.new(1, -105, 0, 24), theme.Muted,
            theme.BodyFont, 10, Enum.TextXAlignment.Left)
        desc.TextTruncate = Enum.TextTruncate.AtEnd
    end
    local track = make("Frame", card, {
        Name = "Switch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(48, 27),
        BackgroundColor3 = theme.Track,
        BorderSizePixel = 0,
    })
    round(track, 14)
    local knob = make("Frame", track, {
        Name = "Knob",
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(21, 21),
        BackgroundColor3 = theme.Panel,
        BorderSizePixel = 0,
    })
    round(knob, 11)
    outline(knob, theme.Ink, 0.7, 0.82)
    local hitbox = make("TextButton", card, {
        Name = "ToggleButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.fromOffset(65, 48),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    local state = config.Default == true
    local controller = {Instance = card, Button = hitbox, Track = track, Knob = knob}
    local function setValue(value, skipCallback)
        local previous = state
        state = value == true
        track.BackgroundColor3 = state and theme.Mint or theme.Track
        knob.Position = state and UDim2.new(1, -24, 0, 3) or UDim2.fromOffset(3, 3)
        if not skipCallback and previous ~= state then
            playControlSound(self.Window, "Toggle")
            safeCall(config.Callback, state)
        end
    end
    function controller:SetValue(value) setValue(value, false) end
    function controller:GetValue() return state end
    trackConnection(self.Window, hitbox.Activated:Connect(function() setValue(not state, false) end))
    setValue(state, true)
    return controller
end

function Tab:CreateSlider(config, callback)
    config = normalizeConfig(config, callback)
    local theme = self.Window.Theme
    local minValue = tonumber(config.Min) or 0
    local maxValue = tonumber(config.Max) or 100
    if maxValue < minValue then minValue, maxValue = maxValue, minValue end
    local increment = tonumber(config.Increment) or 1
    if increment <= 0 then increment = 1 end
    local decimals = tonumber(config.Decimals)
    if decimals == nil then decimals = (increment % 1 == 0) and 0 or 2 end
    local card = self:_card(config.Name or "Slider", config.Height or 79)
    createText(card, "Label", config.Name or "Slider", UDim2.fromOffset(12, 4),
        UDim2.new(1, -100, 0, 25), theme.Ink, theme.Font, 14, Enum.TextXAlignment.Left)
    local valueLabel = createText(card, "Value", "", UDim2.new(1, -86, 0, 4),
        UDim2.fromOffset(72, 25), theme.Pink, theme.Font, 13, Enum.TextXAlignment.Right)

    local track = make("Frame", card, {
        Name = "Track",
        Position = UDim2.new(0, 13, 0, 44),
        Size = UDim2.new(1, -26, 0, 9),
        BackgroundColor3 = theme.Track,
        BorderSizePixel = 0,
    })
    round(track, 5)
    local fill = make("Frame", track, {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.Pink,
        BorderSizePixel = 0,
    })
    round(fill, 5)
    local knob = make("Frame", track, {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(17, 17),
        BackgroundColor3 = theme.Yellow,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    round(knob, 9)
    outline(knob, theme.Ink, 1.2)
    local hitbox = make("TextButton", track, {
        Name = "Hitbox",
        Position = UDim2.new(0, -5, 0, -10),
        Size = UDim2.new(1, 10, 1, 20),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
    })

    local current = math.clamp(tonumber(config.Default) or minValue, minValue, maxValue)
    local dragging = false
    local controller = {Instance = card, Track = track, Fill = fill, Knob = knob, ValueLabel = valueLabel}
    local function roundToIncrement(value)
        value = minValue + math.floor(((value - minValue) / increment) + 0.5) * increment
        value = math.clamp(value, minValue, maxValue)
        local factor = 10 ^ decimals
        return math.floor(value * factor + 0.5) / factor
    end
    local function render()
        local fraction = if maxValue == minValue then 0 else (current - minValue) / (maxValue - minValue)
        fraction = math.clamp(fraction, 0, 1)
        fill.Size = UDim2.new(fraction, 0, 1, 0)
        knob.Position = UDim2.new(fraction, 0, 0.5, 0)
        valueLabel.Text = string.format("%.*f", decimals, current)
    end
    local function setValue(value, skipCallback)
        current = roundToIncrement(tonumber(value) or minValue)
        render()
        if not skipCallback then safeCall(config.Callback, current) end
    end
    local function fromInput(inputX)
        local left = track.AbsolutePosition.X
        local width = track.AbsoluteSize.X
        if width <= 0 then return end
        local fraction = math.clamp((inputX - left) / width, 0, 1)
        setValue(minValue + fraction * (maxValue - minValue), false)
    end
    function controller:SetValue(value) setValue(value, false) end
    function controller:GetValue() return current end

    trackConnection(self.Window, hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            playControlSound(self.Window, "Slider")
            fromInput(input.Position.X)
        end
    end))
    trackConnection(self.Window, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input.Position.X)
        end
    end))
    trackConnection(self.Window, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    setValue(current, true)
    return controller
end

function Tab:CreateDropdown(config, callback)
    config = normalizeConfig(config, callback)
    local theme = self.Window.Theme
    local choices = config.Options or {}
    local card = self:_card(config.Name or "Dropdown", 65)
    createText(card, "Label", config.Name or "Dropdown", UDim2.fromOffset(12, 4),
        UDim2.new(1, -145, 0, 26), theme.Ink, theme.Font, 14, Enum.TextXAlignment.Left)
    local selected = config.Default
    if selected == nil then selected = choices[1] end
    local selector = make("TextButton", card, {
        Name = "SelectedOption",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -9, 0, 12),
        Size = UDim2.fromOffset(config.Width or 130, 35),
        BackgroundColor3 = theme.Soft,
        BorderSizePixel = 0,
        Text = tostring(selected or "Select…") .. "  ▾",
        TextColor3 = theme.Ink,
        Font = theme.BodyFont,
        TextSize = 11,
        AutoButtonColor = true,
    })
    round(selector, 7)
    outline(selector, theme.Ink, 1, 0.75)
    local open = false
    local optionButtons = {}
    local controller = {Instance = card, Button = selector}
    local function setValue(value, skipCallback)
        selected = value
        selector.Text = tostring(selected) .. "  ▾"
        if not skipCallback then safeCall(config.Callback, selected) end
    end
    local function closeChoices()
        open = false
        for _, button in ipairs(optionButtons) do button:Destroy() end
        table.clear(optionButtons)
        card.Size = UDim2.new(1, -2, 0, 65)
    end
    trackConnection(self.Window, selector.Activated:Connect(function()
        playControlSound(self.Window, "Click")
        if open then closeChoices(); return end
        open = true
        local count = math.min(#choices, 8)
        card.Size = UDim2.new(1, -2, 0, 65 + count * 30 + 5)
        for index = 1, count do
            local choice = choices[index]
            local choiceButton = make("TextButton", card, {
                Name = "Option" .. index,
                Position = UDim2.new(0, 10, 0, 61 + (index - 1) * 30),
                Size = UDim2.new(1, -20, 0, 26),
                BackgroundColor3 = (choice == selected) and theme.Yellow or theme.Background,
                BorderSizePixel = 0,
                Text = tostring(choice),
                TextColor3 = theme.Ink,
                TextSize = 11,
                Font = theme.BodyFont,
                AutoButtonColor = true,
                LayoutOrder = 20 + index,
            })
            round(choiceButton, 6)
            table.insert(optionButtons, choiceButton)
            trackConnection(self.Window, choiceButton.Activated:Connect(function()
                playControlSound(self.Window, "Click")
                setValue(choice, false)
                closeChoices()
            end))
        end
    end))
    function controller:SetValue(value) setValue(value, false) end
    function controller:GetValue() return selected end
    return controller
end

function Tab:CreateTextbox(config, callback)
    config = normalizeConfig(config, callback)
    local theme = self.Window.Theme
    local card = self:_card(config.Name or "Textbox", 65)
    createText(card, "Label", config.Name or "Textbox", UDim2.fromOffset(12, 4),
        UDim2.new(1, -150, 0, 25), theme.Ink, theme.Font, 13, Enum.TextXAlignment.Left)
    local input = make("TextBox", card, {
        Name = "Input",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(config.Width or 135, 36),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Text = config.Default or "",
        PlaceholderText = config.Placeholder or "Type here...",
        PlaceholderColor3 = theme.Muted,
        TextColor3 = theme.Ink,
        TextSize = 11,
        Font = theme.BodyFont,
        ClearTextOnFocus = config.ClearOnFocus == true,
    })
    round(input, 7)
    outline(input, theme.Ink, 1, 0.75)
    trackConnection(self.Window, input.FocusLost:Connect(function(enterPressed)
        if not config.OnlyOnEnter or enterPressed then safeCall(config.Callback, input.Text, enterPressed) end
    end))
    return {Instance = card, Input = input, GetValue = function() return input.Text end}
end

function Tab:CreateKeybind(config, callback)
    config = normalizeConfig(config, callback)
    local theme = self.Window.Theme
    local card = self:_card(config.Name or "Keybind", 61)
    createText(card, "Label", config.Name or "Keybind", UDim2.fromOffset(12, 4),
        UDim2.new(1, -130, 1, -8), theme.Ink, theme.Font, 13, Enum.TextXAlignment.Left)
    local current = config.Default or Enum.KeyCode.Unknown
    local button = make("TextButton", card, {
        Name = "CurrentKey",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(105, 34),
        BackgroundColor3 = theme.Soft,
        BorderSizePixel = 0,
        Text = current.Name,
        TextColor3 = theme.Ink,
        Font = theme.BodyFont,
        TextSize = 12,
        AutoButtonColor = true,
    })
    round(button, 7)
    outline(button, theme.Ink, 1, 0.75)
    local listening = false
    local controller = {Instance = card, Button = button}
    trackConnection(self.Window, button.Activated:Connect(function()
        listening = true
        button.Text = "Press key..."
    end))
    trackConnection(self.Window, UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if listening then
            if processed or UserInputService:GetFocusedTextBox() then return end
            current = input.KeyCode
            button.Text = current.Name
            listening = false
            safeCall(config.OnChanged, current)
            return
        end
        if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == current then
            safeCall(config.Callback, current)
        end
    end))
    function controller:SetValue(keyCode)
        current = keyCode
        button.Text = current.Name
        safeCall(config.OnChanged, current)
    end
    function controller:GetValue() return current end
    return controller
end

function Tab:CreateSliderToggle(config, callback)
    return self:CreateToggle(config, callback)
end

-- A small helper for game-style UI click/notification sounds. Asset IDs must be
-- supplied by the caller or available through Library.LoadJSON / SoundCatalog.
function Library.CreateUISound(parent, soundId, volume, playbackSpeed)
    assert(parent, "CreateUISound requires a parent")
    local sound = make("Sound", parent, {
        Name = "UISound",
        SoundId = tostring(soundId or ""),
        Volume = tonumber(volume) or 0.45,
        PlaybackSpeed = tonumber(playbackSpeed) or 1,
    })
    return sound
end

function Library.PlayUISound(parent, soundId, volume, playbackSpeed)
    local sound = Library.CreateUISound(parent, soundId, volume, playbackSpeed)
    sound:Play()
    if not sound.Looped then
        sound.Ended:Connect(function()
            if sound.Parent then sound:Destroy() end
        end)
    end
    return sound
end


return Library
