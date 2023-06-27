import 'dart:convert';

bool debug_print = !true;

class Cell {
  final int _row;
  final int _col;
  int get row => _row;
  int get col => _col;

  String _entry;
  bool _set = false;

  static const ENTRIES = '║═╚╔╗╝';

  bool get upperPossible => 'xX║╚╝'.contains(_entry);
  bool get lowerPossible => 'xX║╔╗'.contains(_entry);
  bool get leftPossible => 'xX═╗╝'.contains(_entry);
  bool get rightPossible => 'xX═╚╔'.contains(_entry);

  set entry(entry) {
    _entry = entry;
  }

  String get entry => _entry;
  void set([String entry = 'X']) {
    if (entry != 'X' || !ENTRIES.contains(_entry)) {
      _entry = entry;
    }
    if (entry != 'x') {
      _set = true;
    }
  }

  void unset() {
    _set = false;
  }

  void disallow() {
    _entry = 'O';
  }

  bool get isNotSet => !isSet;
  bool get isSet => _set;
  bool get isRequired => entry != '.' && !isSet && !isDisallowed;
  bool get isDisallowed => entry == 'O';

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
}

class Grid {
  late List<List<Cell>> _grid = [];
  late int dimension;
  Cell? start;
  Cell? end;

  late List<List<Cell>> _solution = [];
  late List<int> _rowCount;
  late List<int> _colCount;

  String? _error;
  String? get error => _error;

  Grid(List<String> puzzle, List<int> rowCount, List<int> colCount) {
    dimension = puzzle.length;
    _grid = getSolution(puzzle);
    getStartEnd();
    if (_error != null) return;
    _rowCount = rowCount;
    _colCount = colCount;
  }

  Grid.solution(List<String> solution, List<String> puzzle) {
    dimension = puzzle.length;
    if (solution.length != dimension) {
      _error = 'Puzzle and Solution have different dimensions';
      return;
    }

    _grid = getSolution(puzzle);
    getStartEnd();
    if (_error != null) return;

    _solution = getSolution(solution);
    _rowCount = List.filled(dimension, 0);
    _colCount = List.filled(dimension, 0);
    for (var r = 0; r < dimension; r++) {
      var row = _solution[r];
      for (var c = 0; c < dimension; c++) {
        var cell = row[c];
        if (cell.isRequired) {
          _rowCount[r]++;
          _colCount[c]++;
        }
      }
    }
  }

  void getStartEnd() {
    for (var r = 0; r < dimension; r++) {
      var row = _grid[r];
      for (var c = 0; c < dimension; c++) {
        var cell = row[c];
        if ((cell.isRequired || cell.isSet) &&
            (r == 0 && cell.upperPossible ||
                r == dimension - 1 && cell.lowerPossible ||
                c == 0 && cell.leftPossible ||
                c == dimension - 1 && cell.rightPossible)) {
          if (start == null) {
            start = cell;
          } else if (end == null) {
            end = cell;
          } else {
            _error = 'More than two potential start/end cells';
            return;
          }
        }
      }
    }
    if (start == null || end == null) {
      _error = 'No start/end cell';
      return;
    }
  }

  List<List<Cell>> getSolution(List<String> rows) {
    if (rows.length != dimension ||
        rows.any((element) => element.length != dimension)) {
      _error = 'Require $dimension rows of $dimension cells';
      return [];
    }
    var grid = <List<Cell>>[];
    for (var r = 0; r < dimension; r++) {
      var row = rows[r];
      var cells = <Cell>[];
      grid.add(cells);
      for (var c = 0; c < dimension; c++) {
        var entry = row[c];
        cells.add(Cell(r, c, entry));
      }
    }
    return grid;
  }

  @override
  String toString() {
    var text = ' ' + _colCount.join('') + '\n';
    for (var r = 0; r < dimension; r++) {
      text += _rowCount[r].toString() +
          _grid[r].fold('', (p, c) => p + c.entry) +
          // (c == start
          //     ? 'S'
          //     : c == end
          //         ? 'E'
          //         : c.entry)) +
          '\n';
    }
    return text;
  }

  String solutionString(List<List<Cell>> solution) {
    var text = '';
    for (var r = 0; r < dimension; r++) {
      text += ' ' + solution[r].fold('', (p, c) => p + (c.entry)) + '\n';
      ;
    }
    return text;
  }

  List<List<Cell>> copyGrid() {
    var l = json.decode(json.encode(_grid));
    var grid = List<List<Cell>>.from(
        l.map((r) => List<Cell>.from(r.map((e) => Cell.fromJson(e)))));
    return grid;
  }

  Iterable<String> solutions() sync* {
    var solution = copyGrid();
    // Set start cell
    var cell = solution[start!.row][start!.col];
    cell.set(cell.entry != 'x' ? cell.entry : 'X');
    yield* backtrack(solution, cell, cell);
    return;
  }

