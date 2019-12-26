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

extension on Vector {
  bool collinear(Vector other) => x * other.y == y * other.x;
  Vector slope() {
    var g = x.gcd(y); // guaranteed to be non-negative per spec of gcd().
    return Vector(x ~/ g, y ~/ g);
  }
}

class Visible {
  final int count;
  final Vector origin;
  Visible(int this.count, Vector this.origin);
}

class AsteroidMap {
  List<Vector> points;

  AsteroidMap(String input)
      : points = [
          for (var line in input.trim().split("\n").indexed())
            for (var ch in line.value.trim().split("").indexed())
              if (ch.value == "#") Vector(ch.index, line.index)
        ];

  Visible maxVisible() =>
      points.fold(Visible(0, Vector(-1, -1)), (best, origin) {
        var visible = {
          for (var p in points) if (p != origin) (p - origin).slope()
        }.length;
        return visible > best.count ? Visible(visible, origin) : best;
      });

  List<Vector> vaporizeFrom(Vector origin) {
    var targets = [for (var p in points) if (p != origin) p - origin]
      ..sort((a, b) => compareAngles(a.x, -a.y, b.x, -b.y));
    var vaporized = <Vector>[];
    while (targets.isNotEmpty) {
      Vector? last = null;
      targets.retainWhere((target) {
        if (last != null && target.collinear(last!)) return true;
        last = target;
        vaporized.add(origin + target);
        return false;
      });
    }
    return vaporized;
  }
}

void test() {
  void trial(String input, {bool vaporize = false}) {
    var map = AsteroidMap(input);
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
  var map = AsteroidMap((readFile(file)));
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
