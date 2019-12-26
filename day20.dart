import "util.dart";

bool isAlpha(String ch) => ch >= "A" && ch <= "Z";

class Portal {
  Vector? inner = null;
  Vector? outer = null;
  final String name;
  Portal(this.name);
  Iterable<Vector> entrances() =>
      [if (inner != null) inner!, if (outer != null) outer!];
  Vector warp(Vector entrance) =>
      (entrance == inner || inner == null) ? outer! : inner!;
  int levelChange(Vector entrance) => entrance == inner ? 1 : -1;
}

class Path {
  final int distance;
  final int level;
  final Vector pos;
  final List<String> path;
  Path(this.distance, this.pos, {this.level = 0, this.path = const []});
}

class Maze {
  final List<List<String>> _grid;
  final Map<String, Portal> _portals = {};
  final Map<Vector, String> _portalNames = {};
  final Map<Vector, Map<Vector, int>> _connections = {};
  Maze._(this._grid);

  Maze.parse(String input) : _grid = [] {
    var lines = input.split("\n").where((line) => line.isNotEmpty).toList();
    _grid.add(List.filled(lines.first.length, "#"));
    for (int row = 1; row < lines.length - 1; row++) {
      var line = lines[row];
      var out = ["#"];
      for (int col = 1; col < line.length - 1; col++) {
        var ch = line[col];
        if (ch == ".")
          out.add(ch);
        else if (isAlpha((ch))) {
          void makePortal(String ch1, String ch2) => out.add(ch1 + ch2);
          if (lines[row][col + 1] == ".")
            makePortal(lines[row][col - 1], ch);
          else if (lines[row][col - 1] == ".")
            makePortal(ch, lines[row][col + 1]);
          else if (lines[row - 1][col] == ".")
            makePortal(ch, lines[row + 1][col]);
          else if (lines[row + 1][col] == ".")
            makePortal(lines[row - 1][col], ch);
          else
            out.add("#");
        } else
          out.add("#");
      }
      out.add("#");
      _grid.add(out);
    }
    _grid.add(List.filled(lines.last.length, "#"));
    _findPortals();
    _findConnections();
  }

  void _findPortals() {
    for (int y = 0; y < _grid.length; y++) {
      for (int x = 0; x < _grid[y].length; x++) {
        bool isOuter() =>
            y == 1 ||
            x == 1 ||
            y == _grid.length - 2 ||
            x == _grid[y].length - 2;
        var name = _grid[y][x];
        if (name.length == 2) {
          _grid[y][x] = name;
          _portals[name] ??= Portal(name);
          var pos = Vector(x, y);
          if (isOuter()) // outer
            _portals[name].outer = pos;
          else
            _portals[name].inner = pos;
          _portalNames[pos] = name;
        }
      }
    }
  }

  void _findConnectionsFrom(String init, Vector start) {
    var seen = {start};
    var current = [start];
    int distance = -1;
    while (current.isNotEmpty) {
      ++distance;
      var next = <Vector>[];
      for (var pos in current) {
        String sym = _grid[pos.y][pos.x];
        if (sym != init && sym.length == 2) {
          _connections[start][pos] = distance - 1;
        } else {
          const dirs = [-1, 0, 0, 1, 1, 0, 0, -1];
          for (var dir = 0; dir < dirs.length; dir += 2) {
            var newpos = Vector(pos.x + dirs[dir], pos.y + dirs[dir + 1]);
            if (_grid[newpos.y][newpos.x] == "#") continue;
            if (!seen.contains(newpos)) {
              seen.add(newpos);
              next.add(newpos);
            }
          }
        }
      }
      current = next;
    }
  }

  void _findConnections() {
    _portals.forEach((name, portal) {
      for (var pos in portal.entrances()) {
        _connections[pos] ??= {};
        _findConnectionsFrom(name, pos);
      }
    });
  }

  int shortestPath() {
    var seen = <Vector>{};
    var queue = PriorityQueue<num, Path>((loc) => loc.distance);
    var start = Path(-1, _portals["AA"].outer!, path: ["AA"]);
    queue.add(start);
    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      if (seen.contains(current.pos)) continue;
      seen.add(current.pos);
      if (_portalNames[current.pos] == "ZZ") return current.distance;
      _connections[current.pos].forEach((target, distance) {
        var name = _portalNames[target];
        if (name == "AA") return;
        var portal = _portals[name];
        queue.add(Path(current.distance + distance, portal.warp(target),
            path: [...current.path, name]));
      });
    }
    return -1;
  }

  int shortestRecursivePath() {
    var seen = <Set<Vector>>[];
    var queue = PriorityQueue<num, Path>((loc) => loc.distance);
    var start = Path(-1, _portals["AA"].outer!, path: ["AA"]);
    queue.add(start);
    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      if (_portalNames[current.pos] == "ZZ") return current.distance;
      while (seen.length <= current.level) seen.add({});
      if (seen[current.level].contains(current.pos)) continue;
      seen[current.level].add(current.pos);
      _connections[current.pos].forEach((target, distance) {
        var name = _portalNames[target];
        var portal = _portals[name];
        if (name == "AA") return;
        if (current.level == 0) {
          if (name != "ZZ" && target == portal.outer) return;
        } else {
          if (name == "ZZ") return;
        }
        queue.add(Path(current.distance + distance, portal.warp(target),
            level: current.level + portal.levelChange(target),
            path: [...current.path, name]));
      });
    }
    return -1;
  }
}