  Iterable<Cell> neighbours(List<List<Cell>> solution, Cell cell) sync* {
    if (cell.row > 0 && cell.upperPossible) {
      yield solution[cell.row - 1][cell.col];
    }
    if (cell.row < dimension - 1 && cell.lowerPossible) {
      yield solution[cell.row + 1][cell.col];
    }
    if (cell.col > 0 && cell.leftPossible) {
      yield solution[cell.row][cell.col - 1];
    }
    if (cell.col < dimension - 1 && cell.rightPossible) {
      yield solution[cell.row][cell.col + 1];
    }
    return;
  }

  Iterable<Cell> possibleNeighbours(
      List<List<Cell>> solution, Cell cell) sync* {
    for (var nextCell in neighbours(solution, cell)) {
      if (!nextCell.isDisallowed) {
        yield nextCell;
      }
    }
    return;
  }

  Iterable<Cell> possibleNextCells(List<List<Cell>> solution, Cell cell) sync* {
    for (var nextCell in neighbours(solution, cell)) {
      if (nextCell.isNotSet && !nextCell.isDisallowed) {
        yield nextCell;
      }
    }
    return;
  }

  var iterations = 0;
  Iterable<String> backtrack(
      List<List<Cell>> solution, Cell currentCell, Cell priorCell) sync* {
    var nextCells = possibleNextCells(solution, currentCell).toList();
    for (var nextCell in nextCells) {
      setCell(nextCell); // Placeholder until next cell processed
      if (!isStart(currentCell)) {
        currentCell.entry = getEntry(priorCell.row, priorCell.col,
            currentCell.row, currentCell.col, nextCell.row, nextCell.col);
      }
      if (cellOK(solution, nextCell.row, nextCell.col)) {
        iterations++;
        if (nextCell.row != end!.row || nextCell.col != end!.col) {
          yield* backtrack(solution, nextCell, currentCell);
        } else {
          // Complete if no unset grid cells
          if (gridOK(solution) &&
              !solution.any((row) => row.any((cell) => cell.isRequired))) {
            if (nextCell.entry == 'X') {
              nextCell.entry = getEntry(currentCell.row, currentCell.col,
                  nextCell.row, nextCell.col, nextCell.row, nextCell.col);
            }
            yield solutionString(solution);
          }
        }
      }

      undoSetCell();
    }
    return;
  }

  List<Cell> undoCells = [];
  List<String> undoEntries = [];
  List<int> undoIndexes = [];
  List<bool> undoSet = [];
  void rememberCell(Cell cell, [bool combine = false]) {
    if (!combine) {
      // New undo stack item
      undoIndexes.add(undoCells.length);
    }
    undoCells.add(cell);
    undoEntries.add(cell.entry);
    undoSet.add(cell._set);
  }

  void setCell(Cell cell, [bool combine = false, String entry = 'X']) {
    rememberCell(cell, combine);
    cell.set(entry);
  }

  void disallowCell(Cell cell, [bool combine = false]) {
    rememberCell(cell, combine);
    cell.disallow();
  }

  void undoSetCell() {
    assert(undoIndexes.isNotEmpty);
    while (undoCells.length > undoIndexes.last) {
      var cell = undoCells.removeLast();
      cell.entry = undoEntries.removeLast();
      cell._set = undoSet.removeLast();
    }
    undoIndexes.removeLast();
  }

  bool cellOK(List<List<Cell>> solution, int row, int col,
      [bool exact = false]) {
    var rowCells = solution[row];
    var rowSetCells = rowCells.where((cell) => cell.isSet || cell.isRequired);
    var rowEntries = rowSetCells.length;
    if (rowEntries > _rowCount[row]) return false;
    if (exact && rowEntries != _rowCount[row]) return false;

    var colCells = solution.expand((row) => [row[col]]);
    var colSetCells = colCells.where((cell) => cell.isSet || cell.isRequired);
    var colEntries = colSetCells.length;
    if (colEntries > _colCount[col]) return false;
    if (exact && colEntries != _colCount[col]) return false;

    // Optimisation to disallow cells that are known not to be posible
    // and then preset cells that must then be set
    // Can reduce number of iterations by half but runs slower
    updateGrid(solution, row: row, col: col);

    return true;
  }

