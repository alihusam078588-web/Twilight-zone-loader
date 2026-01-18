local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "TZ HUB",
})

Window:EditOpenButton({
    Title = "TZ HUB",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local Tab = Window:Tab({
    Title = "Main",
    Locked = false,
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== BLACK SCREEN GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local BlackFrame = Instance.new("Frame")
BlackFrame.Size = UDim2.fromScale(1,1)
BlackFrame.BackgroundColor3 = Color3.new(0,0,0)
BlackFrame.BorderSizePixel = 0
BlackFrame.Visible = false
BlackFrame.Parent = ScreenGui

-- ===== FLOOR LABEL =====
local FloorLabel = Instance.new("TextLabel")
FloorLabel.Size = UDim2.fromScale(1,0.08)
FloorLabel.BackgroundTransparency = 1
FloorLabel.TextColor3 = Color3.fromRGB(255,255,255)
FloorLabel.Font = Enum.Font.GothamBold
FloorLabel.TextScaled = true
FloorLabel.Text = ""
FloorLabel.Visible = false
FloorLabel.Parent = BlackFrame

-- ===== GENERATOR LABEL =====
local GeneratorLabel = Instance.new("TextLabel")
GeneratorLabel.Size = UDim2.fromScale(1,0.08)
GeneratorLabel.BackgroundTransparency = 1
GeneratorLabel.TextColor3 = Color3.fromRGB(255,255,255)
GeneratorLabel.Font = Enum.Font.GothamBold
GeneratorLabel.TextScaled = true
GeneratorLabel.Text = ""
GeneratorLabel.Visible = false
GeneratorLabel.Parent = BlackFrame

-- ===== STATES =====
local BlackScreenEnabled = false
local ShowFloorEnabled = false
local ShowGeneratorsEnabled = false

-- ===== FLOOR VALUE =====
local function getFloorValue()
    local info = workspace:FindFirstChild("Info")
    if not info then return nil end
    local floor = info:FindFirstChild("Floor")
    if not floor then return nil end

    if floor:IsA("IntValue") or floor:IsA("NumberValue") then
        return floor.Value
    end

    return floor.Name
end

-- ===== GENERATOR COUNT (DYNAMIC & MAP SAFE) =====
local function getGeneratorInfo()
    local room = workspace:FindFirstChild("CurrentRoom")
    if not room then return 0,0 end

    local total = 0
    local completed = 0

    for _,obj in ipairs(room:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name == "Generators" then
            for _,gen in ipairs(obj:GetChildren()) do
                total += 1
                local stats = gen:FindFirstChild("Stats")
                local done = stats and stats:FindFirstChild("Completed")
                if done and done:IsA("BoolValue") and done.Value == true then
                    completed += 1
                end
            end
        end
    end

    return total, completed
end

-- ===== UPDATE UI =====
local function updateUI()
    BlackFrame.Visible = BlackScreenEnabled

    -- Floor text
    if BlackScreenEnabled and ShowFloorEnabled then
        local value = getFloorValue()
        FloorLabel.Text = value and ("Floor "..tostring(value)) or "Floor ?"
        FloorLabel.Position = UDim2.new(0,0,0.42,0)
        FloorLabel.Visible = true
    else
        FloorLabel.Visible = false
        FloorLabel.Text = ""
    end

    -- Generator text
    if BlackScreenEnabled and ShowGeneratorsEnabled then
        local total, done = getGeneratorInfo()
        GeneratorLabel.Text = "Generators "..tostring(done).."/"..tostring(total)

        if ShowFloorEnabled then
            GeneratorLabel.Position = UDim2.new(0,0,0.52,0)
        else
            GeneratorLabel.Position = UDim2.new(0,0,0.45,0)
        end

        GeneratorLabel.Visible = true
    else
        GeneratorLabel.Visible = false
        GeneratorLabel.Text = ""
    end

    -- Floor part visibility
    local floorPart = workspace:FindFirstChild("Info") and workspace.Info:FindFirstChild("Floor")
    if floorPart then
        floorPart.Transparency = ShowFloorEnabled and 0 or 1
        floorPart.CanCollide = ShowFloorEnabled
    end
end

-- ===== AUTO UPDATE SYSTEM =====
local Connections = {}

local function clearConnections()
    for _,c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Connections)
end

local function setupAutoUpdate()
    clearConnections()

    -- Floor value change
    local info = workspace:FindFirstChild("Info")
    if info then
        local floor = info:FindFirstChild("Floor")
        if floor and floor:IsA("ValueBase") then
            table.insert(Connections, floor.Changed:Connect(function()
                updateUI()
            end))
        end
    end

    -- Generator completion change
    local room = workspace:FindFirstChild("CurrentRoom")
    if room then
        for _,obj in ipairs(room:GetDescendants()) do
            if obj:IsA("BoolValue") and obj.Name == "Completed" then
                table.insert(Connections, obj.Changed:Connect(function()
                    updateUI()
                end))
            end
        end
    end
end

-- ===== TOGGLES =====
Tab:Toggle({
    Title = "Black Screen",
    Desc = "Working just like Disable Rendering but it won't hide Riddance gui or Delta icon",
    Default = false,
    Callback = function(v)
        BlackScreenEnabled = v
        updateUI()
    end
})

Tab:Toggle({
    Title = "Show Floor",
    Desc = "While black screen enabled it's gonna show the floor you are in",
    Default = false,
    Callback = function(v)
        ShowFloorEnabled = v
        updateUI()
    end
})

Tab:Toggle({
    Title = "Show Generators",
    Desc = "While Black screen is enabled it gonna show you the generators left and completed",
    Default = false,
    Callback = function(v)
        ShowGeneratorsEnabled = v
        updateUI()
    end
})

-- ===== ROOM CHANGE AUTO REFRESH =====
workspace.ChildAdded:Connect(function(c)
    if c.Name == "CurrentRoom" then
        task.wait(0.2)
        setupAutoUpdate()
        updateUI()
    end
end)

-- ===== INITIAL SETUP =====
task.spawn(function()
    task.wait(1)
    setupAutoUpdate()
    updateUI()
end)
local CoreGui = game:GetService("CoreGui")

local CoreBlackGui = Instance.new("ScreenGui")
CoreBlackGui.Name = "TZ_CoreBlack"
CoreBlackGui.IgnoreGuiInset = true
CoreBlackGui.ResetOnSpawn = false
CoreBlackGui.Enabled = false
CoreBlackGui.Parent = CoreGui

local CoreBlackFrame = Instance.new("Frame")
CoreBlackFrame.Size = UDim2.fromScale(1,1)
CoreBlackFrame.BackgroundColor3 = Color3.new(0,0,0)
CoreBlackFrame.BorderSizePixel = 0
CoreBlackFrame.Parent = CoreBlackGui
local CoreBlackEnabled = false
Tab:Toggle({
    Title = "entire black screen",
    Desc = "This will make the entire screen black and all guis won't show even TZ Hub gui won't show",
    Default = false,
    Callback = function(v)
        CoreBlackEnabled = v
        CoreBlackGui.Enabled = v
    end
})