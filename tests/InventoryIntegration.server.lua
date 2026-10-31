-- Native two-client integration suite. No test controls ship with the game.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local Storage=game:GetService("ServerStorage")
local control=Instance.new("RemoteEvent",RS);control.Name="InventoryTestControl"
local ready,replies={},{}
control.OnServerEvent:Connect(function(p,id,ok,result)
    if id=="Ready" then ready[p]=true else replies[id]={player=p,ok=ok,result=result} end
end)
local seq=0
local function call(p,action,args)
    seq+=1;local id=tostring(seq)
    control:FireClient(p,id,action,args)
    local deadline=os.clock()+10
    repeat task.wait(.03) until replies[id] or os.clock()>deadline
    local r=replies[id];assert(r and r.player==p and r.ok,"Client "..action..": "..tostring(r and r.result))
    replies[id]=nil
    return r.result
end
local count=0
local function check(ok,name) assert(ok,name);count+=1;print("INVENTORY PASS: "..name) end
local function at(p,position)
    p.Character:PivotTo(CFrame.new(position))
    p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
    task.wait(.2)
end
local function run()
    local deadline=os.clock()+120
    repeat task.wait(.2) until #Players:GetPlayers()>=2 or os.clock()>deadline
    assert(#Players:GetPlayers()>=2,"Need two clients")
    local a,b=table.unpack(Players:GetPlayers())
    repeat task.wait(.1) until ready[a] and ready[b] or os.clock()>deadline
    assert(ready[a] and ready[b],"Client drivers not ready")
    local map=workspace:WaitForChild("SlimeMap")
    local secured=Storage:WaitForChild("SecuredSlimes")
    a.Character:WaitForChild("HumanoidRootPart");b.Character:WaitForChild("HumanoidRootPart")
    a.Backpack:WaitForChild("Slime Grabber");a:SetAttribute("GrabberPower",20)
    local snapA=call(a,"Snapshot");local snapB=call(b,"Snapshot")
    check(snapA.base and snapB.base and snapA.base~=snapB.base,"players receive different bases")
    check(#snapA.items==0 and #snapB.items==0,"new inventories start empty")
    check(call(a,"UI").button:find("SLIMES")~=nil,"inventory interface is present")
    local baby=map.WildSlimes.GrassSlime
    baby:PivotTo(CFrame.new(0,2,85));at(a,Vector3.new(0,4,90));at(b,Vector3.new(0,4,160))
    call(a,"Capture",{kind="GrassSlime"})
    check(a:GetAttribute("CarryingSlime")=="GrassSlime","existing capture pipeline still works")
    at(a,Vector3.new(0,4,126));task.wait(.4)
    snapA=call(a,"Snapshot");snapB=call(b,"Snapshot")
    check(#snapA.items==1 and #snapB.items==0,"securing updates only the owner's inventory")
    local item=snapA.items[1];local id=item.id
    check(type(item.weight)=="number" and item.weight>=1 and item.weight<=20,"owner can inspect the fixed captured weight")
    check(item.progress==0 and not item.slot,"secured slime stays an ungrown baby in inventory")
    local source=secured[tostring(a.UserId)]:FindFirstChild("GrassSlime")
    check(source and source:GetAttribute("InventoryId")==id,"original baby remains in private server storage")
    -- An event repeated for the same source must not duplicate it.
    SS.Capture.SlimeSecured:Fire(a,source,item.weight)
    task.wait(.2);check(#call(a,"Snapshot").items==1,"duplicate secure event cannot duplicate inventory")
    call(a,"Place",{id=id,slot=1})
    check(#map.PlacedSlimes:GetChildren()==0,"remote placement from outside the base is rejected")
    local baseA=map.Bases["Base"..snapA.base];local baseB=map.Bases["Base"..snapB.base]
    local function pad(base,i) return base.CollectionSpots["Spot"..i].CollectionSpot end
    at(b,pad(baseB,1).Position+Vector3.new(0,3,3));call(b,"Place",{id=id,slot=1})
    check(#map.PlacedSlimes:GetChildren()==0,"another player cannot place a stolen inventory ID")
    at(a,pad(baseA,1).Position+Vector3.new(0,3,3));call(a,"Place",{id=id,slot=1})
    task.wait(.3)
    local shown=map.PlacedSlimes:GetChildren()[1]
    check(shown and shown:GetAttribute("OwnerUserId")==a.UserId,"owner can place a baby in their own slot")
    check(baseA.CollectionSpots.Spot1:GetAttribute("Occupied"),"placement reserves the slot")
    check(shown:GetAttribute("Weight")==nil,"world display does not expose numerical weight")
    local initialSize=shown.Body.Size.Y
    call(a,"Place",{id=id,slot=2})
    check(#map.PlacedSlimes:GetChildren()==1,"same slime cannot occupy two slots")
    at(b,pad(baseA,1).Position+Vector3.new(0,3,3));call(b,"SlotPrompt",{base=snapA.base,slot=1})
    check(#map.PlacedSlimes:GetChildren()==1,"other players cannot reclaim a placed slime")
    task.wait(1.2)
    check(shown.Body.Size.Y>initialSize,"placed baby visibly grows")
    at(a,pad(baseA,1).Position+Vector3.new(0,3,3));call(a,"Store",{id=id})
    local paused=source:GetAttribute("GrowthProgress")
    check(paused>0 and paused<1 and #map.PlacedSlimes:GetChildren()==0,"reclaim returns a partly grown slime to inventory")
    task.wait(1.1)
    check(source:GetAttribute("GrowthProgress")==paused,"growth pauses while stored")
    check(not baseA.CollectionSpots.Spot1:GetAttribute("Occupied"),"reclaim frees the base slot")
    call(a,"Place",{id=id,slot=1});task.wait(.3)
    shown=map.PlacedSlimes:GetChildren()[1]
    check(source:GetAttribute("GrowthProgress")>paused,"replacing resumes existing growth")
    task.wait(12)
    check(source:GetAttribute("GrowthProgress")==1,"growth reaches completion")
    local target=.8+item.weight^(1/3)*.55
    check(math.abs(shown:GetScale()-target)<.001,"grown size matches captured weight")
    local size=shown.Body.Size;task.wait(.4)
    check((shown.Body.Size-size).Magnitude<.001,"fully grown slime stops growing")
    check(source:GetAttribute("Weight")==item.weight,"growth never rerolls weight")
    -- Stored and placed babies both survive a character reset during this session.
    local countBefore=#call(a,"Snapshot").items
    a.Character.Humanoid.Health=0
    local respawn=a.CharacterAdded:Wait();respawn:WaitForChild("HumanoidRootPart");task.wait(.5)
    snapA=call(a,"Snapshot")
    check(#snapA.items==countBefore and snapA.items[1].progress==1 and snapA.items[1].slot==1,"inventory and growth survive character reset")
    -- Seed additional secured babies through the existing server event to exercise six slots.
    local function seed(weight)
        local clone=source:Clone();clone:SetAttribute("InventoryId",nil);clone:SetAttribute("Weight",weight);clone.Name="TestBaby"..weight
        clone.Parent=secured[tostring(a.UserId)];SS.Capture.SlimeSecured:Fire(a,clone,weight);task.wait(.05)
        return clone:GetAttribute("InventoryId")
    end
    local extra={}
    for i=2,7 do extra[i]=seed(i) end
    for i=2,6 do at(a,pad(baseA,i).Position+Vector3.new(0,3,3));call(a,"Place",{id=extra[i],slot=i}) end
    check(#map.PlacedSlimes:GetChildren()==6,"all six base slots can be used")
    at(a,pad(baseA,1).Position+Vector3.new(0,3,3));call(a,"Place",{id=extra[7],slot=1})
    snapA=call(a,"Snapshot")
    local storedExtra
    for _,v in ipairs(snapA.items) do if v.id==extra[7] then storedExtra=v end end
    check(#map.PlacedSlimes:GetChildren()==6 and storedExtra and not storedExtra.slot,"full base rejects placement without losing the stored baby")
    check(#call(b,"Snapshot").items==0,"other client never receives the owner's inventory entries")
    print("INVENTORY INTEGRATION COMPLETE: "..count.." checks")
end
task.spawn(function()
    local ok,err=xpcall(run,debug.traceback)
    if not ok then warn("INVENTORY INTEGRATION FAILED: "..err) end
    pcall(function() game:GetService("StudioTestService"):EndTest({ok=ok,error=err,checks=count}) end)
end)
