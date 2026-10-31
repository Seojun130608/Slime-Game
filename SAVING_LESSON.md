# Saving progress: three pieces

Open `Steal-A-Slime-Saving.rbxlx` for the current implementation. Cloud verification is pending by your choice. An unpublished local game displays PRACTICE and does not save between Play sessions.

## 1. A saved profile is plain data

`src/shared/ProfileSchema.lua` defines the profile. `src/server/Inventory.server.lua`, in `export`, turns the private live state into this shape:

```lua
{version=1, cash=123, rebirths=2, tokens=3,
 upgrades={Speed=2, Grabber=3},
 slimes={{id="slime-a", kind="Grass", weight=8, progress=0.5, inPen=true}}}
```

The Python equivalent is:

```python
{"version": 1, "cash": 123, "rebirths": 2, "tokens": 3,
 "upgrades": {"Speed": 2, "Grabber": 3},
 "slimes": [{"id": "slime-a", "kind": "Grass", "weight": 8,
             "progress": 0.5, "inPen": True}]}
```

Models and CFrames cannot be used as the saved profile. `SlimeCatalog.lua` supplies appearances and fixed rarities. `SlimeFactory.lua` rebuilds owned models from saved type, weight and progress. Slime IDs are retained rather than generated again. Placed slimes resume in your newly assigned pen; no offline cash or offline growth is awarded.

Check: the isolated saving test starts two players with seeded profiles. It checks one placed slime and one stored slime, including their original IDs and growth.

## 2. Network operations can fail

`src/shared/ProfileStoreCore.lua`, in `request`, wraps each backend operation:

```lua
local ok, value = pcall(function()
    return backend:UpdateAsync(key, transform, userIds)
end)
```

In Python, the corresponding idea is:

```python
try:
    value = backend.update(key, transform, user_ids)
    ok = True
except Exception as error:
    value = error
    ok = False
```

The store retries temporary failures. An unsuccessful load never becomes an empty default save. Malformed or unsupported saved profiles are rejected without overwriting them. Defaults are created only when a successful backend operation says no profile exists.

`Inventory.server.lua` blocks progress-changing actions until loading finishes. Its private cash and collection generate saves; client-provided balances are never used. Saves run every 45 seconds, on leaving, and during server shutdown. Only secured slimes are saved; an unfinished wild capture is not a collected item.

Check: injected outages verify retries and that the previous stored profile survives failures.

## 3. Only one session may save a profile

Each loaded profile gets a unique session token and a 180-second lease. Autosaving renews the lease. A different server cannot acquire it while it is active. Every save checks ownership inside `UpdateAsync`; an old server cannot overwrite a newer session. Leaving saves and releases the lease.

The decision resembles this Python condition:

```python
if saved_token != this_session_token:
    return None  # cancel the write
```

In Luau:

```lua
if old.lease.token ~= session.token then
    return nil -- cancel the write
end
```

`~=` means Python's `!=`. The callback never waits or changes live inventory, because Roblox may run it more than once.

Check: the isolated test acquires the same account from two store instances, verifies that the second is blocked, releases the first, reloads the saved progress, then confirms that the old session cannot overwrite it.

## Local mode and future cloud verification

`src/shared/ProfileStore.lua` chooses an in-memory practice backend only when Studio is running an unpublished local place (`game.GameId == 0`). This memory is discarded when Play ends. It is never presented as cloud persistence.

Published Studio testing uses `StealASlime_Profiles_Studio_v1`; a live Roblox server uses `StealASlime_Profiles_v1`. These namespaces are separate. The test fixture additionally injects a completely isolated backend and never accesses cloud player data.

Actual cloud verification requires publishing a separate private test experience and enabling Studio API access there. This was not done. See the official setup requirements: https://create.roblox.com/docs/cloud-services/data-stores

Run the native isolated test by opening `tests/Saving-Test.rbxlx` and using the edit-mode Command Bar:

```lua
task.spawn(function()
    local result=game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,"Saving")
    print(game:GetService("HttpService"):JSONEncode(result))
end)
```

Ordinary Play in that test place skips the automated test runner. Always use the root-level saving game for normal play.
