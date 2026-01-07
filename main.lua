local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Notification utility
local function notify(msg)
    StarterGui:SetCore("SendNotification", {
        Title = "TZ Loader",
        Text = msg,
        Duration = 8
    })
end

-- Lobby check
if Workspace:FindFirstChild("LobbySpawn") then
    notify("Please use the script only in game, not in lobby!")
end

-- Utility functions
local function findRepresentativePart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart"}
    for _,n in ipairs(names) do
        local f = model:FindFirstChild(n)
        if f and f:IsA("BasePart") then
            return f
        end
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function isFuseLike(name)
    if not name then return false end
    local s = tostring(name):lower()
    return s:find("fuse") or s:find("fusebox") or s:find("fuse_box")
end

-- Godmode: remove HitPlayer
task.spawn(function()
    while true do
        pcall(function()
            if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then
                for _, folder in ipairs(Workspace.Floor.Spirits:GetChildren()) do
                    for _, v in ipairs(folder:GetChildren()) do
                        if v.Name == "HitPlayer" then
                            v:Destroy()
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- Machine gathering
local function findMachinesFolders()
    local folders = {}
    if Workspace:FindFirstChild("Machines") then
        table.insert(folders, Workspace.Machines)
    end
    if Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
                table.insert(folders, obj)
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "machines" then
            table.insert(folders, obj)
        end
    end
    local seen = {}
    local unique = {}
    for _, f in ipairs(folders) do
        if f and not seen[f] then
            seen[f] = true
            table.insert(unique, f)
        end
    end
    return unique
end

local function gatherMachineParts()
    local parts = {}
    local folders = findMachinesFolders()
    for _, machinesFolder in ipairs(folders) do
        for _, machine in ipairs(machinesFolder:GetChildren()) do
            if machine:IsA("Model") and not isFuseLike(machine.Name) then
                local rep = findRepresentativePart(machine) or machine
                if rep then table.insert(parts, rep) end
            end
        end
    end
    if #parts == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and not isFuseLike(obj.Name) then
                if tostring(obj.Name):lower():find("machine") then
                    local rep = findRepresentativePart(obj) or obj
                    table.insert(parts, rep)
                end
            end
        end
    end
    if #parts == 0 and Workspace:FindFirstChild("Floor") then
        for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
            if obj:IsA("Model") and not isFuseLike(obj.Name) then
                local rep = findRepresentativePart(obj)
                if rep and (tostring(obj.Name):lower():find("machine") or rep.Name:lower():find("machine")) then
                    table.insert(parts, rep)
                end
            end
        end
    end
    return parts
end

local function findNearestMachinePart()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local parts = gatherMachineParts()
    if #parts == 0 then return nil end
    table.sort(parts, function(a,b)
        return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
    end)
    return parts[1]
end

-- Teleports
local function teleportToPart(part, yOffset)
    yOffset = yOffset or 5
    if not part then return false end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0)
    end)
    return true
end

