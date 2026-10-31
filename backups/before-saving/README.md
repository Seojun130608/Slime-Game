# Steal a Slime — current rebirth build

Open **Steal-A-Slime-Rebirths.rbxlx** in Roblox Studio and press Play. This `2026/Game` folder is the active project. No automatic VS Code-to-Studio sync is configured.

## Play

Capture babies with the Slime Grabber and cross the COLLECT ZONE. Open SLIMES [I], stand inside your own pen, and release secured babies. Placed slimes grow, roam, and generate cash automatically; stored slimes earn nothing. Slime Bat combat and safe bases remain available.

Open UPGRADES [U] to buy Speed or Grabber Power. Starting limits are five levels each. Speed starts at $25 and Grabber Power at $35; prices double each level.

Open REBIRTH to review your next reset. The first requires $1,000; later requirements double. Click REBIRTH then CONFIRM RESET. All cash and both upgrade levels reset. Your secured and placed slimes, weights, growth, and pen ownership stay unchanged. Income multipliers are 1.5x after one rebirth, 2x after two, 2.5x after three, and so on. Every rebirth adds one upgrade level to both limits and awards one Slime Token. Token spending, extra slots, and cosmetics are later features.

Progress survives character resets for the current game session. Saving between sessions is **not built yet** and is the next PRD feature.

## Structure and building

- `src/server/`: authoritative capture, combat, inventory, cash, upgrades, and rebirth logic.
- `src/client/`: player controls and interfaces.
- `src/shared/`: rule modules, currently installed in ServerScriptService and server-only.
- `tools/build_place.py`: current build entry point; run `python3 tools/build_place.py` from this folder.
- `tools/build_upgrades.py`: implementation of the current packager; its filename is historical.
- `tools/install_current.commandbar.lua`: generated edit-mode installer for current scripts.
- `tests/`: separate test places, test drivers, and result records. Never publish a test place.
- `archive/`: earlier milestones and retired scripts/tools. Legacy tools are historical references.
- `backups/`: files preserved before changes, including `before-rebirths/`.
- `REBIRTHS_LESSON.md` and `UPGRADES_LESSON.md`: small explanations with Python comparisons.

The builder preserves the original map geometry and packages all current source scripts. Close and reopen the playable place after rebuilding externally; avoid saving an older open Studio copy over the rebuilt file.

## Verification

`tests/REBIRTH_RESULTS.md` records 19 passing native Studio client/server checks: resets, retained slimes and growth, additive multipliers, tokens, increased upgrade limits, rejected invalid requests, and character resets. The playable release excludes test drivers and seeded test slimes. Earlier test records describe their respective milestones.
