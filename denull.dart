// Tool to strip NNBD annotations to allow processing with dart2native,
// which does not support the --enable-experiment option.

import "dart:io";

void main(List<String> args) {
  for (var filename in args) {
    var file = File(filename);
    var data = file.readAsStringSync();
    data = data
        .replaceAllMapped(RegExp(r"([A-Za-z_0-9)>])[?!]"), (match) => match[1])
        .replaceAll(RegExp(r"\brequired "), "");
    file.writeAsStringSync(data);
  }
}
