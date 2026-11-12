// GamePlugin for Last Stone — the only game-specific client code.
// Action/View/Options mirror ../src/LastStoneRules.mo exactly.
// `legal()` is a cosmetic echo of that module's `validate`, `applyLocal`
// of its `resolve`.
//
// The 21 stones are drawn as a triangular heap (rows of 1..6), taken from
// the top. Stones already taken stay as faint outlines; the stones of the
// most recent take are ghosts in the taker's colour, ringed when the
// opponent took them, so their last move is visible live and in the
// debrief. Hovering a "Take N" button lights up the N stones it takes.

import { actionAttr, esc } from "@research-ag/duel-game-core/render.js";

const SEAT_NAME = { p1: "Player 1", p2: "Player 2" };
const START_PILE = 21;
const MAX_TAKE = 3;
const ROWS = 6; // 1 + 2 + … + 6 = 21

const seatOf = (v) => Object.keys(v)[0];

function lastTakeOf(game) {
  const t = game.lastTake?.[0];
  return t ? { seat: seatOf(t.seat), count: Number(t.count) } : null;
}

function legal(pile, count) {
  return count >= 1 && count <= MAX_TAKE && count <= pile;
}

const stones = (n) => `${n} stone${n === 1 ? "" : "s"}`;

function drawHeap(game, mySeat) {
  const pile = Number(game.pile);
  const gone = START_PILE - pile; // stones 1..gone (numbered from the top) are taken
  const last = lastTakeOf(game);
  const lastFrom = last ? gone - last.count : gone; // stones lastFrom+1..gone went last
  let k = 0;
  let rows = "";
  for (let r = 1; r <= ROWS; r++) {
    let row = "";
    for (let i = 0; i < r; i++) {
      k++;
      let cls;
      if (k > gone) {
        const depth = k - gone; // 1 = the next stone to be taken
        cls = depth <= MAX_TAKE ? `ls-stone ls-d${depth}` : "ls-stone";
      } else if (last && k > lastFrom) {
        cls = `ls-ghost ls-last ls-by-${last.seat}${last.seat !== mySeat ? " ls-opp" : ""}`;
      } else {
        cls = "ls-ghost";
      }
      row += `<span class="${cls}"></span>`;
    }
    rows += `<div class="ls-row">${row}</div>`;
  }
  return `<div class="ls-heap" aria-hidden="true">${rows}</div>`;
}

function lastTakeLine(game, mySeat) {
  const last = lastTakeOf(game);
  if (!last) return `<p class="ls-note muted">${esc(SEAT_NAME.p1)} moves first.</p>`;
  const who = last.seat === mySeat ? "You" : SEAT_NAME[last.seat];
  const what = Number(game.pile) === 0 ? `${stones(last.count)}, including the last one` : stones(last.count);
  return `<p class="ls-note ${last.seat === mySeat ? "" : "ls-note-opp"}">${esc(who)} took ${esc(what)}.</p>`;
}

export const plugin = {
  idlTypes({ IDL }) {
    const Seat = IDL.Variant({ p1: IDL.Null, p2: IDL.Null });
    const Take = IDL.Record({ seat: Seat, count: IDL.Nat });
    const Action = IDL.Variant({
      take: IDL.Record({ count: IDL.Nat }),
    });
    // Nothing is hidden: the view is the whole state.
    const View = IDL.Record({
      pile: IDL.Nat,
      toMove: Seat,
      lastTake: IDL.Opt(Take),
    });
    const Options = IDL.Record({});
    return { Action, View, Options };
  },

  seatLabel(seat) {
    return SEAT_NAME[seat];
  },

  // Live game and debrief alike: the heap, the count, and the last take.
  renderBoard(gameState, mySeat) {
    const pile = Number(gameState.pile);
    return `
      <div class="ls-board">
        <div class="ls-count"><strong>${pile}</strong> <span class="muted">of ${START_PILE} left</span></div>
        ${drawHeap(gameState, mySeat)}
        ${lastTakeLine(gameState, mySeat)}
      </div>`;
  },

  // Only called while it's mySeat's turn.
  renderActions(gameState) {
    const pile = Number(gameState.pile);
    let out = "";
    for (let count = 1; count <= MAX_TAKE; count++) {
      const enabled = legal(pile, count);
      const left = pile - count;
      const hint = !enabled
        ? `only ${stones(pile)} left`
        : left === 0
          ? "takes the last stone: you lose"
          : `leaves ${stones(left)}`;
      out += `
        <button class="ls-take${enabled && left === 0 ? " ls-fatal" : ""}" data-take="${count}" ${actionAttr({ take: { count } })} ${enabled ? "" : "disabled"}>
          <span class="act">TAKE ${count}</span>
          <span class="hint">${esc(hint)}</span>
        </button>`;
    }
    return out;
  },

  // The view once mySeat's take lands, drawn while the submit is in flight.
  applyLocal(gameState, mySeat, move) {
    const count = Number(move?.take?.count);
    const pile = Number(gameState.pile);
    if (!legal(pile, count)) return null;
    return {
      ...gameState,
      pile: BigInt(pile - count),
      toMove: { [mySeat === "p1" ? "p2" : "p1"]: null },
      lastTake: [{ seat: { [mySeat]: null }, count: BigInt(count) }],
    };
  },
};
