import 'package:collection/collection.dart';

bool debug_print = true;

class Possible {
  static late int dimension;
  late final List<bool> _possible;
  late final int _base;
  Possible([bool initial = true, this._base = 1])
      : _possible = List<bool>.filled(dimension, initial);
  Possible.value(int value, [this._base = 1])
      : _possible = List.generate(
            dimension, (index) => index == value - _base ? true : false);

  bool operator [](int value) => _possible[value - _base];
  void operator []=(int value, bool possible) =>
      _possible[value - _base] = possible;
  int get count => _possible.where((element) => element == true).length;

  @override
  String toString() {
    return List.generate(
      dimension,
      (i) => _possible[i] ? (i + _base).toString() : '',
    ).join('');
  }

  bool clear(int value) {
    if (_possible[value - _base]) {
      _possible[value - _base] = false;
      return true;
    }
    return false;
  }

  bool remove(Possible other) {
    var update = false;
    assert(_base == other._base);
    for (var value = _base; value < _base + dimension; value++) {
      if (other[value]) {
        if (clear(value)) {
          update = true;
        }
      }
    }
    return update;
  }

  int get min {
    for (var value = 0; value < dimension; value++) {
      if (_possible[value]) return value + _base;
    }
    return _base + dimension;
  }

  int get max {
    for (var value = dimension - 1; value >= 0; value--) {
      if (_possible[value]) return value + _base;
    }
    return _base - 1;
  }

  set min(int min) {
    for (var value = _base; value < min; value++) {
      clear(value);
    }
  }

  set max(int max) {
    for (var value = _base + dimension - 1; value > max; value--) {
      clear(value);
    }
  }

  int unique() {
    if (count == 1) {
      return _possible.indexOf(true) + _base;
    }
    return 0;
  }

  Possible subtract(Possible other) {
    assert(_base == other._base);
    var result = Possible.from(this);
    for (var value = 0; value < dimension; value++) {
      if (other._possible[value]) {
        result._possible[value] = false;
      }
    }
    return result;
  }

  Possible.from(Possible other) {
    _possible = List.from(other._possible);
    _base = other._base;
  }
}

class Cell {
  final int _row;
  final int _col;
  int get row => _row;
  int get col => _col;

  int? _entry;

  set entry(entry) {
    _entry = entry;
    if (_entry != null) {
      _possible = Possible.value(_entry!);
    }
  }

  int? get entry => _entry;
  void set(int entry) {
    _entry = entry;
  }

  bool get isNotSet => !isSet;
  bool get isSet => entry != null;

  late Possible _possible;
  Possible get possible => _possible;
  int get min => _entry != null ? _entry! : _possible.min;
  int get max => _entry != null ? _entry! : _possible.max;
  set min(int min) {
    if (_entry != null) {
      if (min > _entry!) {
        throw Exception('Cannot set min $min in $this');
      }
      return;
    }
    _possible.min = min;
  }

  set max(int max) {
    if (_entry != null) {
      if (max < _entry!) {
        throw Exception('Cannot set max $max in $this');
      }
      return;
    }
    _possible.max = max;
  }

  Cell(this._row, this._col, this._entry) {
    if (entry != null) {
      _possible = Possible.value(entry!);
    } else {
      _possible = Possible();
    }
  }

  @override
  String toString() {
    if (_entry != null) {
      return 'R${_row}C$_col=$_entry';
    }
    return 'R${_row}C$_col=$_possible';
  }

  Cell.fromJson(Map<String, dynamic> json)
      : _row = json['_row'],
        _col = json['_col'],
        _entry = json['_entry'];

  Map<String, dynamic> toJson() => {
        '_row': _row,
        '_col': _col,
        '_entry': _entry,
      };

  int compareTo(Cell other) {
    if (_row < other._row || _row == other._row && _col < other._col) {
      return -1;
    }
    if (_row == other._row && _col == other._col) {
      return 0;
    }
    return 1;
  }

  bool removePossible(Possible set) {
    if (_entry != null && set[_entry!]) {
      throw Exception('Cannot remove set entry from $this');
    }
    return _possible.remove(set);
  }

  bool checkUnique() {
    if (_entry != null) return false;
    var unique = _possible.unique();
    if (unique > 0) {
      entry = unique;
      return true;
    }
    return false;
  }

  int getAxis(String axis) {
    if (axis == 'R') return _row;
    if (axis == 'C') return _col;
    throw Exception('etAxis called with axis $axis');
  }
}

