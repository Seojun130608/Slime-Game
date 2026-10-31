# Steal a Slime — current roaming pens and passive income build

Open **Steal-A-Slime-Pens.rbxlx** in Roblox Studio and press Play. This is the active Code Class version. No VS Code syncing is configured.

## Play

- Capture babies with the Slime Grabber and bring them to the entrance COLLECT ZONE to secure them.
- Open **SLIMES [I]** (controller Y). Hover or tap a card to inspect its fixed weight and income rate.
- Stand in your assigned pen, select a baby, and choose **RELEASE INTO PEN**. You can also release the selected baby using E at the pen entrance.
- Slimes grow over 12 seconds, wander and bounce inside the fences, and automatically earn cash while placed. Each pen holds six slimes sharing the same open space.
- There are no individual collection pads or display slots, and no need to walk over anything to collect income.
- Select an active slime and choose **RETURN TO INVENTORY**, or press E near the roaming slime. Storing pauses growth and stops that slime's income immediately.
- Releasing a stored slime resumes growth without changing its weight.
- The existing bat, safe zones, dropped-baby recovery, and parent chases remain available. Q / controller B / the touch Drop Baby button puts down a captured baby before fighting.

## Income

Every placed slime earns automatically, including growing babies. Rates use its type and captured weight: base rate × weight^0.6, rounded to cents per second. Base rates are Grass 1, Mud 2, Water 4, Honey 8, Crystal 16, and Gold 32. Adjust `IncomeRules.lua` to balance them.

Cash and income-per-second appear in the HUD; the leaderboard shows whole cash. The server tracks time and pays the owner directly. Stored slimes earn nothing. Other clients cannot grant cash or manipulate weights.

Pen ownership, growth, inventory, and cash survive character resets during the session. Saving between sessions is a later feature. Next PRD feature: purchasable Speed and Grabber Power upgrades.

## Files and verification

- `Steal-A-Slime-Pens.rbxlx`: clean playable place with the original map geometry and base pads removed.
- `Steal-A-Slime-Growth.rbxl`: preserved previous milestone.
- `Inventory.server.lua`: pen ownership, roaming, growth, storage and cash accrual.
- `Inventory.client.lua`: inventory, pen release/reclaim controls and cash HUD.
- `IncomeRules.lua`: server income formula and type rates.
- `Grassland.server.lua`: map generator with shared pens instead of pads.
- `Install-Pens.commandbar.lua`: optional edit-mode installer for an existing place; not a live sync service.
- `tests/PEN_RESULTS.md`: 32 passing native two-player integration checks.
- `tests/Pen-Test.rbxlx`: isolated automated test place; never publish its test drivers.
- `tools/build_place.py`: regenerates the clean XML place from current sources and the earlier map template.

The exported place was checked for six pens, zero base collection pads, exact source parity, valid object references, and absence of test controls.
