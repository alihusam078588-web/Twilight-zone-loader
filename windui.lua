-- WindUI Library (with tab switching)
local Library = {}
Library.__index = Library

-- CreateWindow
function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TwilightZoneUI"
    ScreenGui.Parent = game:GetService("CoreGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Text = title or "Window"
    Title.Parent = MainFrame

    local TabButtons = Instance.new("Frame")
    TabButtons.Size = UDim2.new(0, 100, 1, -30)
    TabButtons.Position = UDim2.new(0, 0, 0, 30)
    TabButtons.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabButtons.Parent = MainFrame

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -100, 1, -30)
    ContentFrame.Position = UDim2.new(0, 100, 0, 30)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ContentFrame.Parent = MainFrame

    local window = {
        Title = Title,
        Tabs = {},
        ContentFrame = ContentFrame,
        TabButtons = TabButtons,
        ActiveTab = nil
    }

    function window:CreateTab(name)
        local TabFrame = Instance.new("Frame")
        TabFrame.Size = UDim2.new(1, 0, 1, 0)
        TabFrame.BackgroundTransparency = 1
        TabFrame.Visible = false
        TabFrame.Parent = ContentFrame

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 0, 30)
        Button.Text = name
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Button.Parent = TabButtons

        local tab = {
            Name = name,
            Frame = TabFrame,
            Elements = {}
        }

        Button.MouseButton1Click:Connect(function()
            if window.ActiveTab then
                window.ActiveTab.Frame.Visible = false
            end
            TabFrame.Visible = true
            window.ActiveTab = tab
        end)

        function tab:CreateButton(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, 200, 0, 40)
            Btn.Position = UDim2.new(0, 10, 0, (#tab.Elements * 50))
            Btn.Text = text
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            Btn.Parent = TabFrame

            Btn.MouseButton1Click:Connect(callback)
            table.insert(tab.Elements, Btn)
        end

        function tab:CreateToggle(text, default, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, 200, 0, 40)
            Btn.Position = UDim2.new(0, 10, 0, (#tab.Elements * 50))
            Btn.Text = text .. ": " .. tostring(default)
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            Btn.Parent = TabFrame

            local state = default or false
            Btn.MouseButton1Click:Connect(function()
                state = not state
                Btn.Text = text .. ": " .. tostring(state)
                callback(state)
            end)

            table.insert(tab.Elements, Btn)
        end

        table.insert(window.Tabs, tab)

        -- Auto-open first tab
        if not window.ActiveTab then
            window.ActiveTab = tab
            TabFrame.Visible = true
        end

        return tab
    end

    print("✅ Window created:", title)
    return window
end

return Library
