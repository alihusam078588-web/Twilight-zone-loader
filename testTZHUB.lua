--// WindUI Setup
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--// Window
local Window = WindUI:CreateWindow({
    Title = "TZ HUB || Dolly's Factory",
    Folder = "TZHub",
    Icon = "solar:compass-big-bold",
    Theme = "Crimson",
    NewElements = true,
})
Window:EditOpenButton({
    Title = "TZ HUB || Dolly's Factory",
    Icon = "solar:compass-big-bold", -- matches your main window 
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient theme
        Color3.fromHex("DC143C"), -- Crimson start
        Color3.fromHex("8B0000")  -- Darker Crimson end
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

--// Main Tab
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "solar:home-bold",
})
MainTab:Select()

MainTab:Section({
    Title = "Machine Teleport",
    Desc = "some Machines features",
})
--// Teleport Tab
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "lucide:map-pin", -- works in most builds
})
