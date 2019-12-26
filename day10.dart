import "util.dart";

// Doing it the hard way (without atan2()) to avoid floating point errors.
// Note: this also ensures that the vector (0, 0) is minimal.
int compareAngles(int x1, int y1, int x2, int y2) {
  int quadrant(int x, int y) => const [
        [3, 0, 0],
        [3, 0, 1],
        [2, 2, 1],
      ][1 - y.sign][1 + x.sign]; // (1, 1) is in the top right quadrant
  int l1(int x, int y) => x.abs() + y.abs();

  // First compare quadrants.
  int d = quadrant(x1, y1).compareTo(quadrant(x2, y2));
  // Within quadrants, order of angles can be deduced from x/y ratios.
  // This works for all quadrants without sign adjustments.
  // Note that (x1/y1).compareTo(x2/y2) == (x1 * y2).compareTo(x2 * y1)
  if (d == 0) d = (x1 * y2).compareTo(x2 * y1);
  // Same direction, so compare by L1 norm (any norm would do, L1 is fast)
  if (d == 0) d = l1(x1, y1).compareTo(l1(x2, y2));
  return d;
}

bool sameAngle(Vector p1, Vector p2, Vector orig) =>
    (p1.x - orig.x) * (p2.y - orig.y) == (p1.y - orig.y) * (p2.x - orig.x);

class Visible {
  final int count;
  final Vector origin;
  Visible(int this.count, Vector this.origin);
}

class AsteroidMap {
  final List<List<bool>> map;
  final int xs, ys;

  AsteroidMap(this.map)
      : xs = map.first.length,
        ys = map.length;

  factory AsteroidMap.fromText(String text) => AsteroidMap(text
      .trim()
      .split("\n")
      .map((line) =>
          RegExp("[.#]").allMatches(line).map((ch) => ch[0] == "#").toList())
      .toList());

  bool visible(int x1, int y1, int x2, int y2) {
    int xl = min(x1, x2);
    int xh = max(x1, x2);
    int yl = min(y1, y2);
    int yh = max(y1, y2);
    if (xl == xh) {
      for (int y = yl + 1; y < yh; y++) if (map[y][xl]) return false;
    } else if (yl == yh) {
      for (int x = xl + 1; x < xh; x++) if (map[yl][x]) return false;
    } else {
      int d = (yh - yl).gcd(xh - xl);
      int xd = (x2 - x1) ~/ d;
      int yd = (y2 - y1) ~/ d;
      for (int x = x1 + xd, y = y1 + yd; x != x2; x += xd, y += yd)
        if (map[y][x]) return false;
    }
    return true;
  }

  void sortByAngles(List<Vector> coords, Vector p) =>
      coords.sort(/* our angle comparison has the y coordinates inverted */
          (a, b) => compareAngles(a.x - p.x, p.y - a.y, b.x - p.x, p.y - b.y));

  List<Vector> vaporizeFrom(Vector orig) {
    var targets = <Vector>[];
    for (int x = 0; x < xs; x++)
      for (int y = 0; y < ys; y++)
        if ((x != orig.x || y != orig.y) && map[y][x])
          targets.add(Vector(x, y));
    sortByAngles(targets, orig);
    List<Vector> vaporized = [];
    while (targets.isNotEmpty) {
      Vector? last = null;
      targets.retainWhere((point) {
        if (last != null && sameAngle(last!, point, orig)) return true;
        last = point;
        vaporized.add(point);
        return false;
      });
    }
    return vaporized;
  }

  int countVisible(int x1, int y1) {
    int result = 0;
    for (int x2 = 0; x2 < xs; x2++)
      for (int y2 = 0; y2 < ys; y2++)
        if ((x1 != x2 || y1 != y2) && map[y2][x2] && visible(x1, y1, x2, y2))
          result++;
    return result;
  }

  Visible maxVisible() {
    var result = Visible(0, Vector(-1, -1));
    for (int x = 0; x < xs; x++) {
      for (int y = 0; y < ys; y++) {
        if (map[y][x]) {
          int m2 = countVisible(x, y);
          if (m2 > result.count) result = Visible(m2, Vector(x, y));
        }
      }
    }
    return result;
  }
}

void test() {
  void trial(String input, {bool vaporize = false}) {
    var map = AsteroidMap.fromText(input);
    var out = map.maxVisible();
    print(out.count);
    if (vaporize) {
      var vaporized = map.vaporizeFrom(out.origin);
      if (vaporized.length >= 200) print(vaporized[199]);
    }
  }

  trial("""
  .#..#
  .....
  #####
  ....#
  ...##
  """);
  trial("""
  ......#.#.
  #..#.#....
  ..#######.
  .#.#.###..
  .#..#.....
  ..#....#.#
  #..#....#.
  .##.#..###
  ##...#..#.
  .#....####
  """);
  trial("""
  #.#...#.#.
  .###....#.
  .#....#...
  ##.#.#.#.#
  ....#.#.#.
  .##..###.#
  ..#...##..
  ..##....##
  ......#...
  .####.###.
  """);
  trial("""
  .#..#..###
  ####.###.#
  ....###.#.
  ..###.##.#
  ##.##.#.#.
  ....###..#
  ..#.#..#.#
  #..#.#.###
  .##...##.#
  .....#.#..
  """);
  trial("""
  .#..##.###...#######
  ##.############..##.
  .#.######.########.#
  .###.#######.####.#.
  #####.##.#.##.###.##
  ..#####..#.#########
  ####################
  #.####....###.#.#.##
  ##.#################
  #####.##.###..####..
  ..######..##.#######
  ####.##.####...##..#
  .#####..#.######.###
  ##...#.##########...
  #.##########.#######
  .####.#.###.###.#.##
  ....##.##.###..#####
  .#.#.###########.###
  #.#.#.#####.####.###
  ###.##.####.##.#..##
  """, vaporize: true);
}

void run(String file) {
  var map = AsteroidMap.fromText((readFile(file)));
  var out = map.maxVisible();
  print("${out.count} asteroids visible from ${out.origin}");
  var vaporized = map.vaporizeFrom(out.origin);
  if (vaporized.length >= 200) {
    var p = vaporized[199];
    print("The 200th asteroid to be vaporized is at $p");
  }
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
