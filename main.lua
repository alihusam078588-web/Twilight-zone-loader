-- Twilight Zone GUI (Rayfield Version)
-- Creator: Ali_hhjjj
-- Tester/Helper: GOODJOBS3
-- Special thanks: Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving idea to use Rayfield

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone",
    LoadingTitle = "Twilight Zone GUI",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    }
})

-- ESP Tab
local ESPTab = Window:CreateTab("ESP", 4483362458)

local function highlightObject(obj, color)
    if obj:FindFirstChild("ESP_Highlight") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = 0.5
    hl.Parent = obj
end

local espMachines = false
ESPTab:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(Value)
        espMachines = Value
        if Value then
            for _,v in pairs(workspace.Floor:GetChildren()) do
                if v:IsA("Model") and v.Name:match("^%d+$") then
                    highlightObject(v, Color3.fromRGB(0, 255, 0))
                end
            end
        else
            for _,v in pairs(workspace.Floor:GetDescendants()) do
                if v:FindFirstChild("ESP_Highlight") then
                    v.ESP_Highlight:Destroy()
                end
            end
        end
    end
})

local espSpirits = false
ESPTab:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(Value)
        espSpirits = Value
        if Value then
            for _,v in pairs(workspace.Floor:GetChildren()) do
                if v.Name:lower():find("spirit") then
                    highlightObject(v, Color3.fromRGB(255, 0, 0))
                end
            end
        else
            for _,v in pairs(workspace.Floor:GetDescendants()) do
                if v:FindFirstChild("ESP_Highlight") then
                    v.ESP_Highlight:Destroy()
                end
            end
        end
    end
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

local function teleportTo(pos)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:MoveTo(pos)
    end
end

TeleportTab:CreateButton({
    Name = "Teleport to Random Machine (with Aura Spam E)",
    Callback = function()
        local machines = {}
        for _,v in pairs(workspace.Floor:GetChildren()) do
            if v:IsA("Model") and v.Name:match("^%d+$") then
                table.insert(machines, v)
            end
        end
        if #machines > 0 then
            local pick = machines[math.random(1,#machines)]
            teleportTo(pick:GetModelCFrame().p)
            -- Machine Aura Spam E
            task.spawn(function()
                for i = 1,20 do
                    game:GetService("VirtualInputManager"):SendKeyEvent(true,"E",false,game)
                    task.wait(0.2)
                end
            end)
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Elevator",
    Callback = function()
        local elevator = workspace.Floor:FindFirstChild("Elevator")
        if elevator and elevator:IsA("Model") then
            teleportTo(elevator:GetModelCFrame().p)
        end
    end
})

-- Auto Farm Tab
local AutoTab = Window:CreateTab("Auto Farm", 4483362458)

local autoMachines = false
AutoTab:CreateToggle({
    Name = "Auto Teleport to Machine (with Aura Spam E)",
    CurrentValue = false,
    Callback = function(Value)
        autoMachines = Value
        while autoMachines do
            local machines = {}
            for _,v in pairs(workspace.Floor:GetChildren()) do
                if v:IsA("Model") and v.Name:match("^%d+$") then
                    table.insert(machines, v)
                end
            end
            if #machines > 0 then
                local pick = machines[math.random(1,#machines)]
                teleportTo(pick:GetModelCFrame().p)
                for i = 1,20 do
                    game:GetService("VirtualInputManager"):SendKeyEvent(true,"E",false,game)
                    task.wait(0.2)
                end
            end
            task.wait(5)
        end
    end
})

local autoElevator = false
AutoTab:CreateToggle({
    Name = "Auto Teleport to Elevator (when all machines done)",
    CurrentValue = false,
    Callback = function(Value)
        autoElevator = Value
        while autoElevator do
            local machinesLeft = false
            for _,v in pairs(workspace.Floor:GetChildren()) do
                if v:IsA("Model") and v.Name:match("^%d+$") then
                    machinesLeft = true
                end
            end
            if not machinesLeft then
                local elevator = workspace.Floor:FindFirstChild("Elevator")
                if elevator and elevator:IsA("Model") then
                    teleportTo(elevator:GetModelCFrame().p)
                end
            end
            task.wait(3)
        end
    end
})

-- Player Tab
local PlayerTab = Window:CreateTab("Player", 4483362458)
local lp = game.Players.LocalPlayer

PlayerTab:CreateSlider({
    Name = "Custom Speed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
            lp.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
        end
    end
})

-- Godmode (Always On)
task.spawn(function()
    while task.wait(1) do
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
            lp.Character:FindFirstChildOfClass("Humanoid").Health = lp.Character:FindFirstChildOfClass("Humanoid").MaxHealth
        end
    end
end)

-- Auto Skillcheck (Always On)
task.spawn(function()
    while task.wait(0.2) do
        game:GetService("VirtualInputManager"):SendKeyEvent(true,"E",false,game)
    end
end)

-- Infinite Stamina
PlayerTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            lp.PlayerScripts.Stamina.Disabled = true
        else
            lp.PlayerScripts.Stamina.Disabled = false
        end
    end
})

-- Credits Tab
local CreditsTab = Window:CreateTab("Credits", 4483362458)
CreditsTab:CreateLabel("Creator: Ali_hhjjj")
CreditsTab:CreateLabel("Tester/Helper: GOODJOBS3")
CreditsTab:CreateLabel("Special thanks: Olivia (creator of Riddance Hub) and Shelly (Riddance manager) for giving idea to use Rayfield")
