-- Loader.lua
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam07858-web/Twilight-zone-loader/main/windui.lua"))()

-- Create main window
local Window = WindUI:CreateWindow("Twilight Zone GUI")

-- Main tab
local MainTab = Window:CreateTab("Main")
MainTab:CreateButton("Test Button", function()
    print("[TZ Loader] Test Button pressed!")
end)

MainTab:CreateToggle("Test Toggle", false, function(state)
    print("[TZ Loader] Test Toggle is now:", state)
end)

-- Other tab
local OtherTab = Window:CreateTab("Other")
OtherTab:CreateButton("Extra Button", function()
    print("[TZ Loader] Extra Button pressed!")
end)

OtherTab:CreateToggle("Extra Toggle", true, function(state)
    print("[TZ Loader] Extra Toggle is now:", state)
end)

print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
