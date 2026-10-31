# Normal-play verification — October 31, 2026

Recent Studio logs showed the user had opened tests/Rebirth-Test.rbxlx, whose automated driver intentionally changes progress, resets the character, and ends Play. Its log reported REBIRTH COMPLETE: 19 immediately before Disconnect. No bat crash error was found in those sessions.

Changed the rebirth coordinator to run only with explicit StudioTestService test arguments. Ordinary Play now skips its automatic actions and warns which normal release to open. The client driver exits if its test control is absent.

Verified in the actual Steal-A-Slime-Rebirths.rbxlx normal release:
- Starting Grabber Power captured a Grass baby using the actual hold prompt.
- The collect zone secured the captured baby.
- Fifty rapid bat tool activations completed in the corridor.
- Play remained running after those activations and a further fifteen seconds.

This was a single-player swing check, not a new two-player repeated-hit stress test. Production capture and bat scripts were unchanged. The release was checked to exclude rebirth test drivers.
