local okArgs,args=pcall(function() return game:GetService("StudioTestService"):GetTestArgs() end)
if not okArgs or args~="Saving" then warn("Open the normal game to play. Run this test deliberately with StudioTestService.");return end
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local Storage=game:GetService("ServerStorage")
local control=Instance.new("RemoteEvent",RS);control.Name="SavingTestControl"
local ready,replies={},{}
control.OnServerEvent:Connect(function(p,id,ok,result)
 if id=="Ready" then ready[p]=true else replies[id]={player=p,ok=ok,result=result} end
end)
local seq,count=0,0
local function waitFor(fn,seconds,label)
 local deadline=os.clock()+seconds
 repeat task.wait(.05) until fn() or os.clock()>deadline
 assert(fn(),"Timed out: "..label)
end
local function check(ok,label) assert(ok,label);count+=1;print("SAVING GAME PASS: "..label) end
local function call(p,action,value)
 seq+=1;local id=tostring(seq);control:FireClient(p,id,action,value)
 waitFor(function() return replies[id]~=nil end,10,action)
 local r=replies[id];replies[id]=nil;assert(r.player==p and r.ok,tostring(r.result));return r.result
end
local function run()
 local coreCount=require(SS.SavingCoreChecks)()
 waitFor(function() return #Players:GetPlayers()>=2 end,60,"two players")
 local a,b=table.unpack(Players:GetPlayers())
 waitFor(function() return ready[a] and ready[b] and a:GetAttribute("DataReady") and b:GetAttribute("DataReady") end,30,"loaded players")
 waitFor(function() return a:GetAttribute("SpeedLevel")==2 and a.Character and a.Character:FindFirstChild("Humanoid") end,10,"restored stats")
 local inv=call(a,"Inventory")
 check(#inv.items==2 and inv.selected=="placed-id","inventory IDs and selection restored")
 local placed,stored
 for _,item in ipairs(inv.items) do if item.id=="placed-id" then placed=item else stored=item end end
 check(placed.kind=="Gold" and placed.weight==17 and placed.inPen and placed.progress>=.4,"placed slime type weight and growth restored")
 check(stored.kind=="Water" and stored.weight==5 and not stored.inPen and stored.progress==.25,"stored slime remains stored with paused growth")
 check(a:GetAttribute("Rebirths")==2 and a:GetAttribute("SlimeTokens")==3 and a:GetAttribute("CashMultiplier")==2,"rebirth rewards restored")
 check(a:GetAttribute("GrabberPower")==16 and a.Character.Humanoid.WalkSpeed==20,"upgrades and character movement restored")
 check((a:GetAttribute("Cash") or 0)>=2222 and a:GetAttribute("IncomePerSecond")>0,"cash restored and placed income resumes")
 check(a:GetAttribute("BaseIndex")~=b:GetAttribute("BaseIndex"),"restored players receive different available pens")
 local folder=Storage.SecuredSlimes[tostring(a.UserId)]
 check(#folder:GetChildren()==2 and workspace.SlimeMap.PlacedSlimes:GetChildren()[1]:GetAttribute("Weight")==nil,"restored originals remain private and displays hide weights")
 local before=a:GetAttribute("Cash")
 call(a,"BuySpeed")
 check(a:GetAttribute("SpeedLevel")==3 and a.Character.Humanoid.WalkSpeed==22,"purchase after loading uses restored level")
 check(a:GetAttribute("Cash")<before+300,"purchase spends existing balance")
 check(b:GetAttribute("SpeedLevel")==2,"another player's loaded upgrades unchanged")
 local savedProgress=stored.progress
 task.wait(.5);inv=call(a,"Inventory")
 for _,item in ipairs(inv.items) do if item.id=="stored-id" then check(item.progress==savedProgress,"offline or stored growth is not awarded") end end
 local original=a.Character
 original.Humanoid.Health=0
 waitFor(function() return a.Character and a.Character~=original and a.Character:FindFirstChild("Humanoid") end,15,"respawn")
 task.wait(.5)
 check(a.Character.Humanoid.WalkSpeed==22 and a:GetAttribute("Rebirths")==2 and #folder:GetChildren()==2,"character reset does not reload or duplicate profile")
 local ok=SS.Inventory.SavingTestSave:Invoke(a,false)
 check(ok,"inventory autosave snapshot writes successfully")
 local Store=require(SS.ProfileStore)
 local data=Store.TestData["Player_"..a.UserId].profile
 check(data.upgrades.Speed==3 and data.rebirths==2 and #data.slimes==2,"save snapshot includes latest private progress")
 check(data.slimes[1].id~=data.slimes[2].id,"save snapshot contains no duplicate IDs")
 local money=data.cash
 local closeOk=SS.Inventory.SavingTestSave:Invoke(a,true)
 check(closeOk and Store.TestData["Player_"..a.UserId].lease==nil,"leaving flush releases the actual inventory profile lease")
 local session=assert(Store.Load(a.UserId))
 check(session.profile.upgrades.Speed==3 and session.profile.cash>=money and #session.profile.slimes==2,"fresh profile session reloads gameplay changes")
 Store.Save(session,session.profile,true)
 print("SAVING INTEGRATION COMPLETE: "..count.." game checks, "..coreCount.." core checks")
 return {gameChecks=count,coreChecks=coreCount}
end
task.spawn(function()
 local ok,result=xpcall(run,debug.traceback)
 if not ok then warn("SAVING INTEGRATION FAILED: "..result) end
 game:GetService("StudioTestService"):EndTest({ok=ok,result=result})
end)
