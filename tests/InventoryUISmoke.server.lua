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
    local deadline=os.clock()+90
    repeat task.wait(.2) until #Players:GetPlayers()>=2 or os.clock()>deadline
    local a,b=table.unpack(Players:GetPlayers())
    repeat task.wait(.1) until ready[a] and ready[b] or os.clock()>deadline
    assert(ready[a] and ready[b],"Clients not ready")
    local map=workspace:WaitForChild("SlimeMap")
    local secured=Storage:WaitForChild("SecuredSlimes"):WaitForChild(tostring(a.UserId))
    local clone=map.WildSlimes:WaitForChild("GrassSlime"):Clone()
    clone:SetAttribute("Weight",12.75);clone:SetAttribute("Secured",true);clone.Parent=secured
    SS.Capture:WaitForChild("SlimeSecured"):Fire(a,clone,12.75);task.wait(.25)
    local first=call(a,"UIOpen")
    check(first.cards==1 and first.previews==1,"inventory cards and 3D slime previews render")
    check(first.base:find("YOUR BASE")~=nil,"inventory shows the assigned base")
    check(call(b,"UIOpen").cards==0,"other client's open UI remains empty")
    print("INVENTORY UI SMOKE COMPLETE")
end

task.spawn(function()
    local ok,err=xpcall(run,debug.traceback)
    if not ok then warn("INVENTORY INTEGRATION FAILED: "..err) end
    pcall(function() game:GetService("StudioTestService"):EndTest({ok=ok,error=err,checks=count}) end)
end)
