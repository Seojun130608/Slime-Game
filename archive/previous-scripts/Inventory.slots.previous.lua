-- Session inventory and growth. Canonical babies remain in ServerStorage.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local map = workspace:WaitForChild("SlimeMap")
local bases = map:WaitForChild("Bases")
local capture = script.Parent:WaitForChild("Capture")
local securedEvent = capture:WaitForChild("SlimeSecured")
local secured = ServerStorage:WaitForChild("SecuredSlimes")
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "SlimeInventory", RS
local displays = Instance.new("Folder")
displays.Name, displays.Parent = "PlacedSlimes", map
local GROW_SECONDS, ACTION_INTERVAL, RANGE = 12, .15, 18
local inventories, owners, lastAction, slotData = {}, {}, {}, {}

local function notice(player, message)
    if player.Parent then remote:FireClient(player, "Message", message) end
end
local function snapshot(player)
    local state = inventories[player]
    if not state then return end
    local items = {}
    for id, record in pairs(state.items) do
        table.insert(items, {
            id = id, kind = record.kind, rarity = record.rarity, weight = record.weight,
            color = record.source.PrimaryPart.Color, slot = record.slot,
            progress = math.floor(record.progress * 100 + .0001) / 100,
        })
    end
    table.sort(items, function(a,b) return a.id < b.id end)
    remote:FireClient(player, "Snapshot", {items = items, selected = state.selected, base = state.base and state.base:GetAttribute("BaseIndex")})
end
local function showBaseName(base, player)
    for _, label in ipairs(base:GetDescendants()) do
        if label:IsA("TextLabel") then label.Text = player and (player.DisplayName .. "'S BASE") or ("BASE 0" .. base:GetAttribute("BaseIndex")) end
    end
end
local function claim(player)
    local state = inventories[player]
    if not state or state.base then return end
    local sorted = bases:GetChildren()
    table.sort(sorted, function(a,b) return a:GetAttribute("BaseIndex") < b:GetAttribute("BaseIndex") end)
    for _, base in ipairs(sorted) do
        if not owners[base] then
            owners[base], state.base = player, base
            base:SetAttribute("OwnerUserId", player.UserId)
            player:SetAttribute("BaseIndex", base:GetAttribute("BaseIndex"))
            showBaseName(base, player)
            snapshot(player)
            return
        end
    end
end
local function setPrompt(base, index, occupied)
    local info = slotData[base] and slotData[base][index]
    if info then
        info.spot:SetAttribute("Occupied", occupied)
        info.prompt.ActionText = occupied and "Return slime to inventory" or "Place selected baby"
    end
end
local function positionDisplay(record, info)
    local alpha = record.progress
    local target = .8 + record.weight^(1/3) * .55
    local scale = .65 + (target - .65) * alpha
    record.display:ScaleTo(scale)
    local box, size = record.display:GetBoundingBox()
    local pivot = record.display:GetPivot()
    local bottomOffset = pivot.Position.Y - (box.Position.Y - size.Y * .5)
    local position = info.pad.Position
    record.display:PivotTo(CFrame.new(position.X, position.Y + info.pad.Size.Y * .5 + .05 + bottomOffset, position.Z) * record.rotation)
end
local function canUse(player, base, index)
    local state = inventories[player]
    local info = slotData[base] and slotData[base][index]
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return state and state.base == base and owners[base] == player and info and root and hum and hum.Health > 0
        and (root.Position - info.pad.Position).Magnitude <= RANGE
end
local function store(player, id)
    local state = inventories[player]
    local record = state and state.items[id]
    if not record or not record.slot then return false end
    if not canUse(player, state.base, record.slot) then notice(player, "Stand near this slime in your own base."); return false end
    state.slots[record.slot] = nil
    setPrompt(state.base, record.slot, false)
    record.slot = nil
    if record.display then record.display:Destroy();record.display = nil end
    record.source:SetAttribute("GrowthProgress", record.progress)
    snapshot(player)
    notice(player, "Returned to inventory. Growth resumes when placed again.")
    return true
end
local function place(player, id, index)
    local state = inventories[player]
    local record = state and state.items[id]
    if not record or record.slot then return false end
    if not state.base then notice(player, "All bases are occupied. A base will be assigned when one is free."); return false end
    if not canUse(player, state.base, index) then notice(player, "Stand near an empty spot in your own base."); return false end
    if state.slots[index] then notice(player, "That spot is occupied."); return false end
    local info = slotData[state.base][index]
    local display = record.source:Clone()
    for _, item in ipairs(display:GetDescendants()) do
        if item:IsA("ProximityPrompt") or item:IsA("Beam") or item:IsA("WeldConstraint") then item:Destroy()
        elseif item:IsA("BasePart") then item.Anchored, item.CanCollide, item.CanTouch = true, false, false end
    end
    display:SetAttribute("Weight", nil) -- Numerical weight stays in the owner's private inventory.
    display:SetAttribute("CarrierUserId", nil)
    display:SetAttribute("OwnerUserId", player.UserId)
    display:SetAttribute("InventoryId", id)
    display.Name = record.kind .. "Display_" .. string.sub(id, 1, 8)
    record.rotation = CFrame.Angles(0, state.base:GetAttribute("EntrancePosition").X < 0 and math.pi/2 or -math.pi/2, 0)
    record.display, record.slot = display, index
    state.slots[index] = id
    display.Parent = displays
    setPrompt(state.base, index, true)
    positionDisplay(record, info)
    snapshot(player)
    notice(player, record.progress >= 1 and "Slime placed." or "Baby placed! It will grow over 12 seconds.")
    return true
