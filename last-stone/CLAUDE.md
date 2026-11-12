# Last Stone

A 2-player game on duel-game-core
(https://github.com/research-ag/duel-core): `src/LastStoneRules.mo`
holds the rules, `src/Host.mo` the host actor, `frontend/` the page.
Load the duel-game-core skill before changing anything: through
hosty.live, `hosty_get_skill { url:
"https://github.com/research-ag/duel-core/tree/main/skills/duel-game-core" }`.
For a change to the live game, its `references/changing-a-live-game.md`.

## Live

Not live yet: nothing of this game is on mainnet. The canisters below
are a **test copy on hosty.live's free cloud engine** (deployed through
hosty.live). hosty.live may delete them at its discretion, the Duel
dashboard will not list them, and their ids never go into `index.html`,
the README or anything public. Going live buys new mainnet canisters
(`going-live.md`, section 3) and replaces this table.

| Canister | Id                            | Runs                                                  |
| -------- | ----------------------------- | ----------------------------------------------------- |
| backend  | `fzhym-yyaaa-aaacl-aaaiq-cai` | the game (cloud engine); the module store has it      |
| frontend | `fqetq-oqaaa-aaacl-aaaja-cai` | https://fqetq-oqaaa-aaacl-aaaja-cai.icp0.io/ (cloud engine) |

Redeploy every change into these same two canisters until the game goes
live: backend with `hosty_prepare_wasm_upload` (+ `snapshotBeforeUpgrade:
true`), page with `hosty_prepare_zip_upload` (`pureAssets`, `dist`).

## What the game runs

- Mode: `#turnBased` (`State = { pile; toMove; lastTake }`, `View = State`,
  `Options = {}`, `Action = #take { count }`).
- Bot support (the Host's and the page's BOTS lines): off.
- Leaderboard (LEADERBOARD lines): off.
- A bot canister: none.
- duel-game-core: path dependency `../duel-core/backend`, a clone of
  research-ag/duel-core at `e185751` (not on mops.one yet), and
  `@research-ag/duel-game-core` 0.4.1 (npm).

## Working here

- The default branch is the game: merge finished work there, and
  update this file whenever a canister or a feature changes.
- `mops test`; `cd frontend && npm run build && node play-test.mjs`
  (against the local network), `node play-test.mjs <backend-id> --ic`
  (against an online backend).
- `icp build` needs `ic-wasm` on the PATH (`cargo install ic-wasm --locked`).
- Before upgrading the backend: `cd frontend && node check-upgrade.mjs
<backend-id>` must exit 0.
- A change to `View`, `Action`, `Options` or the rules updates
  `SEMANTICS` in the same change.
