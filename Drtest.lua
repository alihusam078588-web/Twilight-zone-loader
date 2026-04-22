--// WindUI Setup
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Config
local MainAccountName = "Ali_hhjjj"

--// Tags (still kept for compatibility with your system)
local TAG_FREEZE_ON  = "rbxassetid://0_FRZ_ON"
local TAG_FREEZE_OFF = "rbxassetid://0_FRZ_OFF"
local TAG_JUMP_ON    = "rbxassetid://0_JMP_ON"
local TAG_JUMP_OFF   = "rbxassetid://0_JMP_OFF"
local TAG_BLIND_ON   = "rbxassetid://0_BLD_ON"
local TAG_BLIND_OFF  = "rbxassetid://0_BLD_OFF"
local TAG_BRING      = "rbxassetid://0_BRING"
local TAG_FLING      = "rbxassetid://0_FLING"
local TAG_HIGHT      = "rbxassetid://0_HIGHT"

--// Window
local Window = WindUI:CreateWindow({
    Title = "TZ HUB || Developer",
    Folder = "TZHub",
    Icon = "solar:compass-big-bold",
    Theme = "Crimson",
    NewElements = true,
})

local DevTab = Window:Tab({ Title = "Developer", Icon = "solar:code-bold" })

--// State System (FIX: prevents one-time bug)
local State = {
    Jump = false,
    Freeze = false,
    Blind = false,
    JumpThread = nil,
}

local function getChar()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

--// Send signal (Main only)
local function sendDevSignal(id)
    if LocalPlayer.Name ~= MainAccountName then return end

    local char, hum = getChar()
    if not hum then return end

    local anim = Instance.new("Animation")
    anim.AnimationId = id

    local track = hum:LoadAnimation(anim)
    track:Play()

    task.wait(0.1)
    track:Stop()
end

--// FIXED ALT ACTION HANDLER
local function handleDevAction(actionId)
    if LocalPlayer.Name == MainAccountName then return end

    local char, hum, root = getChar()
    if not char or not hum or not root then return end

    -- Freeze FIX
    if actionId == TAG_FREEZE_ON then
        State.Freeze = true
        root.Anchored = true

    elseif actionId == TAG_FREEZE_OFF then
        State.Freeze = false
        root.Anchored = false

    -- Jump FIX (no stacking loops)
    elseif actionId == TAG_JUMP_ON then
        State.Jump = true

        if State.JumpThread then return end
        State.JumpThread = task.spawn(function()
            while State.Jump do
                if hum then
                    hum.Jump = true
                end
                task.wait(0.25)
            end
            State.JumpThread = nil
        end)

    elseif actionId == TAG_JUMP_OFF then
        State.Jump = false

    -- Blind FIX (no duplicates)
    elseif actionId == TAG_BLIND_ON then
        State.Blind = true

        local old = LocalPlayer.PlayerGui:FindFirstChild("DevBlind")
        if old then old:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name = "DevBlind"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.Parent = LocalPlayer.PlayerGui

        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,0,1,0)
        f.BackgroundColor3 = Color3.new(0,0,0)
        f.Parent = gui

    elseif actionId == TAG_BLIND_OFF then
        State.Blind = false
        local gui = LocalPlayer.PlayerGui:FindFirstChild("DevBlind")
        if gui then gui:Destroy() end

    -- Bring
    elseif actionId == TAG_BRING then
        local main = Players:FindFirstChild(MainAccountName)
        if main and main.Character and main.Character:FindFirstChild("HumanoidRootPart") then
            root.CFrame = main.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
        end

    -- Fling FIX (stable force)
    elseif actionId == TAG_FLING then
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 1200, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = root

        task.wait(0.4)
        bv:Destroy()

    -- Highlight FIX
    elseif actionId == TAG_HIGHT then
        local h = char:FindFirstChild("DevHighlight")
        if not h then
            h = Instance.new("Highlight")
            h.Name = "DevHighlight"
            h.Parent = char
        end
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineTransparency = 0
    end
end

--// Setup listener
local function setup(player)
    if player.Name ~= MainAccountName then return end

    local function listen(char)
        local hum = char:WaitForChild("Humanoid")

        hum.AnimationPlayed:Connect(function(track)
            handleDevAction(track.Animation.AnimationId)
        end)
    end

    player.CharacterAdded:Connect(listen)
    if player.Character then listen(player.Character) end
end

for _, p in pairs(Players:GetPlayers()) do
    setup(p)
end

Players.PlayerAdded:Connect(setup)

--// UI (Main only)
if LocalPlayer.Name == MainAccountName then

    DevTab:Toggle({
        Title = "Freeze User",
        Callback = function(state)
            if state then sendDevSignal(TAG_FREEZE_ON)
            else sendDevSignal(TAG_FREEZE_OFF) end
        end
    })

    DevTab:Toggle({
        Title = "Force Jump",
        Callback = function(state)
            if state then sendDevSignal(TAG_JUMP_ON)
            else sendDevSignal(TAG_JUMP_OFF) end
        end
    })

    DevTab:Toggle({
        Title = "Black Screen",
        Callback = function(state)
            if state then sendDevSignal(TAG_BLIND_ON)
            else sendDevSignal(TAG_BLIND_OFF) end
        end
    })

    DevTab:Button({
        Title = "Bring User",
        Callback = function() sendDevSignal(TAG_BRING) end
    })

    DevTab:Button({
        Title = "Fling User",
        Callback = function() sendDevSignal(TAG_FLING) end
    })

    DevTab:Button({
        Title = "Highlight User",
        Callback = function() sendDevSignal(TAG_HIGHT) end
    })

else
    DevTab:Paragraph({
        Title = "Status",
        Desc = "Connected as Alt to: " .. MainAccountName
    })
end