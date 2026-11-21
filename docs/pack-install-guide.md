# Pack Install and Update Guide

Install one pack, press Play, join the server. You never install Fabric,
Fabric API or any mod by hand: the pack carries everything.
What to do once you are in the game is in the [play guide](play-guide.md).

## What you need

- A Minecraft Java Edition account.
- A PC that can run the game: see "What your PC needs" in the [play guide](play-guide.md#what-your-pc-needs).
- One of these launchers:
  - [Modrinth App](https://modrinth.com/app) (recommended)
  - [Prism Launcher](https://prismlauncher.org/)
- Your Minecraft username on the server whitelist. Ask the admin.

## 1. Download the pack

Your admin sends you one link. Open it and your browser downloads `cobblemon.mrpack`. The
link never changes: it always gives you the newest pack, so keep it for updates.

## 2. Install the pack

**Modrinth App**

1. Open Modrinth App and click the **+** (Create profile) button.
2. Choose **From file** and pick the `.mrpack` you downloaded, or drag the file into the window.
3. Wait for the download to finish. The profile appears in your library.

**Prism Launcher**

1. Click **Add Instance**, then **Import**.
2. Browse to the `.mrpack` you downloaded and confirm.
3. Wait for the download to finish.

## 3. Set the game's memory

Before the first start, give the game enough memory. How much, and where to set it in your
launcher, is in the play guide: [Give the game enough memory](play-guide.md#give-the-game-enough-memory).

## 4. Join the server

1. Press **Play** on the profile. The first start takes a minute while Minecraft loads the mods.
2. In the main menu choose **Multiplayer**. The server is already in the list, and its name
   ends with your pack version in brackets, for example `Cobblemon Server (2026.11.18-95db987)`.
3. Select it and click **Join Server**.

If the server is not in your list, click **Add Server** and enter the address the admin gave you.

You are in. Continue with the [play guide](play-guide.md): your first minutes in the game, the keys,
and what to do when the game misbehaves.

## Updating the pack

The server list shows two versions: the one in the name of the server entry is your pack, and
the one in the line under it (the MOTD, for example `Pack 2026.11.18-95db987`) is the
server's. When they differ, the server has been upgraded:

1. Download `cobblemon.mrpack` again from the same link.
2. Install it as a new profile, exactly as in step 2.
3. Play from the new profile. Nothing is lost: your Pokémon, items and progress live on the server.

Your client settings (render distance, key binds) return to the pack defaults in the new profile.

## Troubleshooting

| Symptom | What it means | What to do |
|---|---|---|
| "You are not white-listed on this server!" | The admin has not added your username yet | Send your exact Minecraft username to the admin |
| Join fails with a mod or version mismatch message | Your pack version differs from the server's | Compare the version in the entry name with the MOTD; if they differ, update the pack (see "Updating the pack") |

Problems in the game itself (crashes, low FPS, Pokémon that do not appear) are in the
[play guide](play-guide.md#troubleshooting).

When you report a problem, include your pack version (in the name of the server entry) and the exact text of any error message.
