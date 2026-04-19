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

--auto farm

local Players = game:GetService("Players")
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

-- =========================
-- SETTINGS
-- =========================
local offset  = -5
local Enabled = false

local rejectEscapeEnabled = false
local rejectDistance      = 25
local rejectWaitTime      = 5

local avoidingReject = false
local RejectFound = false
local hideWaitTime = 0.2 
-- =========================
-- HELPERS
-- =========================
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
	for _, v in pairs(obj:GetDescendants()) do
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

-- =========================
-- REJECT ESCAPE WATCHER
-- =========================
local function StartRejectWatcher()
	task.spawn(function()
		while Enabled do
			task.wait(0.3)

			if not rejectEscapeEnabled then continue end
			if avoidingReject then continue end
			if not HRP then continue end

			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA("Model") and v.Name:lower():find("reject") then
					local hrp = v:FindFirstChild("HumanoidRootPart")
					if hrp then
						local dist = (HRP.Position - hrp.Position).Magnitude
						if dist <= rejectDistance then

							avoidingReject = true

							local returnCFrame = HRP.CFrame

							HRP.CFrame = SafeZone:GetPivot() * CFrame.new(0, 3, 0)

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

-- =========================
-- TRAIN PARTS
-- =========================
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

    -- find ONLY Train Part (same as your working script)
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("MeshPart") and obj.Name == "Train Part" then
            target = obj
            break
        end
    end

    -- no train part → go safe zone
    if not target then
        if safeZone then
            HRP.CFrame = safeZone.CFrame * CFrame.new(0, 3, 0)
        end
        return false
    end

    -- move to train part
    HRP.CFrame = target.CFrame
    HRP.CFrame = target.CFrame - Vector3.new(0, 4, 0)

    -- fire prompt
    for _, v in ipairs(target:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(v, 0)
            end)
        end
    end

    -- deliver if collected
    if target:FindFirstChild("AlignOrientation") then
        HRP.CFrame = delivery.CFrame * CFrame.new(0, 3, 0)
    end

    return true
end
local function ScanRejectMeistro()
	task.spawn(function()
		while Enabled do
			task.wait(0.5)

			local enemies = workspace:FindFirstChild("Enemies")
			if not enemies then continue end

			local found = false

			for _, v in ipairs(enemies:GetDescendants()) do
				if v:IsA("Model") and v.Name == "RejectMeistro" then
					found = true
					RejectFound = true
					print("RejectMeistro FOUND")
					break
				end
			end

			if not found then
				RejectFound = false
				print("RejectMeistro NOT FOUND (new zone / waiting spawn)")
			end
		end
	end)
end
local function BurstTeleportToSafeZone()
	task.spawn(function()
		local zone = workspace:FindFirstChild("Persistent")
			and workspace.Persistent:FindFirstChild("Zones")
			and workspace.Persistent.Zones:FindFirstChild("TrainSafeZone")

		if not zone or not HRP then return end

		local part = zone:IsA("BasePart") and zone or zone:FindFirstChildWhichIsA("BasePart")
		if not part then return end

		local start = tick()

		while Enabled and (tick() - start < hideWaitTime) do
			if HRP then
				HRP.CFrame = part.CFrame * CFrame.new(0, 3, 0)
			end
			task.wait(0.001)
		end
	end)
end
-- =========================
-- COILS
-- =========================
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

-- =========================
-- MACHINE HANDLER
-- =========================
-- =========================
-- MACHINE HANDLER (Controller Method)
-- =========================
local CollectionService = game:GetService("CollectionService")

local function GetAllMachines()
    local goldenMachines = {}
    local normalMachines = {}

    for _, machine in pairs(CollectionService:GetTagged("PlushieMachine")) do
        local progress = machine:GetAttribute("Progress") or 0
        if progress < 1 then
            if CollectionService:HasTag(machine, "ToughMachine") then
                table.insert(goldenMachines, machine)
            else
                table.insert(normalMachines, machine)
            end
        end
    end

    -- Combine them: Golden machines first, then normal ones
    for _, machine in ipairs(normalMachines) do
        table.insert(goldenMachines, machine)
    end

    return goldenMachines
end


-- Replace HandleMachine with this ultra-aggressive teleport version (0.001s reapply)
local function HandleMachine(machine)
    if not HRP or not machine then return end

    local function getProgress() return machine:GetAttribute("Progress") or 0 end
    if getProgress() >= 1 then return end

    local cylinder = machine:FindFirstChild("Cylinder.270", true)
        or machine:FindFirstChildWhichIsA("BasePart", true)
    if not cylinder then return end

    -- aggressive teleport loop: re-teleport under the correct pivot extremely frequently (0.001s)
    while Enabled and getProgress() < 1 do
        WaitIfAvoiding()

        -- determine side using MachineController (safe pcall)
        local ok, side = pcall(function()
            return MachineController:_getClosestLever(player, machine)
        end)

        local targetCFrame = nil
        if ok and (side == 1 or side == 2) then
            local pivot = machine:FindFirstChild("Player" .. tostring(side) .. "Pivot")
            if pivot and pivot.GetPivot then
                local s, pivotCFrame = pcall(function() return pivot:GetPivot() end)
                if s and pivotCFrame then
                    targetCFrame = pivotCFrame * CFrame.new(0, -4, 0)
                end
            end
        end

        -- fallback to cylinder if pivot not available
        if not targetCFrame then
            targetCFrame = cylinder.CFrame * CFrame.new(0, -4, 0)
        end

        -- Ultra loop: continuously reapply HRP.CFrame at ~0.001s intervals for a short burst,
        -- then re-evaluate pivot/conditions to avoid infinite tight blocking.
        local burstDuration = 0.25 -- total time to aggressively reapply before recalculating
        local burstStart = tick()
        while Enabled and getProgress() < 1 and tick() - burstStart < burstDuration do
            if HRP then
                -- reapply exact target position
                HRP.CFrame = targetCFrame
            end

            -- keep interacting while reapplying
            FirePrompts(machine)
            if machine.Parent then FirePrompts(machine.Parent) end

            -- maintain freeze state while under machine
            if MachineController:UsingMachine() == machine then
                Freeze(true)
            else
                Freeze(true)
            end

            task.wait(0.001) -- ultra-tight reapply interval
            if not machine.Parent then break end
        end

        -- small safety yield to let other systems run and to re-evaluate conditions
        task.wait(0.001)

        if not machine.Parent then break end
    end

    Freeze(false)
end

local function run()
  
ScanRejectMeistro()
if RejectFound then
	BurstTeleportToSafeZone()
end
	StartRejectWatcher()

	task.spawn(function()
		local last = false
		while Enabled do
			WaitIfAvoiding()
			if TimerUI.Visible then
				if not last then
					for i = 1, 3 do
						if HRP then
							HRP.CFrame = SafeZone.CFrame * CFrame.new(0, 3, 0)
						end
						task.wait(0.05)
					end
				end
				last = true
			else
				last = false
			end
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		offset = -4
		for _, v in pairs(StuffingFolder:GetChildren()) do
			if not Enabled then break end
			WaitIfAvoiding()
			local part = GetPart(v)
			if part then
				repeat
					WaitIfAvoiding()
					TPUnder(part)
					FirePrompts(v)
					task.wait(0.001)
				until not v.Parent or not Enabled
			end
		end
	end)

	while Enabled do
		WaitIfAvoiding()

		if CollectTrainParts() then
			task.wait(0.05)
			continue
		end

		local didCoil = DoCoils()

		if not didCoil then
    for _, machine in ipairs(GetAllMachines()) do
        if not Enabled then break end
        WaitIfAvoiding()
        HandleMachine(machine)
    end
end

if not didCoil and HRP then
			WaitIfAvoiding()
			HRP.CFrame = SafeZone.CFrame * CFrame.new(0, 3, 0)
		end

		task.wait(0.001)
	end

end

-- =========================
-- UI
-- =========================
local thread

MainTab:Toggle({
    Title = "Auto Farm",
    Desc = "Auto-disables conflicting features when enabled.",
    Flag = "Autofarm_toggle",
    Callback = function(state)
        Enabled = state
        
        if state then
            -- LINKING LOGIC: 
            -- Disable other toggles here by setting their script variables to false
            -- Example: autoStuffingEnabled = false
            
            if not thread then
                thread = task.spawn(function()
                    run()
                    thread = nil
                end)
            end
        else
            -- Cleanup when turned off
            avoidingReject = false
            Freeze(false) 
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