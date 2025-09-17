-- Load the WindUI library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua"))()

-- Create a main window
local Window = Library:CreateWindow({
    Title = "Twilight Zone GUI",
    Center = true,
    AutoShow = true,
})

-- Add a tab
local Tab = Window:CreateTab({
    Name = "Main",
    Icon = "rbxassetid://10734950020" -- optional icon
})

-- Add a section inside the tab
local Section = Tab:CreateSection("Main Features")

-- Add a button
Section:CreateButton({
    Name = "Fly",
    Callback = function()
        print("Fly enabled")
    end
})

-- Add a toggle
Section:CreateToggle({
    Name = "ESP",
    Default = false,
    Callback = function(value)
        print("ESP is now", value)
    end
})
