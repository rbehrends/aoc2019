import "util.dart";
import "intcode.dart";

void findMaxSignal(List<int> prog) {
  var maxSignal = 0;
  for (var perm in permutations([0, 1, 2, 3, 4])) {
    var signal = 0;
    for (var phase in perm) {
      signal = Processor(prog, [phase, signal]).execute().first;
    }
    if (signal > maxSignal) maxSignal = signal;
  }
  print(maxSignal);
}

void findMaxFeedbackSignal(List<int> prog) {
  var maxSignal = 0;
  for (var perm in permutations([5, 6, 7, 8, 9])) {
    var signal = 0;
    var amps = perm.map((phase) => Processor(prog, [phase])).toList();
    while (!amps.last.halted) {
      for (var amp in amps) {
        amp.input.add(signal);
        amp.executeSyncOutput(onOutput: (output) => signal = output);
      }
    }
    if (signal > maxSignal) maxSignal = signal;
  }
  print(maxSignal);
}

void findMaxFeedbackSignal2(List<int> prog) {
  var maxSignal = 0;
  for (var perm in permutations([5, 6, 7, 8, 9])) {
    var signal = 0;
    var amps = perm.map((phase) => Processor(prog, [phase])).toList();
    var feedback = List.generate(amps.length - 1, (i) => amps[i + 1].input.add);
    feedback.add((sig) {
      amps[0].input.add(sig);
      signal = sig;
    });
    feedback.last(0);
    while (!amps.last.halted) {
      for (int i = 0; i < amps.length; i++) {
        amps[i].executeSyncInput(onOutput: feedback[i]);
      }
    }
    if (signal > maxSignal) maxSignal = signal;
  }
  print(maxSignal);
}

void test() {
  var perms = <String>{};
  for (var perm in permutations([0, 1, 2, 3, 4])) {
    perms.add(perm.toString());
  }
  print(perms.length);
  findMaxSignal(parseInts("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0"));
  findMaxSignal(parseInts("3,23,3,24,1002,24,10,24,1002,23,-1,23,"
      "101,5,23,23,1,24,23,23,4,23,99,0,0"));
  findMaxSignal(parseInts("3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,"
      "1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0"));
  findMaxFeedbackSignal(
      parseInts("3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,"
          "27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5"));
  findMaxFeedbackSignal(parseInts(
      "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,"
      "-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,"
      "53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10"));
}

void run(String filename) {
  var prog = parseInts(readFile(filename));
  findMaxSignal(prog);
  findMaxFeedbackSignal(prog);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
