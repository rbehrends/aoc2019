import "util.dart";
import "intcode.dart";

void run(List<int> prog, int input) {
  print(Processor(prog, [input]).execute());
}

void main(List<String> args) {
  var prog = parseInts(readFile(args[0]));
  run(prog, 1);
  run(prog, 2);
}
