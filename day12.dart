import "util.dart";

class Vector3 {
  final int x, y, z;
  Vector3(this.x, this.y, this.z);
  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 get sign => Vector3(x.sign, y.sign, z.sign);
  int l1() => x.abs() + y.abs() + z.abs();
  String toString() => "<x=$x, y=$y, z=$z>";
}

class Moon {
  Vector3 pos, velocity;
  Moon(this.pos, this.velocity);
  int energy() => pos.l1() * velocity.l1();
  String toString() => "(pos: $pos, velocity: $velocity)";
}

void step(List<Moon> moons, {int steps = 1}) {
  for (int i = 0; i < steps; i++) {
    for (var moon in moons) {
      // We do not need to check for moon != moon2, as the velocity
      // change is zero.
      for (var moon2 in moons) moon.velocity += (moon2.pos - moon.pos).sign;
    }
    for (var moon in moons) moon.pos += moon.velocity;
  }
}

int findCycleAux(List<int> startPos) {
  // Each cycle has to include the initial state, thus we can check for
  // whether we found the initial position with velocities of zero.
  //
  // Proof: the step function is bijective for the states we visit; you
  // can construct each state from its successor state by subtracting
  // the velocities from the positions to arrive at the old positions,
  // then subtracting the signs of the old position differences from the
  // velocities to also get the old velocities.
  //
  // Hence no two different states that are reachable from the initial
  //state can have the same successor state.
  var pos = [...startPos];
  var velocity = List.filled(pos.length, 0);
  int count = 0;
  bool foundCycle = false;
  while (!foundCycle) {
    count++;
    // We do not need to check for i != j, as the velocity change is zero.
    for (int i = 0; i < pos.length; i++)
      for (int j = 0; j < pos.length; j++)
        velocity[i] += (pos[j] - pos[i]).sign;
    foundCycle = true;
    for (int i = 0; i < pos.length; i++) {
      pos[i] += velocity[i];
      if (velocity[i] != 0 || pos[i] != startPos[i]) foundCycle = false;
    }
    if (foundCycle) break;
  }
  return count;
}

int lcm(int a, int b) => a ~/ a.gcd(b) * b;

int findCycle(List<Moon> moons) {
  int cx = findCycleAux([for (var moon in moons) moon.pos.x]);
  int cy = findCycleAux([for (var moon in moons) moon.pos.y]);
  int cz = findCycleAux([for (var moon in moons) moon.pos.z]);
  return lcm(lcm(cx, cy), cz);
}

final coordPat = RegExp("<x=(-?[0-9]+), *y=(-?[0-9]+), *z=(-?[0-9]+)>");

List<Vector3> parseCoords(String input) => coordPat
    .allMatches(input)
    .map((m) => Vector3(int.parse(m[1]), int.parse(m[2]), int.parse(m[3])))
    .toList();

List<Moon> parse(String input) =>
    parseCoords(input).map((pos) => Moon(pos, Vector3(0, 0, 0))).toList();

void printMoons(List<Moon> moons) => print(moons.join("\n"));

int energy(List<Moon> moons) =>
    moons.fold(0, (sum, moon) => sum + moon.energy());

void simulate(String input, int steps) {
  var moons = parse(input);
  printMoons(moons);
  step(moons, steps: steps);
  print("Energy:       ${energy(moons)}");
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
