# Last Stone

A 2-player game on duel-game-core
(https://github.com/research-ag/duel-core): `src/LastStoneRules.mo`
holds the rules, `src/Host.mo` the host actor, `frontend/` the page.
Load the duel-game-core skill before changing anything: through
hosty.live, `hosty_get_skill { url:
"https://github.com/research-ag/duel-core/tree/main/skills/duel-game-core" }`.
For a change to the live game, its `references/changing-a-live-game.md`.

## Live

On mainnet since 2026-11-12, deployed through hosty.live (`going-live.md`,
section 3), both canisters controlled by the user's hosty.live principal.

| Canister | Id                            | Runs                                              |
| -------- | ----------------------------- | ------------------------------------------------- |
| backend  | `szwh4-3qaaa-aaaau-ahjgq-cai` | the game; the module store has it, verified       |
| frontend | `sqvma-nyaaa-aaaau-ahjha-cai` | https://sqvma-nyaaa-aaaau-ahjha-cai.icp0.io/      |

`index.html`'s canonical, Open Graph and JSON-LD tags, `robots.txt` and
`sitemap.xml` name the live frontend. Every change upgrades these two
canisters (a deploy session each time): first `cd frontend && node
check-upgrade.mjs szwh4-3qaaa-aaaau-ahjgq-cai` (Node 24), then the backend with
`hosty_prepare_wasm_upload` and `snapshotBeforeUpgrade: true`, the page
with `hosty_prepare_zip_upload` (`pureAssets`, `dist`).

Not listed on the Duel dashboard (https://games.ic0.info/) until the user
registers the frontend there.

Keep the backend at 1 TC or more: with its ~200 MB of memory and the
30-day freezing threshold, its timer stalls near 0.48 TC. No cloud engine
test copy exists (hosty.live deleted the first one).

## What the game runs

- Mode: `#turnBased` (`State = { pile; toMove; lastTake }`, `View = State`,
  `Options = {}`, `Action = #take { count }`).
- Bot support (the Host's and the page's BOTS lines): off.
- Leaderboard (LEADERBOARD lines): off.
- A bot canister: none.
- Sweep timer: lazy (`sweeper = Transport.sweeper()` in the Host's
  `env`): it runs only while a table or a waiting player exists, so
  `canister_version` in `/metrics` stays flat while nobody plays.
- Invite links: on, from the npm package. "Invite a friend" opens a
  `#code` table whose waiting screen shares `#t=<id>&c=<code>`; the table
  waits 30 minutes, and each seat's first move gets 10 extra minutes.
- duel-game-core: path dependency `../duel-core/backend`, a clone of
  research-ag/duel-core at `cd3f163` (not on mops.one yet), and
  `@research-ag/duel-game-core` 0.5.1 (npm).

## Working here

- The default branch is the game: merge finished work there, and
  update this file whenever a canister or a feature changes.
- `mops test`; `cd frontend && npm run build && node play-test.mjs`
  (against the local network), `node play-test.mjs <backend-id> --ic`
  (against an online backend).
- `icp build` needs `ic-wasm` on the PATH (`cargo install ic-wasm --locked`).
- Before upgrading the backend: `cd frontend && node check-upgrade.mjs
<backend-id>` must exit 0. Run it with Node 24 or later (`/opt/node24/bin/node`
in a cloud session): Node 22 cannot read the live 64-bit Motoko module and
crashes with "invalid table elements limits flags", which is not a verdict.
- A change to `View`, `Action`, `Options` or the rules updates
  `SEMANTICS` in the same change.
