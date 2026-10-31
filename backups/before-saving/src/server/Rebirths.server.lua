-- Requests never supply a balance, multiplier, reward, or another player.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local inventory=script.Parent:WaitForChild("Inventory")
local status=inventory:WaitForChild("RebirthStatus")
local perform=inventory:WaitForChild("PerformRebirth")
local remote=Instance.new("RemoteEvent",RS);remote.Name="SlimeRebirths"
local last={}
remote.OnServerEvent:Connect(function(player,action)
    local now=os.clock()
    if now-(last[player] or -math.huge)<.5 then return end
    last[player]=now
    if action~="Request" and action~="Rebirth" then return end
    local message
    if action=="Rebirth" then local ok;ok,message=perform:Invoke(player) end
    local data=status:Invoke(player)
    if data then data.message=message;remote:FireClient(player,data) end
end)
Players.PlayerRemoving:Connect(function(player) last[player]=nil end)
