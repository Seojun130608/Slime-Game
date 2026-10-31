# Test places are not the playable game

For normal play open `../Steal-A-Slime-Saving.rbxlx`.

The rebirth integration script runs only when invoked deliberately from the edit-mode Command Bar:

```lua
task.spawn(function()
    local result=game:GetService("StudioTestService"):ExecutePlayModeAsync("Rebirths")
    print(game:GetService("HttpService"):JSONEncode(result))
end)
```

Open `Rebirth-Test.rbxlx` first. Ordinary Play in that file now warns and skips the automatic test actions. Other historical test places still contain automated drivers; use the current root-level release to play normally.

For the saving suite, open `Saving-Test.rbxlx` and deliberately call `StudioTestService:ExecuteMultiplayerTestAsync(2,"Saving")` from a task in the edit-mode Command Bar. It uses an isolated test store, not Roblox cloud saves. See `SAVING_RESULTS.md`.
