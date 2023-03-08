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
  bool get isSet => entry != 0;

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
                  colComparisonStr == '^'
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
            if (!r'^ \/'.contains(comparisonStr)) {
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

//   Iterable<String> solutions() sync* {
//     var l = json.decode(json.encode(_grid));
//     var solution = List<List<Cell>>.from(
//         l.map((r) => List<Cell>.from(r.map((e) => Cell.fromJson(e)))));
//     var cell = solution[start!.row][start!.col];
//     cell.set();
//     yield* backtrack(solution, cell, cell);
//     return;
//   }

//   Iterable<Cell> neighbours(List<List<Cell>> solution, Cell cell) {
//     var cells = <Cell>[];
//     if (cell.row > 0) cells.add(solution[cell.row - 1][cell.col]);
//     if (cell.row < dimension - 1) cells.add(solution[cell.row + 1][cell.col]);
//     if (cell.col > 0) cells.add(solution[cell.row][cell.col - 1]);
//     if (cell.col < dimension - 1) cells.add(solution[cell.row][cell.col + 1]);
//     return cells;
//   }

//   var iterations = 0;
//   Iterable<String> backtrack(
//       List<List<Cell>> solution, Cell currentCell, Cell priorCell) sync* {
//     var nextCells = neighbours(solution, currentCell)
//         .where((cell) => cell.isNotSet && !cell.isDisallowed)
//         .toList();
//     for (var nextCell in nextCells) {
//       var oldEntry = nextCell.entry;
//       setCell(nextCell); // Placeholder until next cell processed
//       currentCell.entry = getEntry(priorCell.row, priorCell.col,
//           currentCell.row, currentCell.col, nextCell.row, nextCell.col);
//       if (cellOK(solution, nextCell.row, nextCell.col)) {
//         iterations++;
//         if (nextCell.row != end!.row || nextCell.col != end!.col) {
//           yield* backtrack(solution, nextCell, currentCell);
//         } else {
//           // Complete if no unset grid cells
//           if (gridOK(solution) &&
//               !solution.any((row) => row.any((cell) => cell.isRequired))) {
//             yield solutionString(solution);
//           }
//         }
//       }

//       undoSetCell();
//     }
//     return;
//   }

//   List<Cell> undoCells = [];
//   List<String> undoEntries = [];
//   List<int> undoIndexes = [];
//   void rememberCell(Cell cell, [bool combine = false]) {
//     if (!combine) {
//       // New undo stack item
//       undoIndexes.add(undoCells.length);
//     }
//     undoCells.add(cell);
//     undoEntries.add(cell.entry);
//   }

//   void setCell(Cell cell, [bool combine = false, String entry = 'X']) {
//     rememberCell(cell, combine);
//     cell.set(entry);
//   }

//   void disallowCell(Cell cell, [bool combine = false]) {
//     rememberCell(cell, combine);
//     cell.disallow();
//   }

//   void undoSetCell() {
//     assert(undoIndexes.isNotEmpty);
//     while (undoCells.length > undoIndexes.last) {
//       var cell = undoCells.removeLast();
//       cell.entry = undoEntries.removeLast();
//     }
//     undoIndexes.removeLast();
//   }

//   bool cellOK(List<List<Cell>> solution, int row, int col,
//       [bool exact = false]) {
//     var rowCells = solution[row];
//     var rowSetCells = rowCells.where((cell) => cell.isSet || cell.isRequired);
//     var rowEntries = rowSetCells.length;
//     if (rowEntries > _rowCount[row]) return false;
//     if (exact && rowEntries != _rowCount[row]) return false;

//     var colCells = solution.expand((row) => [row[col]]);
//     var colSetCells = colCells.where((cell) => cell.isSet || cell.isRequired);
//     var colEntries = colSetCells.length;
//     if (colEntries > _colCount[col]) return false;
//     if (exact && colEntries != _colCount[col]) return false;

//     // Optimisation to disallow cells that are known not to be posible
//     // and then preset cells that must then be set
//     // Can reduce number of iterations by half but runs slower

//     var rowUpdate = updateRow(solution, row);
//     var colUpdate = updateCol(solution, col);
//     while (rowUpdate || colUpdate) {
//       var rowUpdateOld = rowUpdate;
//       var colUpdateOld = colUpdate;
//       rowUpdate = false;
//       colUpdate = false;

//       if (colUpdateOld) {
//         for (var row = 0; row < dimension; row++) {
//           rowUpdate = updateRow(solution, row);
//         }
//       }
//       if (rowUpdateOld) {
//         for (var col = 0; col < dimension; col++) {
//           colUpdate = updateCol(solution, col);
//         }
//       }
//     }

//     return true;
//   }

//   bool updateCol(List<List<Cell>> solution, int col) {
//     var colUpdate = false;
//     var colCells = solution.expand((row) => [row[col]]);
//     var colSetCells = colCells.where((cell) => cell.isSet || cell.isRequired);
//     var colEntries = colSetCells.length;
//     var colUnsetCells = colCells
//         .where((cell) => !(cell.isSet || cell.isRequired || cell.isDisallowed));
//     if (colEntries == _colCount[col]) {
//       for (var cell in colUnsetCells) {
//         disallowCell(cell, true);
//         colUpdate = true;
//       }
//     }
//     var colDisallowed = colCells.where((cell) => cell.isDisallowed).length;
//     if (_colCount[col] + colDisallowed == dimension) {
//       for (var cell in colUnsetCells.where((cell) => !cell.isDisallowed)) {
//         setCell(cell, true, 'x');
//         colUpdate = true;
//       }
//     }
//     return colUpdate;
//   }

//   bool updateRow(List<List<Cell>> solution, int row) {
//     var rowUpdate = false;
//     var rowCells = solution[row];
//     var rowSetCells = rowCells.where((cell) => cell.isSet || cell.isRequired);
//     var rowEntries = rowSetCells.length;
//     var rowUnsetCells = rowCells
//         .where((cell) => !(cell.isSet || cell.isRequired || cell.isDisallowed));
//     if (rowEntries == _rowCount[row]) {
//       for (var cell in rowUnsetCells) {
//         disallowCell(cell, true);
//         rowUpdate = true;
//       }
//     }
//     var rowDisallowed = rowCells.where((cell) => cell.isDisallowed).length;
//     if (_rowCount[row] + rowDisallowed == dimension) {
//       for (var cell in rowUnsetCells.where((cell) => !cell.isDisallowed)) {
//         setCell(cell, true, 'x');
//         rowUpdate = true;
//       }
//     }
//     return rowUpdate;
//   }

//   bool gridOK(List<List<Cell>> solution) {
//     for (var i = 0; i < dimension; i++) {
//       if (!cellOK(solution, i, i, true)) return false;
//     }
//     return true;
//   }

//   String getEntry(int r1, int c1, int r2, int c2, int r3, int c3) {
//     if (r1 < r2) {
//       if (c2 == c3) return '║';
//       if (c2 < c3) return '╚';
//       if (c2 > c3) return '╝';
//       assert(false, 'Should not happen!');
//     } else if (r1 > r2) {
//       if (c2 == c3) return '║';
//       if (c2 < c3) return '╔';
//       if (c2 > c3) return '╗';
//       assert(false, 'Should not happen!');
//     } else if (c1 < c2) {
//       if (r2 == r3) return '═';
//       if (r2 < r3) return '╗';
//       if (r2 > r3) return '╝';
//       assert(false, 'Should not happen!');
//     } else if (c1 > c2) {
//       if (r2 == r3) return '═';
//       if (r2 < r3) return '╔';
//       if (r2 > r3) return '╚';
//       assert(false, 'Should not happen!');
//     } else {
//       if (c2 == c3) return '║';
//       if (r2 == r3) return '═';
//       assert(false, 'Should not happen!');
//     }
//     return 'X';
//   }
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
    // for (var solution in _grid.solutions()) {
    //   print(solution);
    //   _solutionCount++;
    // }
    // print('Solutions: $_solutionCount, ${_grid.iterations} iterations\n');
  }
}

void printDebug(String msg) {
  if (debug_print) print(msg);
}
