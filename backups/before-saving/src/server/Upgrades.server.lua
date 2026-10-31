-- ServerScriptService > Upgrades. Prices and balances never come from the client.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Rules = require(script.Parent:WaitForChild("UpgradeRules"))
local spend = script.Parent:WaitForChild("Inventory"):WaitForChild("TrySpendCash")
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "SlimeUpgrades", RS
local levels, lastAction = {}, {}
local function publish(player)
    local state = levels[player]
    player:SetAttribute("SpeedLevel", state.Speed)
    player:SetAttribute("GrabberLevel", state.Grabber)
    player:SetAttribute("GrabberPower", Rules.Power(state.Grabber))
end
local function snapshot(player, message)
    local state = levels[player]
    if not state then return end
    remote:FireClient(player, {
        speedLevel = state.Speed, grabberLevel = state.Grabber, maxLevel = 5 + (player:GetAttribute("Rebirths") or 0),
        speedCost = Rules.Cost("Speed", state.Speed, 5 + (player:GetAttribute("Rebirths") or 0)), grabberCost = Rules.Cost("Grabber", state.Grabber, 5 + (player:GetAttribute("Rebirths") or 0)),
        speed = Rules.Speed(state.Speed), power = Rules.Power(state.Grabber),
        holdSeconds = Rules.HoldSeconds(state.Grabber), message = message,
    })
end
local function setup(player)
    if levels[player] then return end
    levels[player] = {Speed = 0, Grabber = 0}
    publish(player)
end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player) levels[player], lastAction[player] = nil, nil end)
for _, player in ipairs(Players:GetPlayers()) do setup(player) end
remote.OnServerEvent:Connect(function(player, action, kind)
    if not levels[player] then return end
    local now = os.clock()
    if now - (lastAction[player] or -math.huge) < 0.2 then return end
    lastAction[player] = now
    if action == "Request" then snapshot(player); return end
    if action ~= "Buy" or (kind ~= "Speed" and kind ~= "Grabber") then return end
    local state = levels[player]
    local cost = Rules.Cost(kind, state[kind], 5 + (player:GetAttribute("Rebirths") or 0))
    if not cost then snapshot(player, "Maximum level reached for now."); return end
    -- Inventory owns the private cash balance and subtracts the exact server price.
    if not spend:Invoke(player, cost) then snapshot(player, "Not enough cash. Release slimes into your pen to earn more."); return end
    state[kind] = state[kind] + 1
    publish(player)
    snapshot(player, (kind == "Speed" and "Speed" or "Grabber Power") .. " upgraded!")
end)
print("Upgrades ready: Speed and Grabber Power, five levels each, session-only.")

local reset = Instance.new("BindableFunction")
reset.Name = "ResetForRebirth"
reset.OnInvoke = function(player)
    if not levels[player] then return false end
    levels[player] = {Speed=0, Grabber=0}
    lastAction[player] = os.clock()
    publish(player)
    snapshot(player, "Rebirth complete! Upgrade levels reset; limits increased.")
    return true
end
reset.Parent = script
