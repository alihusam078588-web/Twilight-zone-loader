--// Auto Black Screen On Execute
pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FullBlack"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")

    -- Full black overlay
    local blackout = Instance.new("Frame")
    blackout.Size = UDim2.new(1,0,1,0)
    blackout.BackgroundColor3 = Color3.new(0,0,0)
    blackout.ZIndex = 10000
    blackout.Visible = true
    blackout.Parent = gui

    -- Screen toggle
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0,90,0,40)
    toggle.Position = UDim2.new(0.5,-45,0.9,0)
    toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Text = "Screen ON"
    toggle.ZIndex = 10001
    toggle.Parent = gui
    toggle.Active = true
    toggle.Draggable = true

    -- Show/Hide Floor button
    local floorBtn = Instance.new("TextButton")
    floorBtn.Size = UDim2.new(0,130,0,40)
    floorBtn.Position = UDim2.new(0.5,-65,0.83,0)
    floorBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    floorBtn.TextColor3 = Color3.new(1,1,1)
    floorBtn.Text = "Hide Floor"
    floorBtn.ZIndex = 10001
    floorBtn.Parent = gui
    floorBtn.Active = true
    floorBtn.Draggable = true

    -- Floor label
    local floorLabel = Instance.new("TextLabel")
    floorLabel.Size = UDim2.new(0,220,0,40)
    floorLabel.Position = UDim2.new(0.5,-110,0.05,0)
    floorLabel.BackgroundTransparency = 1
    floorLabel.TextColor3 = Color3.new(1,1,1)
    floorLabel.TextScaled = true
    floorLabel.Text = ""
    floorLabel.Visible = true
    floorLabel.ZIndex = 10001
    floorLabel.Parent = gui
    floorLabel.Active = true
    floorLabel.Draggable = true

    local isBlack = true
    local floorVisible = true

    -- Update floor text
    local function updateFloor()
        local info = workspace:FindFirstChild("Info")
        if info and info:FindFirstChild("Floor") then
            floorLabel.Text = "Floor " .. tostring(info.Floor.Value)
        else
            floorLabel.Text = "Floor ?"
        end
    end

    updateFloor()

    -- Screen toggle logic
    toggle.MouseButton1Click:Connect(function()
        isBlack = not isBlack
        blackout.Visible = isBlack

        if isBlack then
            toggle.Text = "Screen ON"
            floorLabel.Visible = floorVisible
        else
            toggle.Text = "Screen OFF"
            floorLabel.Visible = false
        end
    end)

    -- Show / Hide floor toggle
    floorBtn.MouseButton1Click:Connect(function()
        floorVisible = not floorVisible
        floorLabel.Visible = isBlack and floorVisible

        if floorVisible then
            floorBtn.Text = "Hide Floor"
        else
            floorBtn.Text = "Show Floor"
        end
    end)

    -- Auto update when floor changes
    if workspace:FindFirstChild("Info") and workspace.Info:FindFirstChild("Floor") then
        workspace.Info.Floor:GetPropertyChangedSignal("Value"):Connect(updateFloor)
    end
end)