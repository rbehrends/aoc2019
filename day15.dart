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
List<int> walkback(List<int> path) => path.reversed.map(opposite).toList();

Vector adjacent(Vector pos, int dir) => Vector(
    pos.x + const [0, 0, -1, 1][dir - 1], pos.y + const [-1, 1, 0, 0][dir - 1]);

void moveRobot(Processor robot, List<int> path) =>
    robot.executeSyncIO(input: path, output: path.length);

int tryMoveRobot(Processor robot, int dir) {
  int result = robot.executeSyncIO(input: [dir]).first;
  if (result != Wall) robot.executeSyncIO(input: [opposite(dir)]);
  return result;
}

class SystemState {
  Vector? oxygenPos = null;
  int? oxygenDistance = null;
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
  Map<Vector, List<int>> paths = {Vector(0, 0): []};
  var todo = ListQueue.of([Vector(0, 0)]);
  var result = SystemState();
  while (todo.isNotEmpty) {
    var pos = todo.removeFirst();
    var path = [...paths[pos]];
    moveRobot(robot, path);
    for (var dir in AllDirs) {
      if (path.isNotEmpty && path.last == opposite(dir)) continue;
      var newpos = adjacent(pos, dir);
      if (paths.containsKey(newpos) || result.walls.contains(newpos)) continue;
      int tile = tryMoveRobot(robot, dir);
      if (tile == Wall) {
        result.walls.add(newpos);
      } else {
        if (tile == Oxygen) {
          if (result.oxygenPos == null) {
            result.oxygenDistance = path.length + 1;
            result.oxygenPos = newpos;
          }
        }
        paths[newpos] = [...path, dir];
        todo.add(newpos);
      }
    }
    moveRobot(robot, walkback(path));
  }
  return result;
}

int floodFill(SystemState state) {
  var walls = state.walls;
  var filled = {state.oxygenPos!};
  var current = [state.oxygenPos!];
  int minutes = -1;
  while (current.isNotEmpty) {
    ++minutes;
    var next = <Vector>[];
    for (var pos in current) {
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
  return minutes;
}

void run(String filename) {
  var robot = Processor(parseInts(readFile(filename)));
  var state = exploreSystem(robot);
  visualize(state);
  print(state.oxygenDistance!);
  print(floodFill(state));
}

void main(List<String> args) {
  run(args[0]);
}
