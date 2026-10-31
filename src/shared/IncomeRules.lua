-- Server-only rates. Income is automatic for every placed slime, including growing babies.
local baseRates = {Grass=1,Mud=2,Water=4,Honey=8,Crystal=16,Gold=32}
local Rules = {}
function Rules.Rate(kind, weight)
    return math.floor((baseRates[kind] or 1) * weight^.6 * 100 + .5) / 100
end
return Rules
