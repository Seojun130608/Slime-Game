local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local p=Players.LocalPlayer
local control=RS:WaitForChild("SavingTestControl",10);if not control then return end
local snapshot
RS:WaitForChild("SlimeInventory").OnClientEvent:Connect(function(kind,data) if kind=="Snapshot" then snapshot=data end end)
control.OnClientEvent:Connect(function(id,action,value)
 local ok,result=pcall(function()
  if action=="Inventory" then RS.SlimeInventory:FireServer("Request");task.wait(.3);return snapshot
  elseif action=="BuySpeed" then RS.SlimeUpgrades:FireServer("Buy","Speed");task.wait(.3) end
  return true
 end)
 control:FireServer(id,ok,result)
end)
RS:WaitForChild("SlimeUpgrades");control:FireServer("Ready",true)
