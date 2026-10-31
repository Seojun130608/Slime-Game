# Inventory and growth validation

Passed in native Roblox Studio with two clients on October 25, 2026.

## Gameplay: 29 checks

- players receive different bases
- new inventories start empty
- inventory interface is present
- existing capture pipeline still works
- securing updates only the owner's inventory
- owner can inspect the fixed captured weight
- secured slime stays an ungrown baby in inventory
- original baby remains in private server storage
- duplicate secure event cannot duplicate inventory
- remote placement from outside the base is rejected
- another player cannot place a stolen inventory ID
- owner can place a baby in their own slot
- placement reserves the slot
- world display does not expose numerical weight
- same slime cannot occupy two slots
- other players cannot reclaim a placed slime
- placed baby visibly grows
- reclaim returns a partly grown slime to inventory
- growth pauses while stored
- reclaim frees the base slot
- replacing resumes existing growth
- growth reaches completion
- grown size matches captured weight
- fully grown slime stops growing
- growth never rerolls weight
- inventory and growth survive character reset
- all six base slots can be used
- full base rejects placement without losing the stored baby
- other client never receives the owner's inventory entries

## Interface smoke test: 3 checks

- inventory cards and 3D slime previews render
- inventory shows the assigned base
- other client's open UI remains empty

All final sources compiled in Studio. Test controls were removed before saving Steal-A-Slime-Growth.rbxl.
