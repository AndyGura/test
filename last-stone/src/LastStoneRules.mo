/// LastStoneRules — Last Stone game logic, as a pure `#turnBased` module.
///
/// Seats: #p1 = Player 1 (moves first), #p2 = Player 2 (display only).
///
/// Rules:
///   START  a pile of 21 stones sits between the two players.
///   TURNS  Player 1 moves first, then the players take turns.
///   TAKE   on your turn you take 1, 2 or 3 stones from the pile, and
///          never more stones than the pile still holds.
///   LOSE   whoever takes the last stone loses.
///   There are no draws: every game ends with the pile empty.

import TP "mo:duel-game-core";
import List "mo:core/List";
import Nat "mo:core/Nat";

module {

  /// Served at `GET /semantics`: everything a frontend author who cannot
  /// see this file needs.
  public let SEMANTICS : Text = "GAME: Last Stone
MODE: turnBased (one action per turn, seats strictly alternate)
SEATS: p1 = Player 1 (moves first), p2 = Player 2
OPTIONS: none (type Options = record {})

VIEW (Candid)
  type Seat = variant { p1; p2 };
  type Take = record { seat : Seat; count : nat };
  type View = record { pile : nat; toMove : Seat; lastTake : opt Take };
  pile: the number of stones left, 21 at the start, 0 once the game is over.
  toMove: the seat whose turn it is (after the final take it names the
    other seat; the game is over then and nobody moves).
  lastTake: the most recent take, by which seat and how many stones;
    null before the first move.
  Nothing is hidden: both seats see the same view.

ACTION (Candid)
  type Action = variant { take : record { count : nat } };
  count: how many stones the seat on turn takes from the pile.

RULES
  The seat on turn takes count stones; the pile shrinks by count and the
  turn passes to the other seat.
  Rejected: count is 0 or more than 3 (Take 1, 2 or 3 stones.), or count
  is more than the pile holds (Only N stones are left.).

ENDINGS
  The seat that takes the last stone (its take leaves pile = 0) loses:
  the other seat wins. There is no draw.

CLIENT NOTES
  The legal counts are 1 up to min(3, pile). When pile is 1 the seat on
  turn has a single move, taking the last stone, and loses with it.
  lastTake marks the opponent's last move, live and in the final view.
";

  /// One move: who took, and how many stones.
  public type Take = { seat : TP.Seat; count : Nat };

  /// The raw decision only: how many stones to take.
  public type Action = { #take : { count : Nat } };

  public type State = {
    pile : Nat;
    toMove : TP.Seat;
    lastTake : ?Take;
  };

  /// Nothing is hidden: every seat sees the whole state.
  public type View = State;

  /// No table options: every game starts with 21 stones.
  public type Options = {};

  public let START_PILE : Nat = 21;
  public let MAX_TAKE : Nat = 3;

  public func sideName(seat : TP.Seat) : Text = switch (seat) {
    case (#p1) "Player 1";
    case (#p2) "Player 2";
  };

  func other(seat : TP.Seat) : TP.Seat = switch (seat) {
    case (#p1) #p2;
    case (#p2) #p1;
  };

  public func checkOptions(_ : Options) : ?Text = null;

  public func init(_ : Options, _rng : TP.Rng) : State = {
    pile = START_PILE;
    toMove = #p1;
    lastTake = null;
  };

  public func toMove(s : State) : TP.Seat = s.toMove;

  /// Every count `validate` accepts: 1 up to min(3, pile).
  public func legalActions(s : State, _seat : TP.Seat) : [Action] {
    let out = List.empty<Action>();
    for (count in Nat.rangeInclusive(1, Nat.min(MAX_TAKE, s.pile))) {
      out.add(#take { count });
    };
    out.toArray();
  };

  /// null = legal. The only legality gate in the system; the frontend's
  /// disabled buttons are cosmetic. The engine has already checked that
  /// `seat` is on turn.
  public func validate(s : State, _seat : TP.Seat, a : Action) : ?Text {
    switch (a) {
      case (#take { count }) {
        if (count == 0 or count > MAX_TAKE) return ?"Take 1, 2 or 3 stones.";
        if (count > s.pile) {
          return ?(
            if (s.pile == 1) "Only 1 stone is left." else "Only " # s.pile.toText() # " stones are left."
          );
        };
        null;
      };
    };
  };

  /// Applies a validated take. Taking the last stone loses.
  public func resolve(s : State, seat : TP.Seat, a : Action) : {
    state : State;
    verdict : ?TP.Verdict;
  } {
    let count = switch (a) { case (#take t) t.count };
    let pile : Nat = if (count >= s.pile) 0 else s.pile - count;
    let verdict : ?TP.Verdict = if (pile == 0) {
      // The mover took the last stone: the other seat wins.
      ?(switch (seat) { case (#p1) #p2Wins; case (#p2) #p1Wins });
    } else null;
    {
      state = {
        pile;
        toMove = other(seat);
        lastTake = ?{ seat; count };
      };
      verdict;
    };
  };

  /// One action of the seat on turn: checked, then applied.
  public func move(s : State, seat : TP.Seat, a : Action, _ : TP.Rng) : {
    #ok : { state : State; verdict : ?TP.Verdict };
    #err : Text;
  } = switch (validate(s, seat, a)) {
    case (?why) #err why;
    case null #ok(resolve(s, seat, a));
  };

  public func view(s : State, _seat : TP.Seat, _over : Bool) : View = s;

  /// The functions the framework calls. Never stored by it: the host hands
  /// `spec` in on every call.
  public let spec : TP.Spec<State, Action, View, Options> = #turnBased {
    checkOptions;
    init;
    toMove;
    move;
    view;
  };
};
