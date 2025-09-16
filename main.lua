-- 🌌 Twilight Zone Hub (Styled like .ftgs hub)
-- Created by Ali_hhjjj + ChatGPT

-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "TwilightZoneHub"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
title.BorderSizePixel = 0
title.Text = "🌌 Twilight Zone Hub"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = mainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 1, 0)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = title

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 120, 1, -35)
sidebar.Position = UDim2.new(0, 0, 0, 35)
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

-- Content Frame
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -120, 1, -35)
content.Position = UDim2.new(0, 120, 0, 35)
content.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
content.BorderSizePixel = 0
content.Parent = mainFrame

-- Helper: Create Sidebar Button
local function createSidebarButton(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, (order-1)*45)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = sidebar
    return btn
end

-- Pages
local pages = {}

-- Toggle Page
local togglePage = Instance.new("Frame")
togglePage.Size = UDim2.new(1,0,1,0)
togglePage.BackgroundTransparency = 1
togglePage.Visible = true
togglePage.Parent = content
pages["Toggle"] = togglePage

-- Toggle Example
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 200, 0, 40)
toggle.Position = UDim2.new(0, 20, 0, 20)
toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggle.Text = "Example Toggle: OFF"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.Gotham
toggle.TextSize = 14
toggle.Parent = togglePage

local toggleState = false
toggle.MouseButton1Click:Connect(function()
    toggleState = not toggleState
    toggle.Text = "Example Toggle: " .. (toggleState and "ON" or "OFF")
    print("[Twilight Zone] Toggle switched:", toggleState)
end)

-- Button Page
local buttonPage = Instance.new("Frame")
buttonPage.Size = UDim2.new(1,0,1,0)
buttonPage.BackgroundTransparency = 1
buttonPage.Visible = false
buttonPage.Parent = content
pages["Button"] = buttonPage

-- Normal Button
local btn1 = Instance.new("TextButton")
btn1.Size = UDim2.new(0, 200, 0, 40)
btn1.Position = UDim2.new(0, 20, 0, 20)
btn1.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
btn1.Text = "Run Action"
btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
btn1.Font = Enum.Font.Gotham
btn1.TextSize = 14
btn1.Parent = buttonPage

btn1.MouseButton1Click:Connect(function()
    print("[Twilight Zone] Action button clicked")
end)

-- Locked Button
local lockedBtn = Instance.new("TextButton")
lockedBtn.Size = UDim2.new(0, 200, 0, 40)
lockedBtn.Position = UDim2.new(0, 20, 0, 70)
lockedBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
lockedBtn.Text = "🔒 Locked"
lockedBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
lockedBtn.Font = Enum.Font.Gotham
lockedBtn.TextSize = 14
lockedBtn.AutoButtonColor = false
lockedBtn.Parent = buttonPage

lockedBtn.MouseButton1Click:Connect(function()
    print("[Twilight Zone] Locked button clicked (no action).")
end)

-- Sidebar Buttons Logic
local toggleBtn = createSidebarButton("Toggle", 1)
local buttonBtn = createSidebarButton("Button", 2)

toggleBtn.MouseButton1Click:Connect(function()
    for _,p in pairs(pages) do p.Visible = false end
    togglePage.Visible = true
end)

buttonBtn.MouseButton1Click:Connect(function()
    for _,p in pairs(pages) do p.Visible = false end
    buttonPage.Visible = true
end)
