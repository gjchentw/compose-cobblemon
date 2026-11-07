# Player Guide

Install one pack, press Play, join the server. You never install Fabric,
Fabric API or any mod by hand: the pack carries everything.

## What you need

- A Minecraft Java Edition account.
- A PC with at least 8 GB of RAM (6 GB recommended for the game itself).
- One of these launchers:
  - [Modrinth App](https://modrinth.com/app) (recommended)
  - [Prism Launcher](https://prismlauncher.org/)
- Your Minecraft username on the server whitelist. Ask the admin.

## 1. Download the pack

Your admin sends you a link to the release page. Open it and download the file named
`cobblemon-X.Y.Z.mrpack` (X.Y.Z is the pack version).

## 2. Install the pack

**Modrinth App**

1. Open Modrinth App and click the **+** (Create profile) button.
2. Choose **From file** and pick the `.mrpack` you downloaded, or drag the file into the window.
3. Wait for the download to finish. The profile appears in your library.

**Prism Launcher**

1. Click **Add Instance**, then **Import**.
2. Browse to the `.mrpack` you downloaded and confirm.
3. Wait for the download to finish.

## 3. Give the game enough memory

Set the Java maximum memory to 4 GB (minimum) or 6 GB (recommended). More than 8 GB does not help and can cause stutter.

- Modrinth App: **Settings > Java and memory > Maximum memory**, or per profile under **Options**.
- Prism Launcher: right-click the instance, **Edit > Settings > Java > Memory**, set **Maximum memory allocation** to 4096 or 6144 MiB.

## 4. Play

1. Press **Play** on the profile. The first start takes a minute while Minecraft loads the mods.
2. In the main menu choose **Multiplayer**. **Cobblemon Server** is already in the list.
3. Select it and click **Join Server**.

If the server is not in your list, click **Add Server** and enter the address the admin gave you.

## 5. Your first minutes in the game

1. **Choose your starter.** Press **M**. The starter screen shows the Pokémon you can pick; choose one.
   It appears in your party, shown on the left of the screen.
2. **Send it out.** Pick a party slot with the **Up** and **Down** arrow keys, press **R** to send the
   Pokémon out, and press **R** again to recall it. **O** hides and shows the party display.
3. **Battle.** With your Pokémon out, look at a wild Pokémon and press **R** to challenge it, then
   choose moves in the battle screen. Wild Pokémon live in grass, water and caves, and some only
   appear at night or in certain biomes.
4. **Catch.** Poké Balls are crafted from apricorns (they grow on apricorn trees) and metal. To see
   any recipe, open your inventory, hover over an item and press **R** (EMI shows how to make it).
   Weaken a wild Pokémon in battle, then throw a Poké Ball at it with right-click on your turn.
5. **Heal.** Sleeping in a bed heals your party. A Healing Machine (craftable) does the same at home.
6. **Store.** A PC block (craftable) stores the Pokémon that do not fit in your party of six.
7. **Ride.** Some Pokémon can be ridden: send it out and right-click it. Hold **Left Alt** to look
   around while riding.
8. **Trade and battle other players.** Sneak and right-click another player to open the interaction
   menu, then choose Trade or Battle.
9. **Lost or stuck?** Sleep in a bed to set your respawn point. Open chat with **T** and ask; the
   admin can teleport you.

Everything else, from evolution to breeding, is on the [Cobblemon wiki](https://wiki.cobblemon.com).

## Keys worth knowing

| Key | Does |
|---|---|
| M | Cobblemon: choose your starter the first time; afterwards the summary of the selected Pokémon |
| R | Cobblemon: send out or recall the selected Pokémon; start a battle when looking at a wild one |
| Up, Down | Cobblemon: select the previous or next Pokémon in your party |
| O | Cobblemon: hide or show the party display |
| Left Alt (hold) | Cobblemon: free look while riding a Pokémon |
| V | Xaero's World Map (moved from its default M so it does not block the Cobblemon screen) |
| Z | Xaero's Minimap: enlarge the minimap |
| B, U, Y | Xaero's: new waypoint, waypoint list, minimap settings |
| E, T | Inventory, chat |
| R, U (in a menu) | EMI: recipes for the item under the cursor, and what it is used for |

All keys can be changed under **Options > Controls > Key Binds**.

## Updating the pack

When the server list shows a pack version in the MOTD (for example `Pack 1.1.0`) that differs from the one you installed, the server has been upgraded:

1. Download the new `.mrpack` from the link your admin sends.
2. Install it as a new profile, exactly as in step 2.
3. Play from the new profile. Nothing is lost: your Pokémon, items and progress live on the server.

Your client settings (render distance, key binds) return to the pack defaults in the new profile.

## Troubleshooting

| Symptom | What it means | What to do |
|---|---|---|
| "You are not white-listed on this server!" | The admin has not added your username yet | Send your exact Minecraft username to the admin |
| Join fails with a mod or version mismatch message | Your pack version differs from the server's | Check the MOTD and install the matching pack version |
| The game crashes while loading | Not enough memory | Set the maximum memory to 6 GB (step 3) and update your graphics driver |
| Low FPS | The defaults are too high for your PC | In **Options > Video Settings** lower Render Distance to 8 and Simulation Distance to 5 |
| Pokémon do not appear or battles do nothing | The connection is unstable or the server is restarting | Wait a minute, then reconnect |

When you report a problem, include the pack version you installed and the exact text of any error message.
