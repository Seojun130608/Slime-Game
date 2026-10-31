-- Private session inventory, roaming pens, growth, and automatic server-paid income.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Storage=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Income=require(script.Parent:WaitForChild("IncomeRules"))
local map=workspace:WaitForChild("SlimeMap")
local bases=map:WaitForChild("Bases")
local capture=script.Parent:WaitForChild("Capture")
local securedEvent=capture:WaitForChild("SlimeSecured")
local secured=Storage:WaitForChild("SecuredSlimes")
local remote=Instance.new("RemoteEvent",RS);remote.Name="SlimeInventory"
local displays=Instance.new("Folder",map);displays.Name="PlacedSlimes"
local GROW_SECONDS,CAPACITY,ACTION_INTERVAL=12,6,.15
local states,owners,lastAction={}, {}, {}
local random=Random.new()
local function notice(p,message) if p.Parent then remote:FireClient(p,"Message",message) end end
local function rate(state)
    local total=0
    for _,record in pairs(state.items) do if record.inPen then total+=Income.Rate(record.kind,record.weight) end end
    return total
end
local function settle(player,state)
    local now=os.clock()
    state.cash+=(now-state.lastPaid)*rate(state)
    state.lastPaid=now
    local earned=rate(state)
    player:SetAttribute("Cash",math.floor(state.cash*100+.0001)/100)
    player:SetAttribute("IncomePerSecond",earned)
    state.cashValue.Value=math.floor(state.cash)
end
local function snapshot(p)
    local state=states[p];if not state then return end
    local items={};local count=0
    for id,r in pairs(state.items) do
        if r.inPen then count+=1 end
        table.insert(items,{id=id,kind=r.kind,rarity=r.rarity,weight=r.weight,color=r.source.PrimaryPart.Color,
            inPen=r.inPen==true,progress=math.floor(r.progress*100+.0001)/100,rate=Income.Rate(r.kind,r.weight)})
    end
    table.sort(items,function(a,b)return a.id<b.id end)
    remote:FireClient(p,"Snapshot",{items=items,selected=state.selected,base=state.base and state.base:GetAttribute("BaseIndex"),
        capacity=CAPACITY,placed=count,cash=state.cash,income=rate(state)})
end
local function showBaseName(base,p)
    for _,label in ipairs(base:GetDescendants()) do
        if label:IsA("TextLabel") then label.Text=p and (p.DisplayName.."'S PEN") or ("PEN 0"..base:GetAttribute("BaseIndex")) end
    end
end
local function claim(p)
    local state=states[p];if not state or state.base then return end
    local sorted=bases:GetChildren()
    table.sort(sorted,function(a,b)return a:GetAttribute("BaseIndex")<b:GetAttribute("BaseIndex") end)
    for _,base in ipairs(sorted) do
        if not owners[base] then
            owners[base],state.base=p,base;base:SetAttribute("OwnerUserId",p.UserId)
            p:SetAttribute("BaseIndex",base:GetAttribute("BaseIndex"));showBaseName(base,p);snapshot(p);return
        end
    end
end
local function canUse(p,base)
    local state=states[p];local c=p.Character
    local root=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
    if not state or not base or state.base~=base or owners[base]~=p or not root or not hum or hum.Health<=0 then return false end
    local grass=base.PenGrass;local position=grass.CFrame:PointToObjectSpace(root.Position)
    return math.abs(position.X)<=grass.Size.X*.5+4 and math.abs(position.Z)<=grass.Size.Z*.5+4 and math.abs(position.Y)<=12
end
local function bounds(state,r)
    local grass=state.base.PenGrass
    return grass.Position,grass.Size.X*.5-r.radius,grass.Size.Z*.5-r.radius
end
local function target(state,r)
    local center,hx,hz=bounds(state,r)
    local best,bestDistance
    for _=1,16 do
        local point=Vector3.new(center.X+random:NextNumber(-hx,hx),0,center.Z+random:NextNumber(-hz,hz))
        local distance=math.huge
        for _,other in pairs(state.items) do
            if other~=r and other.inPen and other.position then distance=math.min(distance,(point-other.position).Magnitude-other.radius-r.radius) end
        end
        if not bestDistance or distance>bestDistance then best,bestDistance=point,distance end
        if distance>1 then return point end
    end
    return best
