import 'package:collection/collection.dart';

bool debug_print = !true;

class Cell {
  final int _row;
  final int _col;
  int get row => _row;
  int get col => _col;

  int? _entry;
  set entry(entry) {
    _entry = entry;
  }

  int? get entry => _entry;
  void set(int entry) {
    _entry = entry;
  }

  bool get isNotSet => !isSet;
  bool get isSet => entry != null;

  Cell(this._row, this._col, this._entry);

  @override
  String toString() {
    return 'R${_row}C$_col=$_entry';
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
}

enum ConstraintType {
  LESS,
  GREATER;

  @override
  String toString() => this == LESS ? '<' : '>';
}

class Grid {
  List<List<Cell>> _grid = [];
  late int dimension;
  Map<Cell, List<Map<String, dynamic>>> constraints = {};

  late List<List<Cell>> _solution = [];

  String? _error;
  String? get error => _error;

  Grid(List<String> puzzle) {
    dimension = (puzzle.length + 1) ~/ 2;
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
          if (type == ConstraintType.GREATER && cell.entry! <= otherCell.entry!)
            return false;
          if (type == ConstraintType.LESS && cell.entry! >= otherCell.entry!)
            return false;
        }
      }
    }

    return true;
  }
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
