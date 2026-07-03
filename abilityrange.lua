local RunService = game:GetService("RunService")

local toons = {"Shelly", "Sprout", "Cosmo", "Scraps", "Glisten"}
local toonsTable = {}
for _, toon in pairs(toons) do
    toonsTable[toon] = true
end

local function patchRanges()
    local connections = getconnections(RunService.RenderStepped)
    for _, conn in pairs(connections) do
        local func = conn.Function
        if func then
            local ok, upvals = pcall(getupvalues, func)
            if ok and upvals then
                for _, val in pairs(upvals) do
                    if typeof(val) == "table" then
                        local ok2, name = pcall(function() return val.Name end)
                        local ok3, radius = pcall(function() return val.PlayerRadius end)
                        if ok2 and ok3 and toonsTable[name] and radius and radius ~= 500 then
                            val.PlayerRadius = 500
                        end
                    end
                end
            end
        end
    end
end

patchRanges()