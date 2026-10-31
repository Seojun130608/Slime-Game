-- Isolated two-client upgrade checks; test controls never ship in the clean place.
local Players, RS, SS = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local Storage = game:GetService("ServerStorage")
local Rules = require(SS:WaitForChild("UpgradeRules"))
local control = Instance.new("RemoteEvent", RS); control.Name = "UpgradeTestControl"
local ready, replies, seq, count = {}, {}, 0, 0
control.OnServerEvent:Connect(function(player, id, ok, result)
    if id == "Ready" then ready[player] = true else replies[id] = {player=player, ok=ok, result=result} end
end)
local function call(player, action, args)
    seq += 1; local id = tostring(seq)
    control:FireClient(player, id, action, args)
    local deadline = os.clock() + 12
    repeat task.wait(.03) until replies[id] or os.clock() > deadline
    local reply = replies[id]
    assert(reply and reply.player == player and reply.ok, action .. ": " .. tostring(reply and reply.result))
    replies[id] = nil
    return reply.result
end
local function check(ok, text) assert(ok, text); count += 1; print("UPGRADE PASS: " .. text) end
local function at(player, point, toward)
    player.Character:PivotTo(toward and CFrame.lookAt(point, toward) or CFrame.new(point))
    player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    task.wait(.15)
end
local function run()
    local deadline = os.clock() + 120
    repeat task.wait(.2) until #Players:GetPlayers() >= 2 or os.clock() > deadline
    local a, b = table.unpack(Players:GetPlayers())
    repeat task.wait(.1) until ready[a] and ready[b] or os.clock() > deadline
    assert(ready[a] and ready[b], "Need two ready clients")
    a.Character:WaitForChild("HumanoidRootPart"); b.Character:WaitForChild("HumanoidRootPart")
    local map = workspace.SlimeMap
    local initial = call(a, "Request")
    check(initial.speed == 16 and initial.power == 10 and initial.speedCost == 25 and initial.grabberCost == 35, "starting stats and prices")
    call(a, "Buy", {kind="Speed"})
    check(a:GetAttribute("SpeedLevel") == 0 and a:GetAttribute("Cash") == 0, "insufficient cash rejects without changing level")
    call(a, "FakeCash")
    check(a:GetAttribute("SpeedLevel") == 0 and a:GetAttribute("Cash") == 0, "client cash spoof cannot buy an upgrade")
    local spend = SS.Inventory.TrySpendCash
    for _, amount in ipairs({-1, 0, math.huge, 0/0}) do assert(not spend:Invoke(a, amount)) end
    check(true, "cash service rejects negative zero infinite and NaN amounts")
    -- Seed an earned, owned slime in private inventory, then use real pen release/income.
    local source = map.WildSlimes.GoldSlime:Clone()
    source:SetAttribute("Weight", 20); source.Parent = Storage.SecuredSlimes[tostring(a.UserId)]
    SS.Capture.SlimeSecured:Fire(a, source, 20); task.wait(.2)
    local id = source:GetAttribute("InventoryId")
    local pen = map.Bases["Base" .. a:GetAttribute("BaseIndex")]
    at(a, pen.PenGrass.Position + Vector3.new(0, 3, 0))
    call(a, "Inventory", {action="Place", id=id})
    repeat task.wait(.1) until a:GetAttribute("Cash") >= 2200
    call(a, "Inventory", {action="Store", id=id})
    local balance = a:GetAttribute("Cash")
    check(balance >= 2200 and a:GetAttribute("IncomePerSecond") == 0, "real pen income funds purchases; storing stops income")
    local snap = call(a, "Buy", {kind="Speed"})
    check(a:GetAttribute("Cash") == balance - 25 and a.leaderstats.Cash.Value == math.floor(balance - 25), "exact price deducted and leaderboard synchronized")
    check(snap.speedLevel == 1 and a.Character.Humanoid.WalkSpeed == 18, "Speed purchase applies immediately")
    check(snap.speedCost == 50 and b:GetAttribute("SpeedLevel") == 0 and b:GetAttribute("Cash") == 0, "next price increases and other player stays unchanged")
    balance = a:GetAttribute("Cash")
    call(a, "Invalid", {kind={name="Speed"}, userId=b.UserId})
    check(a:GetAttribute("Cash") == balance, "malformed upgrade request cannot spend cash")
    call(a, "Invalid", {kind="GrantCash"})
    check(a:GetAttribute("Cash") == balance, "unknown upgrade rejected")
    call(a, "Buy", {kind="Grabber"})
    check(a:GetAttribute("GrabberLevel") == 1 and a:GetAttribute("GrabberPower") == 12, "Grabber purchase increases power")
    -- Fixed server test target weight, without changing production random weight assignment.
    local baby = map.WildSlimes.GrassSlime
    baby:PivotTo(CFrame.new(0, 2, 85)); at(a, Vector3.new(0, 4, 90)); at(b, Vector3.new(0, 4, 170))
    local result = call(a, "Capture", {kind="GrassSlime", hold=.1})
    check(not a:GetAttribute("CarryingSlime"), "short holds still rejected with upgraded grabber")
    -- Upgrade to unlock every natural weight, then exercise the faster prompt.
    for _=2,5 do call(a, "Buy", {kind="Grabber"}) end
    check(a:GetAttribute("GrabberPower") == 20, "maximum grabber unlocks all starting weights")
    at(a, Vector3.new(0, 4, 110)); at(a, Vector3.new(0, 4, 90))
    result = call(a, "Capture", {kind="GrassSlime"})
    check(a:GetAttribute("CarryingSlime") == baby.Name and result.duration < 1.2, "upgraded client hold bar and server timing capture faster")
    local before = a.Character.Humanoid.WalkSpeed
    call(a, "Buy", {kind="Speed"})
    check(a.Character.Humanoid.WalkSpeed > before and a.Character.Humanoid.WalkSpeed < 20, "Speed purchase while carrying preserves slowdown")
    SS.Capture.InterruptForBat:Invoke(a)
    check(a.Character.Humanoid.WalkSpeed == 20 and not a:GetAttribute("CarryingSlime"), "dropping restores upgraded walking speed")
    result = call(a, "Capture", {kind="GrassSlime", hold=0})
    check(a:GetAttribute("CarryingSlime") == baby.Name, "dropped pickup remains instant after upgrades")
    at(a, Vector3.new(0, 4, 126)); task.wait(.3)
    check(not a:GetAttribute("CarryingSlime") and a.Character.Humanoid.WalkSpeed == 20, "collection restores upgraded speed and still secures baby")
    -- Bat stun must remain zero during a purchase and restore the new level afterwards.
    at(a, Vector3.new(0, 4, 100)); at(b, Vector3.new(0, 4, 105), Vector3.new(0, 4, 100))
    call(b, "Bat")
    check(a.Character.Humanoid.WalkSpeed == 0, "bat stun still stops an upgraded player")
    call(a, "Buy", {kind="Speed"}); task.wait(.6)
    check(a.Character.Humanoid.WalkSpeed == 22, "stun restores the latest purchased speed")
    for _=4,5 do call(a, "Buy", {kind="Speed"}) end
    balance = a:GetAttribute("Cash")
    call(a, "Buy", {kind="Speed"}); call(a, "Buy", {kind="Grabber"})
    check(a:GetAttribute("SpeedLevel") == 5 and a:GetAttribute("GrabberLevel") == 5 and a:GetAttribute("Cash") == balance, "level caps reject extra purchases without charging")
    check(Rules.CarrySpeed(0,5,10,20) > Rules.CarrySpeed(0,0,10,20), "grabber level reduces carrying penalty independently of power")
    local ui = call(a, "UI")
    check(ui.speedButton == "MAX LEVEL" and ui.powerButton == "MAX LEVEL" and ui.cash:find("Cash:"), "upgrade panel shows limits and current cash")
    a.Character.Humanoid.Health = 0
    local character = a.CharacterAdded:Wait(); character:WaitForChild("HumanoidRootPart"); task.wait(.5)
    check(character.Humanoid.WalkSpeed == 26 and a:GetAttribute("GrabberPower") == 20 and a:GetAttribute("Cash") == balance, "levels stats and cash survive character reset")
    check(b:GetAttribute("SpeedLevel") == 0 and b:GetAttribute("GrabberLevel") == 0, "purchases never change another player's levels")
    print("UPGRADE INTEGRATION COMPLETE: " .. count .. " checks")
end
task.spawn(function()
    local ok, err = xpcall(run, debug.traceback)
    if not ok then warn("UPGRADE INTEGRATION FAILED: " .. err) end
    pcall(function() game:GetService("StudioTestService"):EndTest({ok=ok,error=err,checks=count}) end)
end)
