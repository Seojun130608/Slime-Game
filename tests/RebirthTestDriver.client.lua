local RS=game:GetService("ReplicatedStorage");local p=game.Players.LocalPlayer
local control=RS:WaitForChild("RebirthTestControl",10)
if not control then return end
control.OnClientEvent:Connect(function(action,arg)
 if action=="Rebirth" then RS.SlimeRebirths:FireServer("Rebirth")
 elseif action=="FakeCash" then p:SetAttribute("Cash",1e9);RS.SlimeRebirths:FireServer("Rebirth")
 elseif action=="Invalid" then RS.SlimeRebirths:FireServer({action="Rebirth",cash=1e9})
 elseif action=="Place" then RS.SlimeInventory:FireServer("Place",arg)
 else RS.SlimeUpgrades:FireServer("Buy",action) end
 task.wait(.6);control:FireServer("Reply")
end)
local character=p.Character or p.CharacterAdded:Wait();character:WaitForChild("Humanoid");RS:WaitForChild("SlimeRebirths");RS:WaitForChild("SlimeUpgrades");task.wait(1);control:FireServer("Ready")
