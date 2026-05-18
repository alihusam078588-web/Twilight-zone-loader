local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Grab the package directly
local Packages = ReplicatedStorage:WaitForChild("Packages")
local RaycastHitbox = require(Packages.raycastHitbox)

-- Patch stealth mode
local oldNew = RaycastHitbox.new
RaycastHitbox.new = function(obj)
    local hb = oldNew(obj)
    -- Force bypass mode so hitboxes skip detection
    hb.DetectionMode = RaycastHitbox.DetectionMode.Bypass
    -- Block OnHit so Rejects never register you
    hb.OnHit:Connect(function() end)
    return hb
end