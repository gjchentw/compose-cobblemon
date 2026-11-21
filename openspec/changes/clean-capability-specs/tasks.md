# Tasks

## 1. Purposes

- [x] 1.1 Replace the Purpose paragraph of the four main specs with the texts in `design.md` (decision 6), editing `openspec/specs/` directly; show each paragraph before and after, and that `openspec validate --specs --strict` passes (verify: L1)

## 2. Requirements against the repository

- [x] 2.1 Confirm the added and modified requirements of `game-requirements` against the files: the name in the exported pack's index, the published file names, the default display name in the rendered configuration, `options.txt` as the pack's only settings file with its nine lines, and the seven gameplay items in `docs/acceptance-checklist.md` (verify: L1, L2)
- [x] 2.2 Confirm the added and modified requirements of the three mechanism specs describe the present behaviour: `<pack>` reads `cobblemon` wherever the files name the pack, inspection rejects a pack with an extra override, and `docs/acceptance-checklist.md` holds the run's rules and the four items that do not depend on the game (verify: L1, L2)

## 3. Result

- [x] 3.1 In a throwaway clone, archive the change and show that the main specs pass strict validation, that the scan which finds 24 lines with a game value in the three mechanism specs today finds none, and that `game-requirements` declares the five values the other specs refer to (verify: L1)

## Workflow follow-up

- Merge to `main`; the publish job is expected to skip.
- Archive the change.
- Remaining follow-up change: least-privilege mounts for the tools and lint containers.
