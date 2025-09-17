-- WindUI Library (Real GUI Version)
-- Creates ScreenGui, Frames, Tabs, Buttons, and Toggles

local Library = {}
Library.__index = Library

-- Parent GUI to PlayerGui
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- CreateWindow
function Library:CreateWindow(title)
    local window = {}
    window.Title = title or "Window"
    window.Tabs = {}

    -- Create the main ScreenGui + Frame
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WindUI_" .. window.Title
    screenGui.Parent = PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = window.Title
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Parent = mainFrame

    window.Gui = mainFrame

    -- CreateTab
    function window:CreateTab(name)
        local tab = {}
        tab.Name = name or "Tab"
        tab.Elements = {}

        local tabFrame = Instance.new("Frame")
        tabFrame.Size = UDim2.new(1, -10, 1, -40)
        tabFrame.Position = UDim2.new(0, 5, 0, 35)
        tabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabFrame.Parent = mainFrame

        tab.Gui = tabFrame

        -- CreateButton
        function tab:CreateButton(text, callback)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -20, 0, 30)
            button.Position = UDim2.new(0, 10, 0, (#tab.Elements * 40))
            button.Text = text or "Button"
            button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Parent = tabFrame

            button.MouseButton1Click:Connect(callback or function() end)

            table.insert(tab.Elements, button)
            return button
        end

        -- CreateToggle
        function tab:CreateToggle(text, default, callback)
            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(1, -20, 0, 30)
            toggle.Position = UDim2.new(0, 10, 0, (#tab.Elements * 40))
            toggle.Text = (text or "Toggle") .. ": " .. tostring(default or false)
            toggle.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
            toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggle.Parent = tabFrame

            local state = default or false
            toggle.MouseButton1Click:Connect(function()
                state = not state
                toggle.Text = (text or "Toggle") .. ": " .. tostring(state)
                if callback then callback(state) end
            end)

            table.insert(tab.Elements, toggle)
            return toggle
        end

        table.insert(window.Tabs, tab)
        return tab
    end

    return window
end

return Library
