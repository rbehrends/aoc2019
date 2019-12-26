import "util.dart";
import "intcode.dart";

// parse grid in ASCII format.
List<String> parseGrid(String input) {
  var lines = input.trim().split("\n").map((s) => s.trim()).toList();
  var maxlen = lines.map((line) => line.length).reduce(max);
  return lines.map((s) => s.padRight(maxlen, ".")).toList();
}

// surround the grid with sentinel spaces.
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
  // This implementation is fully general and does not require that the
  // path can be broken down into a sequence of A, B, and C calls with
  // no other movement mixed in.
  const maxLineLen = 20;

  Iterable<List<String>> prefixes(List<String> moves, int start) sync* {
    int len = -1;
    int end = start;
    for (end = start; end < moves.length; end += 2) {
      int d = moves[end].length + moves[end + 1].length + 2;
      if (len + d > maxLineLen) break;
      len += d;
    }
    var pat = moves.sublist(start, end);
    while (pat.isNotEmpty) {
      yield pat;
      pat.removeLast();
      pat.removeLast();
    }
  }

  bool match(List<String> a, List<String> b, [int start = 0]) {
    if (b.length > a.length - start) return false;
    for (int i = 0; i < b.length; i++) if (a[i + start] != b[i]) return false;
    return true;
  }

  List<String>? decompose(List<String> moves,
      [List<List<String>> patterns = const [],
      int start = 0,
      int outlen = -1,
      List<String> compressed = const []]) {
    String subroutineName(int p) => const ["A", "B", "C"][p];
    // overflow line length? then fail.
    if (outlen >= maxLineLen) return null;
    // found end of list? then return solution.
    if (start == moves.length)
      return [compressed, ...patterns].map((s) => s.join(",")).toList();
    // try to match existing patterns as first alternative.
    for (int i = 0; i < patterns.length; i++) {
      var p = patterns[i];
      if (match(moves, p, start)) {
        var result = decompose(moves, patterns, start + p.length, outlen + 2,
            [...compressed, subroutineName(i)]);
        if (result != null) return result;
      }
    }
    // if there is still room, try further patterns.
    if (patterns.length < 3) {
      for (var pref in prefixes(moves, start)) {
        var result = decompose(moves, [...patterns, pref], start + pref.length,
            outlen + 2, [...compressed, subroutineName(patterns.length)]);
        if (result != null) return result;
      }
    }
    // try by skipping moves.
    outlen += moves[start].length + moves[start + 1].length + 2;
    return decompose(moves, patterns, start + 2, outlen,
        [...compressed, ...moves.sublist(start, start + 2)]);
    return null;
  }

  return decompose(moves) ?? [moves.join(","), "", "", ""];
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