enum ConstraintType {
  LESS,
  GREATER;

  @override
  String toString() => this == LESS ? '<' : '>';
}

typedef Cells = List<Cell>;

class Grid {
  List<List<Cell>> _grid = [];
  late int dimension;
  Map<Object, List<Map<String, dynamic>>> constraints = {};

  String? _error;
  String? get error => _error;

  final List<String> puzzle;

  Grid(this.puzzle) {
    dimension = (puzzle.length + 1) ~/ 2;
    Possible.dimension = dimension;
    _grid = getPuzzle(puzzle);
  }

  List<List<Cell>> getPuzzle(List<String> rows) {
    var len = 2 * dimension - 1;
    if (rows.length != len || rows.any((element) => element.length != len)) {
      _error =
          'Puzzle of dimension $dimension requires $len rows of $len entries';
      return [];
    }
    var grid = <List<Cell>>[];
    var colComparisons = <String>[];
    List<Cell>? prevRow;
    for (var r = 0; r < len; r++) {
      List<Cell>? cells;
      var row = rows[r];
      if (r % 2 == 0) {
        // Row entries
        cells = <Cell>[];
        grid.add(cells);
        Cell? prevCell;
        var comparisonStr = ' ';
        for (var c = 0; c < len; c++) {
          if (c % 2 == 0) {
            // Grid entry
            var entryStr = row[c];
            int? entry;
            if (entryStr != '.') {
              entry = int.tryParse(entryStr);
              if (entry == null) {
                _error =
                    'Invalid row entry $entryStr at grid[$r,$c], must be "." or integer in range 1 to $dimension';
                return [];
              }
            }
            // New cell
            var cell = Cell(r ~/ 2, c ~/ 2, entry);
            cells.add(cell);
            // Row comparison
            if (comparisonStr != ' ') {
              addConstraints(
                  prevCell!,
                  cell,
                  comparisonStr == '<'
                      ? ConstraintType.LESS
                      : ConstraintType.GREATER);
            }
            // Column comparison
            if (r > 0 && colComparisons[c ~/ 2] != ' ') {
              var colComparisonStr = colComparisons[c ~/ 2];
              var prevCell = prevRow![cells.length - 1];
              addConstraints(
                  prevCell,
                  cell,
                  colComparisonStr == '^' || colComparisonStr == '<'
                      ? ConstraintType.LESS
                      : ConstraintType.GREATER);
            }
            prevCell = cell;
          } else {
            // Horizontal comparison
            comparisonStr = row[c];
            if (!'> <'.contains(comparisonStr)) {
              _error =
                  'Invalid row comparison $comparisonStr at grid[$r,$c], must be space, < or >';
              return [];
            }
          }
        }
        prevRow = cells;
        colComparisons.clear();
      } else {
        // Vertical comparisons
        for (var c = 0; c < len; c++) {
          var comparisonStr = row[c];
          if (c % 2 == 0) {
            // Grid entry - column comparison
            if (!r'^< \/>'.contains(comparisonStr)) {
              _error =
                  'Invalid column comparison $comparisonStr at grid[$r,$c], must be space, \\ or /';
              return [];
            }
            colComparisons.add(comparisonStr);
          } else {
            // Empty
            if (comparisonStr != ' ') {
              _error =
                  'Invalid column comparison $comparisonStr at grid[$r,$c], must be space';
              return [];
            }
          }
        }
      }
    }
    return grid;
  }

  @override
  String toString() {
    var text = '';
    for (var r = 0; r < dimension; r++) {
      text += rowString(r) + '\n';
      if (r < dimension - 1) {
        text += comparisonString(r) + '\n';
      }
    }
    return text;
  }

