import "util.dart";

List<int> execute(List<int> prog, int input) {
  var output = <int>[];
  int pc = 0;
  int arg1 = 0;
  int arg2 = 0;
  int out = 0;
  // parse intcode instruction
  void parse(int nin, int nout) {
    int modes = prog[pc++] ~/ 100;
    int getArg() {
      var imm = modes % 10;
      modes ~/= 10;
      if (imm != 0)
        return prog[pc++];
      else
        return prog[prog[pc++]];
    }

    switch (nin) {
      case 1:
        arg1 = getArg();
        break;
      case 2:
        arg1 = getArg();
        arg2 = getArg();
        break;
    }
    if (nout == 1) out = prog[pc++];
  }

  // main loop
  for (;;) {
    switch (prog[pc] % 100) {
      case 1: // add
        parse(2, 1);
        prog[out] = arg1 + arg2;
        break;
      case 2: // multiply
        parse(2, 1);
        prog[out] = arg1 * arg2;
        break;
      case 3: // input
        parse(0, 1);
        prog[out] = input;
        break;
      case 4: // output
        parse(1, 0);
        output.add(arg1);
        break;
      case 5: // jump if true
        parse(2, 0);
        if (arg1 != 0) pc = arg2;
        break;
      case 6:
        parse(2, 0);
        if (arg1 == 0) pc = arg2;
        break;
      case 7: // less than
        parse(2, 1);
        prog[out] = arg1 < arg2 ? 1 : 0;
        break;
      case 8: // equals
        parse(2, 1);
        prog[out] = arg1 == arg2 ? 1 : 0;
        break;
      case 99: // halt
        return output;
      default:
        throw ("error: bad opcode ${prog[pc]}");
    }
  }
}

List<int> parse(String input) =>
    RegExp(r"-?[0-9]+").allMatches(input).map((x) => int.parse(x[0])).toList();

void test() {
  void trial(String code, int? input) {
    var prog = parse(code);
    var orig = [...prog];
    var output = execute(prog, input ?? 0);
    if (input == null)
      print("Program: $orig => $prog");
    else {
      print("Program: $orig");
      print("I/O: $input => $output");
    }
  }

  trial("1,9,10,3,2,3,11,0,99,30,40,50", null);
  trial("101,0,0,0,99", null);
  trial("2,3,0,3,99", null);
  trial("2,4,4,5,99,0", null);
  trial("1,1,1,4,99,5,6,0,99", null);
  var eq8 = "3,9,8,9,10,9,4,9,99,-1,8";
  trial(eq8, 8);
  trial(eq8, 17);
  var lt8 = "3,9,7,9,10,9,4,9,99,-1,8";
  trial(lt8, 7);
  trial(lt8, 8);
  var eq8i = "3,3,1108,-1,8,3,4,3,99";
  trial(eq8i, 8);
  trial(eq8i, 17);
  var lt8i = "3,3,1107,-1,8,3,4,3,99";
  trial(lt8i, 7);
  trial(lt8i, 8);
  var not0 = "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9";
  trial(not0, 1);
  trial(not0, 0);
  var not0i = "3,3,1105,-1,9,1101,0,0,12,4,12,99,1";
  trial(not0i, 1);
  trial(not0i, 0);
  var cmp8 = """3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
	      1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
	      999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99""";
  trial(cmp8, 7);
  trial(cmp8, 8);
  trial(cmp8, 9);
}

void run(String filename) {
  var prog = parse(readFile(filename));
  print(execute([...prog], 1));
  print(execute([...prog], 5));
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
