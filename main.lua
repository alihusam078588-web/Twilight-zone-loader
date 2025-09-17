-- Twilight Zone Hub (main.lua)

-- Load WindUI
local Library = loadstring(game:HttpGet("https://footagesus.github.io/WindUI-Docs/library.lua"))()
local Window = Library:Window("Twilight Zone Hub", "by Ali_hhjjj", Enum.KeyCode.RightControl, 500, 350)

----------------------------------------------------------------
-- ESP Tab
----------------------------------------------------------------
local espEnabled = false

local function toggleESP(state)
    espEnabled = state
    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if state then
                if not v:FindFirstChild("ESPHighlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ESPHighlight"
                    hl.Parent = v
                    hl.FillColor = Color3.fromRGB(0, 255, 0)
                end
            else
                if v:FindFirstChild("ESPHighlight") then
                    v.ESPHighlight:Destroy()
                end
            end
        end
    end
end

local tabESP = Window:Tab("ESP", "rbxassetid://4483345998")
tabESP:Toggle("Enable ESP", false, function(value)
    toggleESP(value)
end)

----------------------------------------------------------------
-- Teleport Tab
----------------------------------------------------------------
local tabTP = Window:Tab("Teleport", "rbxassetid://4483345998")

local player = game.Players.LocalPlayer
local function tpTo(part)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    end
end

tabTP:Button("Teleport to Elevator", function()
    local elevator = workspace:FindFirstChild("Elevator")
    if elevator then tpTo(elevator) end
end)

tabTP:Button("Teleport to Random Machine", function()
    local gens = workspace.CurrentRoom and workspace.CurrentRoom:FindFirstChild("ProjectorMap") and workspace.CurrentRoom.ProjectorMap:FindFirstChild("Generators")
    if gens then
        local machines = gens:GetChildren()
        if #machines > 0 then
            tpTo(machines[math.random(1, #machines)])
        end
    end
end)

local autoElevator = false
tabTP:Toggle("Auto TP to Elevator", false, function(state)
    autoElevator = state
    if state then
        task.spawn(function()
            while autoElevator do
                task.wait(2)
                local gens = workspace.CurrentRoom and workspace.CurrentRoom:FindFirstChild("ProjectorMap") and workspace.CurrentRoom.ProjectorMap:FindFirstChild("Generators")
                if gens then
                    local allDone = true
                    for _, g in pairs(gens:GetChildren()) do
                        if g:FindFirstChild("Progress") and g.Progress.Value < 1 then
                            allDone = false
                            break
                        end
                    end
                    if allDone then
                        local elevator = workspace:FindFirstChild("Elevator")
                        if elevator then
                            tpTo(elevator)
                            autoElevator = false
                        end
                    end
                end
            end
        end)
    end
end):Description("Automatically teleport to the elevator when all machines are done")

local autoMachine = false
tabTP:Toggle("Auto TP to Machine", false, function(state)
    autoMachine = state
    if state then
        task.spawn(function()
            while autoMachine do
                task.wait(5)
                local gens = workspace.CurrentRoom and workspace.CurrentRoom:FindFirstChild("ProjectorMap") and workspace.CurrentRoom.ProjectorMap:FindFirstChild("Generators")
                if gens then
                    for _, g in pairs(gens:GetChildren()) do
                        if g:FindFirstChild("Progress") and g.Progress.Value < 1 then
                            tpTo(g)
                            break
                        end
                    end
                end
            end
        end)
    end
end):Description("Automatically teleport you to unfinished machines")

----------------------------------------------------------------
-- Player Tab
----------------------------------------------------------------
local tabPlayer = Window:Tab("Player", "rbxassetid://4483345998")

local infiniteStamina = false
tabPlayer:Toggle("Infinite Stamina", false, function(state)
    infiniteStamina = state
    task.spawn(function()
        while infiniteStamina do
            task.wait(1)
            local stats = player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("Stamina")
            if stats then
                local stamina = stats:FindFirstChild("Value")
                if stamina then
                    stamina.Value = stamina.MaxValue
                end
            end
        end
    end)
end)

----------------------------------------------------------------
-- Credits Tab
----------------------------------------------------------------
local tabCredits = Window:Tab("Credits", "rbxassetid://4483345998")
tabCredits:Label("Script by Ali_hhjjj")
tabCredits:Label("Tester / Bug Finder: GoodJOBS3")
tabCredits:Label("Special Thanks: Olivia (Riddance Hub, WindUI)")
