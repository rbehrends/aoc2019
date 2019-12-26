import "util.dart";

int fuel(int mass) => max(mass ~/ 3 - 2, 0);

int extraFuel(int basefuel) {
  var total = 0;
  var extraMass = basefuel;
  while (extraMass > 0) {
    extraMass = fuel(extraMass);
    total += extraMass;
  }
  return total;
}

void test() {
  for (var mass in [12, 14, 1969, 100756]) {
    print("Mass: $mass => Fuel: ${fuel(mass)} | ${extraFuel(mass)}");
  }
}

void run(String filename) {
  int total = 0;
  int extra = 0;
  for (var mass in RegExp("[0-9]+")
      .allMatches(readFile(filename))
      .map((match) => int.parse(match[0]))) {
    var basefuel = fuel(mass);
    total += basefuel;
    extra += extraFuel(basefuel);
  }
  print(total);
  print(total + extra);
}

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
