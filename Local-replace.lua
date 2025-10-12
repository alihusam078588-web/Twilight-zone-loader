-- Local Replace (simple GUI) - KRNL-safe
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local GUI_NAME = "LocalReplaceSimple_v1"
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SIZE = Enum.ThumbnailSize.Size48x48

local aliasMap = {}
local billboardMap = {}
local UI = {}

local function safeParent(inst, parent)
    if inst and parent then
        pcall(function() inst.Parent = parent end)
    end
end

local function fetchUserIdAndThumb(username)
    local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, username)
    if not ok or not id then return nil, nil end
    local ok2, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(id, THUMB_TYPE, THUMB_SIZE)
    end)
    if not ok2 then thumb = nil end
    return id, thumb
end

local function makeBillboardForPlayer(plr)
    if not plr or not plr.Character then return nil end
    if billboardMap[plr] then
        pcall(function() billboardMap[plr]:Destroy() end)
        billboardMap[plr] = nil
    end
    local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return nil end

    repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")

    local screen = Instance.new("ScreenGui")
    screen.Name = GUI_NAME .. "_BB_" .. plr.Name
    screen.ResetOnSpawn = false
    if LocalPlayer.PlayerGui:FindFirstChild(screen.Name) then
        LocalPlayer.PlayerGui[screen.Name]:Destroy()
    end
    safeParent(screen, LocalPlayer.PlayerGui)

    local bg = Instance.new("BillboardGui")
    bg.Name = "AliasBillboard"
    bg.Adornee = head
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 160, 0, 48)
    bg.StudsOffset = Vector3.new(0, 2.4, 0)
    bg.Parent = screen

    local frame = Instance.new("Frame", bg)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1

    local img = Instance.new("ImageLabel", frame)
    img.Name = "Avatar"
    img.Position = UDim2.new(0,6,0.5,-18)
    img.Size = UDim2.new(0,36,0,36)
    img.BackgroundTransparency = 1
    img.Image = ""

    local nameLbl = Instance.new("TextLabel", frame)
    nameLbl.Name = "Name"
    nameLbl.Position = UDim2.new(0,48,0,4)
    nameLbl.Size = UDim2.new(0,106,0,20)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextColor3 = Color3.new(1,1,1)
    nameLbl.Text = plr.Name

    local subLbl = Instance.new("TextLabel", frame)
    subLbl.Name = "Sub"
    subLbl.Position = UDim2.new(0,48,0,22)
    subLbl.Size = UDim2.new(0,106,0,16)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 12
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.TextColor3 = Color3.fromRGB(180,180,180)
    subLbl.Text = ""

    billboardMap[plr] = screen
    return screen
end

local function updateBillboard(plr)
    if not plr then return end
    if not billboardMap[plr] then makeBillboardForPlayer(plr) end
    local screen = billboardMap[plr]
    if not screen then return end
    local bg = screen:FindFirstChild("AliasBillboard")
    if not bg then return end
    local frame = bg:FindFirstChildOfClass("Frame")
    if not frame then return end
    local img = frame:FindFirstChild("Avatar")
    local nameLbl = frame:FindFirstChild("Name")
    local subLbl = frame:FindFirstChild("Sub")

    local alias = aliasMap[plr]
    if alias then
        if nameLbl then nameLbl.Text = alias.aliasName or plr.Name end
        if subLbl then subLbl.Text = "Original: " .. plr.Name end
        if img and alias.thumb then pcall(function() img.Image = alias.thumb end) end
    else
        if nameLbl then nameLbl.Text = plr.Name end
        if subLbl then subLbl.Text = "" end
        if img then pcall(function() img.Image = "" end) end
    end
end

-- Local leaderboard
local function createLocalLeaderboard()
    if UI.Leaderboard then UI.Leaderboard:Destroy() end
    local screen = Instance.new("ScreenGui")
    screen.Name = GUI_NAME .. "_LB"
    screen.ResetOnSpawn = false
    repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")
    safeParent(screen, LocalPlayer.PlayerGui)

    local frame = Instance.new("Frame", screen)
    frame.AnchorPoint = Vector2.new(1,0)
    frame.Position = UDim2.new(0.98,0,0.02,0)
    frame.Size = UDim2.new(0,250,0,260)
    frame.BackgroundTransparency = 0.45
    frame.BackgroundColor3 = Color3.fromRGB(18,18,20)
    frame.BorderSizePixel = 0

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,28)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 14
    title.Text = "Local Leaderboard (visual)"

    local sc = Instance.new("ScrollingFrame", frame)
    sc.Position = UDim2.new(0,0,0,28)
    sc.Size = UDim2.new(1,0,0,232)
    sc.BackgroundTransparency = 1
    sc.ScrollBarThickness = 6

    UI.Leaderboard = screen
    UI.LeaderboardFrame = frame
    UI.LeaderboardScroller = sc
end

local function refreshLocalLeaderboard()
    if not UI.Leaderboard then createLocalLeaderboard() end
    local sc = UI.LeaderboardScroller
    if not sc then return end
    for _,c in ipairs(sc:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    local layout = Instance.new("UIListLayout", sc)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    local order = 1
    for _, plr in ipairs(Players:GetPlayers()) do
        local row = Instance.new("Frame", sc)
        row.Size = UDim2.new(1, -8, 0, 34)
        row.LayoutOrder = order
        row.BackgroundTransparency = 1

        local name = Instance.new("TextLabel", row)
        name.Size = UDim2.new(0.7, 0, 1, 0)
        name.Position = UDim2.new(0, 6, 0, 0)
        name.BackgroundTransparency = 1
        local alias = aliasMap[plr]
        if alias then
            name.Text = alias.aliasName .. "  (" .. plr.DisplayName .. ")"
        else
            name.Text = plr.Name .. "  (" .. plr.DisplayName .. ")"
        end
        name.TextColor3 = Color3.new(1,1,1)
        name.Font = Enum.Font.Gotham
        name.TextSize = 14
        name.TextXAlignment = Enum.TextXAlignment.Left

        local thumb = Instance.new("ImageLabel", row)
        thumb.Size = UDim2.new(0,28,0,28)
        thumb.Position = UDim2.new(0.74, 0, 0.08, 0)
        thumb.BackgroundTransparency = 1
        if alias and alias.thumb then thumb.Image = alias.thumb else thumb.Image = "" end

        order = order + 1
    end
    sc.CanvasSize = UDim2.new(0,0,0, math.max(1, (#Players:GetPlayers() * 36)))
end

-- Populate GUI list safely (KRNL-safe)
local function createMainGui()
    if UI.Main then UI.Main:Destroy() end
    repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")

    -- original createMainGui code here ...
    -- just replace all `goto cont` with
    -- local skip = false
    -- if filter logic fails then skip = true
    -- if not skip then create row end
end

-- Wiring lifecycle
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function() task.wait(0.25); updateBillboard(p) end)
        if p.Character then updateBillboard(p) end
    end
end
Players.PlayerAdded:Connect(function(p) task.wait(0.25); updateBillboard(p); refreshLocalLeaderboard() end)
Players.PlayerRemoving:Connect(function(p)
    aliasMap[p] = nil
    if billboardMap[p] then pcall(function() billboardMap[p]:Destroy() end) billboardMap[p]=nil end
    refreshLocalLeaderboard()
end)

-- UI creation
createMainGui()
createLocalLeaderboard()
StarterGui:SetCore("SendNotification",{Title="Local Replace",Text="GUI ready.",Duration=4})

RunService.Heartbeat:Connect(function()
    for plr,_ in pairs(billboardMap) do
        if plr and plr.Character then updateBillboard(plr) end
    end
end)
