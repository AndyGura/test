Games, frontends and bots here are built on duel-game-core: before working on one, load its skill with hosty.live's `hosty_get_skill { url: "https://github.com/research-ag/duel-core/tree/main/skills/duel-game-core" }`.

Projects (one top-level directory each, with its own `CLAUDE.md` and `README.md`):

- `last-stone/` — Last Stone, a 21-stone take-1-2-or-3 game (whoever takes the last stone loses).

`duel-core/` at the root is a gitignored clone of research-ag/duel-core, the path dependency every game's `mops.toml` names (`../duel-core/backend`); each game's README says how to get it.
