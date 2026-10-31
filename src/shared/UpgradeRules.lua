-- Server-only balance settings. Rebirths can raise these limits in a later feature.
local Rules = {MaxLevel = 5}
function Rules.Cost(kind, level)
    if (kind ~= "Speed" and kind ~= "Grabber") or level < 0 or level >= Rules.MaxLevel then return nil end
    return (kind == "Speed" and 25 or 35) * 2 ^ level
end
function Rules.Speed(level) return 16 + 2 * level end
function Rules.Power(level) return 10 + 2 * level end
function Rules.HoldSeconds(level) return 2 / (1 + 0.15 * level) end
function Rules.CarrySpeed(speedLevel, grabberLevel, weight, power)
    local penalty = 0.35 / (1 + 0.15 * grabberLevel)
    return math.max(6, Rules.Speed(speedLevel) * (1 - penalty * weight / math.max(1, power)))
end
return Rules
