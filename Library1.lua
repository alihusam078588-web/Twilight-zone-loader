--!strict
-- Dandy's World UI Reconstruction Library
-- Reconstructs the UI hierarchy from the JSON produced by UI Exporter v3.
-- This module is intended for Roblox Luau. Executor file I/O is not required
-- by the library itself; LoadJSON accepts JSON text supplied by the caller.

local Library = {}
Library.__index = Library

Library.Version = "1.0.0"
Library.DumpFormat = "RobloxUIExport"

-- Colors sampled from the supplied capture; components can override any value.
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

local function lastEnumToken(value: any): string
    local str = tostring(value)
    local token = string.match(str, "([^%.]+)$")
    return token or str
end

local function decodeValue(value: any): any
    if type(value) ~= "table" then
        return value
    end

    local kind = value.type
    if type(kind) ~= "string" then
        return nil
    end

    if kind == "Color3" then
        if value.r ~= nil and value.g ~= nil and value.b ~= nil then
            return Color3.new(value.r, value.g, value.b)
        end

    elseif kind == "UDim" then
        return UDim.new(value.scale or 0, value.offset or 0)

    elseif kind == "UDim2" then
        return UDim2.new(
            value.xScale or 0,
            value.xOffset or 0,
            value.yScale or 0,
            value.yOffset or 0
        )

    elseif kind == "Vector2" then
        return Vector2.new(value.x or 0, value.y or 0)

    elseif kind == "Vector3" then
        return Vector3.new(value.x or 0, value.y or 0, value.z or 0)

    elseif kind == "Rect" then
        local minimum = decodeValue(value.min)
        local maximum = decodeValue(value.max)
        if typeof(minimum) == "Vector2" and typeof(maximum) == "Vector2" then
            return Rect.new(minimum, maximum)
        end

    elseif kind == "EnumItem" then
        local ok, enumValue = pcall(function()
            local enumType = Enum[value.enum]
            return enumType[value.name]
        end)
        if ok then
            return enumValue
        end

    elseif kind == "NumberRange" then
        return NumberRange.new(value.min or 0, value.max or 0)

    elseif kind == "NumberSequence" then
        local points = {}
        for _, point in ipairs(value.keypoints or {}) do
            table.insert(points, NumberSequenceKeypoint.new(
                point.time or 0,
                point.value or 0,
                point.envelope or 0
            ))
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
        local components = value.components
        if type(components) == "table" and #components >= 12 then
            local ok, result = pcall(function()
                return CFrame.new(table.unpack(components))
            end)
            if ok then return result end
        end

    elseif kind == "BrickColor" then
        local ok, result = pcall(BrickColor.new, value.name or "Institutional white")
        if ok then return result end

    elseif kind == "Instance" then
        return { __uiInstanceReference = value.path }
    end

    -- Unknown encoded data types are skipped instead of assigning a table to
    -- a property and causing errors.
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
        title.Text = "UI LIBRARY"
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
            stage.Text = stageText
            detail.Text = detailText
            local fraction = if total > 0 then math.clamp(done / total, 0, 1) else 0
            fill.Size = UDim2.new(fraction, 0, 1, 0)
        end

        return gui, update
    end)

    if not ok then
        return nil, nil
    end

    return screen, updater
end

local function createProgress(parent: Instance, enabled: boolean)
    if not enabled then
        return nil, nil
    end
    local gui, updater = makeProgressGui(parent)
    return gui, updater
end

local function createInstance(className: string): Instance?
    local ok, instance = pcall(Instance.new, className)
    if ok then
        return instance
    end
    return nil
end

local function isSkipped(node: any, options: {[string]: any}): boolean
    local skipNames = options.SkipNames
    if skipNames and skipNames[node.name] then
        return true
    end

    local skipClasses = options.SkipClasses
    if skipClasses and skipClasses[node.className] then
        return true
    end

    return false
end

