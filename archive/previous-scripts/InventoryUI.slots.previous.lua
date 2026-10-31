local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("SlimeInventory")
local state={items={}}
local currentDetail
local rarityColors={Common=Color3.fromRGB(182,191,180),Uncommon=Color3.fromRGB(107,226,69),Rare=Color3.fromRGB(57,187,255),Epic=Color3.fromRGB(190,116,255),Legendary=Color3.fromRGB(255,189,46)}
local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn="SlimeInventoryUI",false
gui.Parent=player:WaitForChild("PlayerGui")
local function rounded(o,r) local c=Instance.new("UICorner",o);c.CornerRadius=UDim.new(0,r) end
local function border(o,color,width) local s=Instance.new("UIStroke",o);s.Color=color;s.Thickness=width;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end
local function label(parent,name,text,pos,size,fontSize)
    local l=Instance.new("TextLabel")
    l.Name,l.Text,l.Position,l.Size=name,text,pos,size
    l.BackgroundTransparency=1;l.Font=Enum.Font.GothamBold;l.TextSize=fontSize
    l.TextColor3=Color3.fromRGB(246,255,233);l.TextWrapped=true;l.Parent=parent
    return l
end
local function button(parent,name,text,pos,size,color)
    local b=Instance.new("TextButton")
    b.Name,b.Text,b.Position,b.Size=name,text,pos,size
    b.BackgroundColor3=color;b.Font=Enum.Font.GothamBlack;b.TextSize=17
    b.TextColor3=Color3.new(1,1,1);b.TextStrokeTransparency=.25;b.Parent=parent
    rounded(b,8);border(b,Color3.fromRGB(20,43,31),2)
    return b
end
local open=button(gui,"OpenInventory","SLIMES  [I]",UDim2.new(0,16,.48,0),UDim2.fromOffset(174,58),Color3.fromRGB(38,191,226))
local panel=Instance.new("Frame",gui)
panel.Name="Panel";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.48)
panel.Size=UDim2.fromOffset(890,590);panel.BackgroundColor3=Color3.fromRGB(35,63,47);panel.Visible=false
rounded(panel,14);border(panel,Color3.fromRGB(147,236,45),3)
local max=Instance.new("UISizeConstraint",panel);max.MaxSize=Vector2.new(890,590)
local title=label(panel,"Heading","YOUR SLIMES",UDim2.fromOffset(16,10),UDim2.new(1,-80,0,32),25)
title.TextXAlignment=Enum.TextXAlignment.Left
local close=button(panel,"Close","X",UDim2.new(1,-49,0,11),UDim2.fromOffset(34,32),Color3.fromRGB(237,84,97))
local instructions=label(panel,"Instructions","Select a baby, then stand at your base and choose a spot. Hover or tap a card to inspect its weight.",UDim2.fromOffset(16,49),UDim2.new(1,-32,0,39),13)
local list=Instance.new("ScrollingFrame",panel)
list.Name="Items";list.Position=UDim2.new(0,16,0,100);list.Size=UDim2.new(.61,-24,1,-116)
list.BackgroundColor3=Color3.fromRGB(26,48,37);list.BorderSizePixel=0;list.ScrollBarThickness=5
list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new()
rounded(list,8)
local grid=Instance.new("UIGridLayout",list)
grid.CellSize=UDim2.new(.5,-7,0,150);grid.CellPadding=UDim2.fromOffset(6,8)
local padding=Instance.new("UIPadding",list);padding.PaddingTop=UDim.new(0,6);padding.PaddingLeft=UDim.new(0,5)
local info=Instance.new("Frame",panel)
info.Name="Details";info.BackgroundTransparency=1;info.Position=UDim2.new(.61,2,0,99);info.Size=UDim2.new(.39,-18,1,-112)
local base=label(info,"Base","ASSIGNING BASE...",UDim2.new(),UDim2.new(1,0,0,30),18)
local detail=label(info,"WeightDetails","Your secured babies appear here. Stored babies remain small until placed.",UDim2.fromOffset(0,39),UDim2.new(1,0,0,111),15)
local spotTitle=label(info,"SpotTitle","BASE SPOTS",UDim2.fromOffset(0,153),UDim2.new(1,0,0,26),16)
local slots=Instance.new("Frame",info)
slots.Name="Slots";slots.Position=UDim2.fromOffset(0,185);slots.Size=UDim2.new(1,0,0,142);slots.BackgroundTransparency=1
local slotButtons={}
for i=1,6 do
    local b=button(slots,"Slot"..i,"SPOT "..i,UDim2.new(((i-1)%2)*.5,2,0,math.floor((i-1)/2)*46),UDim2.new(.5,-5,0,39),Color3.fromRGB(78,147,65))
    b.TextSize=12;slotButtons[i]=b
    b.Activated:Connect(function()
        local occupied
        for _,item in ipairs(state.items) do if item.slot==i then occupied=item;break end end
        if occupied then remote:FireServer("Store",occupied.id)
        elseif state.selected then remote:FireServer("Place",state.selected,i)
        else detail.Text="Select a baby from your inventory first." end
    end)
