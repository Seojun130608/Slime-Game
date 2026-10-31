# Slime Bat validation

Two-player Roblox Studio integration test passed on October 25, 2026.

- safe-zone attacker cannot hit
- safe-zone victim cannot be hit across boundary
- out-of-range swing misses
- swing cannot hit behind attacker
- wall blocks hit
- valid forward hit gives protection
- bat deals no health damage
- rapid repeated swing is rejected
- protection prevents another hit after swing cooldown
- walking speed restored after impact
- unequipped remote cannot hit
- hit breaks active capture tether
- interrupted pull cannot finish
- normal capture works
- hit drops carried baby
- dropped baby has instant pickup prompt
- drop ends original parent chase
- another player can claim dropped baby
- parent retargets new carrier
- carrying player cannot swing
- voluntary drop works
- original carrier can recover a drop
- stolen drop secures exactly once
- secured drop retains hidden weight

Result: BAT INTEGRATION COMPLETE.

The test-only driver runs actual tool activation and capture prompts on two clients. Test controls are excluded from the playable place.
