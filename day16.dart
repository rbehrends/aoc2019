import "util.dart";
import "dart:typed_data";

Uint8List fftPhase(Uint8List input, int offset) {
  int n = input.length + offset;
  Uint8List result = Uint8List(input.length);
  // This is essentially a multiplication by an upper triangular matrix
  // where all entries to the right of the diagonal in the bottom half
  // are 1. We can therefore optimize for that case.
  if (offset * 2 < n) {
    for (int i = offset; i < n; i++) {
      int step = (i + 1);
      int sum = 0;
      for (int p = -1; p < n;) {
        p += step;
        int m = min(p + step, n);
        while (p < m) sum += input[p++ - offset];
        p += step;
        m = min(p + step, n);
        while (p < m) sum -= input[p++ - offset];
      }
      result[i] = sum.abs() % 10;
    }
  } else {
    int sum = 0;
    for (int i = n - offset - 1; i >= 0; i--) {
      sum += input[i];
      result[i] = sum.abs() % 10;
    }
  }
  return result;
}

String fft(Uint8List input, int n) {
  for (int i = 0; i < n; i++) input = fftPhase(input, 0);
  return input.sublist(0, 8).join();
}

String fftOff(Uint8List input, int n, {int rep = 10000}) {
  int offset(Uint8List input) {
    int r = 0;
    for (int i = 0; i < 7; i++) r = r * 10 + input[i];
    return r;
  }

  var data = Uint8List(input.length * rep);
  for (int i = 0; i < rep; i++)
    data.setRange(i * input.length, (i + 1) * input.length, input);
  int off = offset(input);
  data = data.sublist(off);
  for (int i = 0; i < n; i++) {
    data = fftPhase(data, off);
  }
  return data.sublist(0, 8).join();
}

Uint8List parseDigits(String input) => Uint8List.fromList(
    RegExp("[0-9]").allMatches(input).map((m) => int.parse(m[0])).toList());

void test() {
  void trial(String input) => print(fft(parseDigits(input), 100));
  // trial("12345678");
  trial("80871224585914546619083218645595");
  trial("19617804207202209144916044189917");
  trial("69317163492948606335995924319873");
  void trial2(String input) => print(fftOff(parseDigits(input), 100));
  trial2("03036732577212944063491565474664");
  trial2("02935109699940807407585447034323");
  trial2("03081770884921959731165446850517");
}

void run(String filename) =>
    print(fftOff(parseDigits(readFile(filename)), 100));

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
