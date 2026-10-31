# Pen and passive income validation

Native Roblox Studio test with two clients, October 25, 2026.

- players own different pens
- all six bases have open pens and no collection pads
- capture collection boundary is preserved
- capture still secures a private inventory baby
- stored babies earn no income
- cannot release slimes from outside own pen
- another player cannot release an owned inventory ID
- one release creates one roaming display
- roaming display keeps weight numbers private
- repeated release cannot duplicate a slime
- income uses the server's type and weight formula
- placed slime wanders around the pen
- income is automatically credited without touching a pad
- income is credited only to the owner
- cash HUD and leaderboard use server balance
- roaming stays inside pen throughout movement
- another player cannot reclaim a roaming slime
- reclaim immediately stops income
- stored slime's growth pauses
- selected baby can be released using the pen entrance
- roaming slime finishes growing
- grown roaming slime remains inside fences
- growth and wandering never reroll weight
- inventory uses pen capacity instead of pad buttons
- roaming slime appears in inventory with reclaim control
- cash appears in the HUD
- client cannot grant itself cash
- six slimes share the open pen
- full pen rejects extra releases
- multiple slimes' passive income adds correctly
- other player never receives private inventory
- pen and income survive a character reset

All 32 checks passed.
