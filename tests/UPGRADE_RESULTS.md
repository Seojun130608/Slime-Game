# Upgrade validation

Native Roblox Studio two-client test, October 31, 2026.

- starting stats and prices
- insufficient cash rejects without changing level
- client cash spoof cannot buy an upgrade
- cash service rejects negative zero infinite and NaN amounts
- real pen income funds purchases; storing stops income
- exact price deducted and leaderboard synchronized
- Speed purchase applies immediately
- next price increases and other player stays unchanged
- malformed upgrade request cannot spend cash
- unknown upgrade rejected
- Grabber purchase increases power
- short holds still rejected with upgraded grabber
- maximum grabber unlocks all starting weights
- upgraded client hold bar and server timing capture faster
- Speed purchase while carrying preserves slowdown
- dropping restores upgraded walking speed
- dropped pickup remains instant after upgrades
- collection restores upgraded speed and still secures baby
- bat stun still stops an upgraded player
- stun restores the latest purchased speed
- level caps reject extra purchases without charging
- grabber level reduces carrying penalty independently of power
- upgrade panel shows limits and current cash
- levels stats and cash survive character reset
- purchases never change another player's levels

All 25 checks passed. The clean game excludes the integration scripts and test-control remote.
