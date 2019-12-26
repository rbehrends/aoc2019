library intcode;

import "dart:collection";

class Processor {
  Processor(List<int> prog, [List<int> input = const []])
      : prog = [...prog],
        input = Queue.of(input);
  final List<int> prog;
  final Queue<int> input;
  final Queue<int> output = Queue<int>();
  int _pc = 0;
  int _relbase = 0;
  bool halted = false;
  bool blocked = false;

  Processor fork() {
    var result = Processor(prog, input.toList());
    result.output.addAll(output);
    result._pc = _pc;
    result._relbase = _relbase;
    result.halted = halted;
    result.blocked = blocked;
    return result;
  }

  static const opAdd = 1,
      opMult = 2,
      opInput = 3,
      opOutput = 4,
      opIfTrue = 5,
      opIfFalse = 6,
      opLessThan = 7,
      opEquals = 8,
      opRelBase = 9,
      opHalt = 99;

  int _mem(int p) {
    while (prog.length <= p) prog.add(0);
    return p;
  }

  int _step() {
    int opcode = prog[_pc] % 100;
    int modes = prog[_pc] ~/ 100;
    _pc++;

    int arg() {
      int mode = modes % 10;
      modes ~/= 10;
      int d = prog[_pc++];
      switch (mode) {
        case 0:
          return prog[_mem(d)];
        case 1:
          return d;
        case 2:
          return prog[_mem(_relbase + d)];
      }
      throw StateError("invalid argument mode");
    }

    void out(int result) {
      int d = prog[_pc++];
      switch (modes % 10) {
        case 0:
          prog[_mem(d)] = result;
          break;
        case 2:
          prog[_mem(_relbase + d)] = result;
          break;
        default:
          throw StateError("invalid argument mode");
      }
    }

    switch (opcode) {
      case opAdd:
        out(arg() + arg());
        break;
      case opMult:
        out(arg() * arg());
        break;
      case opInput:
        if (blocked = input.isEmpty) {
          _pc--; // rewind pc for resume
          break;
        }
        out(input.removeFirst());
        break;
      case opOutput:
        output.add(arg());
        break;
      case opIfTrue:
        if (arg() != 0)
          _pc = arg();
        else
          _pc++;
        break;
      case opIfFalse:
        if (arg() == 0)
          _pc = arg();
        else
          _pc++;
        break;
      case opLessThan:
        // dart guarantees left-to-right evaluation of arguments
        out(arg() < arg() ? 1 : 0);
        break;
      case opEquals:
        out(arg() == arg() ? 1 : 0);
        break;
      case opRelBase:
        _relbase += arg();
        break;
      case opHalt:
        halted = true;
        break;
      default:
        throw StateError("error: bad opcode ${prog[_pc - 1]}");
    }
    return opcode;
  }

  Queue<int> execute() {
    while (!halted) _step();
    return output;
  }

  void executeWithIO(
      {required int onInput(), required void onOutput(int out)}) {
    while (!halted) {
      switch (_step()) {
        case opOutput:
          onOutput(output.removeLast());
          break;
        case opInput:
          if (blocked) input.add(onInput());
          break;
      }
    }
  }

  List<int> executeSyncIO({int output = 1, List<int> input = const []}) {
    List<int> result = [];
    this.input.addAll(input);
    while (!halted && result.length < output) {
      if (_step() == opOutput) result.add(this.output.removeLast());
    }
    return result;
  }

  void executeSyncOutput({required void onOutput(int out)}) {
    while (!halted) {
      if (_step() == opOutput) {
        onOutput(output.removeLast());
        return;
      }
    }
  }

  void executeSyncInput({required void onOutput(int out)}) {
    blocked = false;
    while (!halted && !blocked) {
      if (_step() == opOutput) {
        onOutput(output.removeLast());
      }
    }
  }
}
