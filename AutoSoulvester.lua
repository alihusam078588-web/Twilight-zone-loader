local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Stop an earlier copy when re-executed.
local previous = getgenv().SoulAuto
local previousRadiusValues = type(previous) == "table" and type(previous.RadiusValues) == "table"
    and previous.RadiusValues or {}
if type(previous) == "table" and type(previous.Stop) == "function" then
    pcall(previous.Stop)
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local CFG = {
    Enabled = true,
    DangerMode = "VERY_CLOSE",

    -- PREDICTIVE protects the selected player before predicted contact.
    -- HEART_LOSS re-guards after the selected player's metal/shield-heart count drops.
    Mode = "PREDICTIVE",
    SelectedPlayer = "AUTO",
    -- A metal-heart loss waits for ability cooldown to clear, but won't remain queued forever.
    HeartLossQueueWindow = 10.0,
    HeartEventDebounce = 0.18,

    PollRate = 0.02,
    TrackingRefresh = 0.06,
    MaxTrackDistance = 80,
    -- User-configurable per-Twisted trigger radii. These affect SoulAuto's local
    -- prediction only; they do not modify server-side hitboxes.
    RadiusValues = previousRadiusValues,
    PendingGlobalDecrease = "1.5",
    HistoryWindow = 0.22,
    MinHistoryTime = 0.035,
    SampleMinInterval = 0.02,

    -- Predict ahead enough to cover the request/ability startup delay.
    -- Prediction only fires when movement forecasts contact, not just proximity.
    TriggerLead = 0.32,
    ContactBuffer = 0.65,
    EmergencyMargin = 1.90,
    LethalEmergencyMargin = 2.60,
    AttackCueMargin = 2.00,
    PredictionHorizon = 0.80,
    PredictionTolerance = 1.75,

    MinTrendSpeed = 0.80,
    MinRecentSpeed = 0.20,
    MaxClosingSpeed = 70,

    RecastDelay = 0.45,
    -- Block immediate repeated casts on the same player after protecting them.
    TargetProtectionLockout = 6.0,
    FailedRequestLockout = 0.75,
    MinHealth = 2,

    Debug = true,
    DebugWatch = true,
    DebugEvery = 0.55,
}

getgenv().SoulAuto = CFG
local RUNNING = true

local PROFILES = {
    VERY_CLOSE = {
        TriggerLead = 0.32,
        ContactBuffer = 0.65,
        EmergencyMargin = 1.90,
        LethalEmergencyMargin = 2.60,
        AttackCueMargin = 2.00,
        MaxTrackDistance = 80,
    },
    CLOSE = {
        TriggerLead = 0.42,
        ContactBuffer = 0.80,
        EmergencyMargin = 2.10,
        LethalEmergencyMargin = 2.80,
        AttackCueMargin = 2.30,
        MaxTrackDistance = 95,
    },
    EARLY = {
        TriggerLead = 0.55,
        ContactBuffer = 1.00,
        EmergencyMargin = 2.35,
        LethalEmergencyMargin = 3.10,
        AttackCueMargin = 2.70,
        MaxTrackDistance = 110,
    },
}

local profile = PROFILES[CFG.DangerMode] or PROFILES.VERY_CLOSE
for key, value in pairs(profile) do
    CFG[key] = value
end

-- KillRadius values recorded in the supplied decompiled modules.
-- WindUI RadiusValues intentionally override these defaults in SoulAuto calculations.
local TWISTED_SETTINGS = {
    ["Twisted Astro"] = { KillRadius = 3.0 },
    ["Twisted Bassie"] = { KillRadius = 4.0 },
    ["Twisted Blot"] = { KillRadius = 4.0 },
    ["Twisted Bobette"] = { KillRadius = 4.0 },
    ["Twisted Boxten"] = { KillRadius = 3.33 },
    ["Twisted Brightney"] = { KillRadius = 3.3 },
    ["Twisted Brusha"] = { KillRadius = 3.333 },
    ["Twisted Coal"] = { KillRadius = 3.33 },
    ["Twisted Cocoa"] = { KillRadius = 3.33 },
    ["Twisted Connie"] = { KillRadius = 3.3 },
    ["Twisted Cosmo"] = { KillRadius = 3.333 },
    ["Twisted Dandy"] = { KillRadius = 8.5, Lethal = true },
    ["Twisted Dyle"] = { KillRadius = 8.5, Lethal = true },
    ["Twisted Eclipse"] = { KillRadius = 3.33 },
    ["Twisted Eggson"] = { KillRadius = 3.33 },
    ["Twisted Finn"] = { KillRadius = 3.333 },
    ["Twisted Flutter"] = { KillRadius = 3.333 },
    ["Twisted Flyte"] = { KillRadius = 3.333 },
    ["Twisted Gigi"] = { KillRadius = 5.0, Ranged = true },
    ["Twisted Ginger"] = { KillRadius = 3.33 },
    ["Twisted Glisten"] = { KillRadius = 3.3 },
    ["Twisted Goob"] = { KillRadius = 3.5 },
    ["Twisted Gourdy"] = { KillRadius = 4.0 },
    ["Twisted Looey"] = { KillRadius = 3.33 },
    ["Twisted Pebble"] = { KillRadius = 6.5 },
    ["Twisted Poppy"] = { KillRadius = 3.333 },
    ["Twisted Razzle & Dazzle"] = { KillRadius = 40.0 },
    ["Twisted Ribecca"] = { KillRadius = 3.33 },
    ["Twisted Rodger"] = { KillRadius = 30.0 },
    ["Twisted Rudie"] = { KillRadius = 3.33 },
    ["Twisted Scraps"] = { KillRadius = 3.5 },
    ["Twisted Shelly"] = { KillRadius = 4.0 },
    ["Twisted Shrimpo"] = { KillRadius = 3.33 },
    ["Twisted Soulvester"] = { KillRadius = 3.33 },
    ["Twisted Sprout"] = { KillRadius = 4.0 },
    ["Twisted Teagan"] = { KillRadius = 3.333 },
    ["Twisted Tisha"] = { KillRadius = 3.33 },
    ["Twisted Toodles"] = { KillRadius = 3.33 },
    ["Twisted Vee"] = { KillRadius = 4.0 },
    ["Twisted Waxwell"] = { KillRadius = 3.3 },
}

CFG.RadiusValues = type(CFG.RadiusValues) == "table" and CFG.RadiusValues or {}
for twistedName, settings in pairs(TWISTED_SETTINGS) do
    local saved = tonumber(CFG.RadiusValues[twistedName])
    CFG.RadiusValues[twistedName] = math.clamp(saved or settings.KillRadius, 0.5, 60)
end

local function log(...)
    if CFG.Debug then
        print("[SoulAuto]", ...)
    end
end

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function round(value, places)
    local factor = 10 ^ (places or 1)
    return math.floor(value * factor + 0.5) / factor
end

local function toCharacter(value)
    if typeof(value) == "Instance" then
        if value:IsA("Player") then
            return value.Character
        elseif value:IsA("Model") then
            return value
        elseif value:IsA("BasePart") then
            return value:FindFirstAncestorOfClass("Model")
        end
    elseif type(value) == "string" and value ~= "" then
        local player = Players:FindFirstChild(value)
        return player and player.Character or nil
    end
    return nil
end

local function getRoot(model)
    if not model then
        return nil
    end
    return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
end

local function getMonsters()
    local currentRoom = workspace:FindFirstChild("CurrentRoom")
    local roomModel = currentRoom and currentRoom:FindFirstChildOfClass("Model")
    local folder = roomModel and roomModel:FindFirstChild("Monsters")
    return folder and folder:GetChildren() or {}
