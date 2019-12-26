import "util.dart";

// faster version using intsets

void printGrid(int cells) {
  var s = StringBuffer();
  for (int i = 0; i < 5 * 5; i++) {
    if (i > 0 && i % 5 == 0) s.write("\n");
    s.write(cells & (1 << i) != 0 ? "#" : ".");
  }
  print(s);
}

int at(int x, int y) => y * 5 + x;
int mask(int x, int y) => 1 << at(x, y);

int parseGrid(String grid) {
  int result = 0;
  for (int i = 0; i < grid.length; i++) if (grid[i] == "#") result |= 1 << i;
  return result;
}

class SimpleGrid {
  static final List<List<int>> neighbors = [
    for (int y = 0; y < 5; y++)
      for (int x = 0; x < 5; x++)
        [
          if (x > 0) mask(x - 1, y),
          if (x + 1 < 5) mask(x + 1, y),
          if (y > 0) mask(x, y - 1),
          if (y + 1 < 5) mask(x, y + 1)
        ]
  ];

  int cells;

  SimpleGrid(String cells) : cells = parseGrid(cells);

  int countAdjacent(int p) {
    int count = 0;
    for (var nb in neighbors[p]) if (cells & nb != 0) count++;
    return count;
  }

  void show() => printGrid(cells);

  int biodiversity() => cells;

  void nextGen() {
    int result = 0;
    for (int p = 0; p < 5 * 5; p++) {
      int adj = countAdjacent(p);
      int m = 1 << p;
      if (cells & m != 0)
        result |= (adj == 1 ? m : 0);
      else
        result |= (adj == 1 || adj == 2 ? m : 0);
    }
    cells = result;
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
          result[i].addAll([1, 1 << j]);
          result[j].addAll([-1, 1 << i]);
        }
      }
    }
    result[at(2, 2)] = [];
    return result;
  }();

  Map<int, int> levels;
  int minLevel = 0;
  int maxLevel = 0;
  RecursiveGrid(String init) : levels = {0: parseGrid(init)};

  void show() {
    for (int i = minLevel; i <= maxLevel; i++) {
      print("$i:");
      printGrid(levels[i]);
    }
  }

  int totalBugs() {
    int result = 0;
    for (var cells in levels.values)
      for (int i = 0, m = 1; i < 5 * 5; i++, m <<= 1)
        if (cells & m != 0) result++;
    return result;
  }

  void nextGen() {
    var result = <int, int>{};
    levels[--minLevel] = 0;
    levels[++maxLevel] = 0;
    for (int i = minLevel; i <= maxLevel; i++) {
      List<int> sublevels = [
        levels[i - 1] ?? 0,
        levels[i],
        levels[i + 1] ?? 0,
      ];
      int current = sublevels[1];
      int countAdjacent(int p) {
        int count = 0;
        var nb = neighbors[p];
        for (int i = 0; i < nb.length; i += 2) {
          int lvl = nb[i], mask = nb[i + 1];
          if (sublevels[1 + lvl] & mask != 0) count++;
        }
        return count;
      }

      int newLevel = 0;
      for (int p = 0; p < 5 * 5; p++) {
        int adj = countAdjacent(p);
        int m = 1 << p;
        if (current & m != 0) {
          if (adj == 1) newLevel |= m;
        } else {
          if (adj == 1 || adj == 2) newLevel |= m;
        }
      } // for p
      result[i] = newLevel;
    } // for i
    levels = result;
    while (levels[minLevel] == 0 && minLevel < 0) {
      levels.remove(minLevel);
      minLevel++;
    }
    while (levels[maxLevel] == 0 && maxLevel > 0) {
      levels.remove(maxLevel);
      maxLevel--;
    }
  }
}

void simple(String initial) {
  var seen = <int>{};
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
