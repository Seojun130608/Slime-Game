-- Injecting the backend lets the same save code be tested without real player data.
local Schema=require(script.Parent:WaitForChild("ProfileSchema"))
local HttpService=game:GetService("HttpService")
local Core={}
function Core.new(backend,options)
    options=options or {}
    local clock=options.clock or os.time
    local pause=options.pause or task.wait
    local token=options.token or HttpService:GenerateGUID(false)
    local leaseSeconds=options.leaseSeconds or 180
    local api={}
    local function request(key,transform,userId)
        local lastError
        for attempt=1,3 do
            local ok,value=pcall(function() return backend:UpdateAsync(key,transform,userId>0 and {userId} or {}) end)
            if ok then return true,value end
            lastError=tostring(value)
            if attempt<3 then pause(attempt) end
        end
        return false,lastError
    end
    function api.Load(userId)
        local key="Player_"..tostring(userId)
        local ownerToken=token..":"..HttpService:GenerateGUID(false)
        local reason
        local ok,envelope=request(key,function(old)
            reason=nil
            local profile
            if old==nil then profile=Schema.Default()
            elseif type(old)~="table" or old.format~=1 then reason="Unsupported save format";return nil
            else
                local err;profile,err=Schema.Validate(old.profile)
                if not profile then reason=err;return nil end
                local lease=old.lease
                if lease~=nil and (type(lease)~="table" or type(lease.token)~="string" or type(lease.expires)~="number" or lease.expires~=lease.expires or lease.expires==math.huge) then
                    reason="Invalid session lease";return nil
                end
                if lease and lease.token~=ownerToken and lease.expires>clock() then reason="Profile is in use by another server";return nil end
            end
            return {format=1,profile=profile,lease={token=ownerToken,expires=clock()+leaseSeconds}}
        end,userId)
        if not ok then return nil,"Load failed: "..tostring(envelope) end
        if not envelope then return nil,reason or "Load cancelled" end
        return {userId=userId,key=key,token=ownerToken,expires=envelope.lease.expires,profile=envelope.profile}
    end
    function api.Save(session,data,release)
        if session.closed then return false,"Session already closed" end
        local deadline=os.clock()+20
        while session.busy and os.clock()<deadline do pause(.05) end
        if session.busy then return false,"Save still in progress" end
        if session.closed then return false,"Session already closed" end
        local clean,err=Schema.Validate(data)
        if not clean then return false,err end
        local encodedOk,encoded=pcall(function() return HttpService:JSONEncode(clean) end)
        if not encodedOk or #encoded>3900000 then return false,"Profile exceeds save size or cannot be encoded" end
        session.busy=true
        local reason
        local ok,result=request(session.key,function(old)
            reason=nil
            if type(old)~="table" or old.format~=1 or type(old.lease)~="table"
                or old.lease.token~=session.token or type(old.lease.expires)~="number" or old.lease.expires<=clock() then
                reason="Session ownership lost";return nil
            end
            return {format=1,profile=clean,lease=not release and {token=session.token,expires=clock()+leaseSeconds} or nil}
        end,session.userId)
        session.busy=false
        if not ok then return false,"Save failed: "..tostring(result) end
        if not result then return false,reason or "Save cancelled" end
        session.profile=clean
        session.expires=release and 0 or result.lease.expires
        session.closed=release==true
        return true
    end
    return api
end
return Core