end

local function isSoulvester(character)
    local config = character and character:FindFirstChild("Config")
    local moduleName = config and config:FindFirstChild("ModuleName")
    return moduleName and moduleName:IsA("StringValue") and moduleName.Value == "Soulvester"
end

local function isInElevator(character)
    local stats = character and character:FindFirstChild("Stats")
    local value = stats and stats:FindFirstChild("InElevator")
    return value and value:IsA("BoolValue") and value.Value == true
end

-- Local guard lockout protects the same player from duplicate casts while the
-- game replicates GuardedBy/cooldown state. Weak keys allow removed characters to be collected.
local protectedUntil = setmetatable({}, { __mode = "k" })

local function matchesSelectedPlayer(character)
    if not character then
        return false
    end

    local selected = CFG.SelectedPlayer or "AUTO"
    if selected == "AUTO" then
        return true
    end

    if character.Name == selected then
        return true
    end

    local player = Players:FindFirstChild(selected)
    return player ~= nil and player.Character == character
end

local function isEligibleTarget(character, myCharacter)
    if not character or character == myCharacter or not character.Parent then
        return false
    end

    local inGame = workspace:FindFirstChild("InGamePlayers")
    if not inGame or character.Parent ~= inGame then
        return false
    end

    -- The RBXL's AbilityController treats a non-empty GuardedBy value as an
    -- active guard and doesn't allow Soulvester to retarget that player.
    local guardValue = character:GetAttribute("GuardedBy")
    if guardValue ~= nil and guardValue ~= false and guardValue ~= "" then
        return false
    end

    local lockUntil = protectedUntil[character]
    if lockUntil then
        if os.clock() < lockUntil then
            return false
        end
        protectedUntil[character] = nil
    end

    if isInElevator(character) then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0 and getRoot(character) ~= nil
end

local function getChasingValue(monster)
    if not monster then
        return nil
    end

    local direct = monster:FindFirstChild("ChasingValue")
    if direct and (direct:IsA("StringValue") or direct:IsA("ObjectValue")) then
        return direct
    end

    for _, child in ipairs(monster:GetDescendants()) do
        if child.Name == "ChasingValue" and (child:IsA("StringValue") or child:IsA("ObjectValue")) then
            return child
        end
    end

    return nil
end

local function resolveChasingValue(valueObject)
    if not valueObject or not valueObject.Parent then
        return nil
    end
    return toCharacter(valueObject.Value)
end

local function resolveTwistedName(monster)
    if not monster then
        return nil
    end

    local function findName(rawName)
        if type(rawName) ~= "string" then
            return nil
        end
        if TWISTED_SETTINGS[rawName] then
            return rawName
        end
        local shortName = rawName:gsub("^Twisted%s+", ""):gsub("Monster$", "")
        local candidate = "Twisted " .. shortName
        if TWISTED_SETTINGS[candidate] then
            return candidate
        end
        return nil
    end

    local found = findName(monster.Name)
    if found then
        return found
    end

    local config = monster:FindFirstChild("Config")
    local moduleName = config and config:FindFirstChild("ModuleName")
    if moduleName and moduleName:IsA("StringValue") then
        found = findName(moduleName.Value)
        if found then
            return found
        end
    end

    return nil
end

local function getTwistedInfo(monster)
    local twistedName = resolveTwistedName(monster)
    local data = twistedName and TWISTED_SETTINGS[twistedName] or nil

    local function readNumber(key)
        local attribute = monster:GetAttribute(key)
        if type(attribute) == "number" then
            return attribute
        end

        local folders = {
            monster:FindFirstChild("Config"),
            monster:FindFirstChild("Stats"),
            monster:FindFirstChild("Settings"),
            monster,
        }

        for _, folder in ipairs(folders) do
            local object = folder and folder:FindFirstChild(key, true)
            if object and (object:IsA("NumberValue") or object:IsA("IntValue")) then
                return object.Value
            end
        end

        return nil
    end

    local liveRadius = readNumber("KillRadius")
    local configuredRadius = twistedName and tonumber(CFG.RadiusValues[twistedName]) or nil
    local killRadius = configuredRadius or liveRadius or (data and data.KillRadius) or 3.5
    local lethalAttribute = monster:GetAttribute("Lethal") == true

    return {
        Name = twistedName or monster.Name,
        KillRadius = math.clamp(killRadius, 0.5, 60),
        Lethal = (data and data.Lethal == true) or lethalAttribute,
        Ranged = data and data.Ranged == true or false,
    }
end

local chasingTargets = {}
local chaseValueRefs = {}
local chaseValueConnections = {}
local monsterConnections = {}
local trackedMonsters = {}
local motionHistory = {}
local lastDebugTime = {}
local lastRefresh = 0
local lastCast = 0
local lastGateLog = 0
local lastGateState = ""

local function clearMotion(monster)
    motionHistory[monster] = nil
end

local function disconnectMonster(monster)
    local connections = monsterConnections[monster]
    if connections then
        for _, connection in pairs(connections) do
            disconnect(connection)
        end
    end

    disconnect(chaseValueConnections[monster])
    monsterConnections[monster] = nil
    chaseValueConnections[monster] = nil
    chaseValueRefs[monster] = nil
    chasingTargets[monster] = nil
    trackedMonsters[monster] = nil
    motionHistory[monster] = nil
    lastDebugTime[monster] = nil
end

local function setChasingValue(monster, valueObject)
    if chaseValueRefs[monster] == valueObject then
        chasingTargets[monster] = resolveChasingValue(valueObject)
        return
    end

    disconnect(chaseValueConnections[monster])
    chaseValueConnections[monster] = nil
    chaseValueRefs[monster] = valueObject
    chasingTargets[monster] = resolveChasingValue(valueObject)
    clearMotion(monster)

    if valueObject then
        chaseValueConnections[monster] = valueObject:GetPropertyChangedSignal("Value"):Connect(function()
            chasingTargets[monster] = resolveChasingValue(valueObject)
            clearMotion(monster)
        end)
    end
end

local function trackMonster(monster)
    if not monster or not monster.Parent then
        return
    end

    trackedMonsters[monster] = true
    setChasingValue(monster, getChasingValue(monster))

    if monsterConnections[monster] then
        return
    end

    monsterConnections[monster] = {
        added = monster.DescendantAdded:Connect(function(descendant)
            if descendant.Name == "ChasingValue" then
                task.defer(function()
                    if monster.Parent then
                        setChasingValue(monster, getChasingValue(monster))
                    end
                end)
            end
        end),
        removing = monster.DescendantRemoving:Connect(function(descendant)
            if descendant == chaseValueRefs[monster] or descendant.Name == "ChasingValue" then
                task.defer(function()
                    if monster.Parent then
                        setChasingValue(monster, getChasingValue(monster))
                    end
                end)
            end
        end),
    }
end

local function refreshMonsterTracking()
    local now = os.clock()
    if now - lastRefresh < CFG.TrackingRefresh then
        return
    end
    lastRefresh = now

    local found = {}
    for _, monster in ipairs(getMonsters()) do
        found[monster] = true
        trackMonster(monster)
    end

    for monster in pairs(trackedMonsters) do
        if not found[monster] or not monster.Parent then
            disconnectMonster(monster)
        end
    end
end

