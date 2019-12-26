import "util.dart";
import "intcode.dart";

void run(String filename) {
  const n = 100;
  List<int> code = parseInts(readFile(filename));
  bool insideBeam(int x, int y) => Processor(code, [x, y]).execute().first != 0;
  int sum = 0;
  for (int y = 0; y < 50; y++) {
    for (int x = 0; x < 50; x++) {
      if (insideBeam(x, y)) sum++;
    }
  }
  print("Tracked:  $sum");
  int leftBound = 0;
  outer:
  for (int y = n;; y++) {
    inner:
    for (int x = leftBound;; x++) {
      if (insideBeam(x, y)) {
        leftBound = x;
        if (insideBeam(x + n - 1, y - n + 1)) {
          print("Position: ($x, ${y - n + 1})");
          print("Code:     ${x * 10000 + (y - n + 1)}");
          break outer;
        }
        break inner;
      }
    }
  }
}

void main(List<String> args) {
  run(args[0]);
}
