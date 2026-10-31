-- Isolated 2-player integration suite. Not packaged in the playable build.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local control=Instance.new("RemoteEvent",RS);control.Name="BatTestControl"
local ready,answers={},{}
control.OnServerEvent:Connect(function(p,id,ok,err)
    if id=="Ready" then ready[p]=true else answers[id]={p=p,ok=ok,err=err} end
end)
local sequence=0
local function action(p,name,arg)
    sequence+=1;local id=tostring(sequence)
    control:FireClient(p,id,name,arg)
    local endAt=os.clock()+9
    repeat task.wait(.03) until answers[id] or os.clock()>endAt
    local reply=answers[id];assert(reply and reply.p==p and reply.ok,"Client action "..name..": "..tostring(reply and reply.err))
    answers[id]=nil
end
local function place(p,pos,look)
    p.Character:PivotTo(CFrame.lookAt(pos,look or pos+Vector3.new(0,0,-1)))
    p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
end
local function check(ok,name) assert(ok,name);print("BAT PASS: "..name) end
local function run()
    local deadline=os.clock()+120
    repeat task.wait(.2) until #Players:GetPlayers()>=2 or os.clock()>deadline
    assert(#Players:GetPlayers()>=2,"Start Server and Clients with 2 players")
    local a,b=table.unpack(Players:GetPlayers())
    repeat task.wait(.1) until ready[a] and ready[b] or os.clock()>deadline
    assert(ready[a] and ready[b],"Clients not ready")
    for _,p in ipairs({a,b}) do
        p.Character:WaitForChild("HumanoidRootPart")
        p.Backpack:WaitForChild("Slime Bat");p.Backpack:WaitForChild("Slime Grabber")
        p:SetAttribute("GrabberPower",20)
    end
    local capture=SS:WaitForChild("Capture");capture:WaitForChild("InterruptForBat")
    local rules=require(SS.CombatRules)
    local map=workspace:WaitForChild("SlimeMap")
    local slime=map.WildSlimes:WaitForChild("GrassSlime")
    local prompt=slime.Body:WaitForChild("CapturePrompt")
    local function resetCombat()
        task.wait(1)
        for _,p in ipairs({a,b}) do p:SetAttribute("BatProtectedUntil",nil);p:SetAttribute("BatStunnedUntil",nil) end
    end
    place(a,Vector3.new(0,4,180));place(b,Vector3.new(0,4,175))
    action(a,"Bat");check(not b:GetAttribute("BatProtectedUntil"),"safe-zone attacker cannot hit")
    resetCombat();place(a,Vector3.new(0,4,121),Vector3.new(0,4,130));place(b,Vector3.new(0,4,126))
    action(a,"Bat");check(not b:GetAttribute("BatProtectedUntil"),"safe-zone victim cannot be hit across boundary")
    resetCombat();place(a,Vector3.new(0,4,90));place(b,Vector3.new(0,4,70))
    action(a,"Bat");check(not b:GetAttribute("BatProtectedUntil"),"out-of-range swing misses")
    resetCombat();place(a,Vector3.new(0,4,90));place(b,Vector3.new(0,4,95))
    action(a,"Bat");check(not b:GetAttribute("BatProtectedUntil"),"swing cannot hit behind attacker")
    resetCombat();place(a,Vector3.new(0,4,90));place(b,Vector3.new(0,4,85))
    local wall=Instance.new("Part",workspace);wall.Anchored=true;wall.Size=Vector3.new(10,10,1);wall.Position=Vector3.new(0,5,87.5)
    action(a,"Bat");check(not b:GetAttribute("BatProtectedUntil"),"wall blocks hit");wall:Destroy()
    resetCombat();place(a,Vector3.new(0,4,90));place(b,Vector3.new(0,4,85))
    local health=b.Character.Humanoid.Health
    action(a,"Bat");check((b:GetAttribute("BatProtectedUntil") or 0)>workspace:GetServerTimeNow(),"valid forward hit gives protection")
    check(b.Character.Humanoid.Health==health,"bat deals no health damage")
    local expiry=b:GetAttribute("BatProtectedUntil")
    place(b,Vector3.new(0,4,85));action(a,"Swing")
    check(b:GetAttribute("BatProtectedUntil")==expiry,"rapid repeated swing is rejected")
    task.wait(.75);place(b,Vector3.new(0,4,85));action(a,"Swing")
    check(b:GetAttribute("BatProtectedUntil")==expiry,"protection prevents another hit after swing cooldown")
    task.wait(.65);check(b.Character.Humanoid.WalkSpeed==16,"walking speed restored after impact")
    resetCombat();place(a,Vector3.new(0,4,90));place(b,Vector3.new(0,4,85));action(a,"Unequip");action(a,"Swing")
    check(not b:GetAttribute("BatProtectedUntil"),"unequipped remote cannot hit")
    -- Move a baby to the clear lane; its original nursery/home are retained.
    slime:PivotTo(CFrame.new(0,2,80))
    place(b,Vector3.new(0,4,85));place(a,Vector3.new(0,4,92))
    action(b,"Begin","GrassSlime");action(a,"Bat")
    check(not slime.Body:FindFirstChildOfClass("Beam"),"hit breaks active capture tether")
    task.wait(2.1);action(b,"Release","GrassSlime")
    check(not slime:GetAttribute("Captured"),"interrupted pull cannot finish")
    resetCombat();slime:PivotTo(CFrame.new(0,2,80));place(b,Vector3.new(0,4,85));place(a,Vector3.new(0,4,108))
    action(b,"Capture","GrassSlime")
    check(b:GetAttribute("CarryingSlime")=="GrassSlime","normal capture works")
    place(a,Vector3.new(0,4,92));place(b,Vector3.new(0,4,87))
    action(a,"Bat")
    check(not b:GetAttribute("CarryingSlime") and not slime:GetAttribute("Captured"),"hit drops carried baby")
    check(prompt.Enabled and prompt.HoldDuration==0,"dropped baby has instant pickup prompt")
    task.wait(.1);check(not b:GetAttribute("ChasedBy"),"drop ends original parent chase")
    place(a,slime.Body.Position+Vector3.new(0,3,4));action(a,"Pickup","GrassSlime")
    check(a:GetAttribute("CarryingSlime")=="GrassSlime","another player can claim dropped baby")
    task.wait(.1);check(a:GetAttribute("ChasedBy")=="GrassParent","parent retargets new carrier")
    place(b,Vector3.new(0,4,110));place(a,Vector3.new(0,4,105),Vector3.new(0,4,110));resetCombat();action(a,"Bat")
    check(not b:GetAttribute("BatProtectedUntil"),"carrying player cannot swing")
    action(a,"Drop");check(not a:GetAttribute("CarryingSlime"),"voluntary drop works")
    place(a,slime.Body.Position+Vector3.new(0,3,4));action(a,"Pickup","GrassSlime")
    check(a:GetAttribute("CarryingSlime")=="GrassSlime","original carrier can recover a drop")
    place(a,Vector3.new(0,4,126));task.wait(.5)
    check(a:GetAttribute("CollectedSlimes")==1,"stolen drop secures exactly once")
    local secured=game.ServerStorage.SecuredSlimes:FindFirstChild(tostring(a.UserId))
    local baby=secured and secured:FindFirstChild("GrassSlime")
    check(baby and type(baby:GetAttribute("Weight"))=="number","secured drop retains hidden weight")
    print("BAT INTEGRATION COMPLETE")
end
task.spawn(function()
    local ok,err=xpcall(run,debug.traceback)
    if not ok then warn("BAT INTEGRATION FAILED: "..err) end
    pcall(function() game:GetService("StudioTestService"):EndTest({ok=ok,error=err}) end)
end)
