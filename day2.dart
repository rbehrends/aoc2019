import "util.dart";

void execute(List<int> prog) {
  int pc = 0;
  for (;;) {
    switch (prog[pc++]) {
      case 1:
        int a = prog[pc++];
        int b = prog[pc++];
        int r = prog[pc++];
        prog[r] = prog[a] + prog[b];
        break;
      case 2:
        int a = prog[pc++];
        int b = prog[pc++];
        int r = prog[pc++];
        prog[r] = prog[a] * prog[b];
        break;
      case 99:
        return;
    }
  }
}

void executeMod(List<int> prog, int noun, int verb) {
  prog[1] = noun;
  prog[2] = verb;
  execute(prog);
}

void test() {
  for (var code in [
    "1,9,10,3,2,3,11,0,99,30,40,50",
    "1,0,0,0,99",
    "2,3,0,3,99",
    "2,4,4,5,99,0",
    "1,1,1,4,99,5,6,0,99",
  ]) {
    var prog = parseInts(code);
    execute(prog);
    print(prog);
  }
}

void run(String filename) {
  var orig = parseInts(readFile(filename));
  var prog = [...orig];
  executeMod(prog, 12, 2);
  print(prog[0]);
  for (var d = 0;; d++) {
    for (var noun = 0; noun <= d; noun++) {
      var verb = d - noun;
      prog = [...orig];
      executeMod(prog, noun, verb);
      if (prog[0] == 19690720) {
        print(noun * 100 + verb);
        return;
      }
    }
  }
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
