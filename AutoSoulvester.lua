local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer


local previous = getgenv().SoulAuto
if type(previous) == "table" and type(previous.Stop) == "function" then
    pcall(previous.Stop)
end

local CFG = {
    Enabled = true,
    DangerMode = "VERY_CLOSE",

    PollRate = 0.02,
    TrackingRefresh = 0.06,
    MaxTrackDistance = 80,
    
    
    RadiusReduction = 1.5,
    HistoryWindow = 0.22,
    MinHistoryTime = 0.035,
    SampleMinInterval = 0.02,

    
    
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
    ["Twisted Ribecca"] = { KillRadius = 3.33 },
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



local protectedUntil = setmetatable({}, { __mode = "k" })

local function isEligibleTarget(character, myCharacter)
    if not character or character == myCharacter or not character.Parent then
        return false
    end

    local inGame = workspace:FindFirstChild("InGamePlayers")
    if not inGame or character.Parent ~= inGame then
        return false
    end

    if character:GetAttribute("GuardedBy") then
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

local function getTwistedInfo(monster)
    local data = TWISTED_SETTINGS[monster.Name]
    if not data then
        local shortName = monster.Name:gsub("^Twisted%s+", "")
        data = TWISTED_SETTINGS["Twisted " .. shortName]
    end

    local config = monster:FindFirstChild("Config")
    local moduleName = config and config:FindFirstChild("ModuleName")
    if not data and moduleName and moduleName:IsA("StringValue") then
        local value = moduleName.Value:gsub("Monster$", ""):gsub("^Twisted%s+", "")
        data = TWISTED_SETTINGS[value] or TWISTED_SETTINGS["Twisted " .. value]
    end

    data = data or { KillRadius = 3.5 }

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
    local killRadius = liveRadius or data.KillRadius or 3.5
    local lethalAttribute = monster:GetAttribute("Lethal") == true

    return {
        KillRadius = math.clamp(killRadius, 1, 20),
        Lethal = data.Lethal == true or lethalAttribute,
        Ranged = data.Ranged == true,
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
        
        
        closing = math.max(recentClosing, 0) * 0.70
    end

    closing = math.clamp(closing, 0, CFG.MaxClosingSpeed)
    local approaching = velocityClosing >= CFG.MinTrendSpeed or historyConfirmsApproach

    return closing, approaching, longClosing, recentClosing, relativePosition, relativeVelocity, velocityClosing
end

local function timeToEnterRadius(relativePosition, relativeVelocity, radius)
    
    
    
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
        return nil 
    end

    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return nil 
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
    
    
    
    local triggerRadius = math.max(0.5, killRadius - math.max(0, CFG.RadiusReduction or 0))
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
            
            trackMonster(monster)
            local liveValue = getChasingValue(monster)
            if liveValue ~= chaseValueRefs[monster] then
                setChasingValue(monster, liveValue)
            end

            local target = resolveChasingValue(liveValue)
            chasingTargets[monster] = target

            if target and isEligibleTarget(target, myCharacter) then
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
    if not primary or not target or not monster or not monster.Parent then
        log("Skip cast: missing character root, target, or Twisted")
        return
    end

    
    local liveValue = getChasingValue(monster)
    if resolveChasingValue(liveValue) ~= target then
        log("Skip cast: ChasingValue changed before cast", monster.Name)
        clearMotion(monster)
        return
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
    log(
        "CAST ATTEMPT", "target", target.Name,
        "twisted", monster.Name,
        "distance", round(threat.Distance, 2),
        "killRadius", round(threat.KillRadius, 2),
        "triggerRadius", round(threat.TriggerRadius, 2),
        "closing", round(threat.ClosingSpeed, 2),
        "ETA", round(threat.ETA, 3),
        "reason", threat.Reason
    )

    
    task.spawn(function()
        
        
        local currentRoot = getRoot(character)
        local currentValue = getChasingValue(monster)
        local currentTarget = resolveChasingValue(currentValue)

        if not RUNNING or not character.Parent or not monster.Parent or not target.Parent
            or not currentRoot or currentTarget ~= target then
            log("Cast cancelled: character/monster/target changed before invoke")
            lastCast = os.clock() - CFG.RecastDelay
            castPending = false
            return
        end

        local ok, result = pcall(function()
            return abilityEvent:InvokeServer(character, currentRoot.CFrame, target, nil)
        end)

        if not ok then
            log("Invoke error:", result)
            
            protectedUntil[target] = os.clock() + CFG.FailedRequestLockout
            lastCast = os.clock() - math.max(CFG.RecastDelay - 0.12, 0)
        else
            
            
            protectedUntil[target] = os.clock() + CFG.TargetProtectionLockout
            log("Invoke returned:", result and result[1], result and result[2], "rawType=", typeof(result),
                "target lockout:", CFG.TargetProtectionLockout)
        end
        castPending = false
    end)
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
    table.clear(motionHistory)
    table.clear(lastDebugTime)
    log("Stopped")
end

CFG.Stop = stop

log("Started v5. Mode:", CFG.DangerMode, "RadiusReduction:", CFG.RadiusReduction, "TargetLockout:", CFG.TargetProtectionLockout, "TriggerLead:", CFG.TriggerLead, "ContactBuffer:", CFG.ContactBuffer, "MaxTrackDistance:", CFG.MaxTrackDistance)

task.spawn(function()
    while RUNNING do
        task.wait(CFG.PollRate)
        if not RUNNING then
            break
        end

        refreshMonsterTracking()

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
                        local threat = findMostDangerousTarget(character)
                        if threat then
                            lastGateState = "THREAT"
                            castSoulvester(character, threat)
                        else
                            gate = "WATCHING: no target currently meets close-danger conditions"
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