local function isAttackCueActive(monster)
    -- Only used as a cue at close range; it can never trigger from far away.
    for _, name in ipairs({ "IsAttacking", "Attacking", "AttackActive", "IsAttackActive" }) do
        if monster:GetAttribute(name) == true then
            return true
        end

        local value = monster:FindFirstChild(name, true)
        if value and value:IsA("BoolValue") and value.Value then
            return true
        end
    end

    local humanoid = monster:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return false
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local name = string.lower(tostring(track.Name or ""))
        local animation = track.Animation
        local animationName = animation and string.lower(animation.Name or "") or ""
        local combined = name .. " " .. animationName

        if combined:find("attack", 1, true) or combined:find("attacking", 1, true) or combined:find("hit", 1, true) then
            return true
        end
    end

    return false
end

local function getApproachEstimate(monster, target, distance, monsterRoot, targetRoot)
    -- Use live velocities immediately. Position-history estimates compensate for
    -- stale/jittery replicated velocities, especially when a player sprints or turns.
    local now = os.clock()
    local state = motionHistory[monster]
    local relativePosition = targetRoot.Position - monsterRoot.Position
    local liveRelativeVelocity = targetRoot.AssemblyLinearVelocity - monsterRoot.AssemblyLinearVelocity

    if not state or state.target ~= target then
        state = { target = target, samples = {}, lastSampleTime = 0 }
        motionHistory[monster] = state
    end

    if now - state.lastSampleTime >= CFG.SampleMinInterval then
        table.insert(state.samples, {
            time = now,
            distance = distance,
            relativePosition = relativePosition,
        })
        state.lastSampleTime = now
    end

    local samples = state.samples
    while #samples > 2 and samples[2].time < now - CFG.HistoryWindow do
        table.remove(samples, 1)
    end

    local longClosing = nil
    local recentClosing = nil
    local observedRelativeVelocity = nil

    if #samples >= 2 then
        local oldest = samples[1]
        local recent = samples[math.max(1, #samples - 2)]
        local longDt = now - oldest.time
        local shortDt = now - recent.time

        if longDt >= CFG.MinHistoryTime then
            longClosing = (oldest.distance - distance) / longDt
            observedRelativeVelocity = (relativePosition - oldest.relativePosition) / longDt
        end
        if shortDt >= 0.035 then
            recentClosing = (recent.distance - distance) / shortDt
        end
    end

    -- Blend current physics velocity with observed displacement. The live velocity
    -- reacts quickly to direction changes; position history reduces replication noise.
    local relativeVelocity = liveRelativeVelocity
    if observedRelativeVelocity and observedRelativeVelocity.Magnitude <= CFG.MaxClosingSpeed * 1.5 then
        relativeVelocity = liveRelativeVelocity * 0.60 + observedRelativeVelocity * 0.40
    end

    local velocityClosing = 0
    if relativePosition.Magnitude > 0.001 then
        velocityClosing = -relativeVelocity:Dot(relativePosition.Unit)
    end
    velocityClosing = math.clamp(velocityClosing, -CFG.MaxClosingSpeed, CFG.MaxClosingSpeed)

    local historyConfirmsApproach =
        longClosing ~= nil and recentClosing ~= nil
        and longClosing >= CFG.MinTrendSpeed
        and recentClosing >= CFG.MinRecentSpeed

    local closing = math.max(velocityClosing, 0)
    if historyConfirmsApproach then
        closing = closing * 0.60 + math.max(recentClosing, 0) * 0.40
    elseif closing <= 0 and recentClosing and recentClosing >= CFG.MinRecentSpeed then
        -- Use only as a fallback for stale velocity readings; future trajectory still
        -- uses the blended relative vector, so tangential/moving-away targets are filtered.
        closing = math.max(recentClosing, 0) * 0.70
    end

    closing = math.clamp(closing, 0, CFG.MaxClosingSpeed)
    local approaching = velocityClosing >= CFG.MinTrendSpeed or historyConfirmsApproach

    return closing, approaching, longClosing, recentClosing, relativePosition, relativeVelocity, velocityClosing
end

local function timeToEnterRadius(relativePosition, relativeVelocity, radius)
    -- Solve |relativePosition + relativeVelocity * t| = radius.
    -- This accounts for a player sprinting across/away from a Twisted instead of
    -- assuming every target and monster travel directly toward each other.
    local c = relativePosition:Dot(relativePosition) - radius * radius
    if c <= 0 then
        return 0
    end

    local a = relativeVelocity:Dot(relativeVelocity)
    if a < 0.04 then
        return nil
    end

    local b = 2 * relativePosition:Dot(relativeVelocity)
    if b >= 0 then
        return nil -- relative distance is not currently decreasing in this trajectory
    end

    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return nil -- predicted paths do not intersect the danger radius
    end

    local t = (-b - math.sqrt(discriminant)) / (2 * a)
    if t < 0 then
        return nil
    end

    return t
end

local function getClosestApproachDistance(relativePosition, relativeVelocity, horizon)
    local speedSquared = relativeVelocity:Dot(relativeVelocity)
    if speedSquared < 0.04 then
        return relativePosition.Magnitude, 0
    end

    local closestTime = -relativePosition:Dot(relativeVelocity) / speedSquared
    closestTime = math.clamp(closestTime, 0, horizon)
    local closestPosition = relativePosition + relativeVelocity * closestTime
    return closestPosition.Magnitude, closestTime
end

local function evaluateThreat(monster, target)
    local monsterRoot = getRoot(monster)
    local targetRoot = getRoot(target)
    if not monsterRoot or not targetRoot then
        return nil
    end

    local distance = (monsterRoot.Position - targetRoot.Position).Magnitude
    if distance > CFG.MaxTrackDistance then
        return nil
    end

    local settings = getTwistedInfo(monster)
    local killRadius = settings.KillRadius
    -- Use the currently configured per-Twisted radius for SoulAuto's local
    -- trigger calculations. This does not modify the server-side game hitbox.
    local triggerRadius = math.max(0.5, killRadius)
    local emergencyMargin = settings.Lethal and CFG.LethalEmergencyMargin or CFG.EmergencyMargin
    local emergencyRadius = triggerRadius + emergencyMargin
    local emergency = distance <= emergencyRadius

    local attackCue = false
    if distance <= triggerRadius + CFG.AttackCueMargin then
        attackCue = isAttackCueActive(monster)
    end

    local closingSpeed, approaching, longClosing, recentClosing, relativePosition, relativeVelocity, velocityClosing =
        getApproachEstimate(monster, target, distance, monsterRoot, targetRoot)

    local contactRadius = triggerRadius + CFG.ContactBuffer
    local trajectoryETA = timeToEnterRadius(relativePosition, relativeVelocity, contactRadius)
    local closestDistance, closestTime = getClosestApproachDistance(
        relativePosition,
        relativeVelocity,
        CFG.PredictionHorizon
    )
    local trendETA = nil

    -- Secondary predictor compensates for stale velocity readings, but only when
    -- the projected path passes close to the danger radius. This filters out most
    -- sideways runs and players moving away while still helping with sudden turns.
    local pathLooksThreatening =
        trajectoryETA ~= nil
        or closestDistance <= contactRadius + CFG.PredictionTolerance

    if pathLooksThreatening and approaching and closingSpeed >= CFG.MinTrendSpeed then
        local gap = math.max(distance - contactRadius, 0)
        trendETA = gap / closingSpeed
    end

    local eta = math.huge
    if trajectoryETA and trajectoryETA <= CFG.PredictionHorizon then
        eta = trajectoryETA
    end
    if trendETA and trendETA <= CFG.PredictionHorizon then
        -- Use the earlier forecast to protect against replicated velocity lag,
        -- but only within a short horizon and only with approach evidence.
        eta = math.min(eta, trendETA)
    end

    local shouldTrigger = false
    local reason = "not-imminent"

    if emergency then
        shouldTrigger = true
        eta = 0
        reason = "inside-emergency-radius"
    elseif attackCue then
        shouldTrigger = true
        eta = 0.01
        reason = "attack-cue-nearby"
    elseif eta <= CFG.TriggerLead then
        shouldTrigger = true
        reason = trajectoryETA and trajectoryETA <= CFG.TriggerLead
            and "predicted-trajectory-contact" or "predicted-closing-trend"
    end

    local now = os.clock()
    if CFG.Debug and CFG.DebugWatch and now - (lastDebugTime[monster] or 0) >= CFG.DebugEvery then
        lastDebugTime[monster] = now
        log(
            "WATCH", monster.Name, "->", target.Name,
            "dist", round(distance, 2),
            "radius", round(killRadius, 2),
            "triggerRadius", round(triggerRadius, 2),
            "emergencyRadius", round(emergencyRadius, 2),
            "contactRadius", round(contactRadius, 2),
            "closing", round(closingSpeed, 2),
            "velocityClosing", round(velocityClosing, 2),
            "trendETA", trendETA and round(trendETA, 3) or "--",
            "trajectoryETA", trajectoryETA and round(trajectoryETA, 3) or "--",
            "closest", round(closestDistance, 2),
            "closestIn", round(closestTime, 3),
            "chosenETA", eta == math.huge and "--" or round(eta, 3),
            "approaching", approaching,
            "cue", attackCue,
            "emergency", emergency
        )
    end

    if not shouldTrigger then
        return nil
    end

    return {
        Monster = monster,
        Target = target,
        Distance = distance,
        KillRadius = killRadius,
        TriggerRadius = triggerRadius,
        ClosingSpeed = closingSpeed,
        ETA = eta,
        Reason = reason,
        Settings = settings,
    }
end

local function findMostDangerousTarget(myCharacter)
    local best = nil
    local monsters = getMonsters()

    for _, monster in ipairs(monsters) do
        if monster and monster.Parent then
            -- Track changes for fast updates, but read ChasingValue fresh every scan too.
            trackMonster(monster)
            local liveValue = getChasingValue(monster)
            if liveValue ~= chaseValueRefs[monster] then
                setChasingValue(monster, liveValue)
            end

            local target = resolveChasingValue(liveValue)
            chasingTargets[monster] = target

            if target and matchesSelectedPlayer(target) and isEligibleTarget(target, myCharacter) then
                local threat = evaluateThreat(monster, target)
                if threat then
                    if not best
                        or threat.ETA < best.ETA
                        or (threat.ETA == best.ETA and (threat.Distance - threat.TriggerRadius) < (best.Distance - best.TriggerRadius)) then
                        best = threat
                    end
                end
            elseif CFG.Debug and CFG.DebugWatch then
                local now = os.clock()
                if now - (lastDebugTime[monster] or 0) >= CFG.DebugEvery then
                    lastDebugTime[monster] = now
                    if liveValue then
                        log("WATCH", monster.Name, "ChasingValue=", tostring(liveValue.Value), "resolved=", target and target.Name or "nil", "eligible=", target and isEligibleTarget(target, myCharacter) or false)
                    else
                        log("WATCH", monster.Name, "has no ChasingValue")
                    end
                end
            end
        end
    end

    return best
end

-- Heart tracking reads Humanoid.Health for real heart loss and the replicated
-- ShieldHearts attribute for Soul Shield's metallic/guard heart being consumed.
local heartTracking = setmetatable({}, { __mode = "k" })
local pendingHeartLoss = setmetatable({}, { __mode = "k" })
local lastHeartEvent = setmetatable({}, { __mode = "k" })
local lastHeartRefresh = 0

local function readShieldHearts(character)
    local value = character and character:GetAttribute("ShieldHearts")
    if type(value) == "number" then
        return value
    end
    local asNumber = tonumber(value)
    if asNumber then
        return asNumber
    end
    return value == true and 1 or 0
end

local function queueHeartLoss(character, reason, oldValue, newValue)
    -- This mode specifically watches the game's ShieldHearts count (the metal
    -- heart shown by the HUD), not ordinary Humanoid health loss.
    if not RUNNING or CFG.Mode ~= "HEART_LOSS" or not character or character == LocalPlayer.Character then
        return
    end
    if not matchesSelectedPlayer(character) then
        return
    end

    local now = os.clock()
    local prior = lastHeartEvent[character] or 0
    if now - prior < CFG.HeartEventDebounce then
        return
    end
    lastHeartEvent[character] = now

    pendingHeartLoss[character] = {
        time = now,
        reason = reason,
        oldValue = oldValue,
        newValue = newValue,
    }

    -- The metal heart was consumed, so a previous fallback lockout must not
    -- block a new guard request once GuardedBy clears and cooldown is ready.
    protectedUntil[character] = nil
    log("METAL HEART EVENT", character.Name, reason, tostring(oldValue), "->", tostring(newValue))
end

local function untrackHeartCharacter(character)
    local state = heartTracking[character]
    if state then
        disconnect(state.healthConnection)
        disconnect(state.shieldConnection)
        disconnect(state.guardConnection)
    end
    heartTracking[character] = nil
    lastHeartEvent[character] = nil
end

local function trackHeartCharacter(character)
    if not character or not character.Parent then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local oldState = heartTracking[character]
    if oldState and oldState.humanoid == humanoid then
        return
    end
    if oldState then
        untrackHeartCharacter(character)
    end

    local initialGuardValue = character:GetAttribute("GuardedBy")
    local state = {
        humanoid = humanoid,
        health = humanoid.Health,
        shieldHearts = readShieldHearts(character),
        guardValue = initialGuardValue,
        guardWasOurs = initialGuardValue == LocalPlayer.Name,
        guardBeganAt = initialGuardValue == LocalPlayer.Name and os.clock() or nil,
        guardEndedAt = nil,
    }
    heartTracking[character] = state

    -- Ordinary health loss is deliberately not this mode's trigger. The
    -- requested second mode is specifically keyed to ShieldHearts decreasing.
    state.healthConnection = humanoid.HealthChanged:Connect(function(newHealth)
        local previousHealth = state.health
        state.health = newHealth
        if newHealth < previousHealth - 0.01 then
            log("HEALTH CHANGE", character.Name, tostring(previousHealth), "->", tostring(newHealth),
                "(not the metal-heart trigger)")
        end
    end)

    state.shieldConnection = character:GetAttributeChangedSignal("ShieldHearts"):Connect(function()
        local newShieldHearts = readShieldHearts(character)
        local previousShieldHearts = state.shieldHearts
        state.shieldHearts = newShieldHearts
        if newShieldHearts < previousShieldHearts then
            -- A shield/metal heart being consumed ends any fallback lockout.
            -- GuardedBy still prevents recasting while an active guard remains.
            if protectedUntil[character] then
                protectedUntil[character] = nil
            end
            log("SHIELD HEART LOST", character.Name, tostring(previousShieldHearts), "->", tostring(newShieldHearts))
            queueHeartLoss(character, "metal-heart-consumed", previousShieldHearts, newShieldHearts)
        end
    end)

    -- GuardedBy is a real attribute observed by the game's guard UI. When our
    -- guard is released/consumed, clear the fallback lockout so the next real
    -- threat can be protected; while the attribute remains set, eligibility
    -- checks continue to prevent duplicate casts.
    state.guardConnection = character:GetAttributeChangedSignal("GuardedBy"):Connect(function()
        local newValue = character:GetAttribute("GuardedBy")
        local now = os.clock()
        if newValue == LocalPlayer.Name then
            state.guardWasOurs = true
            state.guardBeganAt = now
            log("GUARD ACTIVE", character.Name, "GuardedBy=local player")
        elseif state.guardWasOurs then
            state.guardWasOurs = false
            state.guardEndedAt = now
            protectedUntil[character] = nil
            log("GUARD RELEASED", character.Name, "fallback lockout cleared")
        end
        state.guardValue = newValue
    end)
end

local function refreshHeartTracking()
    local now = os.clock()
    if now - lastHeartRefresh < 0.15 then
        return
    end
    lastHeartRefresh = now

    local inGame = workspace:FindFirstChild("InGamePlayers")
    local found = {}
    if inGame then
        for _, character in ipairs(inGame:GetChildren()) do
            if character:IsA("Model") then
                found[character] = true
                trackHeartCharacter(character)
            end
        end
    end

    for character in pairs(heartTracking) do
        if not found[character] or not character.Parent then
            untrackHeartCharacter(character)
            pendingHeartLoss[character] = nil
        end
    end

    for character, event in pairs(pendingHeartLoss) do
        if not character.Parent or now - event.time > CFG.HeartLossQueueWindow then
            pendingHeartLoss[character] = nil
            if character.Parent then
                log("HEART EVENT EXPIRED", character.Name, event.reason)
            end
        elseif not matchesSelectedPlayer(character) then
            pendingHeartLoss[character] = nil
        end
    end
end

local function findHeartLossTarget(myCharacter)
    local chosenCharacter = nil
    local chosenEvent = nil

    -- Process the oldest valid event first so a queued hit isn't starved by
    -- later heart changes from other players.
    for character, event in pairs(pendingHeartLoss) do
        if not chosenEvent or event.time < chosenEvent.time then
            if matchesSelectedPlayer(character) and isEligibleTarget(character, myCharacter) then
                chosenCharacter = character
                chosenEvent = event
            end
        end
    end

    if not chosenCharacter or not chosenEvent then
        return nil
    end

    return {
        Monster = nil,
        Target = chosenCharacter,
        Distance = 0,
        KillRadius = 0,
        TriggerRadius = 0,
        ClosingSpeed = 0,
        ETA = 0,
        Reason = "metal-heart-loss:" .. chosenEvent.reason,
        HeartLoss = true,
    }
end

local function getAbilityCooldown(character)
    local abilities = character and character:FindFirstChild("Abilities")
    local ability = abilities and abilities:FindFirstChild("Ability1")
    local cooldown = ability and ability:FindFirstChild("CurrentCooldown")

    if not cooldown then
        return nil, "Ability1.CurrentCooldown missing"
    end

    local value = tonumber(cooldown.Value)
    if value == nil then
        return nil, "cooldown is not numeric: " .. tostring(cooldown.Value)
    end

    return value, nil
end

local function isAbilityReady(character)
    local cooldown, reason = getAbilityCooldown(character)
    if cooldown == nil then
        return false, reason
    end
    return cooldown <= 0, cooldown
end

local castPending = false

local function castSoulvester(character, threat)
    local now = os.clock()
    if castPending or now - lastCast < CFG.RecastDelay then
        return
    end

    local primary = getRoot(character)
    local target = threat.Target
    local monster = threat.Monster
    local heartLossCast = threat.HeartLoss == true

    if not primary or not target or not target.Parent then
        log("Skip cast: missing Soulvester root or target")
        return
    end
    if not heartLossCast and (not monster or not monster.Parent) then
        log("Skip cast: missing Twisted")
        return
    end
    if not matchesSelectedPlayer(target) then
        log("Skip cast: selected player changed", target.Name)
        return
    end

    if not heartLossCast then
        local liveValue = getChasingValue(monster)
        if resolveChasingValue(liveValue) ~= target then
            log("Skip cast: ChasingValue changed before cast", monster.Name)
            clearMotion(monster)
            return
        end
    end

    local ready, cooldownOrReason = isAbilityReady(character)
    if not ready then
        log("Skip cast: ability not ready;", tostring(cooldownOrReason))
        return
    end

    local events = ReplicatedStorage:FindFirstChild("Events")
    local abilityEvent = events and events:FindFirstChild("AbilityEvent")
    if not abilityEvent then
        log("CAST FAILED: ReplicatedStorage.Events.AbilityEvent not found")
        return
    end

    castPending = true
    lastCast = now
    if heartLossCast then
        pendingHeartLoss[target] = nil
    end

    log(
        "CAST ATTEMPT",
        "mode", heartLossCast and "HEART_LOSS" or "PREDICTIVE",
        "target", target.Name,
        "twisted", monster and monster.Name or "heart-event",
        "distance", round(threat.Distance, 2),
        "killRadius", round(threat.KillRadius, 2),
        "triggerRadius", round(threat.TriggerRadius, 2),
        "closing", round(threat.ClosingSpeed, 2),
        "ETA", round(threat.ETA, 3),
        "reason", threat.Reason
    )

    task.spawn(function()
        local currentRoot = getRoot(character)
        local inGame = workspace:FindFirstChild("InGamePlayers")
        local targetStillValid = target.Parent and inGame and target.Parent == inGame
        local targetStillSelected = matchesSelectedPlayer(target)
        local targetAlreadyGuarded = target:GetAttribute("GuardedBy") ~= nil
            and target:GetAttribute("GuardedBy") ~= false
            and target:GetAttribute("GuardedBy") ~= ""
        local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
        local targetAlive = targetHumanoid ~= nil and targetHumanoid.Health > 0
        local modeStillValid = not heartLossCast or CFG.Mode == "HEART_LOSS"

        local monsterStillValid = true
        if not heartLossCast then
            local currentValue = getChasingValue(monster)
            monsterStillValid = monster.Parent and resolveChasingValue(currentValue) == target
        end

        if not RUNNING or not character.Parent or not targetStillValid or not targetAlive
            or not currentRoot or not targetStillSelected or targetAlreadyGuarded
            or not modeStillValid or not monsterStillValid or isInElevator(target) then
            log("Cast cancelled: target/state changed before invoke")
            lastCast = os.clock() - CFG.RecastDelay
            if heartLossCast and target.Parent and matchesSelectedPlayer(target) then
                pendingHeartLoss[target] = {
                    time = os.clock(),
                    reason = threat.Reason,
                }
            end
            castPending = false
            return
        end

        local castStartedAt = os.clock()
        local shieldBefore = readShieldHearts(target)
        local ok, result = pcall(function()
            return abilityEvent:InvokeServer(character, currentRoot.CFrame, target, nil)
        end)

        if not ok then
            log("Invoke error:", result)
            protectedUntil[target] = os.clock() + CFG.FailedRequestLockout
            lastCast = os.clock() - math.max(CFG.RecastDelay - 0.12, 0)
            if heartLossCast and target.Parent then
                pendingHeartLoss[target] = {
                    time = os.clock(),
                    reason = threat.Reason,
                }
            end
        else
            -- The game's AbilityController treats response[1] == "Used" as the
            -- successful-use result. Prefer that explicit result over waiting for
            -- GuardedBy/ShieldHearts replication, which can lag behind the request.
            local responseTag = type(result) == "table" and result[1] or nil
            task.wait(0.12)
            local shieldAfter = readShieldHearts(target)
            local guardedBy = target:GetAttribute("GuardedBy")
            local state = heartTracking[target]
            local guardObserved = guardedBy == LocalPlayer.Name
                or (state and state.guardBeganAt and state.guardBeganAt >= castStartedAt)
            local guardConsumedDuringCall = state
                and state.guardBeganAt and state.guardBeganAt >= castStartedAt
                and state.guardEndedAt and state.guardEndedAt >= castStartedAt
            if shieldAfter < shieldBefore then
                guardConsumedDuringCall = true
            end

            local accepted = responseTag == "Used"
                or guardObserved
                or (shieldAfter > shieldBefore)
                or guardConsumedDuringCall

            if accepted then
                if guardConsumedDuringCall then
                    -- The guard appears to have been consumed/released during the
                    -- request itself. Keep only a tiny debounce, not a stale long
                    -- lockout, so a fresh threat or queued metal-heart event can act.
                    protectedUntil[target] = os.clock() + 0.15
                else
                    protectedUntil[target] = os.clock() + CFG.TargetProtectionLockout
                end
            else
                protectedUntil[target] = os.clock() + CFG.FailedRequestLockout
                if heartLossCast and target.Parent then
                    pendingHeartLoss[target] = {
                        time = os.clock(),
                        reason = threat.Reason,
                    }
                end
            end

            log(
                "Invoke returned:", responseTag, result and result[2],
                "rawType=", typeof(result),
                "accepted=", accepted,
                "guardObserved=", guardObserved,
                "guardConsumedDuringCall=", guardConsumedDuringCall,
                "shieldHearts=", shieldBefore, "->", shieldAfter,
                "target lockout=", accepted and (guardConsumedDuringCall and 0.15 or CFG.TargetProtectionLockout) or CFG.FailedRequestLockout
            )
        end
        castPending = false
    end)
end

local SoulAutoWindow = nil
local uiConnections = {}
local radiusSliders = {}
local tuningSliders = {}

local function notify(title, content)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = 4,
        })
    end)
    log(title .. ":", content)
