# Steal a Slime — current upgrades build

Open **Steal-A-Slime-Upgrades.rbxlx** in Roblox Studio and press Play. This is the active Code Class version. No VS Code syncing is configured.

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

Every placed slime earns automatically, including growing babies. Rates use its type and captured weight: base rate × weight^0.6, rounded to cents per second. Base rates are Grass 1, Mud 2, Water 4, Honey 8, Crystal 16, and Gold 32. Adjust `src/shared/IncomeRules.lua` to balance them.

Cash and income-per-second appear in the HUD; the leaderboard shows whole cash. The server tracks time and pays the owner directly. Stored slimes earn nothing. Other clients cannot grant cash or manipulate weights.

Pen ownership, growth, inventory, and cash survive character resets during the session. Saving between sessions is a later feature. Next PRD feature: rebirths.

## Upgrades

Open **UPGRADES [U]** or tap its button above SLIMES. Spend earned cash on five levels each of Speed and Grabber Power. Prices double per level: Speed starts at $25; Grabber Power starts at $35. Speed increases from 16 to 26; power increases from 10 to 20. Pull duration falls from 2 seconds to about 1.14 seconds, and the carrying penalty becomes smaller.

The server decides prices and spends the inventory system’s private cash balance. Stats update immediately, including while carrying. Bat stuns still stop movement and restore the latest purchased speed. Levels survive character resets but reset on leaving the session; persistence is not implemented yet.

## Files and verification

- `Steal-A-Slime-Upgrades.rbxlx`: current clean playable place.
- `archive/milestones/Steal-A-Slime-Pens.rbxlx`: preserved milestone before upgrades.
- `src/shared/UpgradeRules.lua`: costs, limits, walking speed, power, pull time, and carrying formulas.
- `src/server/Upgrades.server.lua`: validated purchases and server-owned upgrade levels.
- `src/client/Upgrades.client.lua`: upgrade panel and local prompt timing.
- `UPGRADES_LESSON.md`: three small explanations with Python comparisons.
- `tests/UPGRADE_RESULTS.md`: 25 passing native two-player checks.
- `tools/build_upgrades.py`: rebuilds the clean and isolated test places.
- `archive/milestones/Steal-A-Slime-Growth.rbxl`: preserved previous milestone.
- `src/server/Inventory.server.lua`: pen ownership, roaming, growth, storage and cash accrual.
- `src/client/Inventory.client.lua`: inventory, pen release/reclaim controls and cash HUD.
- `src/shared/IncomeRules.lua`: server income formula and type rates.
- `src/server/Grassland.server.lua`: map generator with shared pens instead of pads.
- `archive/installers/Install-Pens.commandbar.lua`: optional edit-mode installer for an existing place; not a live sync service.
- `tests/PEN_RESULTS.md`: 32 passing native two-player integration checks.
- `tests/Pen-Test.rbxlx`: isolated automated test place; never publish its test drivers.
- `tools/build_place.py`: regenerates the clean XML place from current sources and the earlier map template.

The exported place was checked for six pens, zero base collection pads, exact source parity, valid object references, and absence of test controls.

## Folder structure

- `src/server/`: server game scripts.
- `src/client/`: player controls and interfaces.
- `src/shared/`: rule modules; these are currently installed in ServerScriptService and remain server-only.
- `tools/`: current builder and generated edit-mode installer. Run `python3 tools/build_place.py` from this folder to rebuild the playable game and isolated upgrade test. All current source files are packaged on each build.
- `tests/`: isolated test places, drivers, and recorded results. Test places are not the playable release.
- `archive/`: earlier playable milestones, replaced scripts, installers and legacy tools. Legacy tools are historical references and should not be run against current sources.
- `backups/`: preserved files from before upgrades.

Open this Code Class folder in VS Code for further work. This iCloud C0DE CLASS/2026/Game folder is now the active project copy. The Documents/Game Dev copy is preserved as the previous location. No automatic VS Code-to-Studio sync is configured. Close and reopen the current place after rebuilding it externally so Studio loads the rebuilt scripts.
