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
    HideSearchBar = false,
})
Window:EditOpenButton({
    Title = "TZ HUB || Dolly's Factory",
    Icon = "solar:compass-big-bold", -- matches your main window icon
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
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer

local function getHRP()
	local char = workspace:WaitForChild("Characters"):WaitForChild(tostring(player.UserId))
	return char:WaitForChild("HumanoidRootPart")
end

local HRP
task.spawn(function()
	while true do
		pcall(function() HRP = getHRP() end)
		task.wait(1)
	end
end)

local Interacts      = workspace:WaitForChild("Interacts")
local StuffingFolder = workspace:WaitForChild("Pickup"):WaitForChild("Stuffing")
local TimerUI        = player:WaitForChild("PlayerGui"):WaitForChild("GameUI"):WaitForChild("HUD"):WaitForChild("Timer")
local SafeZone       = workspace:WaitForChild("Persistent"):WaitForChild("Zones"):WaitForChild("TrainSafeZone")

-- settings
local offset  = -5
local Enabled = false

local rejectEscapeEnabled = false
local rejectDistance      = 25
local rejectWaitTime      = 5

local avoidingReject = false
local RejectFound = false
local hideWaitTime = 0.2 

-- helpers
local function Freeze(state)
	local char = workspace:FindFirstChild("Characters")
		and workspace.Characters:FindFirstChild(tostring(player.UserId))
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = state and 0 or 16
		hum.JumpPower = state and 0 or 50
	end
end

local function TPUnder(part)
	if HRP then
		HRP.CFrame = part.CFrame * CFrame.new(0, offset, 0)
	end
end

local function FirePrompts(obj)
	for _, v in ipairs(obj:GetDescendants()) do
		if v:IsA("ProximityPrompt") then
			pcall(function() fireproximityprompt(v, 0) end)
		end
	end
end

local function GetPart(obj)
	if obj:IsA("BasePart") or obj:IsA("MeshPart") then return obj end
	return obj:FindFirstChildWhichIsA("MeshPart", true)
		or obj:FindFirstChildWhichIsA("BasePart", true)
end

local function WaitIfAvoiding()
	while avoidingReject do
		task.wait(0.1)
	end
end

-- reject escape
local function StartRejectWatcher()
	task.spawn(function()
		while Enabled do
			task.wait(0.2)

			if not rejectEscapeEnabled or avoidingReject or not HRP then continue end

			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("Model") and v.Name:lower():find("reject") then
					local hrp = v:FindFirstChild("HumanoidRootPart")
					if hrp then
						local dist = (HRP.Position - hrp.Position).Magnitude
						if dist <= rejectDistance then

							avoidingReject = true
							local returnCFrame = HRP.CFrame

							-- Evacuate to safety
							if SafeZone then
								HRP.CFrame = SafeZone:GetPivot() * CFrame.new(0, 3, 0)
							end

							task.wait(rejectWaitTime)

							if Enabled and HRP then
								HRP.CFrame = returnCFrame
							end

							avoidingReject = false
							break
						end
					end
				end
			end
		end
	end)
end

-- train parts (Left unchanged structurally)
local function CollectTrainParts()
    local delivery = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("DeliveryPoint")

    local folder = workspace:FindFirstChild("Interacts")
        and workspace.Interacts:FindFirstChild("ItemCollection")

    local safeZone = workspace:FindFirstChild("Persistent")
        and workspace.Persistent:FindFirstChild("Zones")
        and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")

    if not delivery or not folder or not HRP then
        return false
    end

    WaitIfAvoiding()

    local target = nil

    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("MeshPart") and obj.Name == "Train Part" then
            target = obj
            break
        end
    end

    if not target then
        if safeZone then
            HRP.CFrame = safeZone.CFrame * CFrame.new(0, 3, 0)
        end
        return false
    end

    HRP.CFrame = target.CFrame
    HRP.CFrame = target.CFrame - Vector3.new(0, 4, 0)

    for _, v in ipairs(target:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(v, 0)
            end)
        end
    end

    if target:FindFirstChild("AlignOrientation") then
        HRP.CFrame = delivery.CFrame * CFrame.new(0, 3, 0)
    end

    return true
end

local function ScanRejectMeistro()
	task.spawn(function()
		while Enabled do
			local enemies = workspace:FindFirstChild("Enemies")
			local found = false

			if enemies then
				for _, v in ipairs(enemies:GetDescendants()) do
					if v:IsA("Model") and v.Name == "RejectMeistro" then
						found = true
						RejectFound = true
						print("RejectMeistro FOUND")
						break
					end
				end
			end

			if not found then
				RejectFound = false
				print("RejectMeistro NOT FOUND (new zone / waiting spawn)")
			end
			task.wait(0.5)
		end
	end)
end

local function BurstTeleportToSafeZone()
	if not SafeZone or not HRP then return end
	local start = tick()
	while Enabled and (tick() - start < hideWaitTime) do
		if HRP then
			HRP.CFrame = SafeZone:GetPivot() * CFrame.new(0, 3, 0)
		end
		task.wait(0.02)
	end
end
local firedCoils = {}

local function DoCoils()
	local map = workspace:FindFirstChild("Map")
	if not map then return false end

	local safeZone = workspace:FindFirstChild("Persistent")
		and workspace.Persistent:FindFirstChild("Zones")
		and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")

	if not safeZone then return false end

	local coilRoot = map:FindFirstChild("Interact", true)
		and map.Interact:FindFirstChild("TeslaCoil", true)
		and map.Interact.TeslaCoil:FindFirstChild("CoilActivators", true)

	if not coilRoot then return false end

	local function getCoilsWithPrompt()
		local list = {}
		for _, obj in ipairs(coilRoot:GetDescendants()) do
			if obj.Name == "Coil" then
				local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt and prompt.Enabled and prompt.Parent then
					local part = obj:IsA("BasePart") and obj
						or obj:FindFirstChildWhichIsA("MeshPart", true)
						or obj:FindFirstChildWhichIsA("BasePart", true)
					if part then
						table.insert(list, { obj = obj, part = part, prompt = prompt })
					end
				end
			end
		end
		return list
	end

	while Enabled do
		WaitIfAvoiding()
		local coils = getCoilsWithPrompt()

		if #coils == 0 then
			WaitIfAvoiding()
			if HRP then
				HRP.CFrame = safeZone.CFrame * CFrame.new(0, 3, 0)
			end
			task.wait(0.3)

			if not coilRoot or not coilRoot.Parent then
				HRP.CFrame = safeZone.CFrame * CFrame.new(0, 3, 0)
				return false
			end

			continue
		end

		for _, coil in ipairs(coils) do
			if not Enabled then break end
			WaitIfAvoiding()
			if not coil.obj.Parent then continue end

			local start = tick()

			while Enabled and coil.obj.Parent and coil.prompt.Parent do
				WaitIfAvoiding()
				if HRP then
					HRP.CFrame = coil.part.CFrame * CFrame.new(0, 3, 0)
				end

				pcall(function()
					fireproximityprompt(coil.prompt, coil.prompt.HoldDuration or 0)
				end)

				task.wait(0.01)

				if tick() - start > 2 then break end
			end

			task.wait(0.05)
		end

		task.wait(0.05)
	end

	return true
end
-- machine handler
local function GetMaxProgress(machine)
    return CollectionService:HasTag(machine, "ToughMachine") and 2 or 1
end

local function GetAllMachines()
    local goldenMachines = {}
    local normalMachines = {}

    for _, machine in pairs(CollectionService:GetTagged("PlushieMachine")) do
        local progress = machine:GetAttribute("Progress") or 0
        local max = GetMaxProgress(machine)

        if progress < max then
            if CollectionService:HasTag(machine, "ToughMachine") then
                table.insert(goldenMachines, machine)
            else
                table.insert(normalMachines, machine)
            end
        end
    end

    for _, machine in ipairs(normalMachines) do
        table.insert(goldenMachines, machine)
    end

    return goldenMachines
end

local function HandleMachine(machine)
    if not HRP or not machine then return end

    local function getProgress()
        return machine:GetAttribute("Progress") or 0
    end

    local max = GetMaxProgress(machine)
    if getProgress() >= max then return end

    local function getMachineTargetPart()
        local machineType = machine:GetAttribute("MachineType")
        if machineType == "Drone" then
            local base = machine:FindFirstChild("Base")
            if base and base:IsA("BasePart") then return base end
            local pump = machine:FindFirstChild("Pump")
            if pump and pump:IsA("BasePart") then return pump end
        end

        local goldenPart = machine:FindFirstChild("Golden_Machine", true)
        if goldenPart and goldenPart:IsA("BasePart") then
            return goldenPart
        end

        local cylinder = machine:FindFirstChild("Cylinder.270", true)
        if cylinder and cylinder:IsA("BasePart") then
            return cylinder
        end

        return machine:FindFirstChildWhichIsA("BasePart", true)
    end

    local part = getMachineTargetPart()
    if not part then return end

    Freeze(true) -- Freeze ONCE before beginning interaction

    while Enabled and getProgress() < max and machine.Parent do
        WaitIfAvoiding()

        local targetCFrame = nil
        local p1 = machine:FindFirstChild("Player1Pivot")
        local p2 = machine:FindFirstChild("Player2Pivot")

        if p1 and p2 then
            local p1Pos = p1:GetPivot().Position
            local p2Pos = p2:GetPivot().Position
            local charPos = HRP.Position
            -- Choose the closest manual lever pivot part
            if (p1Pos - charPos).Magnitude < (p2Pos - charPos).Magnitude then
                targetCFrame = p1:GetPivot() * CFrame.new(0, -4, 0)
            else
                targetCFrame = p2:GetPivot() * CFrame.new(0, -4, 0)
            end
        else
            targetCFrame = part.CFrame * CFrame.new(0, -4, 0)
        end

        local burstDuration = 0.25
        local burstStart = tick()

        while Enabled and getProgress() < max and machine.Parent and (tick() - burstStart < burstDuration) do
            if HRP then
                HRP.CFrame = targetCFrame
            end

            FirePrompts(machine)
            if machine.Parent then FirePrompts(machine.Parent) end

            task.wait(0.02)
        end
        task.wait(0.02)
    end

    Freeze(false) -- Safely unfreeze once the machine task completes
end

local function run()
	ScanRejectMeistro()
	StartRejectWatcher()

	-- Timer/HUD management loop
	task.spawn(function()
		local last = false
		while Enabled do
			WaitIfAvoiding()
			if TimerUI and TimerUI.Visible then
				if not last then
					for i = 1, 3 do
						if HRP and SafeZone then
							HRP.CFrame = SafeZone:GetPivot() * CFrame.new(0, 3, 0)
						end
						task.wait(0.05)
					end
				end
				last = true
			else
				last = false
			end
			task.wait(0.2)
		end
	end)

	offset = -4

	-- Unified Central Automation Cycle
	while Enabled do
		WaitIfAvoiding()

		if RejectFound then
			BurstTeleportToSafeZone()
			task.wait(0.2)
			continue
		end

		-- 1. Run Stuffing Priority
		local items = StuffingFolder and StuffingFolder:GetChildren() or {}
		if #items > 0 then
			local originCFrame = HRP and HRP.CFrame

			for _, v in ipairs(items) do
				if not Enabled then break end
				WaitIfAvoiding()

				local part = GetPart(v)
				if not part then continue end

				local startCheck = tick()
				repeat
					WaitIfAvoiding()
					if HRP then
						HRP.CFrame = part.CFrame * CFrame.new(0, offset, 0)
					end
					FirePrompts(v)
					task.wait(0.02)
				until not v.Parent or not Enabled or (tick() - startCheck > 3) -- Timeout safeguard
			end

			if Enabled and HRP and originCFrame then
				HRP.CFrame = originCFrame
				task.wait(0.05)
			end
		end

		-- 2. Try Maintain Train Maintenance Tasks
		if CollectTrainParts() then
			task.wait(0.05)
			continue
		end

		-- 3. Cycle and Run Factory Production Machines
		for _, machine in ipairs(GetAllMachines()) do
			if not Enabled then break end
			WaitIfAvoiding()
			HandleMachine(machine)
		end

		-- 4. Idle State Backrest
		if HRP and SafeZone and not avoidingReject then
			HRP.CFrame = SafeZone:GetPivot() * CFrame.new(0, 3, 0)
		end

		task.wait(0.1)
	end
end

-- UI Elements Hook
local thread

MainTab:Toggle({
	Title = "Auto Farm",
	Desc = "While using auto farm please don't enable any other features because they will break the auto farm like auto stuffing toggle but you can only enable auto rejoin features and esp features and reject escape features ",
	Flag = "Autofarm_toggle",
	Icon = "",
	Value = false,
	Callback = function(state)
		Enabled = state
		if not Enabled then
			avoidingReject = false
			Freeze(false)
		else
			if not thread then
				thread = task.spawn(function()
					run()
					thread = nil
				end)
			end
		end
	end
})

local RejectSlider = MainTab:Slider({
	Title = "Reject Hide Delay",
	Desc = "Time spent hiding when RejectMeistro appears",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 5,
		Default = 0.2
	},
	Callback = function(value)
		hideWaitTime = value
	end
})

MainTab:Toggle({
	Title = "Reject Escape",
	Flag = "rejectEscape_toggle",
	Desc = "Make the autofarm avoid rejects when close",
	Icon = "shield",
	Value = false,
	Callback = function(state)
		rejectEscapeEnabled = state
	end
})

MainTab:Slider({
	Title = "Reject Detection Distance",
	Desc = "How close a Reject must be to trigger escape",
	Icon = "",
	Step = 1,
	Value = {
		Min = 5,
		Max = 100,
		Default = 25,
	},
	Callback = function(val)
		rejectDistance = val
	end
})

MainTab:Slider({
	Title = "SafeZone Wait Time",
	Flag = "safezonewait_slider",
	Desc = "How many seconds to stay in SafeZone before returning",
	Icon = "",
	Step = 1,
	Value = {
		Min = 1,
		Max = 100,
		Default = 5,
	},
	Callback = function(val)
		rejectWaitTime = val
	end
})
-- Anti-Poison Script (Executor-safe, LocalPlayer only)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Force poison attributes to safe values
LocalPlayer:SetAttribute("InPoison", false)
LocalPlayer:SetAttribute("PoisonMeter", 0)
LocalPlayer:SetAttribute("PoisonMeterMax", 0)

-- Hook PoisonHandler if present
local PoisonHandler = ReplicatedStorage:FindFirstChild("Shared")
    and ReplicatedStorage.Shared.Modules:FindFirstChild("PoisonHandler")

if PoisonHandler then
    local module = require(PoisonHandler)
    -- Override poison functions to no-op
    module.ApplyPoison = function() end
    module.TickPoison = function() end
    module.RemovePoison = function() end
end

-- Hide poison UI overlays
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PoisonUI = PlayerGui:FindFirstChild("GameUI")
    and PlayerGui.GameUI:FindFirstChild("HUDComponents")
    and PlayerGui.GameUI.HUDComponents:FindFirstChild("PoisonBarUI")

if PoisonUI then
    PoisonUI.Visible = false
end

-- Kill poison feedback loop
local VFXController = LocalPlayer.PlayerScripts.Client.Game.VFXController
local PoisonFeedback = VFXController:FindFirstChild("PoisonFeedback")
if PoisonFeedback then
    local feedbackModule = require(PoisonFeedback)
    feedbackModule.OnAdded = function() end
    feedbackModule.UpdatePoison = function() end
end

print("Anti-poison active")