end

local function stop()
    RUNNING = false

    local monstersToDisconnect = {}
    for monster in pairs(trackedMonsters) do
        table.insert(monstersToDisconnect, monster)
    end
    for _, monster in ipairs(monstersToDisconnect) do
        disconnectMonster(monster)
    end

    local heartCharacters = {}
    for character in pairs(heartTracking) do
        table.insert(heartCharacters, character)
    end
    for _, character in ipairs(heartCharacters) do
        untrackHeartCharacter(character)
    end

    for _, connection in ipairs(uiConnections) do
        disconnect(connection)
    end
    table.clear(uiConnections)
    table.clear(motionHistory)
    table.clear(lastDebugTime)
    table.clear(pendingHeartLoss)

    if SoulAutoWindow then
        pcall(function()
            SoulAutoWindow:Destroy()
        end)
        SoulAutoWindow = nil
    end

    log("Stopped")
end

CFG.Stop = stop

local function setMode(mode)
    if mode ~= "PREDICTIVE" and mode ~= "HEART_LOSS" then
        return
    end
    CFG.Mode = mode
    if mode ~= "HEART_LOSS" then
        table.clear(pendingHeartLoss)
    end
    log("Mode set to", mode)
end

local function setSelectedPlayer(name)
    CFG.SelectedPlayer = name or "AUTO"
    if CFG.SelectedPlayer == "AUTO" then
        log("Target selection: AUTO / most endangered")
    else
        log("Target selection:", CFG.SelectedPlayer)
    end