local function teleportToRandomMachine()
    local parts = gatherMachineParts()
    if #parts == 0 then return false end
    return teleportToPart(parts[math.random(1,#parts)])
end

local function teleportToNearestMachine()
    local p = findNearestMachinePart()
    if not p then return false end
    return teleportToPart(p)
end

local function teleportToElevator()
    local elevator = Workspace:FindFirstChild("Elevator")
    if not elevator then return false end
    local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator)
    if not spawn then return false end
    return teleportToPart(spawn, 2)
end

-- ESP
local espMachinesOn, espSpiritsOn = false, false
local espMap = {}

local function createHighlightForModel(model, color)
    if not model or not model.Parent or espMap[model] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "TZ_HL"
    hl.Adornee = model
    hl.FillColor, hl.OutlineColor = color, color
    hl.FillTransparency = 0.55
    hl.Parent = workspace
    espMap[model] = hl
end

local function clearAllHighlights()
    for model, hl in pairs(espMap) do
        pcall(function()
            if hl then hl:Destroy() end
        end)
    end
    espMap = {}
end

local function cleanupDeadHighlights()
    for model, hl in pairs(espMap) do
        if not model or not model.Parent then
            pcall(function()
                if hl then hl:Destroy() end
            end)
            espMap[model] = nil
        end
    end
end

task.spawn(function()
    while true do
        cleanupDeadHighlights()
        if espMachinesOn then
            local parts = gatherMachineParts()
            for _, rep in ipairs(parts) do
                local model = rep and rep:IsA("BasePart") and rep.Parent or rep
                if model and model:IsA("Model") and not espMap[model] then
                    createHighlightForModel(model, Color3.fromRGB(0, 200, 0))
                end
            end
        end
        if espSpiritsOn then
            local foundSpiritFolders = {}
            if Workspace:FindFirstChild("Floor") then
                for _, obj in ipairs(Workspace.Floor:GetDescendants()) do
                    if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then
                        table.insert(foundSpiritFolders, obj)
                    end
                end
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("Folder") or obj:IsA("Model")) and tostring(obj.Name):lower() == "spirits" then
                    table.insert(foundSpiritFolders, obj)
                end
            end
            local seen = {}
            for _, folder in ipairs(foundSpiritFolders) do
                if folder and not seen[folder] then
                    seen[folder] = true
                    for _, spirit in ipairs(folder:GetChildren()) do
                        if spirit:IsA("Model") then
                            local part = spirit:FindFirstChild("HumanoidRootPart") or spirit:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                createHighlightForModel(spirit, Color3.fromRGB(200, 0, 200))
                            end
                        end
                    end
                end
            end
        end
        if not espMachinesOn and not espSpiritsOn then
            clearAllHighlights()
        end
        task.wait(1)
    end
end)

-- AutoSkill
do
    local function tryAttachSkillCheck(remote)
        if not remote then return end
        if remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...) return 2 end
        elseif remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...) end)
        end
    end

    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then
            tryAttachSkillCheck(v)
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(function(desc)
        if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then
            tryAttachSkillCheck(desc)
        end
    end)
end

-- Infinite Stamina
local staminaFlag = false
local AddStamina
pcall(function()
    AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina")
end)
task.spawn(function()
    while true do
        if staminaFlag and AddStamina then
            pcall(function()
                firesignal(AddStamina.OnClientEvent, 45)
            end)
        end
        task.wait(0.2)
    end
end)

-- Auto Elevator
local autoElevatorFlag = false
task.spawn(function()
    while true do
        if autoElevatorFlag then
            local elevator = Workspace:FindFirstChild("Elevator")
            if elevator then
                local tele = elevator:FindFirstChild("TeleportExit") or elevator:FindFirstChild("Teleport")
                local msg = tele and tele:FindFirstChild("Message")
                if msg and msg.Enabled then
                    teleportToElevator()
                    repeat
                        task.wait(1)
                    until not msg.Enabled
                end
            end
        end
        task.wait(1)
    end
end)

-- Auto Teleport
local autoTeleportFlag = false
task.spawn(function()
    while true do
        if autoTeleportFlag then
            local parts = gatherMachineParts()
            if #parts > 0 then
                teleportToPart(parts[math.random(1, #parts)])
            end
        end
        task.wait(3)
    end
end)

-- Rayfield GUI & Tabs
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Twilight Zone Hub",
    LoadingTitle = "Twilight Zone Loader",
    LoadingSubtitle = "by Ali_hhjjj",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "TwilightZoneHub",
        FileName = "TZ_Config"
    },
    Discord = {
        Enabled = false
    }
})

local TabSettings = Window:CreateTab("Settings", 4483362458)

-- Rayfield built-in theme identifiers
local RayfieldThemes = {
    "Default",
    "AmberGlow",
    "Amethyst",
    "Bloom",
    "DarkBlue",
    "Green",
    "Light",
    "Ocean",
    "Serenity"
}

-- Theme dropdown
TabSettings:CreateDropdown({
    Name = "Theme",
    Options = RayfieldThemes,
    CurrentOption = {"Default"},
    MultipleOptions = false,

    -- This is called when dropdown changes
    Callback = function(Option)
        local SelectedTheme = Option[1]

        -- Apply the selected theme
        Rayfield:ChangeTheme(SelectedTheme)
    end
})

