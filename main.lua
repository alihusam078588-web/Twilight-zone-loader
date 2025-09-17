-- WindUI integration for TZ All-in-One -- Loads WindUI and builds a UI that controls the Twilight Zone script features. -- Credits: Ali_hhjjj | Tester: GoodJOBS3 | Special thanks: Olivia (Riddance Hub WindUI)

-- Load WindUI (official dist) local ok, WindUI = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))() end) if not ok or not WindUI then error("Failed to load WindUI. Check your internet or the WindUI URL.") end

-- === TZ core functions (adapted & exposed as API for WindUI buttons) === -- Note: This embeds the functional parts of the TZ All-in-One script so WindUI toggles -- can call them. The implementation is the same as the working script you already had.

local Players = game:GetService("Players") local ReplicatedStorage = game:GetService("ReplicatedStorage") local Workspace = game:GetService("Workspace") local LocalPlayer = Players.LocalPlayer

local function findRepresentativePart(model) if not model then return nil end if model:IsA("BasePart") then return model end local names = {"Front","front","Head","head","HumanoidRootPart","PrimaryPart"} for _,n in ipairs(names) do local f = model:FindFirstChild(n) if f and f:IsA("BasePart") then return f end end if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end return model:FindFirstChildWhichIsA("BasePart", true) end

local function isFuseLike(name) if not name then return false end local s = tostring(name):lower() return s:find("fuse") or s:find("fusebox") or s:find("fuse_box") end

local function gatherMachineParts() local parts = {} local candidates = { (Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Machines")) or nil, Workspace:FindFirstChild("Machines") or nil, Workspace:FindFirstChild("CurrentRoom") or nil, Workspace } for _, folder in ipairs(candidates) do if folder and folder.GetChildren then for _, child in ipairs(folder:GetChildren()) do if child and not isFuseLike(child.Name) then if child:IsA("Model") then local rep = findRepresentativePart(child) if rep then table.insert(parts, rep) end elseif child:IsA("BasePart") then table.insert(parts, child) end end end end end return parts end

local function teleportToPart(part, yOffset) yOffset = yOffset or 5 if not part then return false end local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2) if not hrp then return false end pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, yOffset, 0) end) return true end

local function teleportToRandomMachine() local parts = gatherMachineParts() if #parts == 0 then return false end return teleportToPart(parts[math.random(1,#parts)]) end

local function teleportToElevator() local elevator = Workspace:FindFirstChild("Elevator") if not elevator then return false end local spawn = elevator:FindFirstChild("ElevatorSpawn") or elevator:FindFirstChild("Elevator1") or elevator:FindFirstChild("Elevator2") or findRepresentativePart(elevator) if not spawn then return false end return teleportToPart(spawn, 2) end

-- ESP helpers local espMachinesOn, espSpiritsOn = false, false local espMap = {} local function createHighlightFor(target, color) if not target or not target.Parent then return end if espMap[target] then return end local ok, hl = pcall(function() local h = Instance.new("Highlight") h.Name = "TZ_HL" h.Adornee = target h.FillColor, h.OutlineColor = color, color h.FillTransparency = 0.55 h.Parent = target return h end) if ok and hl then espMap[target] = hl end end local function clearAllHighlights() for _, hl in pairs(espMap) do pcall(function() hl:Destroy() end) end espMap = {} end

-- AutoSkill always on pcall(function() local function tryAttachSkillCheck(remote) if not remote then return end pcall(function() if remote:IsA("RemoteFunction") then remote.OnClientInvoke = function(...) return 2 end elseif remote:IsA("RemoteEvent") then remote.OnClientEvent:Connect(function(...) end) end end) end for _, v in ipairs(ReplicatedStorage:GetDescendants()) do if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and tostring(v.Name):lower():find("skill") then tryAttachSkillCheck(v) end end ReplicatedStorage.DescendantAdded:Connect(function(desc) if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) and tostring(desc.Name):lower():find("skill") then tryAttachSkillCheck(desc) end end) end)

-- Godmode: remove HitPlayer task.spawn(function() while true do pcall(function() for _,v in ipairs(Workspace:GetDescendants()) do if v and v.Name and tostring(v.Name):match("^HitPlayer") then pcall(function() v:Destroy() end) end end end) task.wait(0.6) end end)

-- Exposed state flags (used by UI) local state = { espMachines = false, espSpirits = false, infiniteStamina = false, autoTeleportToMachine = false, autoElevatorWatch = false }

-- stamina remote (optional) pcall(function() state.AddStamina = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("AddStamina") end)

-- background loops task.spawn(function() while true do if state.infiniteStamina and state.AddStamina then pcall(function() firesignal(state.AddStamina.OnClientEvent, 45) end) end task.wait(0.25) end end)

