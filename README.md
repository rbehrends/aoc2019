# Advent of Code 2019 in Dart

These are Dart implementations of the [Advent of Code
2019](https://adventofcode.com/2019) puzzles.

The code has mostly been refactored and cleaned up, but algorithmically
reflects the original solution. Some days have alternative solutions,
e.g. `day12a.dart`.

# Running the examples.

Note that the codes relies on the (as of yet) experimental NNBD feature
(part of the motivation for writing the code was to try that out). With
current version ofs Dart (2.6 or 2.7) they need to be run with `dart
--enable-experiment=non-nullable` in order to work, e.g.:

    dart --enable-experiment=non-nullable day1.dart input1.txt

Alternatively, you can run `make` to build executables in the `bin`
directory, which can then be run directly. This should ideally be run
with `make -j4` or a similar degree of parallelization in order to build
faster, as over two dozen executables will be compiled, which can take
some time.

As `dart2native` does not currently support experimental flags, the
`denull` tool will automatically be run on copies of the files to strip
out NNBD annotations.

