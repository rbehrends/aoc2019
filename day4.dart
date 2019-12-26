import "util.dart";

void check(int n, void notify(bool hasPair, bool hasTruePair)) {
  // use sentinels at start and end for true pairs
  var s = [-1, ...n.toString().codeUnits, -1];
  bool hasPair = false;
  bool hasTruePair = false;
  for (int i = 2; i < s.length - 1; i++) {
    if (s[i - 1] > s[i]) return;
    if (s[i - 1] == s[i]) {
      hasPair = true;
      if (s[i - 2] != s[i - 1] && s[i] != s[i + 1]) hasTruePair = true;
    }
  }
  notify(hasPair, hasTruePair);
}

void analyze(int start, int end) {
  int pairs = 0;
  int truepairs = 0;
  for (int n = start; n <= end; n++) {
    check(n, (hasPair, hasTruePair) {
      if (hasPair) pairs++;
      if (hasTruePair) truepairs++;
    });
  }
  print("Pairs: $pairs");
  print("True pairs: $truepairs");
}

void run(String filename) {
  var data = RegExp("[0-9]+")
      .allMatches((readFile(filename)))
      .map((m) => int.parse(m[0]))
      .toList();
  print(data);
  analyze(data[0], data[1]);
}

void main(List<String> args) {
  run(args[0]);
}
