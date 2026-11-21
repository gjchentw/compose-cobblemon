# Tasks

## 1. The two guides

- [x] 1.1 Write `docs/pack-install-guide.md` and `docs/pack-install-guide.zh-TW.md` from the old guide's requirements, download, install, join, update and install troubleshooting parts, with a memory step that only links to the play guide; show that both files have the same sections and that the guide states no memory figure and no key (verify: L1)
- [ ] 1.2 Write `docs/play-guide.md` and `docs/play-guide.zh-TW.md` from the old guide's memory, first-minutes, key and game troubleshooting parts, opening with a link to the install guide; show that both files have the same sections and that the guide explains no download, install or update step (verify: L1)

## 2. Retire the old guide

- [ ] 2.1 Show that every instruction line of `docs/player-guide.md` and `docs/player-guide.zh-TW.md` is in one of the new guides, listing the lines the split rewrote; then delete the two files and point `README.md`, `docs/upgrade.md` and `docs/acceptance-checklist.md` at the new guides (verify: L1)
- [ ] 2.2 Reword the language exception in `AGENTS.md` to name the two Chinese copies, and confirm with a search that nothing outside `tasks/` and the archived changes still refers to `player-guide` (verify: L1)

## Workflow follow-up

- Merge to `main`; the publish job is expected to skip, as the template holds the placeholder address.
- Archive the change.
- Administrators of copies send players the links to the two new guides.
