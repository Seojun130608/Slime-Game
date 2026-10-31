-- Slime Bat: clients request swings; the server decides range, safety and the hit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Rules = require(script.Parent:WaitForChild("CombatRules"))
local capture = script.Parent:WaitForChild("Capture")
local interrupt = capture:WaitForChild("InterruptForBat")
local refreshMovement = capture:WaitForChild("RefreshMovement")
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "SlimeBatSwing", ReplicatedStorage
local lastSwing, stuns = {}, {}
local tool = Instance.new("Tool")
tool.Name, tool.CanBeDropped = "Slime Bat", false
tool.ToolTip = "Knock back a rival and drop their baby. Bases are safe."
tool.Grip = CFrame.new(0, -0.8, 0)
local function part(name, size, offset, color)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame, p.Color = name, size, CFrame.new(offset), color
    p.Material, p.CanCollide, p.CanTouch, p.Massless = Enum.Material.SmoothPlastic, false, false, true
    p.Parent = tool
    return p
end
local handle = part("Handle", Vector3.new(.38, 1.4, .38), Vector3.zero, Color3.fromRGB(62,69,89))
local barrel = part("PaddedHead", Vector3.new(1.1, 3, 1.1), Vector3.new(0, 2, 0), Color3.fromRGB(70,218,255))
local cap = part("EndCap", Vector3.new(1.15,.22,1.15), Vector3.new(0,3.55,0), Color3.fromRGB(166,255,49))
for _, p in ipairs({barrel, cap}) do
    local weld = Instance.new("WeldConstraint")
    weld.Part0, weld.Part1, weld.Parent = handle, p, handle
end
tool.Parent = StarterPack
local function getLiving(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.Health > 0 then return character, root, hum end
end
local function feedback(player, text)
    remote:FireClient(player, "Message", text)
end
local function animate(bat)
    local rest = CFrame.new(0, -.8, 0)
    local forward = TweenService:Create(bat, TweenInfo.new(.10), {Grip = rest * CFrame.Angles(0, 0, math.rad(-95))})
    forward:Play()
    task.delay(.12, function()
        if bat.Parent then TweenService:Create(bat, TweenInfo.new(.16), {Grip = rest}):Play() end
    end)
end
local function knockback(player, root, humanoid, attackerRoot)
    local now = workspace:GetServerTimeNow()
    player:SetAttribute("BatProtectedUntil", now + Rules.HitProtection)
    player:SetAttribute("BatStunnedUntil", now + Rules.StunDuration)
    local record = {humanoid = humanoid, speed = humanoid.WalkSpeed, rotate = humanoid.AutoRotate}
    stuns[player] = record
    humanoid.WalkSpeed, humanoid.AutoRotate = 0, false
    local delta = root.Position - attackerRoot.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)
    local direction = flat.Magnitude > .01 and flat.Unit or attackerRoot.CFrame.LookVector
    -- Server owns the short impact, so a client cannot suppress it.
    local canOwn = root:CanSetNetworkOwnership()
    if canOwn then root:SetNetworkOwner(nil) end
    root:ApplyImpulse((direction * Rules.Knockback + Vector3.new(0,12,0)) * root.AssemblyMass)
    local glow = Instance.new("Highlight")
    glow.Name, glow.Adornee = "BatProtection", player.Character
    glow.FillColor, glow.OutlineColor = Color3.fromRGB(132,239,255), Color3.new(1,1,1)
    glow.FillTransparency, glow.OutlineTransparency = .8, .25
    glow.Parent = player.Character
    Debris:AddItem(glow, Rules.HitProtection)
    task.delay(Rules.StunDuration, function()
        if stuns[player] ~= record then return end
        stuns[player] = nil
        if humanoid.Parent and humanoid.Health > 0 then
            humanoid.WalkSpeed, humanoid.AutoRotate = record.speed, record.rotate
            refreshMovement:Invoke(player)
        end
        if root.Parent and canOwn then root:SetNetworkOwnershipAuto() end
    end)
end
local function clearLine(a, b, attacker, target)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = {attacker, target}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(excluded, p.Character) end
    end
    local map = workspace:FindFirstChild("SlimeMap")
    if map then
        if map:FindFirstChild("WildSlimes") then table.insert(excluded, map.WildSlimes) end
        if map:FindFirstChild("Guardians") then table.insert(excluded, map.Guardians) end
    end
    params.FilterDescendantsInstances = excluded
    return not workspace:Raycast(a, b - a, params)
end
local function swing(player)
    local character, root = getLiving(player)
    if not character then return end
    local bat = character:FindFirstChild(tool.Name)
    if not bat or not bat:IsA("Tool") or not bat:FindFirstChild("PaddedHead") then return end
    local now = workspace:GetServerTimeNow()
    if Rules.IsStunned(player) then return end
    if now - (lastSwing[player] or -math.huge) < Rules.SwingCooldown then return end
    -- Rate limit rejected attempts as well as accepted swings.
    lastSwing[player] = now
    if player:GetAttribute("CarryingSlime") then feedback(player, "Put down your baby before swinging."); return end
    if Rules.IsSafe(character) then feedback(player, "Bases and the collect zone are safe."); return end
    animate(bat)
    local nearest, distance
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local c, r, h = getLiving(other)
            if c and not Rules.IsSafe(c) and (other:GetAttribute("BatProtectedUntil") or 0) <= now then
                local delta = r.Position - root.Position
                local d = delta.Magnitude
                -- A short forward arc, never a hit behind the attacker or through a wall.
                if d <= Rules.Range and (d < .01 or root.CFrame.LookVector:Dot(delta.Unit) >= .15)
                    and clearLine(root.Position, r.Position, character, c)
                    and (not distance or d < distance) then
                    nearest, distance = {player = other, root = r, humanoid = h}, d
                end
            end
        end
    end
    if nearest then
        -- Drop before stun, so capture restores the normal walking speed first.
        nearest.player:SetAttribute("BatProtectedUntil", now + Rules.HitProtection)
        nearest.player:SetAttribute("BatStunnedUntil", now + Rules.StunDuration)
        local dropped = interrupt:Invoke(nearest.player)
        knockback(nearest.player, nearest.root, nearest.humanoid, root)
        feedback(player, dropped and "Hit! Their baby is on the ground." or "Hit!")
        feedback(nearest.player, dropped and "Baby dropped! Equip your grabber to recover it." or "Hit! You have two seconds of protection.")
    end
end
remote.OnServerEvent:Connect(function(player, action)
    if action == "Drop" then
        local character = getLiving(player)
        if character and player:GetAttribute("CarryingSlime") and not Rules.IsStunned(player) and not Rules.IsSafe(character) then
            interrupt:Invoke(player)
        end
    elseif action == nil or action == "Swing" then
        swing(player)
    end
end)
local function setup(player)
    local function characterAdded(character)
        stuns[player] = nil
        player:SetAttribute("BatStunnedUntil", nil)
        player:SetAttribute("BatProtectedUntil", nil)
        local backpack = player:WaitForChild("Backpack")
        if player.Character == character and not backpack:FindFirstChild(tool.Name) and not character:FindFirstChild(tool.Name) then
            tool:Clone().Parent = backpack
        end
    end
    player.CharacterAdded:Connect(characterAdded)
    if player.Character then task.spawn(characterAdded, player.Character) end
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player) lastSwing[player], stuns[player] = nil, nil end)
for _, player in ipairs(Players:GetPlayers()) do setup(player) end
print("Slime Bat ready: 0.9s swings, 2s protection, safe bases, shared dropped babies.")