  bool updateGrid(List<List<Cell>> solution,
      {int row = -1, int col = -1, bool all = false, String entry = 'x'}) {
    var update = false;
    var rowUpdate = false;
    var colUpdate = false;
    if (!all) {
      rowUpdate = updateRow(solution, row, entry);
      colUpdate = updateCol(solution, col, entry);
    }
    var first = all;
    while (first || rowUpdate || colUpdate) {
      update = rowUpdate || colUpdate;
      var rowUpdateOld = rowUpdate;
      var colUpdateOld = colUpdate;
      rowUpdate = false;
      colUpdate = false;

      if (first || colUpdateOld) {
        for (var row = 0; row < dimension; row++) {
          rowUpdate = rowUpdate || updateRow(solution, row, entry);
        }
      }
      if (first || rowUpdateOld) {
        for (var col = 0; col < dimension; col++) {
          colUpdate = colUpdate || updateCol(solution, col, entry);
        }
      }
      first = false;
    }
    return update;
  }

  bool updateCol(List<List<Cell>> solution, int col, [String entry = 'x']) {
    var colUpdate = false;
    var colCells = solution.expand((row) => [row[col]]);
    var colSetCells = colCells.where((cell) => cell.isSet || cell.isRequired);
    var colEntries = colSetCells.length;
    var colUnsetCells = colCells
        .where((cell) => !(cell.isSet || cell.isRequired || cell.isDisallowed));
    if (colEntries == _colCount[col]) {
      for (var cell in colUnsetCells) {
        disallowCell(cell, true);
        colUpdate = true;
      }
    }
    var colDisallowed = colCells.where((cell) => cell.isDisallowed).length;
    if (_colCount[col] + colDisallowed == dimension) {
      for (var cell in colUnsetCells.where((cell) => !cell.isDisallowed)) {
        setCell(cell, true, entry);
        colUpdate = true;
      }
    }
    return colUpdate;
  }

  bool updateRow(List<List<Cell>> solution, int row, [String entry = 'x']) {
    var rowUpdate = false;
    var rowCells = solution[row];
    var rowSetCells = rowCells.where((cell) => cell.isSet || cell.isRequired);
    var rowEntries = rowSetCells.length;
    var rowUnsetCells = rowCells
        .where((cell) => !(cell.isSet || cell.isRequired || cell.isDisallowed));
    if (rowEntries == _rowCount[row]) {
      for (var cell in rowUnsetCells) {
        disallowCell(cell, true);
        rowUpdate = true;
      }
    }
    var rowDisallowed = rowCells.where((cell) => cell.isDisallowed).length;
    if (_rowCount[row] + rowDisallowed == dimension) {
      for (var cell in rowUnsetCells.where((cell) => !cell.isDisallowed)) {
        setCell(cell, true, entry);
        rowUpdate = true;
      }
    }
    return rowUpdate;
  }

  bool gridOK(List<List<Cell>> solution) {
    for (var i = 0; i < dimension; i++) {
      if (!cellOK(solution, i, i, true)) return false;
    }
    return true;
  }

  String getEntry(int r1, int c1, int r2, int c2, int r3, int c3) {
    if (r1 < r2) {
      if (c2 == c3) return '║';
      if (c2 < c3) return '╚';
      if (c2 > c3) return '╝';
      assert(false, 'Should not happen!');
    } else if (r1 > r2) {
      if (c2 == c3) return '║';
      if (c2 < c3) return '╔';
      if (c2 > c3) return '╗';
      assert(false, 'Should not happen!');
    } else if (c1 < c2) {
      if (r2 == r3) return '═';
      if (r2 < r3) return '╗';
      if (r2 > r3) return '╝';
      assert(false, 'Should not happen!');
    } else if (c1 > c2) {
      if (r2 == r3) return '═';
      if (r2 < r3) return '╔';
      if (r2 > r3) return '╚';
      assert(false, 'Should not happen!');
    } else {
      if (c2 == c3) return '║';
      if (r2 == r3) return '═';
      assert(false, 'Should not happen!');
    }
    return 'X';
  }

  String? logicSolve() {
    var solution = copyGrid();
    var update = true;
    // Set start cell
    var cell = solution[start!.row][start!.col];
    cell.set(cell.entry != 'x' ? cell.entry : 'X');
    while (update) {
      // Try different logic steps to set required cells
      update = false;
      if (!update) update = updateGrid(solution, all: true, entry: 'X');
      if (!update) update = cellsNeigbours(solution);
      if (!update) update = lastCells(solution);
      if (update) printDebug(solutionString(solution) + '\n');
    }
    if (gridOK(solution)) {
      // Convert X to tracks
      updateTracks(solution);
      return solutionString(solution);
    }
    return null;
  }

  bool cellsNeigbours(solution) {
    var update = false;
    for (var row = 0; row < dimension; row++) {
      for (var col = 0; col < dimension; col++) {
        var cell = solution[row][col];
        var nextCells = possibleNeighbours(solution, cell);
        var numNeighbours = isStart(cell) || isEnd(cell) ? 1 : 2;
        if (nextCells.length == numNeighbours) {
          for (var nextCell in nextCells) {
            if (nextCell.isNotSet) {
              nextCell.set();
              update = true;
              printDebug('cellsNeigbours: $nextCell');
            }
          }
        }
      }
    }
    return update;
  }

