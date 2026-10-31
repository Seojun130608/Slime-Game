local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("SlimeRebirths")
local gui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
gui.Name,gui.ResetOnSpawn,gui.DisplayOrder="SlimeRebirthUI",false,6
local function button(parent,text,pos,size)
 local b=Instance.new("TextButton",parent);b.Text=text;b.Position=pos;b.Size=size
 b.BackgroundColor3=Color3.fromRGB(120,90,180);b.TextColor3=Color3.new(1,1,1)
 b.Font,b.TextSize=Enum.Font.GothamBold,16
 local c=Instance.new("UICorner",b);c.CornerRadius=UDim.new(0,10)
 return b
end
local open=button(gui,"REBIRTH",UDim2.new(1,-166,0,60),UDim2.fromOffset(150,44))
local panel=Instance.new("Frame",gui);panel.Name="Panel";panel.Visible=false
panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.4);panel.Size=UDim2.new(.9,0,0,330)
panel.BackgroundColor3=Color3.fromRGB(35,52,45)
local bound=Instance.new("UISizeConstraint",panel);bound.MaxSize=Vector2.new(490,330)
local info=Instance.new("TextLabel",panel);info.Name="Details";info.BackgroundTransparency=1
info.Position=UDim2.fromOffset(16,10);info.Size=UDim2.new(1,-32,0,230)
info.Font,info.TextSize,info.TextWrapped=Enum.Font.GothamBold,17,true;info.TextColor3=Color3.new(1,1,1)
local confirm=button(panel,"REBIRTH",UDim2.new(0,16,0,244),UDim2.new(.65,-20,0,48))
local close=button(panel,"CLOSE",UDim2.new(.65,0,0,244),UDim2.new(.35,-16,0,48))
local notice=Instance.new("TextLabel",panel);notice.Name="Notice";notice.BackgroundTransparency=1
notice.Position=UDim2.fromOffset(12,296);notice.Size=UDim2.new(1,-24,0,28)
notice.Font,notice.TextSize,notice.TextWrapped=Enum.Font.GothamMedium,12,true;notice.TextColor3=Color3.new(1,1,1);notice.Text=""
local data,armed,pending
local function render()
 if not data then info.Text="Loading...";return end
 info.Text=string.format("REBIRTHS: %d  |  TOKENS: %d\nCash: $%.0f / $%.0f required\nIncome: %.1fx → %.1fx\nUpgrade limit: %d → %d\nReward: %d Slime Token\n\nResets ALL cash and both upgrades.\nKeeps your slimes and their growth.\nProgress lasts this session; saving comes later.",data.count,data.tokens,player:GetAttribute("Cash") or 0,data.requirement,data.multiplier,data.nextMultiplier,data.limit,data.nextLimit,data.reward)
 confirm.Text=armed and "CONFIRM RESET" or "REBIRTH"
end
open.Activated:Connect(function()
 panel.Visible=not panel.Visible;armed=false;notice.Text=""
 if panel.Visible then
  for _,name in ipairs({"SlimeUpgradesUI","SlimeInventoryUI"}) do local other=player.PlayerGui:FindFirstChild(name);if other then other.Panel.Visible=false end end
  remote:FireServer("Request")
 end
 render()
end)
close.Activated:Connect(function() panel.Visible=false;armed=false end)
confirm.Activated:Connect(function()
 if not data or pending then return end
 if (player:GetAttribute("Cash") or 0)<data.requirement then confirm.Text="NEED MORE CASH";return end
 if not armed then armed=true;render();return end
 pending=true;armed=false;remote:FireServer("Rebirth")
 task.delay(.6,function() pending=false end)
end)
remote.OnClientEvent:Connect(function(value) data=value;armed=false;render();if data.message then notice.Text=data.message end end)
player:GetAttributeChangedSignal("Cash"):Connect(render)
