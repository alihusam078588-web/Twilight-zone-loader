local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Book ESP",
    Footer = "Highlight System",
    NotifySide = "Right",
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local Box = Tabs.Main:AddLeftGroupbox("Books ESP", "boxes")

Box:AddToggle("BookESP", {
    Text = "Highlight Books",
    Default = false,
})
:AddColorPicker("BookColor", {
    Default = Color3.fromRGB(255,255,0),
})

local Highlights = {}
local Connection
local BooksFolder = workspace:WaitForChild("Books")

local function highlight(obj)
    if Highlights[obj] then return end

    local h = Instance.new("Highlight")
    h.FillColor = Options.BookColor.Value
    h.FillTransparency = 0.1
    h.OutlineColor = Options.BookColor.Value
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj

    Highlights[obj] = h
end

local function clear()
    for _, h in pairs(Highlights) do
        if h then h:Destroy() end
    end
    Highlights = {}
end

local function scan()
    for _, obj in ipairs(BooksFolder:GetChildren()) do
        highlight(obj)
    end
end

Toggles.BookESP:OnChanged(function()
    if Toggles.BookESP.Value then
        scan()
        Connection = BooksFolder.ChildAdded:Connect(function(obj)
            highlight(obj)
        end)
    else
        clear()
        if Connection then
            Connection:Disconnect()
            Connection = nil
        end
    end
end)

Options.BookColor:OnChanged(function()
    for _, h in pairs(Highlights) do
        if h then
            h.FillColor = Options.BookColor.Value
            h.OutlineColor = Options.BookColor.Value
        end
    end
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddLabel("Menu key")
    :AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true
    })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("BookESP")
SaveManager:SetFolder("BookESP/configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()