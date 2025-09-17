-- main.lua

-- Load the library (WindUI from your repo)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/windui.lua"))()

-- Create the main window
local Window = Library:Window({
    text = "Twilight Zone GUI"
})

-- Create "Main" tab
local MainTab = Window:Tab("Main")

-- Add a button inside Main tab
MainTab:Button({
    text = "Test Button",
    callback = function()
        print("[TZ Loader] Test Button clicked!")
    end
})

-- Create "Other" tab
local OtherTab = Window:Tab("Other")

-- Add a toggle inside Other tab
OtherTab:Toggle({
    text = "Test Toggle",
    state = false,
    callback = function(state)
        print("[TZ Loader] Test Toggle set to:", state)
    end
})

print("[TZ Loader] ✅ Twilight Zone GUI loaded successfully!")