TabSettings:CreateButton({
    Name = "Save Config",
    Callback = function()
        Rayfield:SaveConfiguration()
        Rayfield:Notify({
            Title = "Settings",
            Content = "Configuration saved!",
            Duration = 4
        })
    end
})

TabSettings:CreateButton({
    Name = "Load Config",
    Callback = function()
        Rayfield:LoadConfiguration()
        Rayfield:Notify({
            Title = "Settings",
            Content = "Configuration loaded!",
            Duration = 4
        })
    end
})


local TabMain = Window:CreateTab("Main")
local TabESP = Window:CreateTab("ESP")
local TabAutoCollect = Window:CreateTab("Auto collect")
local TabCredits = Window:CreateTab("Credits")
TabCredits:CreateLabel("Created by Ali_hhjjj")
TabCredits:CreateLabel("Tester: GoodJOBS3")
TabCredits:CreateLabel("Thanks to Olivia (creator of Riddance Hub) and shelly (Riddance manager) for Rayfield idea")

local SupportTab = Window:CreateTab("Support", 4483362458)

TabMain:CreateButton({ Name = "Teleport: Nearest Machine", Callback = teleportToNearestMachine })

TabMain:CreateButton({ Name = "Teleport: Random Machine", Callback = teleportToRandomMachine })


TabMain:CreateButton({ Name = "Teleport: Elevator", Callback = teleportToElevator })


TabMain:CreateToggle({ Name = "Auto Teleport Machines", CurrentValue = false, Callback = function(v) autoTeleportFlag = v end })
TabMain:CreateToggle({ Name = "Auto Elevator", CurrentValue = false, Callback = function(v) autoElevatorFlag = v end })

TabMain:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) staminaFlag = v end })

TabMain:CreateToggle({ Name = "Anti Lag", CurrentValue = false, Callback = function(state)
    if state then
        task.spawn(function()
            while state do
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Decal") or obj:IsA("Texture") then
                        pcall(function() obj:Destroy() end)
                    elseif obj:IsA("ParticleEmitter") then
                        pcall(function() obj.Enabled = false end)
                    elseif obj:IsA("Sound") then
                        pcall(function() obj:Stop() end)
                    end
                end
                task.wait(2)
            end
        end)
    end
end })

TabESP:CreateToggle({
    Name = "ESP Machines",
    CurrentValue = false,
    Callback = function(v)
        espMachinesOn = v
        if not v then clearAllHighlights() end
    end
})
TabESP:CreateToggle({
    Name = "ESP Spirits",
    CurrentValue = false,
    Callback = function(v)
        espSpiritsOn = v
        if not v then clearAllHighlights() end
    end
})




TabAutoCollect:CreateButton({
    Name = "Collect Currency",
    Callback = function()
        local items = workspace.Floor.Items.Currencies:GetChildren()
        for i = 1, #items do
            local item = items[i]
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = item:GetPivot()
                    task.wait(0.3)
                    fireproximityprompt(prompt)
                end
                break
            end
        end
    end
})


TabAutoCollect:CreateButton({
    Name = "Collect Capsule",
    Callback = function()
        local items = workspace.Floor.Items.Capsules:GetChildren()
        for i = 1, #items do
            local item = items[i]
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = item:GetPivot()
                    task.wait(0.3)
                    fireproximityprompt(prompt)
                end
                break
            end
        end
    end
})

local autoCurrency = false

