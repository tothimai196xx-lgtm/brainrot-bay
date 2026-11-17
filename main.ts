// Brainrot Bay — the entry point for the make.fun roblox-brainrot-01 bounty.
//
// The game is a Rojo project in this directory: `rojo build
// default.project.json --output game.rbxl` compiles src/ into the place file.
// This program hands the entry in: it copies game.rbxl, PLAY.json, src/ and
// screenshots/ into the output directory (MAKEFUN_OUTPUT_DIR, or /output as
// the grader runs it) and writes dossier.json there with the vendored
// make.fun library, which summarises the place for the scorer.
//
// Only Node's standard library is used, plus vendor/makefun-roblox.ts (the
// kit's copy, left untouched). Every name copied into the output starts with
// a letter, a digit or an underscore and holds only letters, digits, . _ and
// -: the grader rejects an entry whose output holds any other character, so
// files and folders whose name starts with a dot (.gitkeep, .DS_Store, .git)
// are filtered out at every depth.
//
// Run it the way the grader does:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// cpSync filter: skip anything whose name starts with a dot.
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

// The built place and the play link go first, then the sources and shots.
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
}

// The scorer's caps (from the kit's reference/gate.json): text_max_bytes is
// the only one that shapes the dossier's bytes; the others refuse an entry
// the scorer would refuse — more than 4 screenshots or one over 256 KiB, a
// place of more than 500000 instances, scripts totalling over 8 MiB of
// source, or script paths totalling over 1048576 characters.
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
