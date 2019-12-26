import "util.dart";
import "intcode.dart";

void run(String filename) {
  List<int> encode(List<String> instr) => (instr.join("\n") + "\n").codeUnits;
  var code = parseInts(readFile(filename));
  void executeSpringCode(List<String> instr) {
    var robot = Processor(code, encode(instr));
    var output = robot.execute();
    var result = output.last < 256 ? "FAIL" : output.removeLast().toString();
    print(String.fromCharCodes(output));
    print(result);
  }

  // Jump if there's a hole up to three tiles ahead and ground four
  // tiles ahead.
  // (!A | !B | !C) & D
  executeSpringCode([
    "NOT A J",
    "NOT B T",
    "OR T J",
    "NOT C T",
    "OR T J",
    "AND D J",
    "WALK",
  ]);
  // As above, but we only jump if after the jump we can either walk
  // again (E) or jump again (H).
  // (!A | !B | !C) & D & (E | H)
  executeSpringCode([
    "NOT A J",
    "NOT B T",
    "OR T J",
    "NOT C T",
    "OR T J",
    "AND D J",
    "NOT E T",
    "NOT T T",
    "OR H T",
    "AND T J",
    "RUN"
  ]);
}

void main(List<String> args) {
  run(args[0]);
}
