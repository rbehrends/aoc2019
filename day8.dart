import "util.dart";

void showImage(Iterable<int> image, int width) {
  String toAscii(List<int> line) => line.map((color) => " *?"[color]).join();
  for (var line in image.chunks(width)) print(toAscii(line));
}

Iterable<int> renderImage(List<List<int>> layers) =>
    layers.transpose().map((colors) =>
        colors.reduce((current, next) => current == 2 ? next : current));

int checksumImage(List<List<int>> layers) {
  var counts = layers
      .map((layer) => layer.fold([0, 0, 0], (counts, color) {
            counts[color]++;
            return counts;
          }))
      .reduce((a, b) => a[0] < b[0] ? a : b);
  return counts[1] * counts[2];
}

List<List<int>> parseLayers(String input, int width, int height) =>
    RegExp("[0-9]")
        .allMatches(input)
        .map((m) => int.parse(m[0]))
        .chunks(width * height)
        .toList();

void analyze(String filename, int width, int height) {
  var layers = parseLayers(readFile(filename), width, height);
  print("Checksum: ${checksumImage(layers)}");
  var image = renderImage(layers);
  showImage(image, width);
}

void main(List<String> args) => analyze(args[0], 25, 6);
