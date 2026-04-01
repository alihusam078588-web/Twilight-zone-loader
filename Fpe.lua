local player = game.Players.LocalPlayer
local gui = player.PlayerGui.GameUI.Notebook
local main = gui.QuestionsList.MainFrame

local answeredCache = {}

-- ✅ Answers
local answers = {
    ["What is 2 - 3?"] = "-1",
    ["What is 7 x 8?"] = "56",
    ["What is 9 + 10?"] = "19",
    ["What is 10 / 100?"] = "0.1",
    ["What is 10 / 10?"] = "1",
    ["What is π?"] = "3.14159",
    ["Choose the correct option"] = "Oreo",
    ["What is Brazil's official language?"] = "Portuguese",
    ["Which language has the most native speakers in the world?"] = "Mandarin",
    ["What is Money called in Spanish?"] = "Dinero",
    ["What is an example of a Metaphor?"] = "This test was a piece of cake!",
    ["What is the powerhouse of a cell?"] = "Mitochondria",
    ["What is when a tadpole transforms into a frog?"] = "Metamorphosis",
    ["All living things are made up of cells"] = "True",
    ["What is when a plant uses sunlight to grow?"] = "Photosynthesis",
    ["What is the largest mammal on Earth?"] = "Blue Whale",
    ["Which isn't a characteristic of life?"] = "Sentience",
    ["Which symbol represents silver?"] = "Ag",
    ["At what temperature does water freeze (In Fahrenheit)?"] = "32",
    ["Who was the 1st president of the United States?"] = "George W",
    ["Which era marked a switch from agricultural practices to industrial practices?"] = "Industrial Revolution",
    ["What ended in 1985?"] = "oreo",
    ["When was Hersheys founded?"] = "1894",
    ["When did World War 1 start?"] = "1914",
    ["Which colors make up Orange?"] = "Yellow & Red",
    ["Which one of the following is a primary color?"] = "Blue",
    ["What is the drawing technique that creates the illusion of depth on a flat surface?"] = "Perspective",
    ["What is the complimentary color to Purple?"] = "Yellow",
    ["Which of the following is not a note in the musical scale?"] = "H",
    ["A Treble clef is used for illustrating notes that are:"] = "Higher",
    ["A staff consists of how many horizontal lines?"] = "Five",
    ["How many notes are in the scale?"] = "Eight",
    ["Which of the following markings would affect the length of a note?"] = "Dot"
}

-- 🔍 Get clean button text (removes "A. ")
local function getAnswerText(btn)
    return btn.Text:match("%. (.+)$")
end

-- ⚡ Answer ONE question (FAST + SAFE)
local function answerOneQuestion()
    for _, questionFrame in pairs(main:GetChildren()) do
        if questionFrame:IsA("Frame") and questionFrame.Name:match("^Question_%d+") then

            if answeredCache[questionFrame] then continue end
            if questionFrame:GetAttribute("Answered") then
                answeredCache[questionFrame] = true
                continue
            end

            local qTextObj = questionFrame:FindFirstChild("QuestionText")
            local buttonsFolder = questionFrame:FindFirstChild("ButtonList")

            if not qTextObj or not buttonsFolder then continue end

            local questionText = qTextObj.Text
            local correctAnswer = answers[questionText]

            if not correctAnswer then
                warn("Unknown:", questionText)
                return
            end

            -- 🚀 instantly find correct answer
            for _, btn in pairs(buttonsFolder:GetChildren()) do
                if btn:IsA("TextButton") and btn.Visible then
                    
                    local cleanText = getAnswerText(btn)

                    if cleanText and tostring(cleanText) == tostring(correctAnswer) then
                        
                        -- 🔥 instant click
                        for _, con in pairs(getconnections(btn.Activated)) do
                            con:Fire()
                        end

                        answeredCache[questionFrame] = true
                        return
                    end
                end
            end
        end
    end
end

-- ✅ Check finished
local function isFinished()
    for _, q in pairs(main:GetChildren()) do
        if q:IsA("Frame") and q.Name:match("^Question_%d+") then
            if not q:GetAttribute("Answered") then
                return false
            end
        end
    end
    return true
end

-- 🔁 Auto start when notebook opens
gui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gui.Visible then
        answeredCache = {}

        task.spawn(function()
            while gui.Visible do
                pcall(answerOneQuestion)
                task.wait(0.05) -- ⚡ VERY FAST LOOP

                if isFinished() then
                    task.wait(0.2)
                    gui.Visible = false
                    break
                end
            end
        end)
    end
end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

-- NOTIFICATION LIBRARY
local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/lobox920/Notification-Library/Main/Library.lua"))()

-- STORAGE
local tracers = {}
local highlightedBooks = {}

-- GET ROOT PART (CUSTOM SUPPORT)
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char.PrimaryPart
        or char:FindFirstChildWhichIsA("BasePart")
end

-- CREATE HIGHLIGHT
local function createHighlight(parent, color)
    if not parent:FindFirstChild("ESPHighlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Adornee = parent
        highlight.Parent = parent
    end
end

-- CREATE TRACER
local function createTracer(plr)
    if tracers[plr] then return end

    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Transparency = 1
    line.Visible = false

    tracers[plr] = line
end

-- REMOVE TRACER
local function removeTracer(plr)
    if tracers[plr] then
        tracers[plr]:Remove()
        tracers[plr] = nil
    end
end

-- HEARTBEAT LOOP
RunService.Heartbeat:Connect(function()
    -- STAMINA
    if player.Character and player.Character:GetAttribute("Stamina") then
        local maxStam = player.Character:GetAttribute("MaxStamina") or 100
        player.Character:SetAttribute("Stamina", maxStam)
    end

    -- ENSURE TRACERS + HIGHLIGHTS
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Team ~= player.Team then
            local char = plr.Character
            if char then
                local root = getRoot(char)
                if root then
                    -- TEAM COLOR
                    local color = Color3.new(1,1,1)
                    if plr.Team and plr.Team.TeamColor then
                        color = plr.Team.TeamColor.Color
                    end

                    createHighlight(char, color)
                    createTracer(plr)
                end
            end
        else
            removeTracer(plr)
        end
    end

    -- UPDATE TRACERS
    for plr, line in pairs(tracers) do
        local char = plr.Character
        if char then
            local root = getRoot(char)
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

                local color = Color3.new(1,1,1)
                if plr.Team and plr.Team.TeamColor then
                    color = plr.Team.TeamColor.Color
                end

                if onScreen then
                    line.Visible = true
                    line.Color = color
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end

    -- BOOKS
    local books = workspace:FindFirstChild("Books")
    if books then
        for _, obj in ipairs(books:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                createHighlight(obj, Color3.fromRGB(255,255,0))

                if not highlightedBooks[obj] then
                    highlightedBooks[obj] = true

                    NotificationLibrary:SendNotification(
                        "Info",
                        "Book Spawned: " .. obj.Name,
                        5
                    )
                end
            end
        end
    end
end)

-- CLEANUP
Players.PlayerRemoving:Connect(function(plr)
    removeTracer(plr)
end)
