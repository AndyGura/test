# Last Stone

A two-player game on the Internet Computer, built on
[duel-game-core](https://github.com/research-ag/duel-core).

## Rules

A pile of 21 stones sits between two players. Player 1 moves first, then
the players take turns. On your turn you take 1, 2 or 3 stones from the
pile (never more than are left). Whoever takes the last stone loses.

## Layout

| Path                                  | What                                                        |
| ------------------------------------- | ----------------------------------------------------------- |
| `src/LastStoneRules.mo`               | the rules: a pure `#turnBased` module, and its `SEMANTICS`  |
| `src/Host.mo`                         | the backend actor (the skill's Host template, 90 s / 60 s)  |
| `test/RulesUnit.test.mo`              | rules unit tests                                            |
| `frontend/src/laststone-plugin.js`    | the `GamePlugin`: stone heap, Take 1/2/3 buttons            |
| `frontend/src/{index.html,app.js,style.css}` | the page                                             |
| `frontend/play-test.mjs`              | two headless players play whole games through the real client |
| `frontend/check-upgrade.mjs`          | stable-compatibility check before upgrading a live backend  |
| `icp.yaml`, `publish_wasm.sh`         | canisters `backend` and `frontend`                          |

The backend serves its rules for third-party frontends and bots at
`GET /semantics`, and Prometheus metrics at `GET /metrics`.

## Build and test

Tools: `icp` (icp-cli 1.8.0), `mops` 3.4.1 or later, Node 22, and
`ic-wasm` (`cargo install ic-wasm --locked`), which the Motoko recipe
in `icp.yaml` calls.

`duel-game-core` is not on mops.one yet, so `mops.toml` names a clone of
the framework next to this directory. From the repository root, once:

```bash
git clone https://github.com/research-ag/duel-core.git duel-core
```

Then, from `last-stone/`:

```bash
mops install && mops test
```

```bash
cd frontend && npm install && npm run build && cd ..
```

```bash
icp network start -d
```

```bash
icp deploy
```

```bash
cd frontend && node play-test.mjs && cd ..
```

`icp deploy` prints the local frontend's URL; open it in two browser tabs
(each tab is its own player) to play both seats.

## Online

**Play: https://sqvma-nyaaa-aaaau-ahjha-cai.icp0.io/**

The live game, on Internet Computer mainnet, deployed through hosty.live:

| Canister | Id                            |                                                         |
| -------- | ----------------------------- | ------------------------------------------------------- |
| backend  | `szwh4-3qaaa-aaaau-ahjgq-cai` | `https://szwh4-3qaaa-aaaau-ahjgq-cai.raw.icp0.io/semantics` |
| frontend | `sqvma-nyaaa-aaaau-ahjha-cai` | the page; its `PUBLIC_CANISTER_ID:backend` names the backend |

The backend's module is in hosty.live's module store, so anyone can build
their own frontend or bot for the game from its id.

### Updating the live game

Through hosty.live (the duel-game-core skill's `references/going-live.md`,
section 3), with a deploy session the owner approves in the hosty.live web
app:

1. `mops test`, then the local checks above.
2. `cd frontend && node check-upgrade.mjs szwh4-3qaaa-aaaau-ahjgq-cai`
   must exit 0.
3. `icp build backend`, then install `.icp/cache/artifacts/backend` on the
   backend with `hosty_prepare_wasm_upload` and `snapshotBeforeUpgrade: true`.
4. `cd frontend && npm run build && zip -r dist.zip dist -x "*.map"`, then
   upload it to the frontend with `hosty_prepare_zip_upload` (`pureAssets`,
   `outputDir: "dist"`).
5. `cd frontend && node play-test.mjs szwh4-3qaaa-aaaau-ahjgq-cai --ic`.
