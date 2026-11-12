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
check-upgrade.mjs szwh4-3qaaa-aaaau-ahjgq-cai`, then the backend with
`hosty_prepare_wasm_upload` and `snapshotBeforeUpgrade: true`, the page
with `hosty_prepare_zip_upload` (`pureAssets`, `dist`).

Not listed on the Duel dashboard (https://games.ic0.info/) until the user
registers the frontend there.

Test copy on hosty.live's free cloud engine, not the game (may be deleted
at any time; its ids never go into anything public): backend
`fzhym-yyaaa-aaacl-aaaiq-cai`, frontend `fqetq-oqaaa-aaacl-aaaja-cai`.

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
