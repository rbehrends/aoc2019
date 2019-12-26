import "util.dart";

class Vector3 {
  final int x, y, z;
  Vector3(this.x, this.y, this.z);
  factory Vector3.of(Vector3 other) => Vector3(other.x, other.y, other.z);
  int get(int d) => d == 0 ? x : (d == 1 ? y : z);
  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 get sign => Vector3(x.sign, y.sign, z.sign);
  int get l1 => x.abs() + y.abs() + z.abs();
  String toString() => "<x=$x, y=$y, z=$z>";
}

class Moon {
  Vector3 pos, vel;
  Moon(this.pos, this.vel);
  factory Moon.of(Moon moon) =>
      Moon(Vector3.of(moon.pos), Vector3.of(moon.vel));
  int get energy => pos.l1 * vel.l1;
  String toString() => "(pos: $pos, velocity: $vel)";
}

class State {
  List<Moon> moons;
  State(List<Moon> moons) : moons = [for (var moon in moons) Moon.of(moon)];
  factory State.of(State other) => State(other.moons);
  int get energy => moons.fold(0, (sum, moon) => sum + moon.energy);
  void next() {
    for (var moon in moons)
      for (var moon2 in moons) moon.vel += (moon2.pos - moon.pos).sign;
    for (var moon in moons) moon.pos += moon.vel;
  }

  List<int> project(int d) => [
        for (var moon in moons) ...[moon.pos.get(d), moon.vel.get(d)]
      ];
}

Iterable<State> states(State state) sync* {
  for (;;) {
    state.next();
    yield state;
  }
}

int lcm(int a, int b) => a ~/ a.gcd(b) * b;

int findCycle(List<Moon> moons) {
  bool eq(List<int> v1, List<int> v2) => everyPair(v1, v2, (a, b) => a == b);

  List<int> c = [0, 0, 0];
  State initial = State(moons);
  int count = 0;
  for (var state in states(State(moons))) {
    count++;
    for (int d = 0; d < 3; d++)
      if (c[d] == 0 && eq(initial.project(d), state.project(d))) c[d] = count;
    if (c[0] > 0 && c[1] > 0 && c[2] > 0) break;
  }
  return lcm(lcm(c[0], c[1]), c[2]);
}

final coordPat = RegExp("<x=(-?[0-9]+), *y=(-?[0-9]+), *z=(-?[0-9]+)>");

List<Vector3> parseCoords(String input) => coordPat
    .allMatches(input)
    .map((m) => Vector3(int.parse(m[1]), int.parse(m[2]), int.parse(m[3])))
    .toList();

List<Moon> parse(String input) =>
    parseCoords(input).map((pos) => Moon(pos, Vector3(0, 0, 0))).toList();

void printMoons(List<Moon> moons) => print(moons.join("\n"));

void simulate(String input, int steps) {
  var initial = State(parse(input));
  printMoons(initial.moons);
  print("Energy:       ${states(initial).take(steps).last.energy}");
  print("Cycle length: ${findCycle(parse(input))}");
}

void test() {
  simulate("""
  <x=0, y=0, z=0>
  <x=1, y=1, z=1>
  """, 1);
  print("------------------");
  simulate("""
  <x=-1, y=0, z=2>
  <x=2, y=-10, z=-7>
  <x=4, y=-8, z=8>
  <x=3, y=5, z=-1>
 """, 10);
  print("------------------");
  simulate("""
  <x=-8, y=-10, z=0>
  <x=5, y=5, z=10>
  <x=2, y=-7, z=3>
  <x=9, y=-8, z=-3>
  """, 100);
}

void run(String filename) {
  simulate(readFile(filename), 1000);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
