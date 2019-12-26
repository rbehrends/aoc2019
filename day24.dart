import "util.dart";

void printGrid(String cells) {
  for (int i = 0; i < 5; i++) print(cells.substring(i * 5, i * 5 + 5));
}

int at(int x, int y) => y * 5 + x;

class SimpleGrid {
  static final List<List<int>> neighbors = [
    for (int y = 0; y < 5; y++)
      for (int x = 0; x < 5; x++)
        [
          if (x > 0) at(x - 1, y),
          if (x + 1 < 5) at(x + 1, y),
          if (y > 0) at(x, y - 1),
          if (y + 1 < 5) at(x, y + 1)
        ]
  ];

  String cells;

  SimpleGrid(String this.cells);

  int countAdjacent(int x, int y) {
    int count = 0;
    for (var nb in neighbors[at(x, y)]) if (cells[nb] == "#") count++;
    return count;
  }

  void show() => printGrid(cells);

  int biodiversity() {
    int result = 0;
    for (int i = 0, mask = 1; i < cells.length; i++, mask <<= 1)
      if (cells[i] == "#") result |= mask;
    return result;
  }

  void nextGen() {
    List<String> result = [];
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 5; x++) {
        int adj = countAdjacent(x, y);
        if (cells[at(x, y)] == "#")
          result.add(adj == 1 ? "#" : ".");
        else
          result.add(adj == 1 || adj == 2 ? "#" : ".");
      }
    }
    cells = result.join();
  }
}

class RecursiveGrid {
  static final List<List<int>> neighbors = () {
    List<List<int>> result = [
      for (var nblist in SimpleGrid.neighbors)
        [
          for (var nb in nblist) if (nb != at(2, 2)) ...[0, nb]
        ],
    ];
    // There is a connection between any two locations on different
    // levels where the values have at least one bit in common.
    const t0 = [
      0, 0, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 8, 0, 2, 0, //
      0, 0, 4, 0, 0, //
      0, 0, 0, 0, 0, //
    ];
    const t1 = [
      9, 1, 1, 1, 3, //
      8, 0, 0, 0, 2, //
      8, 0, 0, 0, 2, //
      8, 0, 0, 0, 2, //
      12, 4, 4, 4, 6 //
    ];
    for (int i = 0; i < t0.length; i++) {
      for (int j = 0; j < t1.length; j++) {
        if ((t0[i] & t1[j]) != 0) {
          result[i].addAll([1, j]);
          result[j].addAll([-1, i]);
        }
      }
    }
    result[at(2, 2)] = [];
    return result;
  }();

  Map<int, String> levels;
  int minLevel = 0;
  int maxLevel = 0;
  RecursiveGrid(String init) : levels = {0: init};

  void show() {
    for (int i = minLevel; i <= maxLevel; i++) {
      print("$i:");
      printGrid(levels[i]);
    }
  }

  int totalBugs() {
    int result = 0;
    for (var cells in levels.values)
      for (int i = 0; i < cells.length; i++) if (cells[i] == "#") result++;
    return result;
  }

  void nextGen() {
    final String empty = "." * 5 * 5;
    var result = <int, String>{};
    levels[--minLevel] = empty;
    levels[++maxLevel] = empty;
    for (int i = minLevel; i <= maxLevel; i++) {
      List<String> sublevels = [
        levels[i - 1] ?? empty,
        levels[i],
        levels[i + 1] ?? empty,
      ];
      String current = sublevels[1];
      int countAdjacent(int p) {
        int count = 0;
        var nb = neighbors[p];
        for (int i = 0; i < nb.length; i += 2) {
          int d = nb[i], pos = nb[i + 1];
          if (sublevels[1 + d][pos] == "#") count++;
        }
        return count;
      }

      List<String> newLevel = [];
      for (int p = 0; p < 5 * 5; p++) {
        int adj = countAdjacent(p);
        if (current[p] == "#") {
          newLevel.add(adj == 1 ? "#" : ".");
        } else {
          newLevel.add(adj == 1 || adj == 2 ? "#" : ".");
        }
      } // for p
      result[i] = newLevel.join();
    } // for i
    levels = result;
    while (levels[minLevel] == empty && minLevel < 0) {
      levels.remove(minLevel);
      minLevel++;
    }
    while (levels[maxLevel] == empty && maxLevel > 0) {
      levels.remove(maxLevel);
      maxLevel--;
    }
  }
}

void simple(String initial) {
  var seen = <String>{};
  var grid = SimpleGrid(initial);
  grid.show();
  print("  =>");
  while (!seen.contains(grid.cells)) {
    seen.add(grid.cells);
    grid.nextGen();
  }
  grid.show();
  print(grid.biodiversity());
}

void recursive(int steps, String initial) {
  var grid = RecursiveGrid(initial);
  for (int i = 0; i < steps; i++) grid.nextGen();
  // grid.show();
  print(grid.totalBugs());
}

void test() {
  var data = //
      "....#"
      "#..#."
      "#..##"
      "..#.."
      "#....";
  simple(data);
  recursive(10, data);
}

void run(String filename) {
  var data = readFile(filename).replaceAll(RegExp("[^.#]"), "");
  simple(data);
  recursive(200, data);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