end
local function updateDisplay(state,r)
    local scale=.65+(r.targetScale-.65)*r.progress
    r.display:ScaleTo(scale)
    local box,size=r.display:GetBoundingBox()
    local offset=r.display:GetPivot().Position.Y-(box.Position.Y-size.Y*.5)
    local grass=state.base.PenGrass
    local bounce=math.abs(math.sin(r.phase))*(r.moving and .28 or .035)
    r.display:PivotTo(CFrame.new(r.position.X,grass.Position.Y+grass.Size.Y*.5+.05+offset+bounce,r.position.Z)*r.rotation)
end
local function store(p,id)
    local state=states[p];local r=state and state.items[id]
    if not r or not r.inPen then return false end
    if not canUse(p,state.base) then notice(p,"Stand in your own pen to bring a slime back.");return false end
    settle(p,state);r.inPen=false
    if r.display then r.display:Destroy();r.display=nil end
    r.source:SetAttribute("GrowthProgress",r.progress)
    settle(p,state);snapshot(p);notice(p,"Returned to inventory. Stored slimes do not earn cash.")
    return true
end
local function place(p,id)
    local state=states[p];local r=state and state.items[id]
    if not r or r.inPen then return false end
    if not state.base then notice(p,"Waiting for an available pen.");return false end
    if not canUse(p,state.base) then notice(p,"Stand in your own pen to release a slime.");return false end
    local count=0;for _,other in pairs(state.items) do if other.inPen then count+=1 end end
    if count>=CAPACITY then notice(p,"Your pen is full (6 slimes). Return one to inventory first.");return false end
    settle(p,state)
    local display=r.source:Clone()
    for _,item in ipairs(display:GetDescendants()) do
        if item:IsA("ProximityPrompt") or item:IsA("Beam") or item:IsA("WeldConstraint") then item:Destroy()
        elseif item:IsA("BasePart") then item.Anchored,item.CanCollide,item.CanTouch=true,false,false end
    end
    display:SetAttribute("Weight",nil);display:SetAttribute("GrowthProgress",nil);display:SetAttribute("CarrierUserId",nil)
    display:SetAttribute("OwnerUserId",p.UserId);display:SetAttribute("InventoryId",id)
    display.Name=r.kind.."Pen_"..string.sub(id,1,8)
    r.targetScale=.8+r.weight^(1/3)*.55
    local size=r.source:GetExtentsSize()
    -- Reserve adult-sized margins so a growing slime cannot poke through fences.
    r.radius=math.min(math.max(size.X,size.Z)*r.targetScale*.5+.8,11)
    r.display,r.inPen=display,true;r.position=target(state,r);r.goal=target(state,r)
    r.rotation=CFrame.identity;r.pauseUntil=0;r.phase=random:NextNumber(0,math.pi*2);r.blocked=0
    display.Parent=displays
    local prompt=Instance.new("ProximityPrompt",display.PrimaryPart)
    prompt.Name,prompt.ActionText,prompt.ObjectText="StoreSlime","Return to inventory",r.kind.." Slime"
    prompt.MaxActivationDistance,prompt.HoldDuration,prompt.RequiresLineOfSight=12,0,false
    prompt.Triggered:Connect(function(who)
        if who==p and who.Character and (who.Character:GetPivot().Position-display:GetPivot().Position).Magnitude<=16 then store(who,id) end
    end)
    updateDisplay(state,r);settle(p,state);snapshot(p)
    notice(p,"Slime released! Cash is added automatically while it is in your pen.")
    return true
end
for _,base in ipairs(bases:GetChildren()) do
    -- Also migrate map geometry saved by previous versions.
    local pads=base:FindFirstChild("CollectionSpots");if pads then pads:Destroy() end
    base:SetAttribute("PenCapacity",CAPACITY)
    local anchor=Instance.new("Part")
    anchor.Name="PenEntrance";anchor.Size=Vector3.new(1,1,1)
    anchor.Position=base:GetAttribute("EntrancePosition")+Vector3.new(0,3,0)
    anchor.Anchored,anchor.Transparency,anchor.CanCollide,anchor.CanTouch,anchor.CanQuery=true,1,false,false,false
    anchor.Parent=base
    local prompt=Instance.new("ProximityPrompt",anchor)
    prompt.Name,prompt.ActionText,prompt.ObjectText="PenPrompt","Release selected slime","Slime pen"
    prompt.MaxActivationDistance,prompt.HoldDuration,prompt.RequiresLineOfSight=12,0,false
    prompt.Triggered:Connect(function(p)
        local state=states[p]
        if not state or state.base~=base then notice(p,"This is another player's pen.");return end
        if os.clock()-(lastAction[p] or -math.huge)<ACTION_INTERVAL then return end
        lastAction[p]=os.clock()
        if state.selected then place(p,state.selected) else notice(p,"Open Slimes [I] and select a baby first.") end
    end)
