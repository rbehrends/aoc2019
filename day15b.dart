import "util.dart";
import "intcode.dart";

const North = 1;
const South = 2;
const West = 3;
const East = 4;
const AllDirs = [North, South, East, West];

const Wall = 0;
const Empty = 1;
const Oxygen = 2;

int opposite(int dir) => const [South, North, East, West][dir - 1];

Vector adjacent(Vector pos, int dir) => Vector(
    pos.x + const [0, 0, -1, 1][dir - 1], pos.y + const [-1, 1, 0, 0][dir - 1]);

int moveRobot(Processor robot, int dir) =>
    robot.executeSyncIO(input: [dir]).first;

class SystemState {
  Vector? oxygenPos = null;
  Set<Vector> walls = {};
}

void visualize(SystemState state) {
  int xmin = 0, ymin = 0, xmax = 0, ymax = 0;
  for (var wall in state.walls) {
    xmin = min(xmin, wall.x);
    ymin = min(ymin, wall.y);
    xmax = max(xmax, wall.x);
    ymax = max(ymax, wall.y);
  }
  for (int y = ymin; y <= ymax; y++) {
    List<String> row = [];
    for (int x = xmin; x <= xmax; x++) {
      var pos = Vector(x, y);
      if (state.walls.contains(pos))
        row.add("#");
      else if (state.oxygenPos == pos)
        row.add("O");
      else if (x == 0 && y == 0)
        row.add("R");
      else
        row.add(".");
    }
    print(row.join());
  }
}

SystemState exploreSystem(Processor robot) {
  Set<Vector> seen = {};
  var result = SystemState();
  void exploreFrom(Vector pos) {
    for (var dir in AllDirs) {
      var newpos = adjacent(pos, dir);
      if (seen.contains(newpos)) continue;
      seen.add(newpos);
      int tile = moveRobot(robot, dir);
      if (tile == Wall) {
        result.walls.add(newpos);
      } else {
        if (tile == Oxygen) result.oxygenPos ??= newpos;
        exploreFrom(newpos);
        moveRobot(robot, opposite(dir));
      }
    }
  }

  exploreFrom(Vector(0, 0));
  return result;
}

int? floodFill(SystemState state, {required bool findOxygen}) {
  var walls = state.walls;
  var origin = findOxygen ? Vector(0, 0) : state.oxygenPos!;
  var filled = {origin};
  var current = [origin];
  int distance = -1;
  while (current.isNotEmpty) {
    ++distance;
    var next = <Vector>[];
    for (var pos in current) {
      if (findOxygen && pos == state.oxygenPos) return distance;
      for (var dir in AllDirs) {
        var newpos = adjacent(pos, dir);
        if (!walls.contains(newpos) && !filled.contains(newpos)) {
          filled.add(newpos);
          next.add(newpos);
        }
      }
    }
    current = next;
  }
  return findOxygen ? null : distance;
}

void run(String filename) {
  var robot = Processor(parseInts(readFile(filename)));
  var state = exploreSystem(robot);
  visualize(state);
  print(floodFill(state, findOxygen: true)!);
  print(floodFill(state, findOxygen: false)!);
}

void main(List<String> args) {
  run(args[0]);
}