  String toPossibleString() {
    const rowBoxTopStart = '╔═══';
    const rowBoxTopMiddle = '╤═══';
    const rowBoxTopEnd = '╗\n';
    const rowSeparatorStart = '╟───';
    const rowSeparatorMiddle = '┼───';
    const rowSeparatorEnd = '╢\n';
    const rowBoxBottomStart = '╚═══';
    const rowBoxBottomMiddle = '╧═══';
    const rowBoxBottomEnd = '╝';
    const colBoxSeparator = '║';
    const colSeparator = '│';
    var rowBoxTop =
        rowBoxTopStart + rowBoxTopMiddle * (dimension - 1) + rowBoxTopEnd;
    var rowBoxBottom = rowBoxBottomStart +
        rowBoxBottomMiddle * (dimension - 1) +
        rowBoxBottomEnd;
    var result = StringBuffer();
    var tRows = 1 + (dimension - 1) ~/ 3;
    for (var r = 0; r < dimension; r++) {
      var row = _grid[r];
      var rowSeparator = '';
      if (r == 0) result.write(rowBoxTop);
      for (var t = 0; t < tRows; t++) {
        rowSeparator = rowSeparatorStart[0];
        for (var c = 0; c < dimension; c++) {
          var cell = row[c];
          if (c == 0) result.write(colBoxSeparator);
          for (var p = t * 3; p < t * 3 + 3; p++) {
            if (p < dimension && _grid[r][c].possible[p + 1]) {
              result.write(((p + 1).toString()));
            } else {
              result.write(' ');
            }
          }
          // column constraint
          if (r < dimension - 1) {
            var nextCell = _grid[r + 1][c];
            var constraint = getConstraint(cell, nextCell);
            rowSeparator +=
                (constraint?.toString() ?? rowSeparatorMiddle[1]) * 3;
            if (c < dimension - 1) {
              rowSeparator += rowSeparatorMiddle[0];
            }
          }
          if (c == dimension - 1) {
            result.write(colBoxSeparator);
            rowSeparator += rowSeparatorEnd;
          } else {
            // row constraint
            var nextCell = row[c + 1];
            var constraint = getConstraint(cell, nextCell);
            result.write(constraint?.toString() ?? colSeparator);
          }
        }
        result.write('\n');
      }
      if (r == dimension - 1) {
        result.write(rowBoxBottom);
      } else {
        result.write(rowSeparator);
      }
    }
    return result.toString();
  }

  String rowString(int r) {
    var text = '';
    var row = _grid[r];
    for (var c = 0; c < dimension; c++) {
      var cell = row[c];
      text += cell.entry?.toString() ?? '.';
      if (c < dimension - 1) {
        var nextCell = row[c + 1];
        var constraint = getConstraint(cell, nextCell);
        text += constraint?.toString() ?? ' ';
      }
    }
    return text;
  }

  String comparisonString(int r) {
    var text = '';
    var row = _grid[r];
    var nextRow = _grid[r + 1];
    for (var c = 0; c < dimension; c++) {
      var cell = row[c];
      var nextCell = nextRow[c];
      var constraint = getConstraint(cell, nextCell);
      text += constraint?.toString() ?? ' ';
      if (c < dimension - 1) {
        text += ' ';
      }
    }
    return text;
  }

  void addConstraints(Cell prevCell, Cell cell, ConstraintType constraintType) {
    addConstraint(
      prevCell,
      cell,
      constraintType,
    );
    addConstraint(
        cell,
        prevCell,
        constraintType == ConstraintType.LESS
            ? ConstraintType.GREATER
            : ConstraintType.LESS);
  }

  void addConstraint(Cell prevCell, Cell cell, ConstraintType constraintType) {
    if (!constraints.containsKey(prevCell)) {
      constraints[prevCell] = [];
    }
    constraints[prevCell]!.add({
      'cell': cell,
      'type': constraintType,
    });
  }

  ConstraintType? getConstraint(Cell prevCell, Cell cell) {
    if (!constraints.containsKey(prevCell)) return null;
    var constraint =
        constraints[prevCell]!.firstWhereOrNull((c) => c['cell'] == cell);
    if (constraint == null) return null;
    return constraint['type'];
  }

//   String solutionString(List<List<Cell>> solution) {
//     var text = '';
//     for (var r = 0; r < dimension; r++) {
//       text += ' ' + solution[r].fold('', (p, c) => p + (c.entry)) + '\n';
//       ;
//     }
//     return text;
//   }

  List<Cell> queue = [];

  Iterable<String> solutions() sync* {
    // var l = json.decode(json.encode(_grid));
    // var solution = List<List<Cell>>.from(
    //     l.map((r) => List<Cell>.from(r.map((e) => Cell.fromJson(e)))));
    // var cell = solution[start!.row][start!.col];
    _grid.forEach((row) {
      row.forEach((cell) {
        queue.add(cell);
      });
    });
    queue = queue.reversed.toList();
    var cell = queue.removeLast();
    yield* backtrack(cell);
    return;
  }