void findPaths(String input, {bool recursive = true}) {
  var maze = Maze.parse(input);
  print(maze.shortestPath());
  if (recursive) print(maze.shortestRecursivePath());
}

void test() {
  void trial(String input, {bool recursive = true}) {
    findPaths(input, recursive: recursive);
  }

  trial("""
         A           
         A           
  #######.#########  
  #######.........#  
  #######.#######.#  
  #######.#######.#  
  #######.#######.#  
  #####  B    ###.#  
BC...##  C    ###.#  
  ##.##       ###.#  
  ##...DE  F  ###.#  
  #####    G  ###.#  
  #########.#####.#  
DE..#######...###.#  
  #.#########.###.#  
FG..#########.....#  
  ###########.#####  
             Z       
             Z       
""");
  trial("""
                   A               
                   A               
  #################.#############  
  #.#...#...................#.#.#  
  #.#.#.###.###.###.#########.#.#  
  #.#.#.......#...#.....#.#.#...#  
  #.#########.###.#####.#.#.###.#  
  #.............#.#.....#.......#  
  ###.###########.###.#####.#.#.#  
  #.....#        A   C    #.#.#.#  
  #######        S   P    #####.#  
  #.#...#                 #......VT
  #.#.#.#                 #.#####  
  #...#.#               YN....#.#  
  #.###.#                 #####.#  
DI....#.#                 #.....#  
  #####.#                 #.###.#  
ZZ......#               QG....#..AS
  ###.###                 #######  
JO..#.#.#                 #.....#  
  #.#.#.#                 ###.#.#  
  #...#..DI             BU....#..LF
  #####.#                 #.#####  
YN......#               VT..#....QG
  #.###.#                 #.###.#  
  #.#...#                 #.....#  
  ###.###    J L     J    #.#.###  
  #.....#    O F     P    #.#...#  
  #.###.#####.#.#####.#####.###.#  
  #...#.#.#...#.....#.....#.#...#  
  #.#####.###.###.#.#.#########.#  
  #...#.#.....#...#.#.#.#.....#.#  
  #.###.#####.###.###.#.#.#######  
  #.#.........#...#.............#  
  #########.###.###.#############  
           B   J   C               
           U   P   P               
""", recursive: false);
  trial("""
             Z L X W       C                 
             Z P Q B       K                 
  ###########.#.#.#.#######.###############  
  #...#.......#.#.......#.#.......#.#.#...#  
  ###.#.#.#.#.#.#.#.###.#.#.#######.#.#.###  
  #.#...#.#.#...#.#.#...#...#...#.#.......#  
  #.###.#######.###.###.#.###.###.#.#######  
  #...#.......#.#...#...#.............#...#  
  #.#########.#######.#.#######.#######.###  
  #...#.#    F       R I       Z    #.#.#.#  
  #.###.#    D       E C       H    #.#.#.#  
  #.#...#                           #...#.#  
  #.###.#                           #.###.#  
  #.#....OA                       WB..#.#..ZH
  #.###.#                           #.#.#.#  
CJ......#                           #.....#  
  #######                           #######  
  #.#....CK                         #......IC
  #.###.#                           #.###.#  
  #.....#                           #...#.#  
  ###.###                           #.#.#.#  
XF....#.#                         RF..#.#.#  
  #####.#                           #######  
  #......CJ                       NM..#...#  
  ###.#.#                           #.###.#  
RE....#.#                           #......RF
  ###.###        X   X       L      #.#.#.#  
  #.....#        F   Q       P      #.#.#.#  
  ###.###########.###.#######.#########.###  
  #.....#...#.....#.......#...#.....#.#...#  
  #####.#.###.#######.#######.###.###.#.#.#  
  #.......#.......#.#.#.#.#...#...#...#.#.#  
  #####.###.#####.#.#.#.#.###.###.#.###.###  
  #.......#.....#.#...#...............#...#  
  #############.#.#.###.###################  
               A O F   N                     
               A A D   M                     
""", recursive: true);
}

void run(String filename) {
  findPaths(readFile(filename), recursive: true);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
