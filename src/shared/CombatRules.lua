-- ModuleScript in ServerScriptService. Shared by capture and bat validation.
local Rules = {
    SwingCooldown = 0.9,
    HitProtection = 2,
    StunDuration = 0.55,
    Range = 8,
    Knockback = 34,
    DropLifetime = 30,
}
local map = workspace:WaitForChild("SlimeMap")
local trigger = map:WaitForChild("CollectZone"):WaitForChild("CollectionTrigger")
Rules.SafeZ = trigger.Position.Z - trigger.Size.Z / 2
function Rules.IsSafe(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root ~= nil and root.Position.Z >= Rules.SafeZ
end
function Rules.IsStunned(player)
    return (player:GetAttribute("BatStunnedUntil") or 0) > workspace:GetServerTimeNow()
end
return Rules
