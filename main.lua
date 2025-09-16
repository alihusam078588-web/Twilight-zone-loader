-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Create main window
local Window = WindUI:CreateWindow({
    Title = "Twilight Zone",
    Icon = "ghost",
    Size = UDim2.new(0, 360, 0, 270)
})

---------------------------------------------------
-- Autofarm Tab
---------------------------------------------------
local FarmTab = Window:Tab({
    Title = "Autofarm",
    Icon = "leaf"
})

FarmTab:Button({
    Title = "Start Autofarm",
    Icon = "play",
    Callback = function()
        print("Autofarm started!")
    end
})

FarmTab:Button({
    Title = "Stop Autofarm",
    Icon = "stop-circle",
    Callback = function()
        print("Autofarm stopped!")
    end
})

---------------------------------------------------
-- ESP Tab
---------------------------------------------------
local EspTab = Window:Tab({
    Title = "ESP",
    Icon = "eye"
})

-- Folder to store ESP highlights
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "TwilightESP"

-- Function to add ESP
local function addESP(object, color)
    if object and not object:FindFirstChild("ESP_Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.Parent = object
    end
end

-- Function to clear ESP
local function clearESP()
    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v:FindFirstChild("ESP_Highlight") then
            v.ESP_Highlight:Destroy()
        end
    end
end

EspTab:Toggle({
    Title = "ESP Spirits",
    Default = false,
    Callback = function(state)
        if state then
            for _, spirit in pairs(workspace:GetDescendants()) do
                if spirit.Name:lower():find("spirit") then
                    addESP(spirit, Color3.fromRGB(0, 255, 255))
                end
            end
        else
            clearESP()
        end
    end
})

EspTab:Toggle({
    Title = "ESP Machines",
    Default = false,
    Callback = function(state)
        if state then
            for _, machine in pairs(workspace:GetDescendants()) do
                if machine.Name:lower():find("generator") or machine.Name:lower():find("machine") then
                    addESP(machine, Color3.fromRGB(0, 255, 0))
                end
            end
        else
            clearESP()
        end
    end
})

---------------------------------------------------
-- Teleport Tab
---------------------------------------------------
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map"
})

-- Teleport helper
local function teleportTo(obj)
    if obj and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
        game.Players.LocalPlayer.Character:PivotTo(obj.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0))
    elseif obj and obj:IsA("BasePart") then
        game.Players.LocalPlayer.Character:PivotTo(obj.CFrame + Vector3.new(0, 3, 0))
    end
end

TeleportTab:Button({
    Title = "Teleport to Elevator",
    Icon = "arrow-up",
    Callback = function()
        local elevator = workspace:FindFirstChild("Elevator")
        if elevator then
            teleportTo(elevator)
        else
            warn("Elevator not found!")
        end
    end
})

TeleportTab:Button({
    Title = "Teleport to Random Machine",
    Icon = "shuffle",
    Callback = function()
        local machines = {}
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("generator") or obj.Name:lower():find("machine") then
                table.insert(machines, obj)
            end
        end
        if #machines > 0 then
            local pick = machines[math.random(1, #machines)]
            teleportTo(pick)
        else
            warn("No machines found!")
        end
    end
})

---------------------------------------------------
-- Settings Tab
---------------------------------------------------
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

SettingsTab:Toggle({
    Title = "Infinite Stamina",
    Default = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer
        if player and player.Character then
            if state then
                -- Hook stamina values
                if player:FindFirstChild("Stamina") then
                    player.Stamina.Value = math.huge
                end
                player.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    player.Character.Humanoid.WalkSpeed = 16
                end)
            else
                if player:FindFirstChild("Stamina") then
                    player.Stamina.Value = 100
                end
            end
        end
    end
})

SettingsTab:Toggle({
    Title = "Hide UI",
    Default = false,
    Callback = function(state)
        game:GetService("CoreGui").TwilightZone.Enabled = not state
    end
})

---------------------------------------------------
-- Credits Tab
---------------------------------------------------
local CreditsTab = Window:Tab({
    Title = "Credits",
    Icon = "star"
})

CreditsTab:Label({
    Title = "Made by Ali_hhjjj"
})

CreditsTab:Label({
    Title = "Tester / Bug Finder: GoodJOBS3"
})

CreditsTab:Label({
    Title = "Special Thanks: Olivia (Riddance Hub / WindUI)"
})