end
local message=label(gui,"Notice","",UDim2.new(.15,0,.12,0),UDim2.new(.7,0,0,48),18)
message.BackgroundColor3=Color3.fromRGB(35,63,47);message.BackgroundTransparency=.08;message.Visible=false;rounded(message,10)
local function describe(item)
    currentDetail=item.id
    local status=item.slot and (item.progress>=1 and "Fully grown · Spot "..item.slot or "Growing: "..math.floor(item.progress*100).."% · Spot "..item.slot)
        or (item.progress>0 and "Stored · Growth paused" or "Stored baby · Not growing yet")
    detail.Text=string.format("%s Slime\n%s  ·  %.2f kg\n%s",item.kind,item.rarity,item.weight,status)
end
local function preview(card,item)
    local viewport=Instance.new("ViewportFrame",card)
    viewport.Position=UDim2.fromOffset(4,4);viewport.Size=UDim2.new(1,-8,0,87);viewport.BackgroundTransparency=1
    viewport.Ambient=Color3.fromRGB(210,220,210);viewport.LightColor=Color3.new(1,1,1)
    local model=Instance.new("WorldModel",viewport)
    local function ball(pos,size,color)
        local p=Instance.new("Part",model);p.Shape=Enum.PartType.Ball;p.Anchored=true
        p.Position,p.Size,p.Color=pos,size,color;p.Material=Enum.Material.SmoothPlastic
    end
    ball(Vector3.new(0,0,0),Vector3.new(4,3,4),item.color)
    for _,x in ipairs({-.65,.65}) do ball(Vector3.new(x,.55,-1.78),Vector3.new(.28,.4,.16),Color3.fromRGB(20,20,25)) end
    ball(Vector3.new(0,.15,-1.98),Vector3.new(.4,.18,.16),Color3.fromRGB(20,20,25))
    local camera=Instance.new("Camera",viewport)
    camera.CFrame=CFrame.lookAt(Vector3.new(0,2,-8),Vector3.zero);camera.FieldOfView=40;viewport.CurrentCamera=camera
end
local function render()
    local oldScroll=list.CanvasPosition
    for _,child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    base.Text=state.base and ("YOUR BASE 0"..state.base) or "WAITING FOR A BASE"
    if #state.items==0 then
        local empty=label(list,"Empty","Capture a baby and bring it to the COLLECT ZONE.",UDim2.new(),UDim2.fromOffset(200,150),17)
        empty.LayoutOrder=0
    end
    local selectedInfo
    for i,item in ipairs(state.items) do
        local card=Instance.new("TextButton",list)
        card.Name="Item_"..item.id;card.Size=UDim2.fromOffset(170,150);card.Text=""
        card.BackgroundColor3=Color3.fromRGB(63,89,66);card.LayoutOrder=i;rounded(card,9)
        border(card,item.id==state.selected and Color3.fromRGB(179,255,60) or (rarityColors[item.rarity] or Color3.new(1,1,1)),item.id==state.selected and 3 or 2)
        preview(card,item)
        label(card,"SlimeName",item.kind,UDim2.fromOffset(4,91),UDim2.new(1,-8,0,20),16)
        local status=item.slot and (item.progress>=1 and "GROWN" or "GROWING "..math.floor(item.progress*100).."%") or "IN INVENTORY"
        label(card,"Status",item.rarity.." · "..status,UDim2.fromOffset(4,116),UDim2.new(1,-8,0,28),10)
        card.MouseEnter:Connect(function() describe(item) end)
        card.Activated:Connect(function() describe(item);remote:FireServer("Select",item.id) end)
        if item.id==currentDetail then selectedInfo=item end
    end
    if selectedInfo then describe(selectedInfo) end
    for i,b in ipairs(slotButtons) do
        local occupied
        for _,item in ipairs(state.items) do if item.slot==i then occupied=item;break end end
        b.Text=occupied and (i.." · "..occupied.kind.."\nSTORE") or ("SPOT "..i.."\nPLACE")
        b.BackgroundColor3=occupied and Color3.fromRGB(46,157,192) or Color3.fromRGB(78,147,65)
    end
    list.CanvasPosition=oldScroll
end
local function toggle()
    panel.Visible=not panel.Visible
    if panel.Visible then render();remote:FireServer("Request") end
end
open.Activated:Connect(toggle)
close.Activated:Connect(function() panel.Visible=false end)
UIS.InputBegan:Connect(function(input,processed)
    if not processed and (input.KeyCode==Enum.KeyCode.I or input.KeyCode==Enum.KeyCode.ButtonY) then toggle() end
end)
local version=0
remote.OnClientEvent:Connect(function(kind,data)
    if kind=="Snapshot" then
        state=data
        open.Text="SLIMES ("..#state.items..")  [I]"
        if panel.Visible then render() end
    elseif kind=="Message" then
        version+=1;local this=version
        message.Text,message.Visible=data,true
        task.delay(3,function() if this==version then message.Visible=false end end)
    end
end)
remote:FireServer("Request")

local uiScale=Instance.new("UIScale",panel)
local viewportConnection
local function bindViewport()
    if viewportConnection then viewportConnection:Disconnect() end
    local camera=workspace.CurrentCamera
    if not camera then return end
    local function fit()
        local size=camera.ViewportSize
        uiScale.Scale=math.min(1,(size.X-24)/890,(size.Y*.78)/590)
    end
    viewportConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
    fit()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)
bindViewport()