-- esp updater task.spawn(function() while true do if state.espMachines then for _, p in ipairs(gatherMachineParts()) do if p and p.Parent and not espMap[p] then if p.Parent:IsA("Model") then createHighlightFor(p.Parent, Color3.fromRGB(0,200,0)) else createHighlightFor(p, Color3.fromRGB(0,200,0)) end end end end if state.espSpirits then local containers = {} if Workspace:FindFirstChild("Spirits") then table.insert(containers, Workspace.Spirits) end if Workspace:FindFirstChild("Floor") and Workspace.Floor:FindFirstChild("Spirits") then table.insert(containers, Workspace.Floor.Spirits) end for _, c in ipairs(containers) do for _, s in ipairs(c:GetChildren()) do if s and not espMap[s] then createHighlightFor(s, Color3.fromRGB(200,0,200)) end end end end if not state.espMachines and not state.espSpirits then clearAllHighlights() end task.wait(0.9) end end)

-- Auto teleport to machines (aura) background local auraDelay = 0.2 local auraRepeat = 8 local function findProximityPromptInModel(model) if not model then return nil end for _,d in ipairs(model:GetDescendants()) do if d and d:IsA("ProximityPrompt") then return d end end return nil end

task.spawn(function() while true do if state.autoTeleportToMachine then local parts = gatherMachineParts() if #parts == 0 then -- teleport to elevator automatically when no machines left pcall(teleportToElevator) task.wait(1.2) else local target = parts[math.random(1,#parts)] if teleportToPart(target) then task.wait(0.2) local model = (target.Parent and target.Parent:IsA("Model")) and target.Parent or target local prompt = findProximityPromptInModel(model) or findProximityPromptInModel(target) if prompt then for i=1,auraRepeat do if not state.autoTeleportToMachine then break end pcall(function() fireproximityprompt(prompt) end) task.wait(auraDelay) end else -- fallback: try E key presses for i=1,4 do if not state.autoTeleportToMachine then break end pcall(function() local vim = game:GetService("VirtualInputManager") vim:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.05) vim:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) task.wait(0.15) end end task.wait(0.2) end end end task.wait(2) end end)

-- WindUI window & controls local Window = WindUI:CreateWindow({ Title = "Twilight Zone", Icon = "geist:window", Author = "Ali_hhjjj", Folder = "TwilightZone", Size = UDim2.fromOffset(520, 420), Theme = "Dark", })

-- Main tab: ESP & Teleport local MainTab = Window:CreateTab({ Title = "Main", Icon = "sparkles" }) MainTab:CreateToggle({ Title = "ESP Machines", Description = "Highlight machines", Default = false, Callback = function(v) state.espMachines = v end }) MainTab:CreateToggle({ Title = "ESP Spirits", Description = "Highlight spirits", Default = false, Callback = function(v) state.espSpirits = v end }) MainTab:CreateButton({ Title = "Teleport: Random Machine", Description = "Teleport to a random machine", Callback = function() pcall(teleportToRandomMachine) end }) MainTab:CreateButton({ Title = "Teleport: Elevator", Description = "Teleport to the elevator spawn", Callback = function() pcall(teleportToElevator) end }) MainTab:CreateToggle({ Title = "Auto Teleport To Machine", Description = "Automatically teleport to machines and use aura", Default = false, Callback = function(v) state.autoTeleportToMachine = v end }) MainTab:CreateToggle({ Title = "Auto Teleport To Elevator (when done)", Description = "Auto go to elevator when no machines remain", Default = true, Callback = function(v) -- kept for UI preference WindUI:Notify({ Title = "Note", Content = "Script will still teleport to elevator when no machines remain (this toggle is informational).", Duration = 3 }) end })

-- Stamina & Elevator local MiscTab = Window:CreateTab({ Title = "Misc", Icon = "battery" }) MiscTab:CreateToggle({ Title = "Infinite Stamina", Description = "Toggle infinite stamina (fires AddStamina remote)", Default = false, Callback = function(v) state.infiniteStamina = v end }) MiscTab:CreateToggle({ Title = "Auto Elevator (watch message)", Description = "Teleport to elevator when elevator message appears", Default = false, Callback = function(v) state.autoElevatorWatch = v end })

-- Credits tab local CreditsTab = Window:CreateTab({ Title = "Credits", Icon = "award" }) CreditsTab:CreateLabel({ Text = "Created by Ali_hhjjj" }) CreditsTab:CreateLabel({ Text = "Tester/Helper: GoodJOBS3" }) CreditsTab:CreateLabel({ Text = "Special thanks: Olivia (Riddance Hub WindUI)" })

-- Done WindUI:Notify({ Title = "TZ Integration", Content = "Twilight Zone controls loaded into WindUI.", Duration = 3 })

return { TZState = state, TeleportToRandom = teleportToRandomMachine, TeleportToElevator = teleportToElevator, }

                    
