LeftGroupBox:AddToggle("BookESP", {
    Text = "Highlight Books",
    Default = false,
})
:AddColorPicker("BookESPColor", {
    Default = Color3.fromRGB(255,255,0),
})
local Highlights = {}
local Connection
local BooksFolder = workspace:WaitForChild("Books")

local function highlight(obj)
    if Highlights[obj] then return end

    local h = Instance.new("Highlight")
    h.FillColor = Options.BookESPColor.Value
    h.FillTransparency = 0.5
    h.OutlineColor = Color3.new(0,0,0)
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

Options.BookESPColor:OnChanged(function()
    for _, h in pairs(Highlights) do
        if h then
            h.FillColor = Options.BookESPColor.Value
        end
    end
end)