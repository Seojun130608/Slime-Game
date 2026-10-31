-- Run deliberately through StudioTestService, never automatically during ordinary Play.
local hasArgs,testArgs=pcall(function() return game:GetService("StudioTestService"):GetTestArgs() end)
if not hasArgs or (testArgs~="Rebirths" and testArgs~="RebirthsLimits") then
    warn("This is the rebirth TEST place. Open Steal-A-Slime-Rebirths.rbxlx from the Game folder for normal play.")
    return
end
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local control=Instance.new("RemoteEvent",RS);control.Name="RebirthTestControl"
local reply,ready;control.OnServerEvent:Connect(function(p,kind) if kind=="Ready" then ready=p else reply=true end end)
local count=0
local function check(ok,name) assert(ok,name);count+=1;print("REBIRTH PASS: "..name) end
local function waitFor(check,seconds,label)
 local deadline=os.clock()+seconds
 repeat task.wait(.05) until check() or os.clock()>deadline
 assert(check(),"Timed out: "..label)
end
local function call(action,arg) reply=false;control:FireClient(ready,action,arg);waitFor(function() return reply end,10,action) end
local function run()
 waitFor(function() return ready~=nil end,60,"ready client")
 local p=ready;local inv=SS.Inventory;local status=inv.RebirthStatus
 check(status:Invoke(p).count==0,"starts with zero rebirths")
 call("Rebirth")
 check(status:Invoke(p).count==0,"insufficient cash rejected")
 call("FakeCash")
 check(status:Invoke(p).count==0,"client cash spoof cannot rebirth")
 call("Invalid")
 check(status:Invoke(p).count==0,"malformed action cannot rebirth")
 local source=workspace.SlimeMap.WildSlimes.GoldSlime:Clone();source:SetAttribute("Weight",20)
 source.Parent=game.ServerStorage.SecuredSlimes[tostring(p.UserId)]
 SS.Capture.SlimeSecured:Fire(p,source,20);task.wait(.3)
 local id=source:GetAttribute("InventoryId");local base=workspace.SlimeMap.Bases["Base"..p:GetAttribute("BaseIndex")]
 p.Character:PivotTo(CFrame.new(base.PenGrass.Position+Vector3.new(0,3,0)))
 call("Place",id)
 waitFor(function() return (p:GetAttribute("Cash") or 0)>2200 end,40,"earned cash")
 call("Speed");call("Grabber")
 check(p:GetAttribute("SpeedLevel")==1 and p:GetAttribute("GrabberLevel")==1,"purchased levels before reset")
 waitFor(function() return p:GetAttribute("Cash")>2000 end,30,"first rebirth balance")
 local weight=source:GetAttribute("Weight");local progress=source:GetAttribute("GrowthProgress");local income=p:GetAttribute("IncomePerSecond")
 call("Rebirth")
 local s=status:Invoke(p)
 check(s.count==1 and s.tokens==1 and s.multiplier==1.5,"first rewards and 1.5 multiplier")
 check(s.requirement==2000 and s.limit==6,"next requirement and raised upgrade limit")
 check(p:GetAttribute("SpeedLevel")==0 and p:GetAttribute("GrabberLevel")==0 and p:GetAttribute("GrabberPower")==10,"both upgrades reset")
 check(p.Character.Humanoid.WalkSpeed==16,"movement resets")
 check(p:GetAttribute("Cash")<300,"cash reset rather than requirement subtraction")
 check(source.Parent==game.ServerStorage.SecuredSlimes[tostring(p.UserId)] and source:GetAttribute("Weight")==weight,"owned slime and weight preserved")
 check(source:GetAttribute("GrowthProgress")>=progress and #workspace.SlimeMap.PlacedSlimes:GetChildren()==1,"growth and placed display preserved")
 check(math.abs(p:GetAttribute("IncomePerSecond")-income*1.5)<.01,"income multiplied by 1.5")
 call("Rebirth")
 check(status:Invoke(p).count==1,"repeated request cannot rebirth without new cash")
 waitFor(function() return p:GetAttribute("Cash")>2000 end,30,"second rebirth balance")
 call("Rebirth")
 s=status:Invoke(p)
 check(s.count==2 and s.tokens==2 and s.multiplier==2 and s.requirement==4000 and s.limit==7,"second rebirth additive 2x and increasing requirement")
 check(math.abs(p:GetAttribute("IncomePerSecond")-income*2)<.01,"second income multiplier applied once")
 waitFor(function() return p:GetAttribute("Cash")>3400 end,30,"raised limit purchases")
 for _=1,7 do call("Speed") end
 check(p:GetAttribute("SpeedLevel")==7 and p.Character.Humanoid.WalkSpeed==30,"can buy levels beyond original cap")
 call("Speed")
 check(p:GetAttribute("SpeedLevel")==7,"raised cap still enforced")
 p.Character.Humanoid.Health=0;local char=p.CharacterAdded:Wait();char:WaitForChild("Humanoid");task.wait(.5)
 check(status:Invoke(p).count==2 and p:GetAttribute("SlimeTokens")==2 and char.Humanoid.WalkSpeed==30,"session rewards and raised upgrades survive character reset")
 print("REBIRTH COMPLETE: "..count)
 return count
end
task.spawn(function() local ok,result=xpcall(run,debug.traceback);if not ok then warn("REBIRTH FAILED: "..result) end;game:GetService("StudioTestService"):EndTest({ok=ok,result=result}) end)
