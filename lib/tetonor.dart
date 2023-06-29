import 'dart:math';

bool debug_print = !true;

// Pair of numbers
class Pair {
  final int _lo, _hi;
  int get lo => _lo;
  int get hi => _hi;
  Pair(this._lo, this._hi);
  @override
  String toString() {
    return '($_lo,$_hi)';
  }
}

// Cell in grid with value
class Cell {
  final int _value;
  int get value => _value;
  final List<Pair> _factors = [];
  Cell(this._value);
  @override
  String toString() {
    return '$_value $_factors\n';
  }

  void getFactors(List<Cell> cells) {
    if (_value == 0) return;
    for (var i = 1; i <= sqrt(_value); i++) {
      if (_value % i == 0) {
        var pair = Pair(i, _value ~/ i);
        // Check there is a cell that adds to the sum of the pair
        var sum = pair.lo + pair.hi;
        var match = cells
            .where((cell) => cell != this && cell._value == sum)
            .isNotEmpty;
        if (match) {
          _factors.add(pair);
        }
      }
    }
  }
}

// Operands for the Cell computations, with value, zero is unknown
class Operand {
  final int _value;
  int get value => _value;
  late int _min, _max;
  int get min => _min;
  set min(min) {
    _min = min;
  }

  int get max => _max;
  set max(max) {
    _max = max;
  }

  bool matches(match) {
    if (_value != 0) return match == _value;
    return match >= _min && match <= _max;
  }

  Operand(this._value);
  @override
  String toString() {
    return _value != 0 ? _value.toString() : '($_min,$max)';
  }
}

// Cell in Solution, with product or sum of two operands
class SolvedCell {
  final int _cellIndex;
  int get cellIndex => _cellIndex;
  final int _value;
  int get value => _value;
  final bool _isProduct;
  bool get isProduct => _isProduct;
  final SolvedOperand _operand1;
  SolvedOperand get operand1 => _operand1;
  final SolvedOperand _operand2;
  SolvedOperand get operand2 => _operand2;

  SolvedCell(this._cellIndex, this._value, this._isProduct, this._operand1,
      this._operand2);

  @override
  String toString() {
    return '$_value = ${_operand1.value} ${_isProduct ? '*' : '+'} ${_operand2.value}';
  }
}

// Operand in Solution, with value
class SolvedOperand {
  final int _operandIndex;
  int get operandIndex => _operandIndex;
  final int _value;
  int get value => _value;

  SolvedOperand(this._operandIndex, this._value);

  @override
  String toString() {
    return _value.toString();
  }
}

// Solution for puzzle, with Cell and Operand solutions
class Solution {
  final List<SolvedCell> _cells = [];
  List<SolvedCell> get cells => _cells;
  final List<SolvedOperand> _operands = [];
  List<SolvedOperand> get operands => _operands;
  Solution();

  @override
  String toString() {
    var copiedCells = List.from(_cells);
    copiedCells.sort((a, b) => a._cellIndex.compareTo(b._cellIndex));
    var cells = copiedCells.join(', ');
    var copiedOperands = List.from(_operands);
    // The operand index order may not correspond to value order because of wildcards
    // so we ignore the index order
    copiedOperands.sort((a, b) => a._value.compareTo(b._value));
    var operands = copiedOperands.join(', ');
    return 'Cells:\n$cells\nOperands: $operands';
  }