function Library.Reconstruct(dump: any, targetParent: Instance?, options: {[string]: any}?)
    options = options or {}
    assert(type(dump) == "table", "Reconstruct expects a decoded dump table")
    assert(dump.format == Library.DumpFormat, "Unexpected dump format")

    if not targetParent then
        local players = game:GetService("Players")
        local player = players.LocalPlayer
        assert(player, "Pass targetParent when running outside a LocalScript")
        targetParent = player:WaitForChild("PlayerGui")
    end

    local yieldEvery = math.max(1, tonumber(options.YieldEvery) or 25)
    local maxInstances = math.max(1, tonumber(options.MaxInstances) or 15000)
    local showProgress = options.ProgressGui ~= false
    local progressGui, progressUpdate = createProgress(targetParent, showProgress)

    local allRecords = {}
    local pathMap = {}
    local createdRoots = {}
    local stats = {
        created = 0,
        skipped = 0,
        propertyErrors = 0,
        creationErrors = 0,
        unresolvedReferences = 0,
        attributesRestored = 0,
        truncatedByLimit = false,
        sourceWasTruncated = dump.summary and dump.summary.truncated == true or false,
    }

    local function notify(stage: string, done: number, total: number, detail: string)
        if progressUpdate then
            progressUpdate(stage, done, total, detail)
        end
        if type(options.OnProgress) == "function" then
            pcall(options.OnProgress, stage, done, total, detail, stats)
        end
    end

    -- Stage 1: instantiate objects and register source-path mappings.
    local function addNode(node: any, parent: Instance, isTop: boolean): Instance?
        if not node or type(node) ~= "table" then return nil end
        if isSkipped(node, options) then
            stats.skipped += 1
            return nil
        end

        if stats.created >= maxInstances then
            stats.truncatedByLimit = true
            return nil
        end

        local instance = createInstance(node.className or "Folder")
        if not instance then
            stats.creationErrors += 1
            -- If a class is not creatable, place its children under the last
            -- valid parent instead of dropping the entire subtree.
            for _, child in ipairs(node.children or {}) do
                addNode(child, parent, false)
            end
            return nil
        end

        instance.Name = node.name or node.className or "UIObject"
        instance.Parent = parent
        stats.created += 1

        if node.path then
            pathMap[node.path] = instance
        end
        table.insert(allRecords, {node = node, instance = instance})
        if isTop then
            table.insert(createdRoots, instance)
        end

        if stats.created % yieldEvery == 0 then
            notify("Building UI tree", stats.created, maxInstances, instance.Name .. " (" .. instance.ClassName .. ")")
            task.wait()
        end

        for _, child in ipairs(node.children or {}) do
            if stats.created >= maxInstances then
                stats.truncatedByLimit = true
                break
            end
            addNode(child, instance, false)
        end

        return instance
    end

    local roots = dump.roots or {}
    local rootNodeCount = 0

    -- The exported PlayerGui is a synthetic root. Use the provided target
    -- PlayerGui itself so ScreenGuis stay direct children and render correctly.
    for _, rootEntry in ipairs(roots) do
        local tree = rootEntry.tree
        if tree then
            if tree.className == "PlayerGui" then
                if tree.path then pathMap[tree.path] = targetParent end
                for _, child in ipairs(tree.children or {}) do
                    if stats.created >= maxInstances then
                        stats.truncatedByLimit = true
                        break
                    end
                    local before = stats.created
                    addNode(child, targetParent, true)
                    if stats.created > before then rootNodeCount += 1 end
                end
            else
                local before = stats.created
                addNode(tree, targetParent, true)
                if stats.created > before then rootNodeCount += 1 end
            end
        end
    end

    -- Stage 2: restore properties after every created object has a path mapping.
    local totalRecords = #allRecords
    for index, record in ipairs(allRecords) do
        local node = record.node
        local instance = record.instance
        for propertyName, encodedValue in pairs(node.properties or {}) do
            if propertyName ~= "Parent" and propertyName ~= "Archivable" then
                local decoded = decodeValue(encodedValue)
                if type(decoded) == "table" and decoded.__uiInstanceReference then
                    local path = decoded.__uiInstanceReference
                    local referenced = pathMap[path]
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
                if ok then
                    stats.attributesRestored += 1
                end
            end
        end

        if options.RestoreTags and type(node.tags) == "table" then
            local collectionService = game:GetService("CollectionService")
            for _, tag in ipairs(node.tags) do
                pcall(function() collectionService:AddTag(instance, tag) end)
            end
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
        task.delay(2, function()
            if progressGui and progressGui.Parent then
                progressGui:Destroy()
            end
        end)
    end

    local result = {
        Roots = createdRoots,
        ByPath = pathMap,
        Stats = stats,
        SourceSummary = dump.summary,
        ProgressGui = progressGui,
    }

    function result:Destroy()
        for _, root in ipairs(self.Roots) do
            pcall(function() root:Destroy() end)
        end
        if self.ProgressGui then
            pcall(function() self.ProgressGui:Destroy() end)
        end
    end

    return result
end

function Library.LoadJSON(jsonText: string, targetParent: Instance?, options: {[string]: any}?)
    local httpService = game:GetService("HttpService")
    local dump = httpService:JSONDecode(jsonText)
    return Library.Reconstruct(dump, targetParent, options)
end

-- Reusable component helpers for new UIs using the captured game's general look.
Library.Components = {}

function Library.Components.Create(className: string, parent: Instance?, properties: {[string]: any}?)
    local instance = Instance.new(className)
    if properties then
        for key, value in pairs(properties) do
            pcall(function() instance[key] = value end)
        end
    end
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
    gradient.Color = ColorSequence.new(
        colorA or Library.Theme.Pink,
        colorB or Library.Theme.Yellow
    )
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

function Library.Components.Frame(parent: Instance, name: string, properties: {[string]: any}?)
    local props = {
        Name = name,
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
    }
    for key, value in pairs(properties or {}) do props[key] = value end
    local frame = Library.Components.Create("Frame", parent, props)
    Library.Components.Corner(frame, 10)
    return frame
end

function Library.Components.Label(parent: Instance, text: string, properties: {[string]: any}?)
    local props = {
        Name = "Label",
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Library.Theme.Ink,
        Font = Library.Theme.Font,
        TextSize = 18,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }
    for key, value in pairs(properties or {}) do props[key] = value end
    return Library.Components.Create("TextLabel", parent, props)
end

function Library.Components.Button(parent: Instance, text: string, callback: (() -> ())?, properties: {[string]: any}?)
    local props = {
        Name = "Button",
        Text = text,
        AutoButtonColor = true,
        BackgroundColor3 = Library.Theme.Pink,
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Library.Theme.Font,
        TextSize = 18,
        Size = UDim2.fromOffset(150, 42),
    }
    for key, value in pairs(properties or {}) do props[key] = value end
    local button = Library.Components.Create("TextButton", parent, props)
    Library.Components.Corner(button, 9)
    Library.Components.Stroke(button, Library.Theme.Ink, 1)
    if callback then button.Activated:Connect(callback) end
    return button
end

function Library.Components.Image(parent: Instance, image: string, properties: {[string]: any}?)
    local props = {
        Name = "Image",
        BackgroundTransparency = 1,
        Image = image,
        ScaleType = Enum.ScaleType.Fit,
    }
    for key, value in pairs(properties or {}) do props[key] = value end
    return Library.Components.Create("ImageLabel", parent, props)
end

return Library