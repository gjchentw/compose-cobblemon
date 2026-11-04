# Acceptance Checklist (L5)

Run on staging with the release candidate before every release, and once on production
after the upgrade. Two players are needed for trading. Record one table per run.

Pack version: `________`  Environment: staging / production  Date: `________`
Players: `________`  Launcher used: Modrinth App / Prism Launcher (cover both across the two runs)

On staging the pre-filled entry points at production; for item 1 add the staging address
(`<host>:25566`) by hand, or export a staging pack with `SERVER_PUBLIC_HOST=<host>:25566`.

| # | Item | How to test | Result (pass/fail) | Notes |
|---|---|---|---|---|
| 1 | Login | Install the pack from the Releases page as in `docs/player-guide.md`, join from the pre-filled server entry | | |
| 2 | Pokémon spawn | Walk around spawn for two minutes; wild Pokémon appear in grass, water and caves | | |
| 3 | Starter selection | A new player opens the starter screen and receives the chosen Pokémon | | |
| 4 | Catch | Craft or receive Poké Balls, weaken a wild Pokémon, catch it; it appears in the party | | |
| 5 | Battle | Challenge a wild Pokémon and a second player; both battles start, run and end | | |
| 6 | Trade | Two players open a trade and exchange Pokémon; both parties update | | |
| 7 | Ride | Ride a rideable Pokémon on land and in water | | |
| 8 | Death and respawn | Die, respawn at spawn or bed; inventory behaviour matches `keepInventory` | | |
| 9 | Server restart | Admin runs `scripts/persist-test.sh`; players reconnect afterwards | | |
| 10 | World persistence | After item 9, party, PC storage, position and placed blocks are unchanged | | |
| 11 | Reachable from outside | A player on another network joins through the published port and the host firewall (what `scripts/smoke.sh` cannot prove from the host itself) | | |

Also note: client FPS at the pack defaults, any warning in the server log during the session
(known harmless noise: `No data fixer registered for cobblemon:*` at startup),
and whether the pre-filled server entry survived a pack update (item 1 on the second run).

Sign-off: all eleven pass on staging, then all eleven pass on production.