  String toPrettyString() {
    var copiedCells = List<SolvedCell>.from(_cells);
    copiedCells.sort((a, b) => a._cellIndex.compareTo(b._cellIndex));
    var copiedOperands = List<SolvedOperand>.from(_operands);
    // The operand index order may not correspond to value order because of wildcards
    // so we ignore the index order
    copiedOperands.sort((a, b) => a._value.compareTo(b._value));

    // Each cell can be:
    // +-----+
    // | 999 |
    // +-----+
    // |99*99|
    // +-----+
    // The puzzle has 12 cells in 4 rows of 3
    const ROWS = 3;
    const COLS = 4;
    const OPS = 12;
    const rowBoxTopStart = '╔═════';
    const rowBoxTopMiddle = '╤═════';
    const rowBoxTopEnd = '╗\n';
    const rowSeparatorStart = '╟─────';
    const rowSeparatorMiddle = '┼─────';
    const rowSeparatorEnd = '╢\n';
    const rowBoxBottomStart = '╚═════';
    const rowBoxBottomMiddle = '╧═════';
    const rowBoxBottomEnd = '╝';
    const colBoxSeparator = '║';
    const colSeparator = '│';
    var rowBoxTop =
        rowBoxTopStart + rowBoxTopMiddle * (COLS - 1) + rowBoxTopEnd;
    var rowBoxBottom =
        rowBoxBottomStart + rowBoxBottomMiddle * (COLS - 1) + rowBoxBottomEnd;
    var operandTop = rowBoxTopStart.substring(0, 3) +
        rowBoxTopMiddle.substring(0, 3) * (OPS - 1) +
        rowBoxTopEnd;
    var operandBottom = rowBoxBottomStart.substring(0, 3) +
        rowBoxBottomMiddle.substring(0, 3) * (OPS - 1) +
        rowBoxBottomEnd;
    var result = StringBuffer();
    var index = 0;
    for (var r = 0; r < ROWS; r++) {
      var rowSeparator = rowSeparatorStart;
      if (r == 0) result.write(rowBoxTop);
      for (var c = 0; c < COLS; c++) {
        var cell = copiedCells[index++];
        // Value
        if (c == 0) result.write(colBoxSeparator);
        result.write((cell.value.toString().padLeft(4)));
        result.write(' ');
        if (c == COLS - 1) {
          result.write(colBoxSeparator);
          result.write('\n');
          rowSeparator += rowSeparatorEnd;
        } else {
          result.write(colSeparator);
          rowSeparator += rowSeparatorMiddle;
        }
      }
      // result.write(rowSeparator);
      rowSeparator = rowSeparatorStart;
      index -= COLS;
      for (var c = 0; c < COLS; c++) {
        var cell = copiedCells[index++];
        // Operands
        if (c == 0) result.write(colBoxSeparator);
        result.write((cell.operand1.value.toString().padLeft(2)));
        result.write(cell.isProduct ? '*' : '+');
        result.write((cell.operand2.value.toString().padRight(2)));
        if (c == COLS - 1) {
          result.write(colBoxSeparator);
          result.write('\n');
          rowSeparator += rowSeparatorEnd;
        } else {
          result.write(colSeparator);
          rowSeparator += rowSeparatorMiddle;
        }
      }
      if (r == ROWS - 1) {
        result.write(rowBoxBottom);
      } else {
        result.write(rowSeparator);
      }
    }
    result.write('\n');
    result.write(operandTop);
    result.write(rowSeparatorStart[0]);
    for (var c = 0; c < OPS; c++) {
      var operand = copiedOperands[c];
      result.write(operand.value.toString().padLeft(2));
      if (c == OPS - 1) {
        result.write(colBoxSeparator);
        result.write('\n');
      } else {
        result.write(colSeparator);
      }
    }
    result.write(operandBottom);
    result.write('\n');
    return result.toString();
  }

  void removeLastCells() {
    _cells.removeRange(_cells.length - 2, _cells.length);
    _operands.removeRange(_operands.length - 2, _operands.length);
  }
}

// Puzzle
class Tetonor {
  final int _maxOperand = 99;
  final List<Cell> _cells = [];
  final List<Operand> _operands = [];
  String? error;
  Tetonor(List<int> cells, List<int> operands) {
    if (cells.length != 16 || operands.length != 16) {
      error = 'Require 16 cells and 16 operands';
      return;
    }
    for (var cell in cells) {
      _cells.add(Cell(cell));
    }
    for (var operand in operands) {
      _operands.add(Operand(operand));
    }
    // Determine possible factors for cells
    for (var cell in _cells) {
      cell.getFactors(_cells);
    }
    // Update unknown operands to set bounds
    updateOperandBounds();
  }

  void updateOperandBounds() {
    // Set bounds for unknown operands
    var min = 1;
    for (var operand in _operands) {
      if (operand.value == 0) {
        operand.min = min;
      } else {
        min = operand.value;
      }
    }
    var max = _maxOperand;
    for (var operand in _operands.reversed) {
      if (operand.value == 0) {
        operand.max = max;
      } else {
        max = operand.value;
      }
    }
  }

  @override
  String toString() {
    var cells = _cells.join('');
    var operands = _operands.join(', ');
    return 'Cells:\n${cells}Operands: $operands';
  }

  var _solutionCount = 0;
  var _productCount = 0;
  void solve() {
    // find cells that have factors, in descending order of value
    var cellIndexes = <int>[];
    for (var i = 0; i < 16; i++) {
      if (_cells[i]._factors.isNotEmpty) {
        cellIndexes.add(i);
      }
    }
    cellIndexes
        .sort((ci1, ci2) => _cells[ci2].value.compareTo(_cells[ci1].value));
    // Choose 8 cells at a time as products (others cells will be sums)
    for (var productCellIndexes in chooseIndexes(cellIndexes, [])) {
      if (productCellIndexes == null) continue;
      // Get other cells
      var sumCellIndexes = List<int>.generate(16, (i) => i)
          .where((i) => !productCellIndexes.contains(i))
          .toList();
      printDebug('Products: $productCellIndexes, Sums: $sumCellIndexes');
      // All operands still available
      var operandIndexes = List<int>.generate(16, (i) => i).toList();
      // Get solutions for these indexes
      var productSolved = false;
      for (var solution in solveIndexes(
          productCellIndexes, sumCellIndexes, operandIndexes, Solution())) {
        // print('$solution\n');
        print('${solution.toPrettyString()}\n');
        _solutionCount++;
        if (!productSolved) {
          productSolved = true;
          _productCount++;
        }
      }
    }
    print('Solution Products: $_productCount, Solutions: $_solutionCount\n');
  }