  bool lastCells(List<List<Cell>> solution) {
    var update = false;

    bool lastCellInCells(List<Cell> cells, int count) {
      var setCells = cells.where((cell) => cell.isSet || cell.isRequired);
      if (setCells.length == count) {
        // Row is full, continue processing next row
        return true;
      }
      if (setCells.length < count - 1 || setCells.isEmpty) {
        // More than one cell remaining, cannot continue
        return false;
      }
      // One cell remaining, previous rows are full
      // Last cell is adjacent to one of the other set cells
      var unsetCells = cells
          .where(
              (cell) => !(cell.isSet || cell.isRequired || cell.isDisallowed))
          .toList();
      var possibleCells = <Cell>{};
      for (var cell in setCells) {
        var nextCells = possibleNextCells(solution, cell);
        for (var nextCell in nextCells) {
          if (unsetCells.remove(nextCell)) {
            possibleCells.add(nextCell);
          }
        }
      }
      if (unsetCells.isNotEmpty) {
        for (var cell in unsetCells) {
          cell.disallow();
          printDebug('lastCells: $cell');
        }
        update = true;
      }
      if (possibleCells.length == 1) {
        var cell = possibleCells.first..set();
        printDebug('lastCells: $cell');
        update = true;
      }
      return true;
    }

    // Check rows from beginning
    for (var row = 0; row < dimension; row++) {
      var rowCells = solution[row];
      if (!lastCellInCells(rowCells, _rowCount[row])) break;
    }
    // Check rows from end
    for (var row = dimension - 1; row >= 0; row--) {
      var rowCells = solution[row];
      if (!lastCellInCells(rowCells, _rowCount[row])) break;
    }
    // Check cols from beginning
    for (var col = 0; col < dimension; col++) {
      var colCells = solution.expand((row) => [row[col]]).toList();
      if (!lastCellInCells(colCells, _colCount[col])) break;
    }
    // Check cols from end
    for (var col = dimension - 1; col >= 0; col--) {
      var colCells = solution.expand((row) => [row[col]]).toList();
      if (!lastCellInCells(colCells, _colCount[col])) break;
    }
    return update;
  }

  bool isStart(cell) {
    return cell.row == start!.row && cell.col == start!.col;
  }

  bool isEnd(cell) {
    return cell.row == end!.row && cell.col == end!.col;
  }

  void updateTracks(List<List<Cell>> solution) {
    var update = true;
    while (update) {
      update = false;
      for (var row = 0; row < dimension; row++) {
        for (var col = 0; col < dimension; col++) {
          var cell = solution[row][col];
          if (cell.entry == 'X') {
            var nextCells = possibleNeighbours(solution, cell).toList();
            var numNeighbours = isStart(cell) || isEnd(cell) ? 1 : 2;
            var neighbourCells = <Cell>[];
            if (nextCells.length == numNeighbours) {
              // Cell only has one or two neighbours
              neighbourCells = nextCells;
            } else {
              // Do neighbour cells point at this cell?
              var mayCells = <Cell>[];
              for (var nextCell in nextCells) {
                if (nextCell.entry != 'X') {
                  if (nextCell.row < cell.row && nextCell.lowerPossible ||
                      nextCell.row > cell.row && nextCell.upperPossible ||
                      nextCell.col < cell.col && nextCell.rightPossible ||
                      nextCell.col > cell.col && nextCell.leftPossible) {
                    neighbourCells.add(nextCell);
                  }
                } else {
                  mayCells.add(nextCell);
                }
              }
              if (neighbourCells.length == numNeighbours - 1) {
                if (mayCells.length == 1) {
                  neighbourCells.addAll(mayCells);
                }
              }
            }
            if (neighbourCells.length == numNeighbours) {
              var priorCell = neighbourCells[0];
              var nextCell =
                  neighbourCells.length == 2 ? neighbourCells[1] : cell;
              cell.entry = getEntry(priorCell.row, priorCell.col, cell.row,
                  cell.col, nextCell.row, nextCell.col);
              update = true;
            }
          }
        }
      }
    }
  }
}

class TrainTracks {
  late final Grid _grid;
  String? _error;
  String? get error => _error;

  TrainTracks(List<String> puzzle, List<int> rowCount, List<int> colCount) {
    _grid = Grid(puzzle, rowCount, colCount);
    _error = _grid.error;
  }

  TrainTracks.solution(List<String> solution, List<String> puzzle) {
    _grid = Grid.solution(solution, puzzle);
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

    // Logic solve
    var logicSolution = _grid.logicSolve();
    if (logicSolution != null) {
      print('Logic Solution\n$logicSolution');
    } else {
      print('No Logic Solution!');
    }

    // Backtrack solve
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
