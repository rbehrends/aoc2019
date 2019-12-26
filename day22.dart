import "util.dart";

int extractNum(String line) => int.parse(line.split(" ").last);

// The plain approach from part 1, still useful to verify that
// test cases work.

List<int> shuffleDeck(int n, int count, String input) {
  var deck = List.generate(n, (i) => i);
  for (int i = 0; i < count; i++) {
    for (var line in input.trim().split("\n")) {
      line = line.trim();
      if (line.startsWith("cut ")) {
        var k = extractNum(line);
        if (k >= 0)
          deck = [...deck.sublist(k), ...deck.sublist(0, k)];
        else
          deck = [...deck.sublist(n + k), ...deck.sublist(0, n + k)];
      } else if (line == "deal into new stack") {
        deck = deck.reversed.toList();
      } else if (line.startsWith("deal with increment ")) {
        var k = extractNum(line);
        var newdeck = List<int>.filled(n, 0);
        for (int i = 0, p = 0; i < n; i++) {
          newdeck[p] = deck[i];
          p += k;
          if (p >= n) p -= n;
        }
        deck = newdeck;
      } else {
        throw ArgumentError("bad input line");
      }
    }
  }
  return deck;
}

// The "virtual deck" essentially implements a 2x2 matrix M =
//
//    [ [ mult, 0 ],
//      [  add, 1 ] ]
//
// over Z_mod to represent the function x -> mult * x + add. Everything
// then becomes a matrix operation. The various deck operations are
// linear transformations on the matrix; and repeated applications of
// the shuffle process simply mean taking the matrix to the n-th power,
// which can be done through exponentiation by squaring.

class VirtualDeck {
  int mult, add, mod;
  int get length => mod;
  String toString() => "[ i * $mult + $add mod $mod ]";
  int _multiplyAddMod(int a, int b, int c) =>
      ((a.bigint * b.bigint + c.bigint) % mod.bigint).toInt();
  VirtualDeck(int this.mod, int this.mult, int this.add);

  VirtualDeck operator *(VirtualDeck other) => VirtualDeck(
      mod,
      _multiplyAddMod(mult, other.mult, 0),
      _multiplyAddMod(other.mult, add, other.add));

  VirtualDeck pow(int n) {
    if (n == 0) return VirtualDeck(mod, 1, 0);
    var t = pow(n ~/ 2);
    if (n.isEven)
      return t * t;
    else
      return t * t * this;
  }

  int operator [](int k) {
    // solve mult * x + add = k for x.
    // or [ x, 1 ] * M = [ k, 1 ].
    var inv = mult.modInverse(mod);
    return _multiplyAddMod(k - add, inv, 0);
  }

  List<int> generate() {
    var result = List.filled(mod, 0);
    for (int i = 0, p = add.toInt(); i < mod; i++) {
      result[p] = i;
      p = (p + mult.toInt()) % mod;
    }
    return result;
  }
}

VirtualDeck smartShuffle(int size, int count, String input) {
  int mult = 1;
  int add = 0;
  for (var line in input.trim().split("\n")) {
    line = line.trim();
    if (line.startsWith("cut ")) {
      var k = extractNum(line);
      // M := M * [ [ 1, 0 ], [ -k, 1 ] ]
      add = (add - k) % size;
    } else if (line == "deal into new stack") {
      // M := M * [ [ -1, 0 ], [ -1, 1] ]
      mult = (-mult) % size;
      add = (-add - 1) % size;
    } else if (line.startsWith("deal with increment ")) {
      var k = extractNum(line);
      // M := M * [ [ k, 0 ], [ 0, 1 ] ]
      add = (add * k) % size;
      mult = (mult * k) % size;
    } else {
      throw ArgumentError("bad input line");
    }
  }
  return VirtualDeck(size, mult, add).pow(count);
}

void test() {
  void trial(String input) {
    int iter = 1;
    print(shuffleDeck(10, iter, input).join(" "));
    var deck = smartShuffle(10, iter, input);
    print(deck.generate().join(" "));
    print([for (int i = 0; i < deck.length; i++) deck[i]].join(" "));
    print("");
  }

  trial("""
  deal with increment 7
  deal into new stack
  deal into new stack
  """);
  trial("""
  deal with increment 7
  deal into new stack
  """);
  trial("""
  cut 6
  deal with increment 7
  deal into new stack
  """);
  trial("""
  deal with increment 7
  deal with increment 9
  cut -2
  """);
  trial("""
  deal into new stack
  cut -2
  deal with increment 7
  cut 8
  cut -4
  deal with increment 7
  cut 3
  deal with increment 9
  deal with increment 3
  cut -1
  """);
}

void run(String filename) {
  var input = readFile(filename);
  var deck = shuffleDeck(10007, 1, input);
  print(deck.indexOf(2019));
  int decksize = 119315717514047;
  int shuffles = 101741582076661;
  var deck2 = smartShuffle(decksize, shuffles, input);
  print(deck2[2020]);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