  Iterable<List<int>?> chooseIndexes(List<int> indexes, List<int> chosen,
      [int need = 8, int next = 0]) sync* {
    if (indexes.length - next < need) {
      yield null;
      return;
    }
    if (need == 0) {
      yield chosen;
      return;
    }
    if (indexes.length - next == need) {
      // Need rest of indexes
      chosen += indexes.sublist(next);
      yield chosen;
      return;
    }
    // Either choose first index or not
    // Choose it
    var oldLength = chosen.length;
    chosen.add(indexes[next]);
    yield* chooseIndexes(indexes, chosen, need - 1, next + 1);
    // Do not choose it
    chosen.removeRange(oldLength, chosen.length);
    yield* chooseIndexes(indexes, chosen, need, next + 1);
    return;
  }

  List<int> matchOperands(List<int> operandIndexes, int match) {
    var exactMatch = operandIndexes
        .firstWhere((i) => _operands[i].value == match, orElse: () => -1);
    var wildcardMatch = operandIndexes.firstWhere(
        (i) => _operands[i].value == 0 && _operands[i].matches(match),
        orElse: () => -1);
    var matches = <int>[];
    if (exactMatch != -1) {
      matches.add(exactMatch);
    }
    if (wildcardMatch != -1) {
      matches.add(wildcardMatch);
    }
    return matches;
    // return operandIndexes.where((i) => _operands[i].matches(match)).toList();
  }

  Iterable<Solution> solveIndexes(
      List<int> productCellIndexes,
      List<int> sumCellIndexes,
      List<int> operandIndexes,
      Solution partial) sync* {
    var next = partial.cells.length ~/ 2;
    printDebug('Enter, next=$next');
    var index = productCellIndexes[next];
    var cell = _cells[index];
    // For each factor of cell find matching operands
    for (var pair in cell._factors) {
      // Find other cell that sums to this pair (ignore duplicates)
      var sum = pair.lo + pair.hi;
      var sumIndexIndex =
          sumCellIndexes.indexWhere((i) => _cells[i].value == sum);
      if (sumIndexIndex == -1) continue;
      var sumIndex = sumCellIndexes[sumIndexIndex];
      sumCellIndexes.removeAt(sumIndexIndex);

      // Find operands that match the pair (process an exact match and a wildcard match)
      var loOperandIndexList = matchOperands(operandIndexes, pair.lo);
      operandLoop:
      for (var loOperandIndex in loOperandIndexList) {
        var hiOperandIndexList = matchOperands(
            operandIndexes.where((i) => i > loOperandIndex).toList(), pair.hi);
        for (var hiOperandIndex in hiOperandIndexList) {
          // Update solution
          var loOperand = SolvedOperand(loOperandIndex, pair.lo);
          var hiOperand = SolvedOperand(hiOperandIndex, pair.hi);
          var productCell = SolvedCell(
              index, _cells[index].value, true, loOperand, hiOperand);
          var sumCell = SolvedCell(
              sumIndex, _cells[sumIndex].value, false, loOperand, hiOperand);
          partial.cells.add(productCell);
          partial.cells.add(sumCell);
          partial.operands.add(loOperand);
          partial.operands.add(hiOperand);
          printDebug(
              'Add productCell=$productCell, sumCell=$sumCell lo=${pair.lo}, hi=${pair.hi}, loOp=$loOperandIndex, hiOp=$hiOperandIndex');
          // Finished?
          if (partial.cells.length == 16) {
            printDebug(
                'lo=${pair.lo}, hi=${pair.hi}, loOp=$loOperandIndex, hiOp=$hiOperandIndex');
            yield partial;
            // No need to process other operands as all solutions for these cells will be the same
            // Undo soluion update
            partial.removeLastCells();
            printDebug('Remove Cells');
            break operandLoop;
          } else {
            // Recurse with copy of operand indexes (cannot modify it)
            var newOperandIndexes = List<int>.from(operandIndexes
                .where((i) => i != loOperandIndex && i != hiOperandIndex));
            var oldSolutionCount = _solutionCount;
            yield* solveIndexes(
                productCellIndexes, sumCellIndexes, newOperandIndexes, partial);
            if (oldSolutionCount != _solutionCount) {
              // No need to process other operands as all solutions for these cells will be the same
              // Undo soluion update
              partial.removeLastCells();
              printDebug('Remove Cells');
              break operandLoop;
            }
          }
          // Undo soluion update
          partial.removeLastCells();
          printDebug('Remove Cells');
        }
      }
      printDebug('After operandLoop');
      // Restore sum cell
      sumCellIndexes.insert(sumIndexIndex, sumIndex);
    }
    printDebug('Exit');
    return;
  }
}

void printDebug(String msg) {
  if (debug_print) print(msg);
}
