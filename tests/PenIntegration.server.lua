-- Native two-client integration suite. No test controls ship with the game.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local Storage=game:GetService("ServerStorage")
local control=Instance.new("RemoteEvent",RS);control.Name="PenTestControl"
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
local function check(ok,name) assert(ok,name);count+=1;print("PEN PASS: "..name) end
local function at(p,position)
    p.Character:PivotTo(CFrame.new(position))
    p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
    task.wait(.2)
end
local function run()
    local deadline=os.clock()+120
    repeat task.wait(.2) until #Players:GetPlayers()>=2 or os.clock()>deadline
    local a,b=table.unpack(Players:GetPlayers())
    repeat task.wait(.1) until ready[a] and ready[b] or os.clock()>deadline
    assert(ready[a] and ready[b],"Need two ready clients")
    local map=workspace:WaitForChild("SlimeMap")
    local secured=Storage:WaitForChild("SecuredSlimes")
    local ac=a.Character or a.CharacterAdded:Wait();local bc=b.Character or b.CharacterAdded:Wait()
    ac:WaitForChild("HumanoidRootPart");bc:WaitForChild("HumanoidRootPart")
    a.Backpack:WaitForChild("Slime Grabber");a:SetAttribute("GrabberPower",20)
    local sa=call(a,"Snapshot");local sb=call(b,"Snapshot")
    local pa=map.Bases["Base"..sa.base];local pb=map.Bases["Base"..sb.base]
    check(sa.base~=sb.base,"players own different pens")
    for _,base in ipairs(map.Bases:GetChildren()) do
        assert(not base:FindFirstChild("CollectionSpots"),"Old pads remain")
        assert(base:FindFirstChild("PenEntrance"),"Missing entrance prompt")
    end
    check(true,"all six bases have open pens and no collection pads")
    check(map:FindFirstChild("CollectZone")~=nil,"capture collection boundary is preserved")
    local baby=map.WildSlimes.GrassSlime
    baby:PivotTo(CFrame.new(0,2,85));at(a,Vector3.new(0,4,90));at(b,Vector3.new(0,4,160))
    call(a,"Capture",{kind="GrassSlime"});at(a,Vector3.new(0,4,126));task.wait(.3)
    sa=call(a,"Snapshot");local id=sa.items[1].id;local weight=sa.items[1].weight
    local source=secured[tostring(a.UserId)]:FindFirstChild("GrassSlime")
    check(source and #sa.items==1,"capture still secures a private inventory baby")
    task.wait(.5);check((a:GetAttribute("Cash") or 0)==0,"stored babies earn no income")
    call(a,"Place",{id=id});check(#map.PlacedSlimes:GetChildren()==0,"cannot release slimes from outside own pen")
    at(b,pb.PenGrass.Position+Vector3.new(0,3,0));call(b,"Place",{id=id})
    check(#map.PlacedSlimes:GetChildren()==0,"another player cannot release an owned inventory ID")
    at(a,pa.PenGrass.Position+Vector3.new(0,3,0));call(a,"Place",{id=id})
    local display=map.PlacedSlimes:GetChildren()[1]
    check(display~=nil and sa.capacity==6,"one release creates one roaming display")
    check(display:GetAttribute("Weight")==nil,"roaming display keeps weight numbers private")
    call(a,"Place",{id=id});check(#map.PlacedSlimes:GetChildren()==1,"repeated release cannot duplicate a slime")
    local start=display:GetPivot().Position
    local rate=require(SS.IncomeRules).Rate("Grass",weight)
    check(math.abs(a:GetAttribute("IncomePerSecond")-rate)<.001,"income uses the server's type and weight formula")
    task.wait(2)
    check((display:GetPivot().Position-start).Magnitude>.3,"placed slime wanders around the pen")
    check(a:GetAttribute("Cash")>0,"income is automatically credited without touching a pad")
    check(b:GetAttribute("Cash")==0,"income is credited only to the owner")
    check(a.leaderstats.Cash.Value==math.floor(a:GetAttribute("Cash")),"cash HUD and leaderboard use server balance")
    local function inside()
        local grass=pa.PenGrass
        local box,size=display:GetBoundingBox()
        local localPos=grass.CFrame:PointToObjectSpace(box.Position)
        return math.abs(localPos.X)+size.X/2<=grass.Size.X/2+.05 and math.abs(localPos.Z)+size.Z/2<=grass.Size.Z/2+.05
    end
    for _=1,25 do assert(inside(),"Roaming slime escaped pen bounds");task.wait(.2) end
    check(true,"roaming stays inside pen throughout movement")
    at(b,pa.PenGrass.Position+Vector3.new(0,3,0));call(b,"Store",{id=id})
    check(#map.PlacedSlimes:GetChildren()==1,"another player cannot reclaim a roaming slime")
    at(a,pa.PenGrass.Position+Vector3.new(0,3,0));call(a,"Store",{id=id})
    local cash=a:GetAttribute("Cash");local progress=source:GetAttribute("GrowthProgress")
    task.wait(.6)
    check(a:GetAttribute("Cash")==cash and a:GetAttribute("IncomePerSecond")==0,"reclaim immediately stops income")
    check(source:GetAttribute("GrowthProgress")==progress,"stored slime's growth pauses")
    call(a,"Select",{id=id});at(a,pa:GetAttribute("EntrancePosition")+Vector3.new(0,3,0));call(a,"PenPrompt",{base=sa.base})
    check(#map.PlacedSlimes:GetChildren()==1,"selected baby can be released using the pen entrance")
    display=map.PlacedSlimes:GetChildren()[1];task.wait(6)
    check(source:GetAttribute("GrowthProgress")==1,"roaming slime finishes growing")
    check(inside(),"grown roaming slime remains inside fences")
    check(source:GetAttribute("Weight")==weight,"growth and wandering never reroll weight")
    local ui=call(a,"UIOpen")
    check(ui.noSlots and ui.pen=="PEN 1 / 6","inventory uses pen capacity instead of pad buttons")
    check(ui.cards==1 and ui.previews==1 and ui.reclaim,"roaming slime appears in inventory with reclaim control")
    check(ui.cash:sub(1,1)=="$","cash appears in the HUD")
    local before=a:GetAttribute("Cash");call(a,"GrantCash",{id="1000000000"})
    check(a:GetAttribute("Cash")-before<100,"client cannot grant itself cash")
    local function seed(i)
        local clone=source:Clone();clone.Name="Extra"..i;clone:SetAttribute("InventoryId",nil);clone:SetAttribute("Weight",i)
        clone.Parent=secured[tostring(a.UserId)];SS.Capture.SlimeSecured:Fire(a,clone,i);task.wait(.05)
        return clone:GetAttribute("InventoryId")
    end
    local extra={};for i=2,7 do extra[i]=seed(i) end
    at(a,pa.PenGrass.Position+Vector3.new(0,3,0))
    for i=2,6 do call(a,"Place",{id=extra[i]}) end
    check(#map.PlacedSlimes:GetChildren()==6,"six slimes share the open pen")
    call(a,"Place",{id=extra[7]});sa=call(a,"Snapshot")
    check(#map.PlacedSlimes:GetChildren()==6 and sa.placed==6,"full pen rejects extra releases")
    local expected=rate;for i=2,6 do expected+=require(SS.IncomeRules).Rate("Grass",i) end
    check(math.abs(a:GetAttribute("IncomePerSecond")-expected)<.001,"multiple slimes' passive income adds correctly")
    check(#call(b,"Snapshot").items==0,"other player never receives private inventory")
    a.Character.Humanoid.Health=0;local respawn=a.CharacterAdded:Wait();respawn:WaitForChild("HumanoidRootPart");task.wait(.4)
    check(#map.PlacedSlimes:GetChildren()==6 and a:GetAttribute("IncomePerSecond")>0,"pen and income survive a character reset")
    print("PEN INTEGRATION COMPLETE: "..count.." checks")
end

task.spawn(function()
    local ok,err=xpcall(run,debug.traceback)
    if not ok then warn("PEN INTEGRATION FAILED: "..err) end
    pcall(function() game:GetService("StudioTestService"):EndTest({ok=ok,error=err,checks=count}) end)
end)
