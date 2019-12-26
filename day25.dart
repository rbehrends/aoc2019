import "dart:io";
import "util.dart";
import "intcode.dart";

List<String> lines(String text) =>
    text.trim().split("\n").map((s) => s.trim()).toList();

const fatalItems = {
  "giant electromagnet",
  "molten lava",
  "infinite loop",
  "escape pod",
  "photons",
};

class Room {
  String name = "???";
  String desc = "";
  List<String> exits = [];
  List<String> items = [];
  String text;
  String toString() => name;
  int get hashCode => name.hashCode;
  bool operator ==(covariant Room other) => name == other.name;
  Room.parse(String text) : text = text.trim() {
    bool parseItems = false;
    for (var line in lines(text)) {
      switch (line) {
        case "Doors here lead:":
          parseItems = false;
          break;
        case "Items here:":
          parseItems = true;
          break;
        case "Command?":
          return;
        default:
          if (line.startsWith("- ")) {
            (parseItems ? items : exits).add(line.substring(2));
          } else if (line.startsWith("==")) {
            name = line;
          } else if (line != "") {
            desc = "$desc$line\n";
          }
      }
    }
  }
}

class SearchState {
  final Room room;
  final Processor robot;
  SearchState(this.room, this.robot);
}

class Path {
  final Room room;
  final List<String> path;
  Path(this.room, this.path);
}

class Robot {
  Processor cpu;
  Room room;
  Map<Room, Map<String, Room>> map = {};

  Robot._(Processor this.cpu, Room this.room);

  factory Robot(List<int> code) {
    var cpu = Processor(code);
    var room = Room.parse(executeAscii(cpu, ""));
    return Robot._(cpu, room);
  }

  static String executeAscii(Processor cpu, String input) {
    var output = StringBuffer();
    if (input != "") cpu.input.addAll("$input\n".codeUnits);
    cpu.executeSyncInput(onOutput: output.writeCharCode);
    return output.toString();
  }

  String runCommand(String input, {Processor? cpu}) =>
      executeAscii(cpu ?? this.cpu, input);

  Room moveDirection(String input, {Processor? cpu}) =>
      Room.parse(runCommand(input, cpu: cpu));

  void explore(Room start) {
    var queue = Queue.of([SearchState(start, cpu.fork())]);
    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      var currentRoom = current.room;
      if (map.containsKey(current.room)) continue;
      for (var exit in current.room.exits) {
        var fork = current.robot.fork();
        var nextRoom = moveDirection(exit, cpu: fork);
        map[currentRoom] ??= {};
        map[currentRoom][exit] = nextRoom;
        queue.add(SearchState(nextRoom, fork));
      }
    }
  }

  Set<String> findItems() =>
      map.keys.fold(<String>{}, (items, room) => items..addAll(room.items));

  List<String> findPath(Room start, Room end) {
    var seen = <Room>{};
    var queue = ListQueue.of([Path(start, <String>[])]);
    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      if (current.room == end) return current.path;
      if (seen.contains(current.room)) continue;
      seen.add(current.room);
      for (var exit in current.room.exits) {
        queue.add(Path(map[current.room][exit], [...current.path, exit]));
      }
    }
    throw StateError("path not found");
  }

  Room findItem(String item) {
    for (var room in map.keys) {
      if (room.items.contains(item)) return room;
    }
    throw ArgumentError("item not found");
  }

  Path findFinalRoom() {
    for (var room in map.keys) {
      for (var exit in room.exits) {
        if (map[room][exit] == room) return Path(room, [exit]);
      }
    }
    throw StateError("no final room");
  }

  void autonomousMode() {
    explore(room);
    var items =
        findItems().where((item) => !fatalItems.contains(item)).toList();
    void goto(Room dest) {
      var path = findPath(room, dest);
      for (var exit in path) {
        runCommand(exit);
      }
      room = dest;
    }

    var destination = findFinalRoom();

    for (var item in items) {
      goto(findItem(item));
      runCommand("take $item");
    }
    goto(destination.room);
    for (var item in items) {
      runCommand("drop ${item}");
    }
    for (int bitset = 0; bitset < (1 << items.length); bitset++) {
      var inv = <String>[];
      for (int i = 0; i < items.length; i++) {
        if (bitset & (1 << i) != 0) inv.add(items[i]);
      }
      var save = cpu.fork();
      for (var item in inv) {
        runCommand("take ${item}");
      }
      room = moveDirection(destination.path.first);
      if (room != destination.room) {
        print(room.text);
        print("\nInventory: ${inv.join(", ")}");
        return;
      }
      cpu = save;
    }
  }

  void interact() {
    for (;;) {
      List<int> output = [];
      cpu.executeSyncInput(onOutput: (out) => output.add(out));
      stdout.write(String.fromCharCodes(output));
      if (cpu.halted) break;
      var line = stdin.readLineSync();
      if (line == null) break;
      cpu.input.addAll("$line\n".codeUnits);
    }
  }
}

void run(String filename) {
  var code = parseInts(readFile(filename));
  var robot = Robot(code);
  // to play the game, comment out the autonomous mode call.
  robot.autonomousMode();
  robot.interact();
}

void main(List<String> args) {
  run(args[0]);
}
