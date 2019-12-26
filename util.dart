library util;

import "dart:io";
import "dart:math";
import "dart:collection";

export "dart:math";
export "dart:collection";

const int minInt = (-1) << 63;
const int maxInt = -(minInt + 1);

const int hashInit = 5381;
int rehash(int hash, int val) => hash * 33 + val;
int hash2(int a, int b) => rehash(rehash(hashInit, a), b);

extension ExtString on String {
  bool operator <=(String other) => compareTo(other) <= 0;
  bool operator >=(String other) => compareTo(other) >= 0;
  bool operator <(String other) => compareTo(other) < 0;
  bool operator >(String other) => compareTo(other) > 0;
}

extension<T> on List<T> {
  void swap(int a, int b) {
    var tmp = this[a];
    this[a] = this[b];
    this[b] = tmp;
  }
}

bool everyPair<T>(List<T> a, List<T> b, bool pred(T a, T b)) {
  int n = min(a.length, b.length);
  for (int i = 0; i < n; i++) if (!pred(a[i], b[i])) return false;
  return true;
}

List<R> mapPairs<R, A, B>(List<A> a, List<B> b, R mapfunc(A a, B b)) =>
    List.generate(min(a.length, b.length), (i) => mapfunc(a[i], b[i]));

R foldPairs<R, A, B>(List<A> a, List<B> b, R init, R foldfunc(R r, A a, B b)) {
  int n = min(a.length, b.length);
  R acc = init;
  for (int i = 0; i < n; i++) acc = foldfunc(acc, a[i], b[i]);
  return acc;
}

extension Matrix<T> on List<List<T>> {
  List<List<T>> transpose() => List.generate(
      first.length, (col) => List.generate(length, (row) => this[row][col]));
}

extension ExtInt on int {
  BigInt get bigint => BigInt.from(this);
}

class Indexed<T> {
  final int index;
  final T value;
  Indexed(this.index, this.value);
}

extension ExtIterable<T> on Iterable<T> {
  Iterable<Indexed<T>> indexed({int start = 0}) sync* {
    for (var item in this) yield Indexed(start++, item);
  }

  Iterable<List<T>> chunks(int chunksize) sync* {
    assert(chunksize > 0);
    var result = <T>[];
    for (var item in this) {
      result.add(item);
      if (result.length == chunksize) {
        yield result;
        result = <T>[];
      }
    }
    if (result.isNotEmpty) yield result;
  }
}

Iterable<List<T>> _permutations<T>(List<T> items, int k) sync* {
  if (k == 0)
    yield [...items];
  else
    for (int i = 0; i <= k; i++) {
      items.swap(i, k);
      yield* _permutations(items, k - 1);
      items.swap(i, k);
    }
}

Iterable<List<T>> permutations<T>(List<T> items) =>
    _permutations([...items], items.length - 1);

List<int> parseInts(String input) =>
    RegExp(r"-?[0-9]+").allMatches(input).map((x) => int.parse(x[0])).toList();

String readFile(String filename) => File(filename).readAsStringSync();

List<String> readLines(String filename) => File(filename).readAsLinesSync();

class Vector {
  final int x, y;
  Vector(int this.x, int this.y);
  bool operator ==(covariant Vector other) => x == other.x && y == other.y;
  String toString() => "($x, $y)";
  int get hashCode => hash2(x, y);
  Vector operator +(covariant Vector other) => Vector(x + other.x, y + other.y);
  Vector operator -(covariant Vector other) => Vector(x - other.x, y - other.y);
}

class PriorityQueue<P extends Comparable<P>, T> {
  final _queue = SplayTreeMap<P, List<T>>();
  final P Function(T item)? _prioFunc;
  PriorityQueue([this._prioFunc = null]);
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  void add(T item, {P? prio = null}) {
    prio ??= _prioFunc!(item);
    if (_queue.containsKey(prio))
      _queue[prio].add(item);
    else
      _queue[prio] = [item];
  }

  T removeFirst() {
    P prio = _queue.firstKey();
    List<T> items = _queue[prio];
    if (items.length == 1) _queue.remove(prio);
    return items.removeAt(0);
  }
}
