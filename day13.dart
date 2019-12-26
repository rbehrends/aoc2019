import "util.dart";
import "intcode.dart";

class Game {
  Vector? ball = null;
  Vector? paddle = null;
  Map<Vector, int> grid = {};
  Processor program;
  int score = 0;
  Game(this.program);
  String toString() {
    Vector p0 = grid.keys.first;
    int ymin = p0.y, xmin = p0.x, ymax = ymin, xmax = xmin;
    for (var p in grid.keys) {
      ymin = min(ymin, p.y);
      ymax = max(ymax, p.y);
      xmin = min(xmin, p.x);
      xmax = max(xmax, p.x);
    }
    return List.generate(
            ymax - ymin + 1, // rows
            (y) => List.generate(
                xmax - xmin + 1, // columns
                (x) => " #%_o"[grid[Vector(x + xmin, y + ymin)] ?? 0]).join())
        .join("\n");
  }

  void run() {
    List<int> output = [];
    program.executeWithIO(
        onInput: () => (ball!.x - paddle!.x).sign,
        onOutput: (x) {
          output.add(x);
          if (output.length == 3) {
            if (output[0] < 0) {
              score = output[2];
            } else {
              Vector pos = Vector(output[0], output[1]);
              grid[pos] = output[2];
              switch (output[2]) {
                case 3:
                  paddle = pos;
                  break;
                case 4:
                  ball = pos;
                  break;
              }
            }
            output = [];
          }
        });
  }
}

void run(String filename) {
  var code = parseInts(readFile(filename));
  var game = Game(Processor(code));
  // initial setup
  game.run();
  print(game);
  print(game.grid.values.where((id) => id == 2).length);
  // play the game
  code[0] = 2;
  game = Game(Processor(code));
  game.run();
  print(game.score);
}

void main(List<String> args) {
  run(args[0]);
}
