-- main.lua
-- Twilight Zone GUI using WindUI

-- load the WindUI library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua"))()

-- create the main window
local Window = Library:CreateWindow({
    Title = "Twilight Zone GUI",
    SubTitle = "by Ali & ChatGPT",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 350),
    Acrylic = true, -- blurred background
    Theme = "Dark"
})

-- create a "Main" tab
local Tab1 = Window:AddTab({ Title = "Main", Icon = "home" })

-- add a button
Tab1:AddButton({
    Title = "Click Me!",
    Description = "Test button",
    Callback = function()
        print("[TZ GUI] Button Clicked!")
    end
})

-- add a toggle
Tab1:AddToggle({
    Title = "Test Toggle",
    Default = false,
    Callback = function(Value)
        print("[TZ GUI] Toggle state:", Value)
    end
})

-- create another tab
local Tab2 = Window:AddTab({ Title = "Other", Icon = "settings" })

-- add input field
Tab2:AddInput({
    Title = "Enter Text",
    Placeholder = "Type something...",
    Callback = function(Text)
        print("[TZ GUI] Input:", Text)
    end
})
