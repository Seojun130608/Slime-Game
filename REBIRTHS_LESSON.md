# Rebirths: three pieces

1. `src/shared/RebirthRules.lua` defines the formulas. Luau `1 + 0.5 * count` is identical to Python `1 + 0.5 * count`. Luau `1000 * 2 ^ count` is Python `1000 * 2 ** count`. Requirements start at $1,000 and double. Multipliers increase additively: 1.5x, 2x, 2.5x.

2. `src/server/Inventory.server.lua`, `PerformRebirth`, checks private cash and resets only cash and upgrades. Luau `state.cash = 0` corresponds to Python `state["cash"] = 0`. It preserves slime records, weights, growth, placement, and pen ownership. `state.tokens += 1` is the same increment syntax as Python, using a table field.

3. `src/client/Rebirths.client.lua` opens a preview and requires a second confirmation click. The client requests the action; the server decides eligibility and rewards. Each rebirth grants one token and raises each upgrade limit by one. Token spending, extra slots, and cosmetics are later features.

To check: earn $1,000 from placed slimes, open REBIRTH, review what resets, click REBIRTH then CONFIRM RESET. Cash and upgrade levels reset; slimes remain and income becomes 1.5x. The next requirement is $2,000. Resetting your character preserves rewards for this session. Saving between game sessions is still a later feature.
