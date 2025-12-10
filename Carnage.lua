local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local containerNames = {
    "Cabinet",
    "Cardboard Box",
    "TrashBin",
    "Metal Locker"
}

local function isContainer(obj)
    for _, name in ipairs(containerNames) do
        if string.find(obj.Name, name) then
            return true
        end
    end
    return false
end

local function ESP_Player(player, character)
    if character:FindFirstChild("PlayerESP_Billboard") then
        character.PlayerESP_Billboard:Destroy()
    end

    local head = character:WaitForChild("Head", 3)
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "PlayerESP_Billboard"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 80)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = character

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1,1,1)
    text.TextScaled = true
    text.Size = UDim2.new(1,0,1,0)
    text.Font = Enum.Font.GothamBold
    text.Parent = bb

    if not character:FindFirstChild("PlayerESP_Highlight") then
        local h = Instance.new("Highlight")
        h.Name = "PlayerESP_Highlight"
        h.FillTransparency = 0.7
        h.OutlineTransparency = 0
        h.FillColor = Color3.fromRGB(0, 255, 255)
        h.Parent = character
    end

    task.spawn(function()
        while character.Parent do
            local backpackItems = {}
            local backpack = player:FindFirstChild("Backpack")

            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    table.insert(backpackItems, tool.Name)
                end
            end

            local equippedItems = {}
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") then
                    table.insert(equippedItems, tool.Name)
                end
            end

            text.Text =
                player.Name ..
                "\nBackpack: " .. (#backpackItems > 0 and table.concat(backpackItems, ", ") or "None") ..
                "\nEquipped: " .. (#equippedItems > 0 and table.concat(equippedItems, ", ") or "None")

            task.wait(0.4)
        end
    end)
end

local function SetupPlayer(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        ESP_Player(player, char)
    end)

    if player.Character then
        ESP_Player(player, player.Character)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        SetupPlayer(plr)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        SetupPlayer(plr)
    end
end)

local function updateContainerESP(obj)
    if not obj:IsA("Model") and not obj:IsA("BasePart") then return end
    if not isContainer(obj) then return end

    if not obj:FindFirstChild("ContainerESP_Highlight") then
        local h = Instance.new("Highlight")
        h.Name = "ContainerESP_Highlight"
        h.FillTransparency = 0.7
        h.OutlineTransparency = 0
        h.FillColor = Color3.fromRGB(255, 150, 0)
        h.Parent = obj
    end

    if not obj:FindFirstChild("ContainerESP_Label") then
        local bb = Instance.new("BillboardGui")
        bb.Name = "ContainerESP_Label"
        bb.Size = UDim2.new(0, 200, 0, 60)
        bb.AlwaysOnTop = true
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.Parent = obj

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.new(1,1,1)
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Size = UDim2.new(1,0,1,0)
        text.Parent = bb
    end

    local label = obj.ContainerESP_Label.TextLabel

    task.spawn(function()
        while obj.Parent do
            local found = {}
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("Tool") then
                    table.insert(found, d.Name)
                end
            end

            label.Text = obj.Name .. "\nItems: " .. (#found > 0 and table.concat(found, ", ") or "None")

            task.wait(0.5)
        end
    end)
end

local function scanContainers()
    for _, v in ipairs(workspace:GetDescendants()) do
        if isContainer(v) then
            updateContainerESP(v)
        end
    end
end

scanContainers()

task.spawn(function()
    while true do
        task.wait(1)
        scanContainers()
    end
end)
