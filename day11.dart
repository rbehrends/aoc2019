import "util.dart";
import "intcode.dart";

Map<Vector, int> paint(Vector pos, Processor driver, Map<Vector, int> panels) {
  var delta = Vector(0, -1);
  panels = Map.of(panels);
  while (!driver.halted) {
    driver.input.add(panels[pos] ?? 0);
    driver.executeSyncOutput(onOutput: (color) {
      panels[pos] = color;
      driver.executeSyncOutput(onOutput: (dir) {
        if (dir == 0)
          delta = Vector(delta.y, -delta.x);
        else
          delta = Vector(-delta.y, delta.x);
        pos += delta;
      });
    });
  }
  return panels;
}

void showGrid(Map<Vector, int> panels) {
  int xmax = 0, xmin = 0, ymin = 0, ymax = 0;
  for (var pos in panels.keys) {
    ymin = min(ymin, pos.y);
    ymax = max(ymax, pos.y);
    xmin = min(xmin, pos.x);
    xmax = max(xmax, pos.x);
  }
  var output = List.generate(
      ymax - ymin + 1,
      (y) => List.generate(
          xmax - xmin + 1,
          (x) => [
                "\u001b[40m \u001b[0m",
                "\u001b[47m \u001b[0m"
              ][panels[Vector(x - xmin, y - ymin)] ?? 0]));
  for (var line in output) {
    print(line.join());
  }
}

void run(String filename) {
  var code = parseInts(readFile(filename));
  print(paint(Vector(0, 0), Processor(code), {}).length);
  showGrid(paint(Vector(0, 0), Processor(code), {Vector(0, 0): 1}));
}

void main(List<String> args) {
  run(args[0]);
}