end

local function applyDangerProfile(mode)
    local profile = PROFILES[mode]
    if not profile then
        return
    end
    CFG.DangerMode = mode
    for key, value in pairs(profile) do
        CFG[key] = value
        local slider = tuningSliders[key]
        if slider then
            pcall(function()
                slider:Set(value)
            end)
        end
    end
    log("Danger profile applied:", mode)
end

local function sortedTwistedNames()
    local names = {}
    for name in pairs(TWISTED_SETTINGS) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b)
        return a:lower() < b:lower()
    end)
    return names
end

local function getPlayerOptions()
    local options = { "AUTO" }
    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
    for _, player in ipairs(players) do
        if player ~= LocalPlayer then
            table.insert(options, player.Name)
        end
    end
    return options
end

local function setRadius(name, value)
    local number = tonumber(value)
    if not number or number ~= number then
        return
    end
    CFG.RadiusValues[name] = math.clamp(number, 0.5, 60)
end

local function refreshRadiusSliders()
    for name, slider in pairs(radiusSliders) do
        local value = CFG.RadiusValues[name] or TWISTED_SETTINGS[name].KillRadius
        pcall(function()
            slider:Set(value)
        end)
    end
end

local function applyGlobalDecrease(rawAmount)
    local amount = tonumber(rawAmount)
    if not amount or amount ~= amount or amount < 0 or amount > 60 then
        notify("Invalid decrease", "Enter a number from 0 to 60 studs.")
        return
    end

    for name, settings in pairs(TWISTED_SETTINGS) do
        local current = tonumber(CFG.RadiusValues[name]) or settings.KillRadius
        CFG.RadiusValues[name] = math.clamp(round(current - amount, 3), 0.5, 60)
    end

    refreshRadiusSliders()
    notify("Applied to all Twisteds", "Subtracted " .. tostring(amount) .. " studs from every SoulAuto radius. Minimum radius is 0.5 studs.")