end
for _, base in ipairs(bases:GetChildren()) do
    slotData[base] = {}
    for _, spot in ipairs(base:WaitForChild("CollectionSpots"):GetChildren()) do
        local index = spot:GetAttribute("SlotIndex")
        local pad = spot:WaitForChild("CollectionSpot")
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name, prompt.ObjectText, prompt.ActionText = "PlacementPrompt", "Base spot " .. index, "Place selected baby"
        prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 0, 12, false
        prompt.Parent = pad
        slotData[base][index] = {spot=spot,pad=pad,prompt=prompt}
        prompt.Triggered:Connect(function(player)
            local state = inventories[player]
            if not state or not canUse(player,base,index) then notice(player,"This spot belongs to another base.");return end
            local now=os.clock()
            if now-(lastAction[player] or -math.huge)<ACTION_INTERVAL then return end
            lastAction[player]=now
            if state.slots[index] then store(player,state.slots[index])
            elseif state.selected then place(player,state.selected,index)
            else notice(player,"Open Inventory [I] and select a baby first.") end
        end)
    end
end
local function add(player, source)
    local state=inventories[player]
    local folder=secured:FindFirstChild(tostring(player.UserId))
    if not state or not folder or source.Parent~=folder or not source.PrimaryPart then return end
    local id=source:GetAttribute("InventoryId")
    if id and state.items[id] then return end
    local weight=source:GetAttribute("Weight")
    if type(weight)~="number" or weight~=weight or weight<=0 or weight==math.huge then return end
    id=HttpService:GenerateGUID(false)
    source:SetAttribute("InventoryId",id)
    source:SetAttribute("GrowthProgress",0)
    state.items[id]={source=source,weight=weight,kind=source:GetAttribute("SlimeType"),rarity=source:GetAttribute("Rarity"),progress=0}
    state.selected=state.selected or id
    snapshot(player)
end
local function setup(player)
    if inventories[player] then return end
    inventories[player]={items={},slots={}}
    claim(player)
    -- Capture may create its secured folder before or after this script.
    task.spawn(function()
        local folder=secured:WaitForChild(tostring(player.UserId),30)
        if not folder or not inventories[player] then return end
        for _, source in ipairs(folder:GetChildren()) do add(player,source) end
    end)
end
securedEvent.Event:Connect(function(player,source) add(player,source) end)
Players.PlayerAdded:Connect(setup)
for _,player in ipairs(Players:GetPlayers()) do setup(player) end
Players.PlayerRemoving:Connect(function(player)
    local state=inventories[player]
    if not state then return end
    for _,record in pairs(state.items) do if record.display then record.display:Destroy() end end
    local base=state.base
    inventories[player],lastAction[player]=nil,nil
    if base then
        owners[base]=nil;base:SetAttribute("OwnerUserId",nil);showBaseName(base,nil)
        for index in pairs(slotData[base]) do setPrompt(base,index,false) end
        for _,waiting in ipairs(Players:GetPlayers()) do if waiting~=player then claim(waiting) end end
    end
end)
remote.OnServerEvent:Connect(function(player,action,id,index)
    local state=inventories[player]
    if not state then return end
    local now=os.clock()
    if now-(lastAction[player] or -math.huge)<ACTION_INTERVAL then return end
    lastAction[player]=now
    if action=="Request" then snapshot(player);return end
    if type(id)~="string" or #id>64 or not state.items[id] then return end
    if action=="Select" then state.selected=id;snapshot(player)
    elseif action=="Store" then store(player,id)
    elseif action=="Place" and type(index)=="number" and index%1==0 and index>=1 and index<=6 then place(player,id,index) end
end)
local accumulated,sendElapsed=0,0
RunService.Heartbeat:Connect(function(dt)
    accumulated+=dt;sendElapsed+=dt
    if accumulated<.1 then return end
    local elapsed=accumulated;accumulated=0
    local send=sendElapsed>=1
    if send then sendElapsed=0 end
    for player,state in pairs(inventories) do
        local changed=false
        for _,record in pairs(state.items) do
            if record.slot and record.progress<1 then
                record.progress=math.min(1,record.progress+elapsed/GROW_SECONDS)
                record.source:SetAttribute("GrowthProgress",record.progress)
                positionDisplay(record,slotData[state.base][record.slot])
                changed=true
            end
        end
        if changed and send then snapshot(player) end
        -- Send the final 100% state even if it fell between periodic updates.
        for _,record in pairs(state.items) do
            if record.progress==1 and not record.reportedGrown then
                record.reportedGrown=true;snapshot(player)
            end
        end
    end
end)
print("Inventory ready: private weights, six owned slots, 12-second resumable growth.")
