import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:train_tracks/train_tracks.dart';

var grid1 = [
  '........',
  '........',
  '........',
  '........',
  '........',
  '........',
  '........',
  '........',
];
var solutionGrid2 = [
  '....xx..',
  '....xx..',
  'x..xxx..',
  'x.xx.xxx',
  'xxx....x',
  '.....xxx',
  '....xxxx',
  '....x...',
];
var puzzleGrid2 = [
  '........',
  '........',
  'x..xxx..',
  '...x....',
  '........',
  '........',
  '........',
  '....x...',
];
var operands2 = [0, 5, 0, 7, 0, 0, 16, 0, 0, 20, 20, 0, 0, 0, 0, 0];
// var grid2 = [];
// var operands2 = [];

const help = 'help';
const program = 'train_tracks';

void main(List<String> arguments) {
  exitCode = 0; // presume success

  var runner = CommandRunner('train_tracks', 'train_tracks solver.')
    ..addCommand(SolveCommand());
  try {
    runner.run(arguments);
  } on UsageException catch (e) {
    // Arguments exception
    print('$program: ${e.message}');
    print('');
    print('${runner.usage}');
  }
}

class SolveCommand extends Command {
  @override
  final name = 'solve';
  @override
  final description =
      'Solve puzzle specified by <grid>, with <solution>.\n\nThe 1st argument <grid> is a list of N strings (rows) of length N (cells).\nThe 2nd argument specifies the <solution>, either as another full grid, or a list with rowCounts and colCounts.\n\ne.g. solve "..........,..........,.......x..,x.........,..........,...x......,..........,..........,..........,.......x.." "5647341451,1318438624"';

  @override
  void run() {
    // Arguments specify grid
    TrainTracks? railwayTracks;
    String? error;
    var numArgs = argResults!.rest.length;
    if (numArgs == 0) {
      railwayTracks = TrainTracks.solution(solutionGrid2, puzzleGrid2);
    } else {
      if (numArgs == 2) {
        var gridString = argResults!.rest[0];
        var rowList = gridString.split(',');
        var dimension = rowList.length;
        if (rowList.any((element) => element.length != dimension)) {
          error =
              '$program: Error in <grid>, must have $dimension rows of $dimension cells';
        } else {
          var solutionString = argResults!.rest[1];
          var solutionList = solutionString.split(',');
          if (solutionList.length == dimension) {
            // Solution is a grid
            railwayTracks = TrainTracks.solution(solutionList, rowList);
          } else if (solutionList.length == 2 &&
              solutionList[0].length == dimension &&
              solutionList[1].length == dimension) {
            // Solution is column and row counts
            var rowCount =
                solutionList[0].split('').map((e) => int.tryParse(e)).toList();
            var colCount =
                solutionList[1].split('').map((e) => int.tryParse(e)).toList();
            if (rowCount.every((element) => element != null) &&
                colCount.every((element) => element != null)) {
              railwayTracks = TrainTracks(
                  rowList, rowCount.cast<int>(), colCount.cast<int>());
            } else {
              error =
                  '$program: RowCount and ColCount must be strings of integers';
            }
          } else {
            error = '$program: Solution must be <grid> or <rowCount,colCount>';
          }
        }
      } else {
        error = '$program: Wrong number of arguments';
      }
      if (error != null) {
        print(error);
        print('${runner!.usage}');
        exitCode = 1;
        return;
      }
    }
    railwayTracks!.solve();
  }
}
