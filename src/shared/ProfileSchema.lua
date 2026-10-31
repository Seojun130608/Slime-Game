-- Only plain data goes to DataStore: no Models, Colors, CFrames, or client balances.
local Catalog=require(script.Parent:WaitForChild("SlimeCatalog"))
local Schema={Version=1}
local function number(value,minimum,integer)
    return type(value)=="number" and value==value and value<math.huge
        and value>=minimum and (not integer or value%1==0)
end
function Schema.Default()
    return {version=1,cash=0,rebirths=0,tokens=0,upgrades={Speed=0,Grabber=0},slimes={}}
end
function Schema.Validate(data)
    if type(data)~="table" or data.version~=1 then return nil,"Unsupported profile version" end
    if not number(data.cash,0) or not number(data.rebirths,0,true) or not number(data.tokens,0,true) then
        return nil,"Invalid currency or rebirth count"
    end
    local upgrades=data.upgrades
    if type(upgrades)~="table" or not number(upgrades.Speed,0,true) or not number(upgrades.Grabber,0,true)
        or upgrades.Speed>5+data.rebirths or upgrades.Grabber>5+data.rebirths then
        return nil,"Invalid upgrades"
    end
    if type(data.slimes)~="table" then return nil,"Invalid collection" end
    local clean=Schema.Default()
    clean.cash,clean.rebirths,clean.tokens=data.cash,data.rebirths,data.tokens
    clean.upgrades={Speed=upgrades.Speed,Grabber=upgrades.Grabber}
    local ids,placed,count={ },0,0
    for key in pairs(data.slimes) do
        if not number(key,1,true) or key>#data.slimes then return nil,"Invalid collection array" end
        count+=1
    end
    if count~=#data.slimes then return nil,"Sparse collection" end
    for _,slime in ipairs(data.slimes) do
        if type(slime)~="table" or type(slime.id)~="string" or #slime.id<1 or #slime.id>64 or ids[slime.id]
            or not Catalog.Find(slime.kind) or not number(slime.weight,.000001)
            or not number(slime.progress,0) or slime.progress>1 or type(slime.inPen)~="boolean" then
            return nil,"Invalid or duplicate slime"
        end
        ids[slime.id]=true
        if slime.inPen then placed+=1 end
        table.insert(clean.slimes,{id=slime.id,kind=slime.kind,weight=slime.weight,progress=slime.progress,inPen=slime.inPen})
    end
    if placed>6 then return nil,"Saved pen exceeds capacity" end
    if data.selected~=nil and (type(data.selected)~="string" or not ids[data.selected]) then return nil,"Invalid selection" end
    clean.selected=data.selected
    return clean
end
return Schema