end
local function add(p,source)
    local state=states[p];local folder=secured:FindFirstChild(tostring(p.UserId))
    if not state or not folder or source.Parent~=folder or not source.PrimaryPart then return end
    local id=source:GetAttribute("InventoryId");if id and state.items[id] then return end
    local weight=source:GetAttribute("Weight")
    if type(weight)~="number" or weight~=weight or weight<=0 or weight==math.huge then return end
    id=HttpService:GenerateGUID(false);source:SetAttribute("InventoryId",id);source:SetAttribute("GrowthProgress",0)
    state.items[id]={source=source,weight=weight,kind=source:GetAttribute("SlimeType"),rarity=source:GetAttribute("Rarity"),progress=0}
    state.selected=state.selected or id;snapshot(p)
end
local function setup(p)
    if states[p] then return end
    local stats=p:FindFirstChild("leaderstats") or Instance.new("Folder",p);stats.Name="leaderstats"
    local cash=Instance.new("IntValue",stats);cash.Name="Cash"
    states[p]={items={},cash=0,lastPaid=os.clock(),cashValue=cash}
    settle(p,states[p]);claim(p)
    task.spawn(function()
        local folder=secured:WaitForChild(tostring(p.UserId),30)
        if folder and states[p] then for _,source in ipairs(folder:GetChildren()) do add(p,source) end end
    end)
end
securedEvent.Event:Connect(add)
Players.PlayerAdded:Connect(setup)
for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerRemoving:Connect(function(p)
    local state=states[p];if not state then return end
    for _,r in pairs(state.items) do if r.display then r.display:Destroy() end end
    local base=state.base;states[p],lastAction[p]=nil,nil
    if base then
        owners[base]=nil;base:SetAttribute("OwnerUserId",nil);showBaseName(base,nil)
        for _,waiting in ipairs(Players:GetPlayers()) do if waiting~=p then claim(waiting) end end
    end
end)
remote.OnServerEvent:Connect(function(p,action,id)
    local state=states[p];if not state then return end
    if os.clock()-(lastAction[p] or -math.huge)<ACTION_INTERVAL then return end
    lastAction[p]=os.clock()
    if action=="Request" then settle(p,state);snapshot(p);return end
    if type(id)~="string" or #id>64 or not state.items[id] then return end
    if action=="Select" then state.selected=id;snapshot(p)
    elseif action=="Store" then store(p,id)
    elseif action=="Place" then place(p,id) end
end)
local elapsed,sendElapsed=0,0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;sendElapsed+=dt;if elapsed<.1 then return end
    local step=elapsed;elapsed=0;local send=sendElapsed>=1;if send then sendElapsed=0 end
    local now=os.clock()
    for p,state in pairs(states) do
        settle(p,state)
        for _,r in pairs(state.items) do
            if r.inPen then
                r.progress=math.min(1,r.progress+step/GROW_SECONDS);r.source:SetAttribute("GrowthProgress",r.progress)
                local delta=r.goal-r.position;r.moving=false
                if now>=r.pauseUntil then
                    if delta.Magnitude<.5 then
                        r.pauseUntil=now+random:NextNumber(.5,1.6);r.goal=target(state,r)
                    else
                        local candidate=r.position+delta.Unit*math.min(delta.Magnitude,2.6*math.min(step,.25))
                        local clear=true
                        for _,other in pairs(state.items) do
                            if other~=r and other.inPen and other.position and (candidate-other.position).Magnitude<(r.radius+other.radius)*.8 then clear=false;break end
                        end
                        if clear then r.position=candidate;r.rotation=r.rotation:Lerp(CFrame.lookAt(Vector3.zero,-delta.Unit),.3);r.moving=true;r.blocked=0
                        else r.blocked+=step;if r.blocked>1 then r.goal=target(state,r);r.blocked=0 end end
                    end
                end
                local center,hx,hz=bounds(state,r)
                r.position=Vector3.new(math.clamp(r.position.X,center.X-hx,center.X+hx),0,math.clamp(r.position.Z,center.Z-hz,center.Z+hz))
                r.phase+=step*(r.moving and 7 or 2);updateDisplay(state,r)
            end
        end
        if send then snapshot(p) end
    end
end)
print("Pens ready: roaming slimes, automatic income, no collection pads.")
