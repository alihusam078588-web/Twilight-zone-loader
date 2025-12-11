local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local window = Rayfield:CreateWindow({
    Name = "TZ HUB",
    LoadingTitle = "TZ HUB",
    LoadingSubtitle = "Carnage ESP",
    ConfigurationSaving = { Enabled = true, FileName = "TZHubConfig" }
})

local playersTab = window:CreateTab("Players ESP")
local containersTab = window:CreateTab("Containers ESP")
local alertsTab = window:CreateTab("Kill Alerts")

local playersSection = playersTab:CreateSection("Players Settings")
local containersSection = containersTab:CreateSection("Containers Settings")
local alertsSection = alertsTab:CreateSection("Alerts Settings")

local settings = {
    playersESPEnabled = true,
    containersESPEnabled = true,
    showBackpack = true,
    textSize = 18,
    antiLag = false,
    showHighlights = true,
    updateRate = 0.35,
    containerNames = {"Cabinet","Cardboard Box","TrashBin","Metal Locker"},
    killAlerts = true
}

playersSection:CreateToggle({
    Name = "Enable Players ESP",
    CurrentValue = settings.playersESPEnabled,
    Flag = "playersESPEnabled",
    Callback = function(v) settings.playersESPEnabled = v end
})

playersSection:CreateToggle({
    Name = "Show Backpack Items",
    CurrentValue = settings.showBackpack,
    Flag = "showBackpack",
    Callback = function(v) settings.showBackpack = v end
})

playersSection:CreateToggle({
    Name = "Use Highlights (may lag)",
    CurrentValue = settings.showHighlights,
    Flag = "showHighlights",
    Callback = function(v) settings.showHighlights = v end
})

playersSection:CreateSlider({
    Name = "ESP Text Size",
    Min = 10,
    Max = 40,
    Increment = 1,
    Suffix = "px",
    CurrentValue = settings.textSize,
    Flag = "textSize",
    Callback = function(v) settings.textSize = v end
})

playersSection:CreateToggle({
    Name = "Anti-Lag Mode",
    CurrentValue = settings.antiLag,
    Flag = "antiLag",
    Callback = function(v)
        settings.antiLag = v
        settings.updateRate = v and 1 or 0.35
        if v then settings.showHighlights = false end
    end
})

containersSection:CreateToggle({
    Name = "Enable Containers ESP",
    CurrentValue = settings.containersESPEnabled,
    Flag = "containersESPEnabled",
    Callback = function(v) settings.containersESPEnabled = v end
})

containersSection:CreateToggle({
    Name = "Container Highlights (may lag)",
    CurrentValue = true,
    Flag = "containerHighlights",
    Callback = function(v) settings.containerHighlights = v end
})

containersSection:CreateButton({
    Name = "Rescan Containers Now",
    Callback = function() scanContainers(true) end
})

alertsSection:CreateToggle({
    Name = "Kill Alerts",
    CurrentValue = settings.killAlerts,
    Flag = "killAlerts",
    Callback = function(v) settings.killAlerts = v end
})

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification",{
            Title = "TZ HUB",
            Text = msg,
            Duration = 5
        })
    end)
end

local function isContainerByName(obj)
    for _, name in ipairs(settings.containerNames) do
        if string.find(obj.Name, name) then
            return true
        end
    end
    return false
end

local function ensurePlayerESP(player)
    if not player.Character then return end
    if not settings.playersESPEnabled then return end
    local character = player.Character

    if character:FindFirstChild("TZ_PlayerESP_Gui") then
        character.TZ_PlayerESP_Gui:Destroy()
    end

    if settings.showHighlights then
        if not character:FindFirstChild("TZ_PlayerESP_Highlight") then
            local h = Instance.new("Highlight")
            h.Name = "TZ_PlayerESP_Highlight"
            h.Adornee = character
            h.FillTransparency = settings.antiLag and 1 or 0.7
            h.OutlineTransparency = 0
            h.FillColor = Color3.fromRGB(0,255,255)
            h.Parent = character
        end
    else
        if character:FindFirstChild("TZ_PlayerESP_Highlight") then
            character.TZ_PlayerESP_Highlight:Destroy()
        end
    end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "TZ_PlayerESP_Gui"
    bb.Size = UDim2.new(0,200,0,90)
    bb.Adornee = head
    bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true
    bb.Parent = character

    local label = Instance.new("TextLabel")
    label.Name = "TZ_PlayerESP_Label"
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = settings.textSize
    label.TextWrapped = false
    label.Text = player.Name
    label.Parent = bb
end

local function cleanupPlayerESP(player)
    if player.Character then
        if player.Character:FindFirstChild("TZ_PlayerESP_Gui") then
            player.Character.TZ_PlayerESP_Gui:Destroy()
        end
        if player.Character:FindFirstChild("TZ_PlayerESP_Highlight") then
            player.Character.TZ_PlayerESP_Highlight:Destroy()
        end
    end
end