end

local function resetAllRadii()
    for name, settings in pairs(TWISTED_SETTINGS) do
        CFG.RadiusValues[name] = settings.KillRadius
    end
    refreshRadiusSliders()
    notify("Radii reset", "All listed radii restored to their decompiled defaults.")
end

local function createSoulAutoWindUI()
    pcall(function()
        WindUI:AddTheme({
            Name = "Lunar",
            Accent = Color3.fromRGB(57, 46, 122),
            Background = Color3.fromRGB(12, 13, 24),
            Outline = Color3.fromRGB(81, 70, 145),
            Text = Color3.fromRGB(244, 243, 255),
            Placeholder = Color3.fromRGB(155, 153, 181),
            Button = Color3.fromRGB(39, 35, 74),
            Icon = Color3.fromRGB(174, 164, 255),
            Hover = Color3.fromRGB(63, 52, 111),
        })
    end)

    SoulAutoWindow = WindUI:CreateWindow({
        Title = "SoulAuto | Soul Shield",
        Icon = "solar:compass-big-bold",
        Author = "TZ HUB",
        Folder = "TZHub_SoulAuto",
        Theme = "Lunar",
        Size = UDim2.fromOffset(720, 560),
        MinSize = Vector2.new(520, 400),
        MaxSize = Vector2.new(960, 760),
        ToggleKey = Enum.KeyCode.RightControl,
        Resizable = true,
        HideSearchBar = false,
        ScrollBarEnabled = true,
        AutoScale = true,
    })

    pcall(function()
        SoulAutoWindow:EditOpenButton({
            Title = "SoulAuto",
            Icon = "solar:compass-big-bold",
            OnlyMobile = true,
            Enabled = true,
            Draggable = true,
        })
    end)

    local MainTab = SoulAutoWindow:Tab({ Title = "Main", Icon = "solar:shield-user-bold" })
    local TargetTab = SoulAutoWindow:Tab({ Title = "Targeting", Icon = "users" })
    local RadiusTab = SoulAutoWindow:Tab({ Title = "Twisted Radii", Icon = "crosshair" })
    local SettingsTab = SoulAutoWindow:Tab({ Title = "Settings", Icon = "sliders-horizontal" })
    local InfoTab = SoulAutoWindow:Tab({ Title = "Info", Icon = "circle-help" })

    MainTab:Paragraph({
        Title = "SoulAuto protection",
        Desc = "Client-side automation for Soulvester. Radii in this UI are used by SoulAuto's trigger predictor; they do not alter the game's server hitboxes.",
    })

    MainTab:Toggle({
        Title = "Enable SoulAuto",
        Desc = "Toggle automation without re-executing the script.",
        Value = CFG.Enabled,
        Flag = "soulauto_enabled",
        Callback = function(state)
            CFG.Enabled = state == true
            notify("Automation", CFG.Enabled and "Enabled" or "Disabled")
        end,
    })

    MainTab:Dropdown({
        Title = "Protection Mode",
        Desc = "Predictive mode attempts protection before contact. Heart-loss mode reacts after a ShieldHearts decrease.",
        Values = { "Predict before hit", "After metal-heart loss" },
        Value = CFG.Mode == "HEART_LOSS" and "After metal-heart loss" or "Predict before hit",
        Flag = "soulauto_mode",
        Callback = function(value)
            if value == "After metal-heart loss" then
                setMode("HEART_LOSS")
            else
                setMode("PREDICTIVE")
            end
        end,
    })

    MainTab:Dropdown({
        Title = "Danger Profile",
        Desc = "Presets for prediction timing. More aggressive profiles can cast earlier.",
        Values = { "VERY_CLOSE", "CLOSE", "EARLY" },
        Value = CFG.DangerMode,
        Flag = "soulauto_danger_profile",
        Callback = function(value)
            applyDangerProfile(value)
        end,
    })

    MainTab:Button({
        Title = "Stop and close SoulAuto",
        Desc = "Disconnect tracking, stop automation, and destroy this WindUI window.",
        Icon = "power",
        Callback = function()
            stop()
        end,
    })

    TargetTab:Paragraph({
        Title = "Choose who to protect",
        Desc = "AUTO selects the most endangered eligible teammate. A username restricts protection to that player.",
    })

    local targetDropdown = TargetTab:Dropdown({
        Title = "Target Player",
        Desc = "Select AUTO or a player username.",
        Values = getPlayerOptions(),
        Value = table.find(getPlayerOptions(), CFG.SelectedPlayer) and CFG.SelectedPlayer or "AUTO",
        SearchBarEnabled = true,
        AllowNone = false,
        Flag = "soulauto_target",
        Callback = function(value)
            setSelectedPlayer(value)
        end,
    })

    local function refreshPlayers()
        local values = getPlayerOptions()
        pcall(function()
            targetDropdown:Refresh(values)
        end)
        local current = CFG.SelectedPlayer or "AUTO"
        if not table.find(values, current) then
            setSelectedPlayer("AUTO")
            current = "AUTO"
        end
        pcall(function()
            targetDropdown:Select(current)
        end)
        notify("Player list refreshed", tostring(#values - 1) .. " other player(s) available.")
    end

    TargetTab:Button({
        Title = "Refresh Player List",
        Icon = "refresh-cw",
        Callback = refreshPlayers,
    })

    table.insert(uiConnections, Players.PlayerAdded:Connect(function()
        task.defer(function()
            if RUNNING and targetDropdown then
                pcall(function()
                    targetDropdown:Refresh(getPlayerOptions())
                end)
            end
        end)
    end))
    table.insert(uiConnections, Players.PlayerRemoving:Connect(function(player)
        if CFG.SelectedPlayer == player.Name then
            setSelectedPlayer("AUTO")
        end
        task.defer(function()
            if RUNNING and targetDropdown then
                pcall(function()
                    targetDropdown:Refresh(getPlayerOptions())
                    targetDropdown:Select(CFG.SelectedPlayer or "AUTO")
                end)
            end
        end)
    end))

    RadiusTab:Paragraph({
        Title = "Per-Twisted trigger radii",
        Desc = "Each slider controls the radius SoulAuto uses when predicting danger. This is a local trigger threshold, not a server-side hitbox edit. Listed defaults came from the supplied decompiled modules; Razzle & Dazzle and Rodger set KillRadius from InstantRadius in that source.",
    })

    local decreaseInput = RadiusTab:Input({
        Title = "Decrease every Twisted by",
        Desc = "Enter a non-negative number of studs. Press the button below to subtract it from all listed radii.",
        Value = tostring(CFG.PendingGlobalDecrease or "1.5"),
        Placeholder = "e.g. 1.5",
        Type = "Input",
        InputIcon = "minus-circle",
        Flag = "soulauto_global_decrease",
        Callback = function(value)
            CFG.PendingGlobalDecrease = tostring(value)
        end,
    })

    RadiusTab:Button({
        Title = "Apply Decrease to ALL Twisteds",
        Desc = "Subtract the entered amount from each radius. Values cannot go below 0.5 studs.",
        Icon = "check-check",
        Callback = function()
            local raw = CFG.PendingGlobalDecrease
            if decreaseInput and type(decreaseInput.Get) == "function" then
                local ok, value = pcall(function()
                    return decreaseInput:Get()
                end)
                if ok and value ~= nil then
                    raw = value
                end
            end
            applyGlobalDecrease(raw)
        end,
    })

    RadiusTab:Button({
        Title = "Reset All Radii to Defaults",
        Desc = "Restore every listed Twisted to its source default radius.",
        Icon = "rotate-ccw",
        Callback = resetAllRadii,
    })

    RadiusTab:Divider()

    local twistedNames = sortedTwistedNames()
    for _, twistedName in ipairs(twistedNames) do
        local defaultRadius = CFG.RadiusValues[twistedName] or TWISTED_SETTINGS[twistedName].KillRadius
        radiusSliders[twistedName] = RadiusTab:Slider({
            Title = twistedName .. " — radius",
            Desc = "SoulAuto trigger radius in studs. Source default: " .. tostring(TWISTED_SETTINGS[twistedName].KillRadius),
            Step = 0.01,
            Value = {
                Min = 0.5,
                Max = 60,
                Default = defaultRadius,
            },
            Flag = "soulauto_radius_" .. twistedName:gsub("[^%w]", "_"),
            Callback = function(value)
                setRadius(twistedName, value)
            end,
        })
    end

    SettingsTab:Paragraph({
        Title = "Prediction tuning",
        Desc = "Defaults are intended for VERY_CLOSE. Change these only after observing the WATCH logs. Radius sliders are managed in the Twisted Radii tab.",
    })

    local function addTuneSlider(title, key, minimum, maximum, step, description)
        tuningSliders[key] = SettingsTab:Slider({
            Title = title,
            Desc = description or ("Current value: " .. tostring(CFG[key])),
            Step = step,
            Value = { Min = minimum, Max = maximum, Default = CFG[key] },
            Flag = "soulauto_tune_" .. key,
            Callback = function(value)
                CFG[key] = value
            end,
        })
    end

    addTuneSlider("Max Track Distance", "MaxTrackDistance", 5, 150, 1, "Ignore Twisteds farther away than this distance.")
    addTuneSlider("Trigger Lead", "TriggerLead", 0.02, 1.2, 0.01, "Predicted contact time that triggers an attempt. Larger values act earlier.")
    addTuneSlider("Contact Buffer", "ContactBuffer", 0, 5, 0.05, "Extra distance beyond configured radius for trajectory prediction.")
    addTuneSlider("Emergency Margin", "EmergencyMargin", 0, 10, 0.1, "Immediate trigger margin outside a configured radius.")
    addTuneSlider("Lethal Emergency Margin", "LethalEmergencyMargin", 0, 12, 0.1, "Emergency margin used for lethal Twisteds.")
    addTuneSlider("Attack Cue Margin", "AttackCueMargin", 0, 10, 0.1, "Only inspect attack cues when the Twisted is this close to its configured radius.")
    addTuneSlider("Prediction Horizon", "PredictionHorizon", 0.1, 2, 0.05, "Maximum future window considered by the trajectory predictor.")
    addTuneSlider("Prediction Tolerance", "PredictionTolerance", 0, 10, 0.25, "Allows some tolerance for paths that pass near the contact radius.")
    addTuneSlider("Minimum Trend Speed", "MinTrendSpeed", 0.1, 15, 0.1, "Minimum measured approach speed before using trend-based predictions.")
    addTuneSlider("Minimum Recent Speed", "MinRecentSpeed", 0.05, 15, 0.05, "Minimum recent speed used to confirm approach history.")
    addTuneSlider("Maximum Closing Speed", "MaxClosingSpeed", 5, 100, 1, "Clamp for computed relative approach speed.")
    addTuneSlider("History Window", "HistoryWindow", 0.08, 1, 0.02, "Seconds of recent target/monster positions to retain.")
    addTuneSlider("Minimum History Time", "MinHistoryTime", 0.02, 0.25, 0.01, "Minimum time span required for history estimates.")
    addTuneSlider("Sample Minimum Interval", "SampleMinInterval", 0.01, 0.12, 0.01, "Minimum spacing between history samples.")
    addTuneSlider("Poll Rate", "PollRate", 0.01, 0.12, 0.01, "Seconds between automation scans; lower values cost more client processing.")
    addTuneSlider("Tracking Refresh", "TrackingRefresh", 0.05, 0.6, 0.01, "How often the active Twisted list is refreshed.")
    addTuneSlider("Recast Delay", "RecastDelay", 0.1, 2, 0.05, "Minimum delay between ability requests.")
    addTuneSlider("Target Protection Lockout", "TargetProtectionLockout", 0, 20, 0.25, "Prevents immediate duplicate attempts on the same protected player.")
    addTuneSlider("Failed Request Lockout", "FailedRequestLockout", 0.1, 5, 0.05, "Retry delay after an unaccepted or failed attempt.")
    addTuneSlider("Heart-Loss Queue Window", "HeartLossQueueWindow", 1, 30, 1, "How long a detected shield-heart loss waits for ability readiness.")
    addTuneSlider("Heart Event Debounce", "HeartEventDebounce", 0.05, 1, 0.05, "Suppress duplicate heart-loss events within this interval.")
    addTuneSlider("Minimum Soulvester Health", "MinHealth", 1, 4, 1, "Stop sending new requests if Soulvester health is below this value.")

    SettingsTab:Toggle({
        Title = "Debug Logging",
        Desc = "Print SoulAuto status and cast decisions to the executor Output.",
        Value = CFG.Debug,
        Flag = "soulauto_debug",
        Callback = function(value)
            CFG.Debug = value == true
        end,
    })

    SettingsTab:Toggle({
        Title = "Threat Watch Logs",
        Desc = "Print periodic WATCH diagnostics for active Twisteds.",
        Value = CFG.DebugWatch,
        Flag = "soulauto_debug_watch",
        Callback = function(value)
            CFG.DebugWatch = value == true
        end,
    })

    addTuneSlider("Debug Watch Interval", "DebugEvery", 0.1, 3, 0.05, "Seconds between WATCH logs per Twisted.")

    local configProfile
    pcall(function()
        if SoulAutoWindow.ConfigManager then
            configProfile = SoulAutoWindow.ConfigManager:Config("SoulAuto_Default")
        end
    end)

    SettingsTab:Button({
        Title = "Save UI Configuration",
        Desc = "Save current UI controls and radius sliders to the SoulAuto config profile.",
        Icon = "save",
        Callback = function()
            if not configProfile then
                notify("Config unavailable", "WindUI ConfigManager was not available in this version.")
                return
            end
            local ok, err = pcall(function()
                configProfile:Save()
            end)
            notify(ok and "Configuration saved" or "Save failed", ok and "Saved SoulAuto_Default." or tostring(err))
        end,
    })

    SettingsTab:Button({
        Title = "Load UI Configuration",
        Desc = "Load SoulAuto_Default, applying the saved control values.",
        Icon = "folder-open",
        Callback = function()
            if not configProfile then
                notify("Config unavailable", "WindUI ConfigManager was not available in this version.")
                return
            end
            local ok, err = pcall(function()
                configProfile:Load()
            end)
            if ok then
                refreshRadiusSliders()
                notify("Configuration loaded", "Loaded SoulAuto_Default.")
            else
                notify("Load failed", tostring(err))
            end
        end,
    })

    InfoTab:Paragraph({
        Title = "What these controls change",
        Desc = "Twisted Radii changes SoulAuto's client-side danger thresholds only; it cannot change actual server collision/damage hitboxes. Global decrease is cumulative and clamps every radius at 0.5 studs. Use Reset All Radii to restore module defaults.",
    })
    InfoTab:Paragraph({
        Title = "Protection modes",
        Desc = "Predict before hit uses motion and proximity prediction. After metal-heart loss watches ShieldHearts decrease and attempts protection when eligible. A lost heart cannot be restored by SoulAuto.",
    })
    InfoTab:Button({
        Title = "Print Current Radius Table",
        Desc = "Prints every current effective radius to Output.",
        Icon = "list-check",
        Callback = function()
            for _, name in ipairs(sortedTwistedNames()) do
                log("RADIUS", name, round(CFG.RadiusValues[name] or TWISTED_SETTINGS[name].KillRadius, 3))
            end
        end,
    })

    CFG.SetMode = setMode
    CFG.SetTarget = setSelectedPlayer
    CFG.ApplyGlobalDecrease = applyGlobalDecrease
    CFG.ResetAllRadii = resetAllRadii
    CFG.RefreshPlayers = refreshPlayers
    CFG.Window = SoulAutoWindow
    return SoulAutoWindow
end

createSoulAutoWindUI()

log("RBXL note: the saved Soulvester character module lists Knightly Armor as Passive; an active Ability1 cooldown must exist in the current runtime for guard casts to be accepted.")
log("Started WindUI build. Mode:", CFG.Mode, "DangerMode:", CFG.DangerMode,
    "Target:", CFG.SelectedPlayer, "TargetLockout:", CFG.TargetProtectionLockout,
    "Configured Twisted radii:", #sortedTwistedNames())

task.spawn(function()
    while RUNNING do
        task.wait(CFG.PollRate)
        if not RUNNING then
            break
        end

        refreshMonsterTracking()
        refreshHeartTracking()

        if not CFG.Enabled then
            continue
        end

        local character = LocalPlayer.Character
        local gate = nil

        if not character or not character.Parent then
            gate = "WAIT: character not spawned"
        elseif not isSoulvester(character) then
            gate = "WAIT: current toon is not Soulvester"
        else
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health < CFG.MinHealth then
                gate = "WAIT: Soulvester humanoid missing/low health"
            else
                local info = workspace:FindFirstChild("Info")
                local floorActive = info and info:FindFirstChild("FloorActive")
                if not floorActive or floorActive.Value ~= true then
                    gate = "WAIT: FloorActive is not true"
                else
                    local ready, cooldownOrReason = isAbilityReady(character)
                    if not ready then
                        gate = "WAIT: ability unavailable (" .. tostring(cooldownOrReason) .. ")"
                    else
                        local threat
                        if CFG.Mode == "HEART_LOSS" then
                            threat = findHeartLossTarget(character)
                        else
                            threat = findMostDangerousTarget(character)
                        end

                        if threat then
                            lastGateState = "THREAT"
                            castSoulvester(character, threat)
                        else
                            if CFG.Mode == "HEART_LOSS" then
                                gate = "WATCHING: waiting for selected player's heart or shield-heart to drop"
                            else
                                gate = "WATCHING: no selected target currently meets close-danger conditions"
                            end
                        end
                    end
                end
            end
        end

        if gate then
            local now = os.clock()
            if gate ~= lastGateState or now - lastGateLog >= 0.8 then
                log(gate)
                lastGateLog = now
                lastGateState = gate
            end
        end
    end
end)
