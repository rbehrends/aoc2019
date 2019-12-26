import "util.dart";

Vector findInGrid(List<List<String>> grid, String ch) {
  for (int row = 0; row < grid.length; row++) {
    for (int col = 0; col < grid[row].length; col++) {
      if (grid[row][col] == ch) return Vector(col, row);
    }
  }
  throw ArgumentError("grid does not contain a \"$ch\"");
}

List<List<String>> copyGrid(List<List<String>> grid) => [
      for (var row in grid) [...row]
    ];

List<List<String>> parGrid(List<List<String>> grid) {
  grid = copyGrid(grid);
  var pos = findInGrid(grid, "@");
  int row = pos.y;
  int col = pos.x;
  for (int i = -1; i <= 1; i++) {
    grid[row + i][col] = "#";
    grid[row][col + i] = "#";
  }
  grid[row - 1][col - 1] = "0";
  grid[row - 1][col + 1] = "1";
  grid[row + 1][col - 1] = "2";
  grid[row + 1][col + 1] = "3";
  return grid;
}

bool isLetter(String ch) =>
    (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z");
bool isLowerCase(String ch) => ch >= "a" && ch <= "z";

Map<String, int> findNeighbors(List<List<String>> grid, String init) {
  var start = findInGrid(grid, init);
  Map<String, int> result = {};
  var filled = {start};
  var current = [start];
  int distance = -1;
  while (current.isNotEmpty) {
    ++distance;
    var next = <Vector>[];
    for (var pos in current) {
      String ch = grid[pos.y][pos.x];
      if (init != ch && isLetter(ch))
        result[ch] = distance;
      else {
        const dirs = [-1, 0, 0, 1, 1, 0, 0, -1];
        for (var dir = 0; dir < dirs.length; dir += 2) {
          var newpos = Vector(pos.x + dirs[dir], pos.y + dirs[dir + 1]);
          if (newpos.x < 0 || newpos.y < 0) continue;
          if (newpos.x >= grid.first.length || newpos.y >= grid.length)
            continue;
          if (grid[newpos.y][newpos.x] == "#") continue;
          if (!filled.contains(newpos)) {
            filled.add(newpos);
            next.add(newpos);
          }
        }
      }
    }
    current = next;
  }
  return result;
}

List<List<String>> parseInput(String input) =>
    input.trim().split("\n").map((line) => line.trim().split("")).toList();

class Path {
  int length;
  Set<String> doors;
  Set<String> keys;
  int doorCodes;
  int keyCodes;
  bool operator >=(Path other) =>
      length >= other.length &&
      (doorCodes & other.doorCodes) == other.doorCodes &&
      (keyCodes & other.keyCodes) == other.keyCodes;
  Path(this.length, this.doors, this.keys)
      : doorCodes = intSet(doors),
        keyCodes = intSet(keys);
  String toString() =>
      "(#$length via ${doors.map((d) => d.toUpperCase()).toSet()} getting $keys)";
}

const AsciiLowerA = 97;

int letterCode(String item) => item.codeUnitAt(0) - AsciiLowerA;

int intSet(Set<String> items) {
  int result = 0;
  for (var item in items) result |= 1 << letterCode(item);
  return result;
}

// While this does not happen for actual puzzle input, this code assumes
// that there can be multiple paths between two keys that require going
// through different sets of doors and deals with such a situation.
//
// Without that assumption, this and the following functions could use
// Path instead of List<Path> and avoid looping over those.
Map<String, List<Path>> findConnectionsFrom(
    Map<String, Map<String, int>> distances, String startSym) {
  var paths = {
    startSym: [Path(0, {}, {})]
  };
  var queue = ListQueue.from([startSym]);
  while (queue.isNotEmpty) {
    var node = queue.removeFirst();
    for (var succ in distances[node].keys) {
      paths[succ] ??= [];
      var succPathList = paths[succ];
      bool enqueueSucc = false;
      nextPath:
      for (var path in paths[node]) {
        int p = path.length + distances[node][succ];
        var succPath = isLowerCase(succ)
            ? Path(p, path.doors, {...path.keys, succ})
            : Path(p, {...path.doors, succ.toLowerCase()}, path.keys);
        for (var sp in succPathList) if (succPath >= sp) continue nextPath;
        succPathList.add(succPath);
        enqueueSucc = true;
      }
      if (enqueueSucc) queue.add(succ);
    }
  }
  paths.remove(startSym);
  paths = {
    for (var dest in paths.keys) if (isLowerCase(dest)) dest: paths[dest]
  };
  return paths;
}

// This function computes a poor person's transitive closure, which also
// tracks the best paths between any two keys and which doors are being
// visited on the way.
Map<String, Map<String, List<Path>>> findConnections(
    Map<String, Map<String, int>> distances, Set<String> startSyms) {
  Map<String, Map<String, List<Path>>> result = {};
  Set<String> keys =
      distances.values.fold({}, (acc, d) => acc.union(d.keys.toSet()));
  keys = keys.where(isLowerCase).toSet();
  for (var key in {...startSyms, ...keys}) {
    if (isLowerCase(key) || startSyms.contains(key)) {
      result[key] = findConnectionsFrom(distances, key);
    }
  }
  return result;
}

class State {
  String loc;
  int keys;
  int pathLen;
  State(this.loc, this.keys, this.pathLen);
  int get index => keys + (letterCode(loc) << 32);
}

class ParState {
  List<String> loc;
  int keys;
  int pathLen;
  ParState(this.loc, this.keys, this.pathLen);
  int get index {
    int result = keys;
    result += letterCode(loc[0]) << 32;
    result += letterCode(loc[1]) << 40;
    result += letterCode(loc[0]) << 48;
    result += letterCode(loc[0]) << 56;
    return result;
  }
}

// A simple breadth first search. We prune the search graph whenever
// we have all keys collected or when we have a better solution to arrive
// at the current position with the same set of keys (this is encoded in
// the index function).
int findAllKeys(Map<String, Map<String, int>> distances) {
  var connections = findConnections(distances, {"@"});
  int shortestPath = maxInt;
  var shortestPaths = <int, int>{};
  int allKeys = 0;
  for (var key in connections.keys)
    if (key != "@") allKeys |= 1 << letterCode(key);
  var queue = ListQueue.of([State("@", 0, 0)]);
  while (queue.isNotEmpty) {
    var state = queue.removeFirst();
    if (state.keys == allKeys) {
      if (state.pathLen < shortestPath) shortestPath = state.pathLen;
      continue;
    }
    int index = state.index;
    if (shortestPaths.containsKey(index)) {
      if (state.pathLen >= shortestPaths[index]) continue;
    }
    shortestPaths[index] = state.pathLen;
    var conns = connections[state.loc];
    for (var succ in conns.keys) {
      int k = 1 << letterCode(succ);
      if ((state.keys & k) != 0) continue;
      for (var conn in conns[succ]) {
        if ((state.keys & conn.doorCodes) == conn.doorCodes)
          queue.add(State(
              succ, state.keys | conn.keyCodes, state.pathLen + conn.length));
      }
    }
  }
  return shortestPath;
}

int parFindAllKeys(Map<String, Map<String, int>> distances) {
  const startSyms = {"0", "1", "2", "3"};
  var connections = findConnections(distances, startSyms);
  int shortestPath = maxInt;
  var shortestPaths = <int, int>{};
  int allKeys = 0;
  for (var key in connections.keys)
    if (!startSyms.contains(key)) allKeys |= 1 << letterCode(key);
  var queue = ListQueue.of([
    ParState(["0", "1", "2", "3"], 0, 0)
  ]);
  while (queue.isNotEmpty) {
    var state = queue.removeFirst();
    if (state.keys == allKeys) {
      if (state.pathLen < shortestPath) shortestPath = state.pathLen;
      continue;
    }
    int index = state.index;
    if (shortestPaths.containsKey(index)) {
      if (state.pathLen >= shortestPaths[index]) continue;
    }
    shortestPaths[index] = state.pathLen;
    for (var robot = 0; robot <= 3; robot++) {
      var conns = connections[state.loc[robot]];
      for (var succ in conns.keys) {
        int k = 1 << letterCode(succ);
        if ((state.keys & k) != 0) continue;
        for (var conn in conns[succ]) {
          if ((state.keys & conn.doorCodes) == conn.doorCodes) {
            var newloc = state.loc.sublist(0);
            newloc[robot] = succ;
            queue.add(ParState(newloc, state.keys | conn.keyCodes,
                state.pathLen + conn.length));
          }
        }
      }
    }
  }
  return shortestPath == maxInt ? -1 : shortestPath;
}

Map<String, Map<String, int>> calcDistances(
    List<List<String>> grid, List<String> startSyms) {
  Map<String, Map<String, int>> result = {
    for (var sym in startSyms) sym: findNeighbors(grid, sym)
  };
  Set<String> names = {};
  names = result.keys.toSet();
  for (;;) {
    for (String ch in names) {
      if (!result.containsKey(ch)) result[ch] = findNeighbors(grid, ch);
    }
    var newNames = {...names, for (var name in names) ...result[name].keys};
    if (newNames.length == names.length) break;
    names = newNames;
  }
  return result;
}

void findShortestPathFromStart(String input,
    {bool seq = true, bool par = false}) {
  var grid = parseInput(input);
  if (seq) {
    var distances = calcDistances(grid, ["@"]);
    print("Shortest path: ${findAllKeys(distances)}");
  }
  if (par) {
    var pargrid = parGrid(grid);
    var pardistances = calcDistances(pargrid, ["0", "1", "2", "3"]);
    print("Parallelized:  ${parFindAllKeys(pardistances)}");
  }
}

void test() {
  void trial(String input, {bool par = false}) {
    findShortestPathFromStart(input, seq: !par, par: par);
  }

  trial("""
  #########
  #b.A.@.a#
  #########
  """);
  trial("""
  ########################
  #f.D.E.e.C.b.A.@.a.B.c.#
  ######################.#
  #d.....................#
  ########################
  """);
  trial("""
  ########################
  #...............b.C.D.f#
  #.######################
  #.....@.a.B.c.d.A.e.F.g#
  ########################
  """);
  trial("""
  #################
  #i.G..c...e..H.p#
  ########.########
  #j.A..b...f..D.o#
  ########@########
  #k.E..a...g..B.n#
  ########.########
  #l.F..d...h..C.m#
  #################
  """);
  trial("""
  ########################
  #@..............ac.GI.b#
  ###d#e#f################
  ###A#B#C################
  ###g#h#i################
  ########################
  """);
  trial("""
  ###############
  #d.ABC.#.....a#
  ######...######
  ######.@.######
  ######...######
  #b.....#.....c#
  ###############
  """, par: true);
  trial("""
  #############
  #DcBa.#.GhKl#
  #.###...#I###
  #e#d#.@.#j#k#
  ###C#...###J#
  #fEbA.#.FgHi#
  #############
  """, par: true);
  trial("""
  #############
  #g#f.D#..h#l#
  #F###e#E###.#
  #dCba...BcIJ#
  #####.@.#####
  #nK.L...G...#
  #M###N#H###.#
  #o#m..#i#jk.#
  #############
  """, par: true);
}

void run(String filename) {
  var input = readFile(filename);
  findShortestPathFromStart(input, par: true);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
