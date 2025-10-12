-- Local-only visual "replace player" GUI (KRNL-friendly)
-- Paste into your executor and run in-game (private server recommended)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- config
local GUI_NAME = "LocalReplaceGUI_v1"
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SIZE = Enum.ThumbnailSize.Size48x48

-- state
local aliasMap = {}      -- [player] = { aliasName=string, thumb=url }
local billboardMap = {}  -- [player] = ScreenGui (holds BillboardGui)
local UI = {}

local function safeParent(inst, parent)
    if inst and parent then
        pcall(function() inst.Parent = parent end)
    end
end

local function fetchUserIdAndThumb(username)
    local ok, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
    if not ok or not userId then return nil, nil end
    local ok2, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(userId, THUMB_TYPE, THUMB_SIZE)
    end)
    if not ok2 then thumb = nil end
    return userId, thumb
end

-- create billboard UI for a player (stored in billboardMap)
local function makeBillboardForPlayer(plr)
    if not plr or not plr.Character then return nil end
    if billboardMap[plr] then
        pcall(function() billboardMap[plr]:Destroy() end)
        billboardMap[plr] = nil
    end

    local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChildWhichIsA("BasePart")
    if not head then return nil end

    local screen = Instance.new("ScreenGui")
    screen.Name = GUI_NAME .. "_Billboard_" .. plr.Name
    screen.ResetOnSpawn = false
    safeParent(screen, LocalPlayer:WaitForChild("PlayerGui"))

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
        if img and alias.thumb then
            pcall(function() img.Image = alias.thumb end)
        end
    else
        if nameLbl then nameLbl.Text = plr.Name end
        if subLbl then subLbl.Text = "" end
        if img then pcall(function() img.Image = "" end) end
    end
end

