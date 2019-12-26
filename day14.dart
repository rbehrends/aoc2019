import "util.dart";

class Reagent {
  final String type;
  final int amount;
  Reagent(this.type, this.amount);
  String toString() => "($type: $amount)";
}

class Recipe {
  final String type;
  final int amount;
  final List<Reagent> inputs;
  Recipe(this.type, this.amount, this.inputs);
}

Map<String, Recipe> parseRecipes(String input) {
  Map<String, Recipe> result = {};
  for (var line in input.trim().split("\n")) {
    List<Reagent> recipe = [];
    for (var match in RegExp("([0-9]+) +([A-Z]+)").allMatches(line)) {
      recipe.add(Reagent(match[2], int.parse(match[1])));
    }
    result[recipe.last.type] = Recipe(recipe.last.type, recipe.last.amount,
        recipe.sublist(0, recipe.length - 1));
  }
  return result;
}

void fuelCheck(String input) {
  var recipes = parseRecipes(input);
  const maxOre = 1000 * 1000 * 1000 * 1000;

  int oreNeeded(int fuel) {
    // State maps reagents to needed quantities; negative amounts
    // indicate that needs could be satisfied from overproduction in
    // previous steps.
    var state = {"FUEL": fuel};
    // Breadth first search requires fewer iterations for shared
    // reagents than depth first search. We could speed it up still
    // further by topologically sorting the reagents so that each
    // reagent is encountered only after all recipes that contain it
    // are processed, but that is overkill.
    var productionQueue = ListQueue.of(state.keys);
    while (productionQueue.isNotEmpty) {
      var component = productionQueue.removeFirst();
      var neededAmount = state[component];
      if (neededAmount > 0) {
        var recipe = recipes[component];
        int amount = recipe.amount;
        int repeats = (neededAmount + amount - 1) ~/ amount;
        state[component] -= repeats * amount;
        for (var reagent in recipe.inputs) {
          state[reagent.type] ??= 0;
          state[reagent.type] += reagent.amount * repeats;
          if (reagent.type != "ORE") productionQueue.add(reagent.type);
        }
      }
    }
    return state["ORE"] ?? 0;
  }

  int fuelFromOre(int availableOre) {
    int minFuel = recipes["FUEL"].amount;
    int fuel = availableOre * minFuel ~/ oreNeeded(minFuel); // low estimate
    int step = fuel;
    while (step > 0) {
      if (oreNeeded(fuel + step) > availableOre)
        step ~/= 2;
      else
        fuel += step;
    }
    return fuel;
  }

  print("Ore needed per fuel: ${oreNeeded(1)}");
  print("Fuel produced from ${maxOre} ore: ${fuelFromOre(maxOre)}");
}

void test() {
  fuelCheck("""
  9 ORE => 2 A
  8 ORE => 3 B
  7 ORE => 5 C
  3 A, 4 B => 1 AB
  5 B, 7 C => 1 BC
  4 C, 1 A => 1 CA
  2 AB, 3 BC, 4 CA => 1 FUEL
  """);
  fuelCheck("""
  157 ORE => 5 NZVS
  165 ORE => 6 DCFZ
  44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL
  12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ
  179 ORE => 7 PSHF
  177 ORE => 5 HKGWZ
  7 DCFZ, 7 PSHF => 2 XJWVT
  165 ORE => 2 GPVTF
  3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT
  """);
  fuelCheck("""
  2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG
  17 NVRVD, 3 JNWZP => 8 VPVL
  53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL
  22 VJHF, 37 MNCFX => 5 FWMGM
  139 ORE => 4 NVRVD
  144 ORE => 7 JNWZP
  5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC
  5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV
  145 ORE => 6 MNCFX
  1 NVRVD => 8 CXFTF
  1 VJHF, 6 MNCFX => 4 RFSQX
  176 ORE => 6 VJHF
  """);
  fuelCheck("""
  171 ORE => 8 CNZTR
  7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL
  114 ORE => 4 BHXH
  14 VRPVC => 6 BMBT
  6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL
  6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT
  15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW
  13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW
  5 BMBT => 4 WPTQ
  189 ORE => 9 KTJDG
  1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP
  12 VRPVC, 27 CNZTR => 2 XDBXC
  15 KTJDG, 12 BHXH => 5 XCVML
  3 BHXH, 2 VRPVC => 7 MZWV
  121 ORE => 7 VRPVC
  7 XCVML => 6 RJRHP
  5 BHXH, 4 VRPVC => 5 LTCX
  """);
}

void run(String filename) => fuelCheck(readFile((filename)));

void main(List<String> args) {
  if (args.isEmpty)
    test();
  else
    run(args[0]);
}
