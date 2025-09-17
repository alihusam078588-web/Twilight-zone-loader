-- WindUI Library
-- Provides basic window, tab, button, and toggle functionality

local Library = {}
Library.__index = Library

-- CreateWindow
function Library:CreateWindow(title)
    local window = {}
    window.Title = title or "Window"
    window.Tabs = {}

    function window:CreateTab(name)
        local tab = {}
        tab.Name = name or "Tab"
        tab.Elements = {}

        -- CreateButton
        function tab:CreateButton(text, callback)
            local button = {
                Text = text or "Button",
                Callback = callback or function() end
            }
            table.insert(tab.Elements, button)
            print("🖱️ Button created:", button.Text)
            return button
        end

        -- CreateToggle
        function tab:CreateToggle(text, default, callback)
            local toggle = {
                Text = text or "Toggle",
                State = default or false,
                Callback = callback or function() end
            }
            table.insert(tab.Elements, toggle)
            print("🔘 Toggle created:", toggle.Text, "default:", toggle.State)
            return toggle
        end

        table.insert(window.Tabs, tab)
        print("📑 Tab created:", tab.Name)
        return tab
    end

    print("🪟 Window created:", window.Title)
    return window
end

return Library
