import "util.dart";

void orbits(String data, {bool findSanta = false}) {
  var input = RegExp(r"([A-Z0-9]+)\)([A-Z0-9]+)")
      .allMatches(data)
      .map((match) => [match[1], match[2]]);
  int totalOrbits = 0;
  var satellites = <String, List<String>>{};
  var paths = <String, List<String>>{};
  for (var pair in input) {
    var inner = pair[0];
    var outer = pair[1];
    satellites[inner] ??= [];
    satellites[inner].add(outer);
  }

  void visit(String obj, int depth, List<String> path) {
    totalOrbits += depth;
    paths[obj] = path = [obj, ...path];
    for (var sat in satellites[obj] ?? []) {
      visit(sat, depth + 1, path);
    }
  }

  void findDistance(String origin, String dest) {
    var toOrigin = paths[origin].sublist(1);
    var toDest = paths[dest].sublist(1);
    // sort in reverse to find object farthest from COM
    var common = toOrigin.toSet().intersection(toDest.toSet()).toList()
      ..sort((a, b) => paths[b].length.compareTo(paths[a].length));
    int distance =
        toOrigin.length + toDest.length - 2 * paths[common[0]].length;
    print("Distance: $distance");
  }

  visit("COM", 0, []);
  print("Total orbits: $totalOrbits");
  if (findSanta) {
    findDistance("YOU", "SAN");
  }
}

void test() {
  orbits("COM)B B)C C)D D)E E)F B)G G)H D)I E)J J)K K)L", findSanta: false);
  orbits("COM)YOU COM)SAN", findSanta: true);
  orbits("COM)A A)YOU COM)SAN", findSanta: true);
  orbits("COM)A COM)B A)SAN B)YOU", findSanta: true);
  orbits("COM)A A)B A)SAN B)YOU ", findSanta: true);
}

void run(String filename) {
  orbits(readFile(filename), findSanta: true);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
