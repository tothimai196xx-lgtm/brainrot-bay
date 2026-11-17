# brainrot-bay

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/tothimai196xx-lgtm/brainrot-bay/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/tothimai196xx-lgtm/brainrot-bay/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bay** is a 3D steal-a-brainrot game for Roblox, built with Luau and Rojo. Twelve original characters — Noodle Cat, Sir Barksalot, Captain Croissant, DJ Pickle, Turbo Toaster, Professor Pigeon, Baron Banana, Queen Quokka, Lord Lasagna, Disco Duckling, General Gnocchi and Cosmic Couch — ride a conveyor across a sandy island in the middle of the sea. Buy one (press **E** near it on the belt), carry it back to your base, and it earns cash every second. Rare ones pay more. Every buy can roll a mutation — Golden ×2, Diamond ×4, Rainbow ×8, Frozen ×3 or Lava ×6.

Then the game pushes back:

- **Steal** — sneak into another player's open base, grab one of their brainrots and lug it home. Carrying slows you down, and getting caught outside a base when the wave hits makes you drop it.
- **Lock your base** — 30 seconds of safety per lock (60s cooldown), longer with the Shield upgrade.
- **Tsunami** — the first wave rolls in after 150 seconds, then every 240 seconds. A 20-second warning gives you time to get inside a base; anyone caught outside loses 10% of their cash and drops what they are carrying.
- **Rebirth** — once your lifetime earnings pass $1,000,000 (×10 each time after), rebirth resets your cash and brainrots for a permanent +25% income per rebirth.
- **Upgrades** — faster WalkSpeed, bigger carry capacity, stronger Shield. Progress saves to a DataStore.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio to play it. `main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` into the output directory and writes `dossier.json` there with the vendored `vendor/makefun-roblox.ts`.

Screenshots are pre-visualization renders of the map; they will be replaced by real Roblox Studio captures after the experience is published.

---

<sub>Entered on [make.fun](https://make.fun/?ref=wxz47nrz&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
