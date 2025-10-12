-- Local Replace GUI (KRNL-ready)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local GUI_NAME = "LocalReplace_v2"
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SIZE = Enum.ThumbnailSize.Size48x48

local aliasMap = {} -- [player] = {aliasName, thumb}
local billboardMap = {}
local UI = {}

-- Safe parent
local function safeParent(inst, parent)
    if inst and parent then
        pcall(function() inst.Parent = parent end)
    end
end

-- Fetch thumbnail
local function fetchThumb(username)
    local ok, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(username, THUMB_TYPE, THUMB_SIZE)
    end)
    if not ok then thumb = nil end
    return thumb
end

-- Make billboard above player head
local function makeBillboard(plr)
    if not plr.Character then return end
    if billboardMap[plr] then pcall(function() billboardMap[plr]:Destroy() end) end

    local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return end

    repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")

    local screen = Instance.new("ScreenGui")
    screen.Name = GUI_NAME.."_BB_"..plr.Name
    screen.ResetOnSpawn = false
    if LocalPlayer.PlayerGui:FindFirstChild(screen.Name) then
        LocalPlayer.PlayerGui[screen.Name]:Destroy()
    end
    safeParent(screen, LocalPlayer.PlayerGui)

    local bg = Instance.new("BillboardGui")
    bg.Name = "AliasBillboard"
    bg.Adornee = head
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0,160,0,48)
    bg.StudsOffset = Vector3.new(0,2.4,0)
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
end

-- Update billboard
local function updateBillboard(plr)
    if not plr then return end
    if not billboardMap[plr] then makeBillboard(plr) end
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
        if subLbl then subLbl.Text = "Original: "..plr.Name end
        if img and alias.thumb then pcall(function() img.Image = alias.thumb end) end
    else
        if nameLbl then nameLbl.Text = plr.Name end
        if subLbl then subLbl.Text = "" end
        if img then pcall(function() img.Image = "" end) end
    end
end

-- Local leaderboard
local function refreshLeaderboard()
    if not UI.Leaderboard then return end
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
        name.Position = UDim2.new(0,6,0,0)
        name.BackgroundTransparency = 1
        local alias = aliasMap[plr]
        if alias then
            name.Text = alias.aliasName.."  ("..plr.DisplayName..")"
        else
            name.Text = plr.Name.."  ("..plr.DisplayName..")"
        end
        name.TextColor3 = Color3.new(1,1,1)
        name.Font = Enum.Font.Gotham
        name.TextSize = 14
        name.TextXAlignment = Enum.TextXAlignment.Left

        local thumb = Instance.new("ImageLabel", row)
        thumb.Size = UDim2.new(0,28,0,28)
        thumb.Position = UDim2.new(0.74,0,0.08,0)
        thumb.BackgroundTransparency = 1
        if alias and alias.thumb then thumb.Image = alias.thumb else thumb.Image = "" end

        order = order + 1
    end
    sc.CanvasSize = UDim2.new(0,0,0, math.max(1,#Players:GetPlayers()*36))
end

-- Create GUI
local function createGUI()
    repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")
    if UI.Main then UI.Main:Destroy() end

    local screen = Instance.new("ScreenGui")
    screen.Name = GUI_NAME.."_Main"
    screen.ResetOnSpawn = false
    safeParent(screen, LocalPlayer.PlayerGui)

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0,360,0,400)
    frame.Position = UDim2.new(0.02,0,0.05,0)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local header = Instance.new("TextLabel", frame)
    header.Size = UDim2.new(1,0,0,30)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextColor3 = Color3.new(1,1,1)
    header.TextSize = 16
    header.Text = "Local Replace GUI"

    -- Players button
    local playersBtn = Instance.new("TextButton", frame)
    playersBtn.Size = UDim2.new(0.48,0,0,26)
    playersBtn.Position = UDim2.new(0.02,0,0.08,0)
    playersBtn.Text = "Players"
    playersBtn.Font = Enum.Font.GothamSemibold
    playersBtn.TextColor3 = Color3.new(1,1,1)
    playersBtn.BackgroundColor3 = Color3.fromRGB(50,120,50)

    -- Input for username
    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(0.96,0,0,26)
    input.Position = UDim2.new(0.02,0,0.15,0)
    input.PlaceholderText = "Enter username to mimic"
    input.ClearTextOnFocus = true
    input.Text = ""

    -- Apply button
    local applyBtn = Instance.new("TextButton", frame)
    applyBtn.Size = UDim2.new(0.96,0,0,26)
    applyBtn.Position = UDim2.new(0.02,0,0.22,0)
    applyBtn.Text = "Apply Replacement"
    applyBtn.Font = Enum.Font.GothamSemibold
    applyBtn.TextColor3 = Color3.new(1,1,1)
    applyBtn.BackgroundColor3 = Color3.fromRGB(50,50,150)

    -- Leaderboard
    local lb = Instance.new("Frame", frame)
    lb.Size = UDim2.new(0.96,0,0.65,0)
    lb.Position = UDim2.new(0.02,0,0.3,0)
    lb.BackgroundColor3 = Color3.fromRGB(20,20,25)
    lb.BorderSizePixel = 0

    local sc = Instance.new("ScrollingFrame", lb)
    sc.Size = UDim2.new(1,0,1,0)
    sc.BackgroundTransparency = 1
    sc.ScrollBarThickness = 6
    local layout = Instance.new("UIListLayout", sc)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    UI.Main = screen
    UI.Input = input
    UI.ApplyBtn = applyBtn
    UI.LeaderboardScroller = sc

    -- Player selection
    local selectedPlayer = nil
    local listOpen = false

    playersBtn.MouseButton1Click:Connect(function()
        if listOpen then return end
        listOpen = true
        local listFrame = Instance.new("Frame", frame)
        listFrame.Size = UDim2.new(0.96,0,0.35,0)
        listFrame.Position = UDim2.new(0.02,0,0.08,30)
        listFrame.BackgroundColor3 = Color3.fromRGB(30,30,35)
        listFrame.BorderSizePixel = 0

        local sc = Instance.new("ScrollingFrame", listFrame)
        sc.Size = UDim2.new(1,0,1,0)
        sc.BackgroundTransparency = 1
        sc.ScrollBarThickness = 6
        local layout = Instance.new("UIListLayout", sc)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        for _,p in ipairs(Players:GetPlayers()) do
            local btn = Instance.new("TextButton", sc)
            btn.Size = UDim2.new(1,0,0,26)
            btn.Text = p.Name.." ("..p.DisplayName..")"
            btn.Font = Enum.Font.Gotham
            btn.TextColor3 = Color3.new(1,1,1)
            btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = p
                UI.Input.Text = ""
            end)
        end

        -- Close button
        local closeBtn = Instance.new("TextButton", listFrame)
        closeBtn.Size = UDim2.new(1,0,0,26)
        closeBtn.Position = UDim2.new(0,0,1,-26)
        closeBtn.Text = "Close"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.BackgroundColor3 = Color3.fromRGB(140,40,40)
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.MouseButton1Click:Connect(function()
            listFrame:Destroy()
            listOpen = false
        end)
    end)

    -- Apply replacement
    applyBtn.MouseButton1Click:Connect(function()
        if not selectedPlayer then
            StarterGui:SetCore("SendNotification",{Title="Local Replace",Text="Select a player first",Duration=2})
            return
        end
        local username = UI.Input.Text
        if username == "" then
            StarterGui:SetCore("SendNotification",{Title="Local Replace",Text="Enter a username",Duration=2})
            return
        end
        local thumb = fetchThumb(username)
        aliasMap[selectedPlayer] = {aliasName = username, thumb = thumb
