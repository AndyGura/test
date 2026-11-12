// Unit checks for LastStoneRules: init/validate/resolve/move called
// directly, no engine. One block per illegal move and per ending.
// Run: mops test
import R "../src/LastStoneRules";
import TP "mo:duel-game-core";
import Rng "mo:duel-game-core/rng";
import Debug "mo:core/Debug";
import Runtime "mo:core/Runtime";

let rng = Rng.new(42);
let options : R.Options = {};

func at(pile : Nat, toMove : TP.Seat) : R.State = { pile; toMove; lastTake = null };
func take(count : Nat) : R.Action = #take { count };

// One action through `move`, trapping on a rejection or an unexpected end.
func step(s : R.State, seat : TP.Seat, a : R.Action) : R.State {
  switch (R.move(s, seat, a, rng)) {
    case (#err why) Runtime.trap("rejected: " # why);
    case (#ok { verdict = ?_ }) Runtime.trap("unexpected end");
    case (#ok { state; verdict = null }) state;
  };
};

func expectRejected(s : R.State, seat : TP.Seat, a : R.Action, what : Text) {
  switch (R.validate(s, seat, a)) {
    case (?_) {};
    case null Runtime.trap("expected rejection: " # what);
  };
  switch (R.move(s, seat, a, rng)) {
    case (#err _) {};
    case (#ok _) Runtime.trap("move accepted what validate rejects: " # what);
  };
};

// ── 1. options, init and spec wiring ──────────────────────────────────────
assert R.checkOptions(options) == null;
let s0 = R.init(options, rng);
assert s0.pile == 21;
assert s0.toMove == #p1;
assert s0.lastTake == null;
assert R.toMove(s0) == #p1;
let sp = switch (R.spec) {
  case (#turnBased s) s;
  case (#simultaneous _) Runtime.trap("Last Stone is a #turnBased game");
};
let s1 = sp.init(options, rng);
assert s1 == s0;
assert sp.toMove(s1) == #p1;
assert sp.view(s1, #p2, false) == s1;
Debug.print("1. options + init + spec wiring OK");

// ── 2. validate: 1, 2 and 3 are legal; 0, 4+ and more than the pile are not
for (n in [1, 2, 3].values()) {
  switch (R.validate(s0, #p1, take(n))) {
    case null {};
    case (?why) Runtime.trap("taking " # debug_show n # " of 21 must be legal: " # why);
  };
};
expectRejected(s0, #p1, take(0), "take 0");
expectRejected(s0, #p1, take(4), "take 4");
expectRejected(s0, #p1, take(21), "take the whole pile");
expectRejected(at(2, #p2), #p2, take(3), "take 3 of 2");
expectRejected(at(1, #p1), #p1, take(2), "take 2 of 1");
switch (R.validate(at(2, #p1), #p1, take(3))) {
  case (?"Only 2 stones are left.") {};
  case (other) Runtime.trap("unexpected message: " # debug_show other);
};
switch (R.validate(at(1, #p1), #p1, take(2))) {
  case (?"Only 1 stone is left.") {};
  case (other) Runtime.trap("unexpected message: " # debug_show other);
};
// legalActions agrees with validate.
assert R.legalActions(s0, #p1) == [take(1), take(2), take(3)];
assert R.legalActions(at(2, #p2), #p2) == [take(1), take(2)];
assert R.legalActions(at(1, #p1), #p1) == [take(1)];
Debug.print("2. validate OK");

// ── 3. a take shrinks the pile, passes the turn, records the move ─────────
let s2 = step(s0, #p1, take(3));
assert s2.pile == 18;
assert s2.toMove == #p2;
assert s2.lastTake == ?{ seat = #p1; count = 3 };
let s3 = step(s2, #p2, take(1));
assert s3.pile == 17;
assert s3.toMove == #p1;
assert s3.lastTake == ?{ seat = #p2; count = 1 };
Debug.print("3. take + alternation OK");

// ── 4. taking the last stone loses ────────────────────────────────────────
// p1 forced to take the last one: p2 wins.
switch (R.move(at(1, #p1), #p1, take(1), rng)) {
  case (#ok { state; verdict = ?#p2Wins }) {
    assert state.pile == 0;
    assert state.lastTake == ?{ seat = #p1; count = 1 };
  };
  case (_) Runtime.trap("p1 taking the last stone must lose");
};
// p2 empties a pile of 3 in one go: p1 wins.
switch (R.move(at(3, #p2), #p2, take(3), rng)) {
  case (#ok { state; verdict = ?#p1Wins }) assert state.pile == 0;
  case (_) Runtime.trap("p2 taking the last stones must lose");
};
// Leaving one stone is not an ending.
switch (R.move(at(4, #p2), #p2, take(3), rng)) {
  case (#ok { state; verdict = null }) {
    assert state.pile == 1;
    assert state.toMove == #p1;
  };
  case (_) Runtime.trap("leaving one stone must continue the game");
};
Debug.print("4. endings OK");

// ── 5. a whole game: always taking 1, the 21st stone falls to p1 ──────────
do {
  var s = s0;
  var seat : TP.Seat = #p1;
  var verdict : ?TP.Verdict = null;
  var moves = 0;
  label play while (verdict == null) {
    switch (R.move(s, seat, take(1), rng)) {
      case (#err why) Runtime.trap("rejected mid-game: " # why);
      case (#ok r) {
        s := r.state;
        verdict := r.verdict;
        moves += 1;
        seat := R.toMove(s);
      };
    };
    if (moves > 21) Runtime.trap("game did not end");
  };
  assert moves == 21;
  assert s.pile == 0;
  assert verdict == ?#p2Wins; // p1 took stones 1, 3, …, 21
};
Debug.print("5. full game OK");

// ── 6. view: nothing hidden ───────────────────────────────────────────────
assert R.view(s2, #p1, false) == s2;
assert R.view(s2, #p2, false) == s2;
assert R.view(s2, #p2, true) == s2;
Debug.print("6. view OK");

Debug.print("ALL LastStoneRules RULESUNIT CHECKS PASSED");
