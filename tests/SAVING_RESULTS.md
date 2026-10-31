# Saving validation

October 31, 2026: 19 save-engine checks and 18 two-player gameplay checks passed in native Studio using an isolated backend.

- SAVING CORE PASS: new account defaults
- SAVING CORE PASS: another server cannot load an active profile
- SAVING CORE PASS: same server cannot acquire a second overlapping session
- SAVING CORE PASS: autosave succeeds when UpdateAsync retries its callback
- SAVING CORE PASS: cash weights and growth stored as plain data
- SAVING CORE PASS: temporary backend failures retry
- SAVING CORE PASS: failed save preserves last stored profile
- SAVING CORE PASS: NaN cannot enter saved profile
- SAVING CORE PASS: duplicate slime IDs rejected
- SAVING CORE PASS: unknown profile version rejected
- SAVING CORE PASS: leaving saves and releases session lock
- SAVING CORE PASS: fresh session restores currency rebirths and tokens
- SAVING CORE PASS: fresh session restores upgrade levels
- SAVING CORE PASS: fresh session restores IDs growth and placement
- SAVING CORE PASS: closed session cannot overwrite a new session
- SAVING CORE PASS: expired old session cannot overwrite takeover
- SAVING CORE PASS: takeover saves with its own lease
- SAVING CORE PASS: bad existing data never replaced with defaults
- SAVING CORE PASS: load outage never creates an empty save
- SAVING GAME PASS: inventory IDs and selection restored
- SAVING GAME PASS: placed slime type weight and growth restored
- SAVING GAME PASS: stored slime remains stored with paused growth
- SAVING GAME PASS: rebirth rewards restored
- SAVING GAME PASS: upgrades and character movement restored
- SAVING GAME PASS: cash restored and placed income resumes
- SAVING GAME PASS: restored players receive different available pens
- SAVING GAME PASS: restored originals remain private and displays hide weights
- SAVING GAME PASS: purchase after loading uses restored level
- SAVING GAME PASS: purchase spends existing balance
- SAVING GAME PASS: another player's loaded upgrades unchanged
- SAVING GAME PASS: offline or stored growth is not awarded
- SAVING GAME PASS: character reset does not reload or duplicate profile
- SAVING GAME PASS: inventory autosave snapshot writes successfully
- SAVING GAME PASS: save snapshot includes latest private progress
- SAVING GAME PASS: save snapshot contains no duplicate IDs
- SAVING GAME PASS: leaving flush releases the actual inventory profile lease
- SAVING GAME PASS: fresh profile session reloads gameplay changes

Actual Roblox cloud persistence and separate published-server rejoin remain UNVERIFIED. The user chose to keep the project local. The PRD saving checkbox stays open.

Final static release checks: all 22 source files exactly match the packaged game, all object references are unique, six pens remain, and test drivers, fake seed backends and test-only inventory controls are excluded. The final normal-place visual check could not finish because the Studio UI connection timed out.
