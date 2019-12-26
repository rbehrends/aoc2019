import "util.dart";
import "intcode.dart";

class Network {
  List<Node> nodes;
  List<int>? nat = null;
  Network(List<int> code, int size)
      : nodes = [for (int i = 0; i < size; i++) Node(code, i)];
}

class Node {
  Processor cpu;
  Queue<int> output = ListQueue();
  Node(List<int> code, int id) : cpu = Processor(code, [id]) {
    cpu.executeSyncInput(onOutput: (out) => output.add(out));
  }
  void send(List<int> data) => cpu.input.addAll(data);
  bool timeslice() {
    bool haveData = cpu.input.length >= 2;
    if (!haveData) {
      cpu.input.add(-1);
    }
    cpu.executeSyncInput(onOutput: (out) => output.add(out));
    return haveData;
  }

  bool transmitPackets(Network network) {
    bool haveData = false;
    while (output.length >= 3) {
      haveData = true;
      int dest = output.removeFirst();
      int x = output.removeFirst();
      int y = output.removeFirst();
      if (dest == 255) {
        network.nat = [x, y];
      } else
        network.nodes[dest].send([x, y]);
    }
    return haveData;
  }
}

void run(String filename) {
  var code = parseInts(readFile(filename));
  var network = Network(code, 50);
  bool natActive = false;
  int? lastY = null;
  for (;;) {
    bool activity = false;
    for (var node in network.nodes) {
      activity |= node.timeslice();
      activity |= node.transmitPackets(network);
    }
    var nat = network.nat;
    if (nat != null && !natActive) {
      print("NAT startup code: ${nat[1]}");
      natActive = true;
    }
    if (!activity) {
      int y = nat![1];
      if (y == lastY) {
        print("NAT repeated code: $y");
        return;
      }
      lastY = y;
      network.nodes[0].send(nat);
    }
  }
}

void main(List<String> args) {
  run(args[0]);
}
