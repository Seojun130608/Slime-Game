-- Increasing requirements, additive multipliers, and session token rewards.
local Rules = {}
function Rules.Requirement(count) return 1000 * 2 ^ count end
function Rules.Multiplier(count) return 1 + 0.5 * count end
function Rules.TokenReward(count) return 1 end
function Rules.UpgradeLimit(count) return 5 + count end
return Rules