local function updatePlayerESPText(player)
    if not player.Character then return end
    local gui = player.Character:FindFirstChild("TZ_PlayerESP_Gui")
    if not gui then
        if settings.playersESPEnabled then
            ensurePlayerESP(player)
            gui = player.Character:FindFirstChild("TZ_PlayerESP_Gui")
        else
            return
        end
    end
    if not gui then return end
    local label = gui:FindFirstChild("TZ_PlayerESP_Label")
    if not label then return end

    label.TextSize = settings.textSize

    local backpackItems = {}
    if settings.showBackpack then
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                table.insert(backpackItems, item.Name)
            end
        end
    end

    local equipped = {}
    if player.Character then
        for _, c in ipairs(player.Character:GetChildren()) do
            if c:IsA("Tool") then
                table.insert(equipped, c.Name)
            end
        end
    end

    label.Text =
        player.Name..
        "\nBackpack: "..((#backpackItems>0) and table.concat(backpackItems,", ") or "None")..
        "\nEquipped: "..((#equipped>0) and table.concat(equipped,", ") or "None")
end

local function ensureContainerESP(obj)
    if not obj or not obj.Parent then return end
    if not settings.containersESPEnabled then return end

    if obj:FindFirstChild("TZ_ContainerESP_Gui") then
        obj.TZ_ContainerESP_Gui:Destroy()
    end

    if settings.containerHighlights and settings.showHighlights then
        if not obj:FindFirstChild("TZ_ContainerESP_Highlight") then
            local h = Instance.new("Highlight")
            h.Name = "TZ_ContainerESP_Highlight"
            h.Adornee = obj
            h.FillTransparency = settings.antiLag and 1 or 0.7
            h.OutlineTransparency = 0
            h.FillColor = Color3.fromRGB(255,150,0)
            h.Parent = obj
        end
    else
        if obj:FindFirstChild("TZ_ContainerESP_Highlight") then
            obj.TZ_ContainerESP_Highlight:Destroy()
        end
    end

    local attachmentPart = nil
    if obj:IsA("BasePart") then
        attachmentPart = obj
    else
        attachmentPart = obj:FindFirstChildWhichIsA("BasePart") or obj:FindFirstChild("PrimaryPart")
    end
    if not attachmentPart then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "TZ_ContainerESP_Gui"
    bb.Size = UDim2.new(0,200,0,60)
    bb.Adornee = attachmentPart
    bb.StudsOffset = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop = true
    bb.Parent = obj

    local label = Instance.new("TextLabel")
    label.Name = "TZ_ContainerESP_Label"
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = settings.textSize
    label.Parent = bb
end

local function updateContainerLabel(obj)
    local gui = obj:FindFirstChild("TZ_ContainerESP_Gui")
    if not gui then
        if settings.containersESPEnabled then
            ensureContainerESP(obj)
            gui = obj:FindFirstChild("TZ_ContainerESP_Gui")
        else
            return
        end
    end
    if not gui then return end

    local label = gui:FindFirstChild("TZ_ContainerESP_Label")
    if not label then return end

    label.TextSize = settings.textSize
    local found = {}
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("Tool") then
            table.insert(found, d.Name)
        end
    end
    label.Text = obj.Name.."\nItems: "..((#found>0) and table.concat(found,", ") or "None")
end

local PlayerConnections = {}
local function onPlayerAdded(plr)
    if plr == LocalPlayer then return end
    if PlayerConnections[plr] then
        for _, c in ipairs(PlayerConnections[plr]) do
            c:Disconnect()
        end
    end
    PlayerConnections[plr] = {}

    local function charAdded(char)
        ensurePlayerESP(plr)
        task.spawn(function()
            while char.Parent do
                updatePlayerESPText(plr)
                task.wait(settings.updateRate)
            end
        end)
        if settings.killAlerts then
            local hum = char:WaitForChild("Humanoid",5)
            if hum then
                local conn = hum.Died:Connect(function()
                    local tag = hum:FindFirstChild("creator")
                    if tag and tag.Value and tag.Value ~= plr then
                        notify(tag.Value.Name.." killed "..plr.Name)
                    end
                end)
                table.insert(PlayerConnections[plr],conn)
            end
        end
    end

    plr.CharacterAdded:Connect(charAdded)
    if plr.Character then charAdded(plr.Character) end
end

for _,p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p)
    if PlayerConnections[p] then
        for _, c in ipairs(PlayerConnections[p]) do c:Disconnect() end
        PlayerConnections[p] = nil
    end
    cleanupPlayerESP(p)
end)

task.spawn(function()
    while true do
        for _, v in ipairs(workspace:GetDescendants()) do
            if isContainerByName(v) then
                if settings.containersESPEnabled then
                    updateContainerLabel(v)
                end
            end
        end
        task.wait(settings.updateRate)
    end
end)

playersSection:CreateButton({Name = "Disable All ESP", Callback = function() settings.playersESPEnabled = false settings.containersESPEnabled = false end})
playersSection:CreateButton({Name = "Enable All ESP", Callback = function() settings.playersESPEnabled = true settings.containersESPEnabled = true end})
containersSection:CreateButton({Name = "Clear Container GUIs", Callback = function() for _, v in ipairs(workspace:GetDescendants()) do if isContainerByName(v) then if v:FindFirstChild("TZ_ContainerESP_Gui") then v.TZ_ContainerESP_Gui:Destroy() end if v:FindFirstChild("TZ_ContainerESP_Highlight") then v.TZ_ContainerESP_Highlight:Destroy() end end end end})
alertsSection:CreateButton({Name = "Test Kill Alert", Callback = function() notify("Test: killer killed victim") end})
