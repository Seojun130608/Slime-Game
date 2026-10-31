-- Run with the native engine; no live DataStore access.
return function()
 local SS=game:GetService("ServerScriptService")
 local Core=require(SS.ProfileStoreCore)
 local Schema=require(SS.ProfileSchema)
 local Http=game:GetService("HttpService")
 local function copy(v) return v and Http:JSONDecode(Http:JSONEncode(v)) end
 local data,fail,replays,calls={},0,false,0
 local backend={UpdateAsync=function(_,key,transform)
  calls+=1
  if fail>0 then fail-=1;error("Injected DataStore outage") end
  local old=copy(data[key])
  if replays then transform(copy(old)) end
  local new=transform(old)
  if new~=nil then data[key]=copy(new) end
  return copy(new)
 end}
 local now=1000
 local options={clock=function() return now end,pause=function() end,leaseSeconds=180}
 local a,b=Core.new(backend,options),Core.new(backend,options)
 local count=0
 local function check(ok,label) assert(ok,label);count+=1;print("SAVING CORE PASS: "..label) end
 local session=assert(a.Load(101))
 check(session.profile.cash==0 and #session.profile.slimes==0,"new account defaults")
 check(not b.Load(101),"another server cannot load an active profile")
 check(not a.Load(101),"same server cannot acquire a second overlapping session")
 local profile=Schema.Default();profile.cash=123.45;profile.rebirths=2;profile.tokens=4
 profile.upgrades={Speed=6,Grabber=3};profile.selected="saved-a"
 profile.slimes={{id="saved-a",kind="Gold",weight=17,progress=.6,inPen=true},{id="saved-b",kind="Mud",weight=4,progress=.2,inPen=false}}
 replays=true
 check(a.Save(session,profile,false),"autosave succeeds when UpdateAsync retries its callback")
 check(data.Player_101.profile.slimes[1].weight==17 and data.Player_101.profile.cash==123.45,"cash weights and growth stored as plain data")
 fail=2;local before=calls
 check(a.Save(session,profile,false) and calls-before==3,"temporary backend failures retry")
 local changed=copy(profile);changed.cash=777;fail=3
 check(not a.Save(session,changed,false) and data.Player_101.profile.cash==123.45,"failed save preserves last stored profile")
 local invalid=copy(profile);invalid.cash=0/0
 check(not a.Save(session,invalid,false),"NaN cannot enter saved profile")
 invalid=copy(profile);invalid.slimes[2].id=invalid.slimes[1].id
 check(not Schema.Validate(invalid),"duplicate slime IDs rejected")
 invalid=copy(profile);invalid.version=99
 check(not Schema.Validate(invalid),"unknown profile version rejected")
 check(a.Save(session,profile,true),"leaving saves and releases session lock")
 local loaded=assert(b.Load(101))
 check(loaded.profile.cash==123.45 and loaded.profile.rebirths==2 and loaded.profile.tokens==4,"fresh session restores currency rebirths and tokens")
 check(loaded.profile.upgrades.Speed==6 and loaded.profile.upgrades.Grabber==3,"fresh session restores upgrade levels")
 check(loaded.profile.slimes[1].id=="saved-a" and loaded.profile.slimes[1].progress==.6 and loaded.profile.slimes[1].inPen,"fresh session restores IDs growth and placement")
 check(not a.Save(session,changed,false),"closed session cannot overwrite a new session")
 now+=181
 local takeover=assert(a.Load(101))
 check(not b.Save(loaded,changed,false),"expired old session cannot overwrite takeover")
 check(a.Save(takeover,profile,true),"takeover saves with its own lease")
 data.Player_202={format=1,profile={version=99}}
 check(not a.Load(202) and data.Player_202.profile.version==99,"bad existing data never replaced with defaults")
 fail=3;check(not a.Load(303) and data.Player_303==nil,"load outage never creates an empty save")
 print("SAVING CORE COMPLETE: "..count)
 return count
end
