import "util.dart";
import "intcode.dart";

List<String> parseGrid(String input) {
  var lines = input.trim().split("\n").map((s) => s.trim()).toList();
  var maxlen = lines.map((line) => line.length).reduce(max);
  return lines.map((s) => s.padRight(maxlen, ".")).toList();
}

List<String> padGrid(List<String> grid) => [
      "." * (grid.first.length + 2),
      ...grid.map((s) => ".$s."),
      "." * (grid.first.length + 2),
    ];

// find all Intersections.
int countIntersections(String input) {
  var lines = parseGrid(input);
  int result = 0;
  for (int row = 1; row < lines.length - 1; row++) {
    nextcol:
    for (int col = 1; col < lines[row].length - 1; col++) {
      for (int r = -1; r <= 1; r++) {
        for (int c = -1; c <= 1; c++) {
          if ((lines[row + r][col + c] != ".") != (r == 0 || c == 0))
            continue nextcol;
        }
      }
      result += row * col;
    }
  }
  return result;
}

const North = 0;
const East = 1;
const South = 2;
const West = 3;

int right(int dir) => const [East, South, West, North][dir];
int left(int dir) => const [West, North, East, South][dir];

class Pos {
  int row, col;
  int dir;
  Pos(this.row, this.col, this.dir);
  String toString() => "($row, $col) facing ${"NESW"[dir]}";
  void turnRight() => dir = right(dir);
  void turnLeft() => dir = left(dir);
  void move() {
    row += const [-1, 0, 1, 0][dir];
    col += const [0, 1, 0, -1][dir];
  }
}

List<String> findPath(String input) {
  // We make the simplifying assumptions that no path ends in an
  // intersection or T intersection. In particular, there will
  // only ever be one path through the system.
  var grid = padGrid(parseGrid(input));
  Pos findRobot(List<String> grid) {
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        switch (grid[row][col]) {
          case "^":
            return Pos(row, col, North);
          case ">":
            return Pos(row, col, East);
          case "<":
            return Pos(row, col, West);
          case "v":
            return Pos(row, col, South);
        }
      }
    }
    throw StateError("no robot present");
  }

  var pos = findRobot(grid);

  List<String> moves = [];
  for (;;) {
    var adj = [
      grid[pos.row - 1][pos.col], // north
      grid[pos.row][pos.col + 1], // east
      grid[pos.row + 1][pos.col], // south
      grid[pos.row][pos.col - 1], // west
    ];
    if (adj[pos.dir] == "#") {
      moves.add("+");
      pos.move();
    } else if (adj[left(pos.dir)] == "#") {
      moves.add("L");
      pos.turnLeft();
    } else if (adj[right(pos.dir)] == "#") {
      moves.add("R");
      pos.turnRight();
    } else {
      break;
    }
  }
  List<String> path = [];
  int pathLen = 0;
  void completeStraightSegment() {
    if (pathLen > 0) {
      path.add(pathLen.toString());
      pathLen = 0;
    }
  }

  for (var move in moves) {
    switch (move) {
      case "L":
      case "R":
        completeStraightSegment();
        path.add(move);
        break;
      case "+":
        pathLen++;
        break;
    }
  }
  completeStraightSegment();
  return path;
}

List<String> compress(List<String> moves) {
  // In order to achieve proper compression, we'll do string matches
  // on comma separated strings. We assume that each subroutine will
  // begin with a turn command and alternate between turn commands and
  // numbers. In order for subroutines to fit that pattern, we encode
  // these as "A,0", "B,0", or "C,0" and strip out the zeroes at the
  // end.
  const maxLineLen = 20;
  List<String> subPatterns(String input) {
    var abc = const {"A", "B", "C"};
    var moves = input.split(",");
    Map<String, int> dict = {};
    for (int i = 0; i < moves.length; i += 2) {
      for (int j = i + 2; j < moves.length; j += 2) {
        if (abc.contains(moves[j - 2])) break;
        var s = moves.sublist(i, j).join(",");
        dict[s] ??= 0;
        dict[s]++;
      }
    }
    var best = dict.keys.where((s) => s.length <= maxLineLen).toList();
    best.sort((a, b) => dict[b] * b.length - dict[a] * a.length);
    return best;
  }

  // We add a trailing comma to the moves and to all pattern during
  // replacement to prevent "R,1" from matching "R,10", for example.

  String moveString = moves.join(",") + ",";
  String bestMoveString = moveString;
  List<String> subroutineCode = ["", "", ""];
  const subroutineNames = ["A", "B", "C"];
  bool findDecomposition(String moveString, int d) {
    if (d == 3) {
      // strip zeroes and trailing comma.
      moveString = moveString.replaceAll(",0", "");
      moveString = moveString.substring(0, moveString.length - 1);
      if (moveString.length <= bestMoveString.length)
        bestMoveString = moveString;
      return bestMoveString.length <= maxLineLen;
    }
    for (var pattern in subPatterns(moveString)) {
      subroutineCode[d] = pattern;
      if (findDecomposition(
          moveString.replaceAll(pattern + ",", "${subroutineNames[d]},0,"),
          d + 1)) {
        return true;
      }
    }
    return false;
  }

  findDecomposition(moveString, 0);
  return [bestMoveString, ...subroutineCode];
}

void test() {
  countIntersections("""
  ..#..........
  ..#..........
  #######...###
  #.#...#...#.#
  #############
  ..#...#...#..
  ..#####...^..
  """);
  print(findPath("""
  ..#..........
  ..#..........
  #######...###
  #.#...#...#.#
  #############
  ..#...#...#..
  ..#####...^..
  """));
}

void run(String filename) {
  var code = parseInts(readFile(filename));
  var robot = Processor(code);
  List<int> output = robot.execute().toList();
  String data = String.fromCharCodes(output);
  print(data);
  print(countIntersections(data));
  var path = findPath(data);
  var instr = compress(path).join("\n");
  print(instr);
  instr += "\nn\n";
  code[0] = 2;
  robot = Processor(code, instr.codeUnits);
  output = robot.execute().toList();
  print(robot.output.last);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