  var iterations = 0;
  Iterable<String> backtrack(Cell currentCell) sync* {
    // Try values in currentCell
    var alreadySet = currentCell.isSet;
    for (var v = 1; v <= dimension; v++) {
      if (!alreadySet || v == currentCell.entry) {
        iterations++;
        setCell(currentCell, v);
        if (cellOK(currentCell)) {
          // Try next cell
          if (queue.isNotEmpty) {
            var nextCell = queue.removeLast();
            yield* backtrack(nextCell);
            queue.add(nextCell);
          } else {
            // Solution
            yield toString();
          }
        }
        undoSetCell();
      }
    }
    return;
  }

  List<Cell> undoCells = [];
  List<int?> undoEntries = [];
  List<int> undoIndexes = [];
  void rememberCell(Cell cell, [bool combine = false]) {
    if (!combine) {
      // New undo stack item
      undoIndexes.add(undoCells.length);
    }
    undoCells.add(cell);
    undoEntries.add(cell.entry);
  }

  void setCell(Cell cell, int value, [bool combine = false]) {
    rememberCell(cell, combine);
    cell.set(value);
  }

  void undoSetCell() {
    assert(undoIndexes.isNotEmpty);
    while (undoCells.length > undoIndexes.last) {
      var cell = undoCells.removeLast();
      cell.entry = undoEntries.removeLast();
    }
    undoIndexes.removeLast();
  }

  bool cellOK(Cell cell) {
    var solution = _grid;
    var rowCells = solution[cell.row];
    var colCells = solution.expand((row) => [row[cell.col]]);

    // Check for duplicates in row or column
    if (rowCells.any((c) => c != cell && c.entry == cell.entry)) return false;
    if (colCells.any((c) => c != cell && c.entry == cell.entry)) return false;

    // Check constraints
    if (constraints.containsKey(cell)) {
      for (var constraint in constraints[cell]!) {
        var otherCell = constraint['cell'] as Cell;
        if (otherCell.isSet) {
          var type = constraint['type'] as ConstraintType;
          if (type == ConstraintType.GREATER &&
              cell.entry! <= otherCell.entry!) {
            return false;
          }
          if (type == ConstraintType.LESS && cell.entry! >= otherCell.entry!) {
            return false;
          }
        }
      }
    }

    return true;
  }

  String? logicSolve() {
    var update = true;
    while (update) {
      // Try different logic steps
      update = false;
      if (!update) update = updatePossible();
      if (!update) update = updateConstraints();
      if (!update) update = findSingle();
      if (!update) update = nakedGroup();
    }
    printDebug(toPossibleString() + '\n');
    return toString();
  }

  bool updatePossible() {
    var update = false;
    for (var axis in ['R', 'C']) {
      for (var index = 0; index < dimension; index++) {
        var cells = getAxis(axis, index);
        var set = Possible(false);
        for (var cell in cells) {
          if (cell.entry != null) {
            set[cell.entry!] = true;
          }
        }
        if (set.count > 0) {
          for (var cell in cells) {
            if (cell.entry == null) {
              if (cell.removePossible(set)) {
                update = true;
                printDebug('updatePossible: $cell');
              }
            }
          }
        }
      }
    }
    return update;
  }

  bool updateConstraints() {
    var update = false;
    for (var entry in constraints.entries) {
      var cell = entry.key as Cell;
      for (var constraint in entry.value) {
        var otherCell = constraint['cell'] as Cell;
        var type = constraint['type'] as ConstraintType;
        if (type == ConstraintType.GREATER && cell.min <= otherCell.min) {
          cell.min = otherCell.min + 1;
          update = true;
          printDebug('updateConstraints: set min for $cell');
        }
        if (type == ConstraintType.LESS && cell.max >= otherCell.max) {
          cell.max = otherCell.max - 1;
          update = true;
          printDebug('updateConstraints: set max for $cell');
        }
      }
    }
    return update;
  }

  bool findSingle() {
    var updated = false;
    _grid.forEach((row) => row.forEach((cell) {
          if (!cell.isSet) {
            if (cell.checkUnique()) {
              updated = true;
              cellUpdated(cell, 'Naked Single', '$cell');
            } else {
              // Check for a possible value not in row or column
              for (var axis in ['R', 'C']) {
                var cells = getAxis(axis, cell.getAxis(axis)).toList();
                if (cells.isNotEmpty) {
                  cells.remove(cell);
                  var otherPossible = unionCellsPossible(cells);
                  var difference = cell.possible.subtract(otherPossible);
                  var value = difference.unique();
                  if (value > 0) {
                    cell.entry = value;
                    updated = true;
                    cellUpdated(cell, 'Hidden Single', '$cell');
                    break;
                  }
                }
              }
            }
          }
        }));
    return updated;
  }

