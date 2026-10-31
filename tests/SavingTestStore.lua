-- TEST-ONLY backend: preloads a profile and exposes recorded writes to integration checks.
local Core=require(script.Parent.ProfileStoreCore)
local Schema=require(script.Parent.ProfileSchema)
local Http=game:GetService("HttpService")
local data={}
local function copy(v) return v and Http:JSONDecode(Http:JSONEncode(v)) end
local backend={UpdateAsync=function(_,key,transform)
 task.wait(.02)
 local old=copy(data[key]);transform(copy(old)) -- Check replay-safe callbacks.
 local new=transform(old)
 if new~=nil then data[key]=copy(new) end
 return copy(new)
end}
local core=Core.new(backend)
local Store={Practice=true,TestData=data}
function Store.Load(userId)
 local key="Player_"..tostring(userId)
 if not data[key] then
  local p=Schema.Default();p.cash=2222;p.rebirths=2;p.tokens=3;p.upgrades={Speed=2,Grabber=3};p.selected="placed-id"
  p.slimes={{id="placed-id",kind="Gold",weight=17,progress=.4,inPen=true},{id="stored-id",kind="Water",weight=5,progress=.25,inPen=false}}
  data[key]={format=1,profile=p}
 end
 task.wait(.5) -- Deliberately let the client arrive before data is ready.
 return core.Load(userId)
end
function Store.Save(session,profile,release) return core.Save(session,profile,release) end
return Store
