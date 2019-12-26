import "util.dart";

class Coord {
  final int x, y;
  int delay = 0;
  Coord(this.x, this.y);
  int get distance => x.abs() + y.abs();
  String toString() => "($x, $y)";
}

class Wire {
  final int xl, xh, yl, yh;
  final int xstart, ystart;
  final List<Coord> intersections = [];
  int get length => (xh - xl) + (yh - yl);
  Wire(int this.xstart, int this.ystart, int xend, int yend)
      : xl = min(xstart, xend),
        xh = max(xstart, xend),
        yl = min(ystart, yend),
        yh = max(ystart, yend);
  Coord? intersect(Wire other) {
    // We could make this simply by distinguishing between
    // vertical and horizontal wire types, but the complexity
    // isn't worth it.
    if (xh <= other.xl) return null;
    if (xl >= other.xh) return null;
    if (yh <= other.yl) return null;
    if (yl >= other.yh) return null;
    if (xl == xh) {
      // vertical wire
      if (other.xl == other.xh) return null;
      return Coord(xl, other.yl);
    } else {
      // horizontal wire
      if (other.yl == other.yh) return null;
      return Coord(other.xl, yl);
    }
  }
}

// The problem size is small enough that we can just brute force
// this.

List<Coord> findIntersections(List<Wire> wires1, List<Wire> wires2) {
  var result = <Coord>[];
  for (var w1 in wires1) {
    for (var w2 in wires2) {
      Coord? inter = w1.intersect(w2);
      if (inter != null) result.add(inter);
    }
  }
  return result;
}

void calculateDelays(
    List<Coord> intersections, List<Wire> wires1, List<Wire> wires2) {
  for (var inter in intersections) {
    var x = inter.x;
    var y = inter.y;
    int delay = 0;
    void addDelays(List<Wire> wires) {
      for (var w in wires) {
        if (x == w.xl && x == w.xh) {
          delay += (y - w.ystart).abs();
          break;
        } else if (y == w.yl && y == w.yh) {
          delay += (x - w.xstart).abs();
          break;
        } else {
          delay += w.length;
        }
      }
    }

    addDelays(wires1);
    addDelays(wires2);
    inter.delay += delay;
  }
}

List<Coord> sortIntersections(List<Coord> intersections) =>
    [...intersections]..sort((a, b) => a.distance.compareTo(b.distance));

List<Coord> sortIntersectionsByDelay(List<Coord> intersections) =>
    [...intersections]..sort((a, b) => a.delay.compareTo(b.delay));

List<Wire> parseWires(String input) {
  var x = 0;
  var y = 0;
  var wires = <Wire>[];
  for (var wiredesc in RegExp("[UDLR][0-9]+").allMatches(input)) {
    var code = wiredesc[0][0];
    var distance = int.parse(wiredesc[0].substring(1));
    int xold = x;
    int yold = y;
    switch (code) {
      case "U":
        y += distance;
        break;
      case "D":
        y -= distance;
        break;
      case "L":
        x -= distance;
        break;
      case "R":
        x += distance;
        break;
    }
    wires.add(Wire(xold, yold, x, y));
  }
  return wires;
}

void analyze(String input1, String input2) {
  var w1 = parseWires(input1);
  var w2 = parseWires(input2);
  var intersections = findIntersections(w1, w2);
  calculateDelays(intersections, w1, w2);
  var result = sortIntersections(intersections);
  var result2 = sortIntersectionsByDelay(intersections);
  print("Distance: ${result[0].distance}");
  print("Delay: ${result2[0].delay}");
}

void test() {
  analyze("R8,U5,L5,D3", "U7,R6,D4,L4");
  analyze(
      "R75,D30,R83,U83,L12,D49,R71,U7,L72", "U62,R66,U55,R34,D71,R55,D58,R83");
  analyze("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51",
      "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7");
}

void run(String filename) {
  var lines = readLines(filename);
  analyze(lines[0], lines[1]);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