TabAutoCollect:CreateToggle({
    Name = "Auto Collect Currency",
    CurrentValue = false,
    Callback = function(state)
        autoCurrency = state
        if state then
            task.spawn(function()
                while autoCurrency do
                    local items = workspace.Floor.Items.Currencies:GetChildren()
                    for i = 1, #items do
                        if not autoCurrency then break end
                        local item = items[i]
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if prompt and hrp then
                            hrp.CFrame = item:GetPivot()
                            task.wait(0.25)
                            fireproximityprompt(prompt)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

local autoCapsule = false

TabAutoCollect:CreateToggle({
    Name = "Auto Collect Capsule",
    CurrentValue = false,
    Callback = function(state)
        autoCapsule = state
        if state then
            task.spawn(function()
                while autoCapsule do
                    local items = workspace.Floor.Items.Capsules:GetChildren()
                    for i = 1, #items do
                        if not autoCapsule then break end
                        local item = items[i]
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if prompt and hrp then
                            hrp.CFrame = item:GetPivot()
                            task.wait(0.25)
                            fireproximityprompt(prompt)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local OWNER_NAME = "Ali_hhjjj"


local function notifyOwner()
    StarterGui:SetCore("SendNotification", {
        Title = "TZ Owner",
        Text = "The owner joined your server",
        Duration = 8
    })
end


for _, plr in pairs(Players:GetPlayers()) do
    if plr.Name == OWNER_NAME then
        notifyOwner()
    end
end


Players.PlayerAdded:Connect(function(plr)
    if plr.Name == OWNER_NAME then
        notifyOwner()
    end
end)

TabAutoCollect:CreateToggle({
    Name = "Auto Collect Snowflakes",
    CurrentValue = false,
    Callback = function(state)
        autoSnowflakes = state

        if state then
            task.spawn(function()
                local player = game.Players.LocalPlayer
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")

                -- Save original position
                local originalCFrame = hrp.CFrame

                while autoSnowflakes do
                    local folder = workspace:FindFirstChild("Floor")
                        and workspace.Floor:FindFirstChild("Items")
                        and workspace.Floor.Items:FindFirstChild("Currencies")

                    if not folder then break end

                    local children = folder:GetChildren()
                    local foundAny = false

                    for index, item in ipairs(children) do
                        if not autoSnowflakes then break end

                        -- ❌ Ignore index 2
                        if index == 2 then
                            continue
                        end

                        -- Only Snowflakes
                        if not item.Name:lower():find("snow") then
                            continue
                        end

                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            foundAny = true

                            -- Teleport & collect
                            hrp.CFrame = item:GetPivot() + Vector3.new(0, 2, 0)
                            task.wait(0.25)

                            pcall(function()
                                fireproximityprompt(prompt)
                            end)

                            task.wait(0.3)
                        end
                    end

                    -- If no snowflakes left → return to original spot
                    if not foundAny then
                        hrp.CFrame = originalCFrame
                        autoSnowflakes = false
                        break
                    end

                    task.wait(0.5)
                end
            end)
        end
    end
})

local function copyLink(name, link)
    setclipboard(link)
    Rayfield:Notify({
        Title = "Copied!",
        Content = name .. " link copied to clipboard",
        Duration = 3
    })
end

-- From low robux to high plz support me!
SupportTab:CreateButton({
    Name = "linkvertice",
    Callback = function()
        setclipboard("https://link-hub.net/1402067/y38uvYI5ny4q")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Support",
            Text = "Link copied to clipboard!",
            Duration = 5
        })
    end
})

SupportTab:CreateButton({
    Name = "💎 3 Robux",
    Callback = function()
        copyLink("3 Robux", "https://www.roblox.com/game-pass/1393917970/3-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 5 Robux",
    Callback = function()
        copyLink("5 Robux", "https://www.roblox.com/game-pass/1394051778/5-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 7 Robux",
    Callback = function()
        copyLink("7 Robux", "https://www.roblox.com/game-pass/1590110782/7-ROBUX")
    end
})

SupportTab:CreateButton({
    Name = "💎 10 Robux",
    Callback = function()
        copyLink("10 Robux", "https://www.roblox.com/game-pass/1397546692/10-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 20 Robux",
    Callback = function()
        copyLink("20 Robux", "https://www.roblox.com/game-pass/1399668269/20-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 50 Robux",
    Callback = function()
        copyLink("50 Robux", "https://www.roblox.com/game-pass/1396221207/50-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 100 Robux",
    Callback = function()
        copyLink("100 Robux", "https://www.roblox.com/game-pass/1394439639/100-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 150 Robux",
    Callback = function()
        copyLink("150 Robux", "https://www.roblox.com/game-pass/1421451261/Thanks")
    end
})

SupportTab:CreateButton({
    Name = "💎 200 Robux",
    Callback = function()
        copyLink("200 Robux", "https://www.roblox.com/game-pass/1423400055/Ty")
    end
})

SupportTab:CreateButton({
    Name = "💎 300 Robux",
    Callback = function()
        copyLink("300 Robux", "https://www.roblox.com/game-pass/1504992105/300-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 500 Robux",
    Callback = function()
        copyLink("500 Robux", "https://www.roblox.com/game-pass/1395983236/500-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 1000 Robux",
    Callback = function()
        copyLink("1000 Robux", "https://www.roblox.com/game-pass/1394041876/1000-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 1000 Robux (Thanks)",
    Callback = function()
        copyLink("1000 Robux Thanks", "https://www.roblox.com/game-pass/1460106222/Thanks-nnnnn")
    end
})

SupportTab:CreateButton({
    Name = "💎 2500 Robux",
    Callback = function()
        copyLink("2500 Robux", "https://www.roblox.com/game-pass/1437117512/2-500-robux")
    end
})

SupportTab:CreateButton({
    Name = "💎 3000 Robux",
    Callback = function()
        copyLink("3000 Robux", "https://www.roblox.com/game-pass/1587430862/3000-Robux")
    end
})

SupportTab:CreateButton({
    Name = "💎 5000 Robux",
    Callback = function()
        copyLink("5000 Robux", "https://www.roblox.com/game-pass/1395963387/5000-rbx")
    end
})

SupportTab:CreateButton({
    Name = "💎 10000 Robux",
    Callback = function()
        copyLink("10000 Robux", "https://www.roblox.com/game-pass/1399060598/10000-rbx")
    end
})



Rayfield:Notify({
   Title = "TZ notify",
   Content = "Godmode and auto skillcheck is active!",
   Duration = 6.5,
   Image = "shield-half",
})


local fullbrightEnabled = false
local oldLighting = {}

TabMain:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Callback = function(state)
        fullbrightEnabled = state

        local Lighting = game:GetService("Lighting")

        if state then
            -- Save old values
            oldLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient
            }

            Lighting.Brightness = 3
            Lighting.ClockTime = 12
            Lighting.FogEnd = 1e9
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        else
            -- Restore old values
            for prop, value in pairs(oldLighting) do
                pcall(function()
                    Lighting[prop] = value
                end)
            end
        end
    end
})


local noFogEnabled = false
local originalFogEnd, originalFogStart

TabMain:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Callback = function(state)
        noFogEnabled = state
        local Lighting = game:GetService("Lighting")

        if state then
            originalFogEnd = Lighting.FogEnd
            originalFogStart = Lighting.FogStart

            task.spawn(function()
                while noFogEnabled do
                    Lighting.FogStart = 0
                    Lighting.FogEnd = 1e9
                    task.wait(1)
                end
            end)
        else
            if originalFogEnd then
                Lighting.FogEnd = originalFogEnd
            end
            if originalFogStart then
                Lighting.FogStart = originalFogStart
            end
        end
    end
})

-- // Player ESP Variables
-- Player ESP Variables
local espPlayersOn = false
local espNameOn = true
local espDistanceOn = true
local playerESPMap = {}

-- Create or update ESP for a player
local function createOrUpdatePlayerESP(player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local data = playerESPMap[player]
    
    if not data then
        -- Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "TZ_PlayerHighlight"
        highlight.Adornee = player.Character
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
        highlight.FillTransparency = 0.7
        highlight.Parent = workspace

        -- Billboard for name & distance
        local billboard, textLabel
        if espNameOn or espDistanceOn then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "TZ_PlayerESPText"
            billboard.Adornee = hrp
            billboard.Size = UDim2.new(0, 100, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true

            textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            textLabel.TextScaled = true
            textLabel.Text = player.Name
            textLabel.Parent = billboard
            billboard.Parent = workspace
        end

        playerESPMap[player] = {
            highlight = highlight,
            billboard = billboard,
            textLabel = textLabel
        }
    end

    -- Update Billboard text
    local data2 = playerESPMap[player]
    if data2 and data2.textLabel then
        local dist = math.floor((hrp.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
        if espNameOn and espDistanceOn then
            data2.textLabel.Text = player.Name .. " | " .. dist .. "m"
        elseif espNameOn then
            data2.textLabel.Text = player.Name
        elseif espDistanceOn then
            data2.textLabel.Text = dist .. "m"
        else
            data2.textLabel.Text = ""
        end
    end
end

-- Remove ESP for a player
local function removePlayerESP(player)
    local data = playerESPMap[player]
    if data then
        if data.highlight then pcall(function() data.highlight:Destroy() end) end
        if data.billboard then pcall(function() data.billboard:Destroy() end) end
        playerESPMap[player] = nil
    end
end

-- Main ESP loop
task.spawn(function()
    while true do
        if espPlayersOn then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    createOrUpdatePlayerESP(player)
                end
            end
        else
            for _, player in ipairs(game.Players:GetPlayers()) do
                removePlayerESP(player)
            end
        end
        task.wait(0.5) -- Update every 0.5s
    end
end)

-- Remove ESP when player leaves
game.Players.PlayerRemoving:Connect(removePlayerESP)

-- Update ESP text with name/distance
task.spawn(function()
    while true do
        if espPlayersOn then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    createPlayerESP(player)
                    local data = playerESPMap[player]
                    if data and data.textLabel then
                        local dist = math.floor((player.Character.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                        if espNameOn and espDistanceOn then
                            data.textLabel.Text = player.Name .. " | " .. dist .. "m"
                        elseif espNameOn then
                            data.textLabel.Text = player.Name
                        elseif espDistanceOn then
                            data.textLabel.Text = dist .. "m"
                        else
                            data.textLabel.Text = ""
                        end
                    end
                end
            end
        else
            for _, player in ipairs(game.Players:GetPlayers()) do
                removePlayerESP(player)
            end
        end
        task.wait(0.5)
    end
end)

-- Remove ESP when player leaves
game.Players.PlayerRemoving:Connect(removePlayerESP)

-- ESP Tab
TabESP:CreateToggle({
    Name = "ESP Players",
    CurrentValue = false,
    Callback = function(state)
        espPlayersOn = state
    end
})

TabESP:CreateToggle({
    Name = "ESP Name",
    CurrentValue = true,
    Callback = function(state)
        espNameOn = state
    end
})

TabESP:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = true,
    Callback = function(state)
        espDistanceOn = state
    end
})

-- // Item ESP Variables
local ItemsESPEnabled = false
local ItemHighlights = {}

local function clearItemESP()
    for _, h in pairs(ItemHighlights) do
        if h and h.Parent then
            h:Destroy()
        end
    end
    table.clear(ItemHighlights)
end

local function createItemESP(obj)
    if ItemHighlights[obj] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 180, 0)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = obj
    highlight.Parent = obj

    ItemHighlights[obj] = highlight
end

task.spawn(function()
    while task.wait(0.5) do
        if not ItemsESPEnabled then
            clearItemESP()
            continue
        end

        local itemsFolder = workspace:FindFirstChild("Floor")
            and workspace.Floor:FindFirstChild("Items")
            and workspace.Floor.Items:FindFirstChild("Items")

        if not itemsFolder then continue end

        for _, item in ipairs(itemsFolder:GetChildren()) do
            local spawnFolder = item:FindFirstChild("Spawn")
            if spawnFolder then
                for _, realItem in ipairs(spawnFolder:GetChildren()) do
                    if realItem:IsA("BasePart") or realItem:IsA("Model") then
                        createItemESP(realItem)
                    end
                end
            end
        end
    end
end)
-- ESP Tab toggle
TabESP:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Callback = function(v)
        ItemsESPEnabled = v
        if not v then
            clearItemESP()
        end
    end
})
local autoSnowmapEnabled = false

TabMain:CreateToggle({
    Name = "Auto Snowmap",
    CurrentValue = false,
    Callback = function(state)
        autoSnowmapEnabled = state
        if not state then return end

        task.spawn(function()
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            local DropItem = player:WaitForChild("PlayerGui")
                :WaitForChild("main")
                :WaitForChild("Bottom")
                :WaitForChild("DropItem")

            while autoSnowmapEnabled do
                -- Map check
                if not workspace:FindFirstChild("Floor")
                or not workspace.Floor:FindFirstChild("Map")
                or not workspace.Floor.Map:FindFirstChild("IceFloor") then
                    task.wait(1)
                    continue
                end

                local machines = workspace.Floor:FindFirstChild("Machines")
                if not machines then task.wait(1) continue end

                local didSomething = false

                -- 🔁 IF HOLDING ITEM → GO TO SNOWMAN
                if DropItem.Visible then
                    for _, machine in ipairs(machines:GetChildren()) do
                        if machine:FindFirstChild("Snowman") then
                            local middle = machine.Snowman:FindFirstChild("MiddleSnowball")
                            local prompt = middle and middle:FindFirstChildWhichIsA("ProximityPrompt")

                            if prompt then
                                hrp.CFrame = middle:GetPivot() + Vector3.new(0, 2, 0)
                                task.wait(0.2)
                                fireproximityprompt(prompt)
                                task.wait(0.4)
                                didSomething = true
                                break
                            end
                        end
                    end

                -- 🔁 IF NOT HOLDING ITEM → PICK ONE
                else
                    for _, machine in ipairs(machines:GetChildren()) do
                        if not machine.Name:lower():find("fuse") and machine:FindFirstChild("Pickup") then
                            for _, obj in ipairs(machine.Pickup:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    hrp.CFrame = obj.Parent:GetPivot() + Vector3.new(0, 2, 0)
                                    task.wait(0.2)
                                    fireproximityprompt(obj)
                                    task.wait(0.4)
                                    didSomething = true
                                    break
                                end
                            end
                        end
                        if didSomething then break end
                    end
                end

                -- ✅ NOTHING LEFT → GO TO ELEVATOR
                if not didSomething then
                    local elevator = workspace:FindFirstChild("Elevator")
                    local part = elevator and elevator:FindFirstChildWhichIsA("BasePart")
                    if part then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                    end
                    autoSnowmapEnabled = false
                    break
                end

                task.wait(0.3)
            end
        end)
    end
})
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local AutoFarm = false
local TP_DELAY = 0.2

-- Safe teleport
local function teleport(part, offsetY)
    offsetY = offsetY or 3
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and part and part:IsA("BasePart") then
        hrp.CFrame = part.CFrame + Vector3.new(0, offsetY, 0)
    end
end

-- Fire all prompts inside a model
local function firePrompts(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(v) end)
        end
    end
end

-- Get current floor reference dynamically
local function getFloor()
    return workspace:FindFirstChild("Floor")
end

-- Collect items in a folder
local function collectFolder(folderName)
    local floor = getFloor()
    if not floor then return end
    local folder = floor.Items:FindFirstChild(folderName)
    if not folder then return end

    for _, item in ipairs(folder:GetChildren()) do
        if not AutoFarm then return end
        local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
        if part then
            teleport(part)
            task.wait(TP_DELAY)
            firePrompts(item)
            task.wait(TP_DELAY)
        end
    end
end

-- Check if player is repairing
local function isRepairing()
    return player.PlayerGui.main.Bottom:FindFirstChild("StopRepairing") ~= nil
end

-- Get all incomplete machines
local function getIncompleteMachines()
    local floor = getFloor()
    if not floor then return {} end
    local machines = {}
    for _, machine in ipairs(floor.Machines:GetChildren()) do
        if machine.Name ~= "FuseBox" then
            local completed = machine:FindFirstChild("Completed")
            if completed and completed.Value == false then
                table.insert(machines, machine)
            end
        end
    end
    return machines
end

-- Work on a single machine
local function workMachine(machine)
    local part = machine:FindFirstChildWhichIsA("BasePart", true)
    if part then
        teleport(part)
        task.wait(TP_DELAY)
        firePrompts(machine)
        -- Wait until StopRepair appears (machine is being worked)
        repeat task.wait(0.2) until isRepairing()
        -- Wait until machine is done
        repeat task.wait(0.3) until not isRepairing() or (machine:FindFirstChild("Completed") and machine.Completed.Value == true)
    end
end

-- Teleport to elevator if Arrow exists
local function teleportElevatorIfArrow()
    local arrow = workspace.Elevator.TeleportExit.Message:FindFirstChild("Arrow")
    if arrow then
        local elevatorPart = workspace.Elevator.ElevatorModel:GetChildren()[3]:GetChildren()[5].Union
        if elevatorPart then
            teleport(elevatorPart, 5)
            -- Wait for new floor to load
            repeat task.wait(0.5) until workspace:FindFirstChild("Floor")
            task.wait(1) -- extra delay for Android lag
        end
    end
end

-- Restart farming when floor changes
local function watchFloorChanges()
    local gameInfo = workspace:FindFirstChild("GameInformation")
    if not gameInfo then return end
    local floorVal = gameInfo:FindFirstChild("Floor")
    if not floorVal then return end

    floorVal:GetPropertyChangedSignal("Value"):Connect(function()
        if AutoFarm then
            -- New floor detected, restart farming loop
            task.spawn(function()
                collectFolder("Capsules")
                collectFolder("Currencies")
                local incompleteMachines = getIncompleteMachines()
                while #incompleteMachines > 0 and AutoFarm do
                    workMachine(incompleteMachines[1])
                    incompleteMachines = getIncompleteMachines()
                end
            end)
        end
    end)
end

-- Fire machine prompts when EyeIcon appears
local function watchEyeIcon()
    local topGui = player.PlayerGui.main.Top
    topGui.ChildAdded:Connect(function(child)
        if child.Name == "EyeIcon" and AutoFarm then
            local incompleteMachines = getIncompleteMachines()
            for _, machine in ipairs(incompleteMachines) do
                firePrompts(machine)
            end
        end
    end)
end

-- Main loop
TabMain:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(state)
        AutoFarm = state
        if AutoFarm then
            watchFloorChanges()
            watchEyeIcon()
            task.spawn(function()
                while AutoFarm do
                    -- Step 1: Collect all items
                    collectFolder("Capsules")
                    collectFolder("Currencies")

                    -- Step 2: Handle machines
                    local incompleteMachines = getIncompleteMachines()
                    while #incompleteMachines > 0 and AutoFarm do
                        local machine = incompleteMachines[math.random(1, #incompleteMachines)]
                        workMachine(machine)
                        incompleteMachines = getIncompleteMachines()
                        task.wait(0.2)
                    end

                    -- Step 3: Teleport elevator if Arrow exists
                    teleportElevatorIfArrow()

                    task.wait(0.2)
                end
            end)
        end
    end
})

local Label = TabMain:CreateLabel("This auto farm only for machines and normal floors (doesn't work with spirit traps", "triangle-alert")

-- Player Tab
local PlayerTab = Window:CreateTab("Player")

-- Noclip toggle
local noclipEnabled = false
PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(state)
        noclipEnabled = state
        game:GetService("RunService").Stepped:Connect(function()
            if noclipEnabled and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
})

-- Fly toggle (fixed)
local flyEnabled = false
local flySpeed = 50
local flyConnection -- store the RenderStepped connection

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(state)
        flyEnabled = state

        -- Turn ON fly
        if flyEnabled then
            local runService = game:GetService("RunService")
            flyConnection = runService.RenderStepped:Connect(function()
                if flyEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    local cam = workspace.CurrentCamera
                    local moveDir = player.Character.Humanoid.MoveDirection

                    -- Move in camera direction with WASD
                    if moveDir.Magnitude > 0 then
                        hrp.Velocity = (cam.CFrame.LookVector * moveDir.Magnitude) * flySpeed
                    else
                        hrp.Velocity = Vector3.new(0,0,0)
                    end
                end
            end)

        -- Turn OFF fly
        else
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            -- Reset velocity when fly is off
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            end
        end
    end
})

-- Fly Speed slider
PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {20, 200},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(value)
        flySpeed = value
    end
})

-- Walk Speed slider
PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200}, -- default Roblox walk speed is 16
    Increment = 1,
    CurrentValue = 16,
    Callback = function(value)
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
        end
    end
})

-- FINAL NOTIFICATION
Rayfield:Notify({
   Title = "TZ announcement",
   Content = "OK guys ... sorry for that error..",
   Duration = 6.5,
   Image = "megaphone",
})