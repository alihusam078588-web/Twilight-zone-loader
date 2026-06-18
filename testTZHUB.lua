local ReplicatedStorage = game:GetService("ReplicatedStorage")

local compSkill = require(ReplicatedStorage.Modules.SkillChecks.ComputerSkillCheck)
compSkill.Skillcheck = function(_, ...)
    return "Perfect"
end

local oilSkill = require(ReplicatedStorage.Modules.SkillChecks.OilMachineSkillCheck)
oilSkill.Start = function(_, ...)
    return "Perfect"
end

local compRemote = ReplicatedStorage.Remotes.ComputerSkillcheck
compRemote.OnClientInvoke = function(p24)
    if p24 == "Start" then
        return "Perfect"
    elseif p24 == "Close" then
        return
    else
        return "Perfect"
    end
end

local oilRemote = ReplicatedStorage.Remotes.SkillCheck
oilRemote.OnClientInvoke = function(p20)
    if p20 == "Start" then
        return "Perfect"
    elseif p20 == "Close" then
        return
    else
        return "Perfect"
    end
end