  bool nakedGroup() {
    var update = false;
    for (var axis in ['R', 'C']) {
      for (var index = 0; index < dimension; index++) {
        var cells = getAxis(axis, index);
        if (nonetNakedGroup(cells)) {
          update = true;
        }
      }
    }
    return update;
  }

  bool nonetNakedGroup(Iterable<Cell> cells) {
    var anyUpdate = false;
    // Check cells for groups
    // Ignore known cells
    var possibleCells = cells.where((cell) => !cell.isSet).toList();
    var groupMax = (possibleCells.length + 1) ~/ 2;
    //var groupMax = possibleCells.length - 1;
    var groupMin = 2;
    if (groupMax < groupMin) return false;

    // Check for groups of groupMin to groupMax cells
    var updated = true;
    while (updated) {
      updated = false;
      for (var gl = groupMin; gl <= groupMax; gl++) {
        var groups = findGroups(possibleCells, gl, [], 0);
        for (var group in groups) {
          var possible = unionCellsPossible(group);
          // Remove group from other cells
          for (var i = 0; i < possibleCells.length; i++) {
            var c = possibleCells[i];
            if (!group.contains(c)) {
              if (c.removePossible(possible)) {
                updated = true;
                anyUpdate = true;
                cellUpdated(c, 'Naked Group', 'remove group $possible from $c');
              }
            }
          }
        }
      }
    }
    return anyUpdate;
  }

  /// Recursive function to compute Groups (Pairs, Triples, etc) of possible values
  /// pC - list of cells to check
  /// g - required group size
  /// sC - current cells in group
  /// f - next index in check cells to try
  /// Returns list of groups, each of which is a list of cells
////
  List<Cells> findGroups(Cells pC, int g, Cells sC, int f) {
    var groups = <Cells>[];
    for (var index = f; index < pC.length; index++) {
      var c = pC[index];
      if (!sC.contains(c) && c.possible.count <= g) {
        var newSC = [...sC, c];
        var possible = unionCellsPossible(newSC);
        if (possible.count <= g) {
          if (newSC.length == g) {
            groups.add(newSC);
          } else {
            // try adding cells to group
            var newGroups = findGroups(pC, g, newSC, index + 1);
            if (newGroups.isNotEmpty) {
              groups.addAll(newGroups);
            }
          }
        }
      }
    }
    return groups;
  }

  Iterable<Cell> getAxis(String axis, int index) {
    if (axis == 'R') {
      return _grid[index];
    }
    if (axis == 'C') {
      return _grid.expand((row) => [row[index]]);
    }
    return [];
  }

  void cellUpdated(Cell cell, String s, String t) {
    printDebug('$s: $t');
  }
}

Possible unionCellsPossible(List<Cell> cells) {
  var possibles = cells.map((cell) => cell.possible).toList();
  return unionPossible(possibles);
}

Possible unionPossible(List<Possible> possibles, [base = 1]) {
  var result = Possible(false, base);
  for (var value = 0; value < Possible.dimension; value++) {
    result._possible[value] = possibles.fold(
        false,
        (previousValue, possible) =>
            possible._possible[value] ? true : previousValue);
  }
  return result;
}

class Futoshiki {
  late final Grid _grid;
  String? _error;
  String? get error => _error;

  Futoshiki(List<String> puzzle) {
    _grid = Grid(puzzle);
    _error = _grid.error;
  }

  @override
  String toString() {
    return '$_grid';
  }

  var _solutionCount = 0;
  void solve() {
    if (error != null) {
      print(error);
      return;
    }

    print(this);
    var copy = Grid(_grid.puzzle);
    var logicSolution = copy.logicSolve();
    if (logicSolution != null) {
      print('Logic Solution\n$logicSolution');
    }
    print('Backtrack Solution(s)');
    for (var solution in _grid.solutions()) {
      print(solution);
      _solutionCount++;
    }
    print('Solutions: $_solutionCount, ${_grid.iterations} iterations\n');
  }
}

void printDebug(String msg) {
  if (debug_print) print(msg);
}
