# Speed and Grabber Power: three small pieces

Open `Steal-A-Slime-Upgrades.rbxlx` in Roblox Studio. This place already contains these files; no manual pasting is needed. The scripts do not sync automatically from VS Code.

## 1. Prices and level limits

File: `src/shared/UpgradeRules.lua`, the `Cost` function. In Studio this is `ServerScriptService > UpgradeRules` (ModuleScript).

Luau:
```lua
return (kind == "Speed" and 25 or 35) * 2 ^ level
```
Python:
```python
return (25 if kind == "Speed" else 35) * 2 ** level
```

`^` means exponentiation in Luau. The `and/or` expression selects the starting price; both possible prices are truthy, so it works like this Python conditional expression. Speed prices are 25, 50, 100, 200, 400. Grabber prices are 35, 70, 140, 280, 560. Both stop at level 5.

Check: press Play, open **UPGRADES [U]**, and inspect the starting prices. Earn cash by releasing a secured slime into your own pen. Buy one upgrade; its price should double and its level should increase by one.

## 2. Buy only with enough real cash

File: `src/server/Inventory.server.lua`, directly after `snapshot`, inside `TrySpendCash`.

Luau:
```lua
if state.cash < amount then return false end
state.cash -= amount
```
Python:
```python
if state["cash"] < amount:
    return False
state["cash"] -= amount
```

`state` is a table used like a Python dictionary. The inventory script owns the private cash balance. `src/server/Upgrades.server.lua` asks its `TrySpendCash` BindableFunction to subtract the server's price, then increases the purchased level. There is no wait between checking and subtracting, so another request cannot use the same cash in the middle of that operation.

Check: with $0, try buying Speed. The message should say you need more cash, and your level should stay 0. After earning enough, buying Speed should subtract exactly the displayed price. The cash HUD and leaderboard should agree.

## 3. Turn upgrade levels into movement and capture stats

Files: `src/shared/UpgradeRules.lua` contains the formulas; `src/server/Capture.server.lua` applies them in `movement`. `src/server/Bat.server.lua` calls `RefreshMovement` after its stun finishes.

Luau:
```lua
function Rules.Speed(level) return 16 + 2 * level end
function Rules.HoldSeconds(level) return 2 / (1 + 0.15 * level) end
```
Python (using a class as a namespace):
```python
class Rules:
    @staticmethod
    def Speed(level):
        return 16 + 2 * level

    @staticmethod
    def HoldSeconds(level):
        return 2 / (1 + 0.15 * level)
```

At level 5, normal walking speed is 26, Grabber Power is 20, and pulling takes about 1.14 seconds. Carrying still slows you down, but Grabber upgrades reduce that penalty. A bat stun temporarily sets speed to 0; when it ends, the current upgraded speed is recalculated.

`src/client/Upgrades.client.lua` displays the panel and adjusts the local prompt's hold bar. The server independently measures how long the capture took, so changing a client timer cannot force an early capture.

Check: buy Speed, capture a baby, and notice the slower carrying speed. Collect or drop it; normal upgraded speed should return. Buy Grabber Power and capture again; the hold bar should finish sooner. Reset your character: levels remain for this session. Leaving the game resets them until the later Saving feature is built.

## Automated verification

`tests/UPGRADE_RESULTS.md` records 25 passing checks with two native Studio clients, including malformed purchases, client cash spoofing, level caps, faster capture timing, carrying, bat stuns, and character resets. `tests/Upgrade-Test.rbxlx` is the isolated test place; open the clean `Steal-A-Slime-Upgrades.rbxlx` to play normally.
