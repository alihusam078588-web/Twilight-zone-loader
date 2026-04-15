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
local function HandleMachine(machine)
    if not machine then return end

    -- unwrap tough/golden
    local target = machine
    local tough = machine:FindFirstChild("ToughMachine")
    if tough then
        target = tough:FindFirstChild("Golden_Machine") or tough
    elseif machine:FindFirstChild("Golden_Machine") then
        target = machine:FindFirstChild("Golden_Machine")
    end

    -- check prompt
    local hasPrompt = false
    for _, v in pairs(target:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            hasPrompt = true
            break
        end
    end
    if not hasPrompt then return end

    local vfx = target:FindFirstChild("VFX")
    if not vfx or #vfx:GetChildren() == 0 then return end

    while Enabled and vfx and vfx.Parent and #vfx:GetChildren() > 0 do
        WaitIfAvoiding()

        local root = target:FindFirstChild("Root")
        local pos = root and root.Position or target:GetPivot().Position

        if HRP and pos and pos.Y > -50 then
            HRP.CFrame = CFrame.new(pos) * CFrame.new(0, 3, 0)
        end

        Freeze(true)
        FirePrompts(target)

        task.wait(0.01)
    end

    Freeze(false)
end
-- =========================
-- REJECT MEISTRO TRACKER
-- =========================
-- default (slider will control this)
-- =========================
-- MAIN LOOP
-- =========================
local function GetAllMachines()
    local list = {}

    for _, obj in pairs(Interacts:GetChildren()) do
        if obj.Name == "ItemCollection" then continue end

        local function isValidMachine(m)
            if not m then return false end

            -- must have a real part
            local part = m:FindFirstChildWhichIsA("BasePart", true)
            if not part then return false end

            -- must have prompt
            local hasPrompt = false
            for _, v in pairs(m:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Enabled then
                    hasPrompt = true
                    break
                end
            end
            if not hasPrompt then return false end

            return true
        end

        -- check normal
        if isValidMachine(obj) then
            table.insert(list, obj)
        end

        -- check tough
        local tough = obj:FindFirstChild("ToughMachine")
        if tough and isValidMachine(tough) then
            table.insert(list, tough)
        end

        -- check golden
        local golden = obj:FindFirstChild("ToughMachine")
            and obj.ToughMachine:FindFirstChild("Golden_Machine")

        if golden and isValidMachine(golden) then
            table.insert(list, golden)
        end
    end

    return list
end
local function GetClosestMachine()
    if not HRP then return nil end

    local closest = nil
    local shortest = math.huge

    for _, machine in ipairs(GetAllMachines()) do
        local target = machine

        local tough = machine:FindFirstChild("ToughMachine")
        if tough then
            target = tough:FindFirstChild("Golden_Machine") or tough
        elseif machine:FindFirstChild("Golden_Machine") then
            target = machine:FindFirstChild("Golden_Machine")
        end

        local root = target:FindFirstChild("Root")
        local pos = root and root.Position or target:GetPivot().Position

        if pos then
            local dist = (HRP.Position - pos).Magnitude

            if dist < shortest and dist < 400 then
                shortest = dist
                closest = machine
            end
        end
    end

    return closest
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
    local machine = GetClosestMachine()
    if machine then
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
	Desc = "test 6",
	Flag = "Autofarm_toggle",
	Icon = "",
	Value = false,
	Callback = function(state)
		Enabled = state
		if not Enabled then
			avoidingReject = false
		end
		if Enabled then
			if not thread then
				thread = task.spawn(function()
					run()
					thread = nil
				end)
			end
		end
	end
})