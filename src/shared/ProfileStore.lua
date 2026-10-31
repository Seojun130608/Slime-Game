local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Core=require(script.Parent:WaitForChild("ProfileStoreCore"))
local Store={}
-- An unpublished local place stays playable, but never pretends to save to the cloud.
Store.Practice=RunService:IsStudio() and game.GameId==0
local backend
if Store.Practice then
    local data={}
    backend={UpdateAsync=function(_,key,transform)
        local updated=transform(data[key])
        if updated~=nil then data[key]=updated end
        return updated
    end}
else
    -- Studio testing has its own namespace, separate from live profiles.
    local name=RunService:IsStudio() and "StealASlime_Profiles_Studio_v1" or "StealASlime_Profiles_v1"
    backend=DataStoreService:GetDataStore(name)
end
local core=Core.new(backend)
function Store.Load(userId) return core.Load(userId) end
function Store.Save(session,data,release) return core.Save(session,data,release) end
return Store