-- local leaderboard (visual only)
local function createLocalLeaderboard()
    if UI.Leaderboard then UI.Leaderboard:Destroy() end
    local screen = Instance.new("ScreenGui")
    screen.Name = GUI_NAME .. "_LB"
    screen.ResetOnSpawn = false
    safeParent(screen, LocalPlayer:WaitForChild("PlayerGui"))

    local frame = Instance.new("Frame", screen)
    frame.AnchorPoint = Vector2.new(1,0)
    frame.Position = UDim2.new(0.98,0,0.02,0)
    frame.Size = UDim2.new(0,260,0,300)
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
    sc.Size = UDim2.new(1,0,0,272)
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
        name.Size = UDim2.new(0.65, 0, 1, 0)
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
        thumb.Position = UDim2.new(0.75, 0, 0.08, 0)
        thumb.BackgroundTransparency = 1
        if alias and alias.thumb then thumb.Image = alias.thumb else thumb.Image = "" end

        order = order + 1
    end
    sc.CanvasSize = UDim2.new(0,0,0, math.max(1, (#Players:GetPlayers() * 36)))
end

-- Main manager GUI
local function createMainGui()
    if UI.Main then UI.Main:Destroy() end
    local screen = Instance.new("ScreenGui")
    screen.Name = GUI_NAME .. "_Main"
    screen.ResetOnSpawn = false
    safeParent(screen, LocalPlayer:WaitForChild("PlayerGui"))

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 360, 0, 420)
    frame.Position = UDim2.new(0.02, 0, 0.06, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,24)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local header = Instance.new("TextLabel", frame)
    header.Size = UDim2.new(1,0,0,30)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextColor3 = Color3.new(1,1,1)
    header.TextSize = 16
    header.Text = "Local Replace Manager"

    local search = Instance.new("TextBox", frame)
    search.Size = UDim2.new(0.6, -8, 0, 26)
    search.Position = UDim2.new(0, 8, 0, 36)
    search.PlaceholderText = "Filter players..."
    search.ClearTextOnFocus = false

    local refreshBtn = Instance.new("TextButton", frame)
    refreshBtn.Size = UDim2.new(0.18, 0, 0, 26)
    refreshBtn.Position = UDim2.new(0.62, 6, 0, 36)
    refreshBtn.Text = "Refresh"
    refreshBtn.Font = Enum.Font.Gotham
    refreshBtn.TextSize = 14
    refreshBtn.BackgroundColor3 = Color3.fromRGB(60,60,66)

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0.18, 0, 0, 26)
    closeBtn.Position = UDim2.new(0.82, -8, 0, 36)
    closeBtn.Text = "Close"
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextSize = 14
    closeBtn.BackgroundColor3 = Color3.fromRGB(140,40,40)

    local listFrame = Instance.new("ScrollingFrame", frame)
    listFrame.Position = UDim2.new(0, 8, 0, 68)
    listFrame.Size = UDim2.new(1, -16, 0, 300)
    listFrame.CanvasSize = UDim2.new(0,0)
    listFrame.BackgroundTransparency = 1
    listFrame.ScrollBarThickness = 6

    local uiListLayout = Instance.new("UIListLayout", listFrame)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0,6)

    local selectedPlayer = nil

    local function populateList(filter)
        for _, child in pairs(listFrame:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
        local order = 1
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if filter and filter ~= "" then
                    if not tostring(plr.Name):lower():find(filter:lower()) and not tostring(plr.DisplayName):lower():find(filter:lower()) then goto cont end
                end

                local row = Instance.new("Frame", listFrame)
                row.Size = UDim2.new(1, 0, 0, 40)
                row.BackgroundTransparency = 1
                row.LayoutOrder = order

                local nameLbl = Instance.new("TextLabel", row)
                nameLbl.Size = UDim2.new(0.6, 0, 1, 0)
                nameLbl.Position = UDim2.new(0, 6, 0, 0)
                nameLbl.BackgroundTransparency = 1
                local alias = aliasMap[plr]
                if alias then
                    nameLbl.Text = alias.aliasName .. "   (" .. plr.Name .. ")"
                else
                    nameLbl.Text = plr.Name .. "   (" .. plr.DisplayName .. ")"
                end
                nameLbl.TextColor3 = Color3.new(1,1,1)
                nameLbl.Font = Enum.Font.Gotham
                nameLbl.TextSize = 14
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                local btn = Instance.new("TextButton", row)
                btn.Size = UDim2.new(0.28, -8, 0.75, 0)
                btn.Position = UDim2.new(0.66, 0, 0.12, 0)
                btn.Text = "Manage"
                btn.Font = Enum.Font.GothamSemibold
                btn.TextSize = 13
                btn.BackgroundColor3 = Color3.fromRGB(50,120,50)
                btn.TextColor3 = Color3.new(1,1,1)

                btn.MouseButton1Click:Connect(function()
                    selectedPlayer = plr
                    UI.EditFrame.Visible = true
                    UI.EditFor.Text = "Editing: " .. plr.Name
                    UI.EditInput.Text = ""
                    local alias = aliasMap[plr]
                    if alias then UI.EditInput.PlaceholderText = alias.aliasName else UI.EditInput.PlaceholderText = "Enter username to mimic" end
                end)

                order = order + 1
            end
            ::cont::
        end
        listFrame.CanvasSize = UDim2.new(0,0,0, math.max(1, (order*46)))
    end

    refreshBtn.MouseButton1Click:Connect(function() populateList(search.Text); refreshLocalLeaderboard() end)
    closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)
    search:GetPropertyChangedSignal("Text"):Connect(function() populateList(search.Text) end)

    local edit = Instance.new("Frame", frame)
    edit.Size = UDim2.new(0, 340, 0, 90)
    edit.Position = UDim2.new(0, 10, 0, 372)
    edit.BackgroundColor3 = Color3.fromRGB(16,16,18)
    edit.BorderSizePixel = 0
    edit.Name = "EditFrame"

    local editFor = Instance.new("TextLabel", edit)
    editFor.Name = "EditFor"
    editFor.Size = UDim2.new(1, -12, 0, 24)
    editFor.Position = UDim2.new(0, 6, 0, 6)
    editFor.BackgroundTransparency = 1
    editFor.Font = Enum.Font.GothamBold
    editFor.TextColor3 = Color3.new(1,1,1)
    editFor.TextSize = 13
    editFor.Text = "Select a player to manage"

    local input = Instance.new("TextBox", edit)
    input.Name = "EditInput"
    input.Size = UDim2.new(1, -12, 0, 28)
    input.Position = UDim2.new(0, 6, 0, 32)
    input.PlaceholderText = "Enter target username (e.g. Ali_hhjjj)"
    input.ClearTextOnFocus = true

    local applyBtn = Instance.new("TextButton", edit)
    applyBtn.Size = UDim2.new(0.32, 0, 0, 26)
    applyBtn.Position = UDim2.new(0.02, 0, 0.75, -6)
    applyBtn.Text = "Apply"
    applyBtn.Font = Enum.Font.GothamSemibold
    applyBtn.BackgroundColor3 = Color3.fromRGB(40,140,40)
    applyBtn.TextColor3 = Color3.new(1,1,1)

    local removeBtn = Instance.new("TextButton", edit)
    removeBtn.Size = UDim2.new(0.32, 0, 0, 26)
    removeBtn.Position = UDim2.new(0.36, 0, 0.75, -6)
    removeBtn.Text = "Remove"
    removeBtn.Font = Enum.Font.GothamSemibold
    removeBtn.BackgroundColor3 = Color3.fromRGB(140,40,40)
    removeBtn.TextColor3 = Color3.new(1,1,1)

    UI.Main = screen
    UI.EditFrame = edit
    UI.EditFor = editFor
    UI.EditInput = input

    populateList("")
    refreshLocalLeaderboard()
end

-- lifecycle bindings
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function() task.wait(0.25); updateBillboard(p) end)
        if p.Character then updateBillboard(p) end
    end
