-- Twilight Zone GUI using WindUI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/FootageSUS/WindUI/main/library.lua"))()
local Window = Library:CreateWindow("Twilight Zone GUI")

local Tab1 = Window:CreateTab("Main")
Tab1:CreateButton("Test Button", function()
    print("[TZ] Test button clicked!")
end)

local Tab2 = Window:CreateTab("Other")
Tab2:CreateToggle("Test Toggle", false, function(state)
    print("[TZ] Test toggle:", state)
end)