end
Players.PlayerAdded:Connect(function(p) task.wait(0.25); updateBillboard(p); refreshLocalLeaderboard() end)
Players.PlayerRemoving:Connect(function(p) aliasMap[p]=nil if billboardMap[p] then pcall(function() billboardMap[p]:Destroy() end) billboardMap[p]=nil end refreshLocalLeaderboard() end)

-- create UIs
createMainGui()
createLocalLeaderboard()

-- apply/remove handlers
UI.EditInput = UI.EditInput or UI.Main:FindFirstChildWhichIsA("Frame") and UI.Main:FindFirstChildWhichIsA("Frame"):FindFirstChild("EditInput")
-- wire apply/remove
do
    local applyBtn = UI.EditFrame and UI.EditFrame:FindFirstChildWhichIsA("TextButton")
    -- We already created applyBtn as local earlier when building; find proper buttons:
    -- safer approach: iterate children of EditFrame to find "Apply" and "Remove" by Text
    local apply, remove
    for _, c in ipairs(UI.EditFrame:GetChildren()) do
        if c:IsA("TextButton") and c.Text == "Apply" then apply = c end
        if c:IsA("TextButton") and c.Text == "Remove" then remove = c end
    end
    if apply then
        apply.MouseButton1Click:Connect(function()
            local selected = nil
            -- find selected player from UI.EditFor text (format "Editing: PlayerName")
            local txt = UI.EditFor and UI.EditFor.Text or ""
            local name = txt:match("^Editing:%s*(.+)$")
            if name then selected = Players:FindFirstChild(name) end
            if not selected then StarterGui:SetCore("SendNotification",{Title="Replace",Text="No player selected",Duration=2}) return end
            local target = UI.EditInput and UI.EditInput.Text or ""
            if not target or target == "" then StarterGui:SetCore("SendNotification",{Title="Replace",Text="Enter a username",Duration=2}); return end
            local id, thumb = fetchUserIdAndThumb(target)
            if not id then StarterGui:SetCore("SendNotification",{Title="Replace",Text="Username not found",Duration=3}); return end
            aliasMap[selected] = { aliasName = target, thumb = thumb }
            updateBillboard(selected)
            refreshLocalLeaderboard()
            StarterGui:SetCore("SendNotification",{Title="Replace",Text=("Applied local alias %s → %s"):format(selected.Name, target),Duration=3})
            UI.EditInput.Text = ""
        end)
    end
    if remove then
        remove.MouseButton1Click:Connect(function()
            local txt = UI.EditFor and UI.EditFor.Text or ""
            local name = txt:match("^Editing:%s*(.+)$")
            local selected = name and Players:FindFirstChild(name)
            if not selected then StarterGui:SetCore("SendNotification",{Title="Replace",Text="No player selected",Duration=2}); return end
            aliasMap[selected] = nil
            if billboardMap[selected] then pcall(function() billboardMap[selected]:Destroy() end) billboardMap[selected] = nil end
            refreshLocalLeaderboard()
            StarterGui:SetCore("SendNotification",{Title="Replace",Text=("Removed alias from %s"):format(selected.Name),Duration=3})
        end)
    end
end

-- update loop keeps billboards fresh
RunService.Heartbeat:Connect(function()
    for plr,_ in pairs(billboardMap) do
        updateBillboard(plr)
    end
end)

-- expose simple console helpers
_G.LocalReplace = _G.LocalReplace or {}
_G.LocalReplace.assign = function(playerNameOrObj, targetUsername)
    local plr = nil
    if typeof(playerNameOrObj) == "Instance" and playerNameOrObj:IsA("Player") then plr = playerNameOrObj
    elseif type(playerNameOrObj) == "string" then plr = Players:FindFirstChild(playerNameOrObj) end
    if not plr then return false, "player not found" end
    local id, thumb = fetchUserIdAndThumb(targetUsername)
    if not id then return false, "username not found" end
    aliasMap[plr] = { aliasName = targetUsername, thumb = thumb }
    updateBillboard(plr)
    refreshLocalLeaderboard()
    return true
end
_G.LocalReplace.remove = function(playerNameOrObj)
    local plr = nil
    if typeof(playerNameOrObj) == "Instance" and playerNameOrObj:IsA("Player") then plr = playerNameOrObj
    elseif type(playerNameOrObj) == "string" then plr = Players:FindFirstChild(playerNameOrObj) end
    if not plr then return false, "player not found" end
    aliasMap[plr] = nil
    if billboardMap[plr] then pcall(function() billboardMap[plr]:Destroy() end) billboardMap[plr] = nil end
    refreshLocalLeaderboard()
    return true
end

StarterGui:SetCore("SendNotification",{Title="Local Replace",Text="GUI ready. Select a player and apply an alias.",Duration=4})
print("Local Replace GUI loaded. Use GUI or _G.LocalReplace.assign(Players.Name, 'TargetUsername').")
