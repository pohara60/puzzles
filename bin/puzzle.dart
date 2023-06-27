// ignore_for_file: prefer_single_quotes

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:puzzle/futoshiki.dart';
import 'package:puzzle/train_tracks.dart';

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
var solutionGrid3 = [
  '....╔╗..',
  '....║║..',
  '╗..╔╝║..',
  '║.╔╝.╚═╗',
  '╚═╝....║',
  '.....╔╗║',
  '....╔╝╚╝',
  '....║...',
];
var puzzleGrid3 = [
  '........',
  '........',
  '╗..╔╝║..',
  '...╝....',
  '........',
  '........',
  '........',
  '....║...',
];
var puzzleGrid4 = [
  '....╔...',
  '........',
  '........',
  '....╝...',
  '........',
  '........',
  '═.......',
  '.....║..',
];
var rowCount4 = [3, 4, 5, 4, 4, 3, 3, 1];
var colCount4 = [1, 3, 3, 2, 4, 6, 4, 4];

var futoshiki1 = [
  ". . . . 2",
  "    >   ^",
  ". .<. . .",
  "      <  ",
  ". . . .<.",
  "        <",
  "3 . . . .",
  "  >      ",
  ". . . . ."
];

var futoshikiEmpty = [
  ". . . . .",
  "         ",
  ". . . . .",
  "         ",
  ". . . . .",
  "         ",
  ". . . . .",
  "         ",
  ". . . . ."
];

const help = 'help';
const program = 'puzzle';

void main(List<String> arguments) {
  exitCode = 0; // presume success

  var runner = CommandRunner('puzzle', 'Puzzle solver.')
    ..addCommand(TrainTracksCommand())
    ..addCommand(FutoshikiCommand());
  try {
    runner.run(arguments);
  } on UsageException catch (e) {
    // Arguments exception
    print('$program: ${e.message}');
    print('');
    print('${runner.usage}');
  }
}

class TrainTracksCommand extends Command {
  @override
  final name = 'train_tracks';
  @override
  final description =
      'Solve Train Tracks puzzle specified by <grid>, with <solution>.\n\nThe 1st argument <grid> is a list of N strings (rows) of length N (cells).\nThe 2nd argument specifies the <solution>, either as another full grid, or a list with rowCounts and colCounts.\n\nThe cells may be specified using the track characters "║═╚╔╗╝" or simply "x", with "." for unspecified, e.g.\n\ntrain_tracks "........,........,╗..╔╝║..,...╝....,........,........,........,....║..." "34544331,13324644"\nor\ntrain_tracks "........,........,x..xxx..,...x....,........,........,........,....x..." "34544331,13324644"';

  @override
  void run() {
    // Arguments specify grid
    TrainTracks? trainTracks;
    String? error;
    var numArgs = argResults!.rest.length;
    if (numArgs == 0) {
      trainTracks = TrainTracks.solution(solutionGrid3, puzzleGrid3);
      // trainTracks = TrainTracks(puzzleGrid4, rowCount4, colCount4);
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
            trainTracks = TrainTracks.solution(solutionList, rowList);
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
              trainTracks = TrainTracks(
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
    trainTracks!.solve();
  }
}

class FutoshikiCommand extends Command {
  @override
  final name = 'futoshiki';
  @override
  final description =
      'Solve Futoshiki puzzle specified by <grid>.\n\nThe argument <grid> is a list of 2N-1 strings (rows) of length 2N-1 (cells).\nThe odd rows have N optional grid entries in range 1 to N, separated by optional < or > signs to specify horizontal comparisons.\nThe even rows have optional < or > signs to specify column comparisons.\n\ne.g. futoshiki ". . . . 2,    >   ^,. .<. . .,      <  ,. . . .<.,        <,3 . . . .,  >      ,. . . . ."';

  @override
  void run() {
    // Arguments specify grid
    Futoshiki? futoshiki;
    String? error;
    var numArgs = argResults!.rest.length;
    if (numArgs == 0) {
      futoshiki = Futoshiki(futoshiki1);
      error = futoshiki.error;
    } else if (numArgs == 1) {
      var gridString = argResults!.rest[0];
      var puzzle = gridString.split(',');
      futoshiki = Futoshiki(puzzle);
      error = futoshiki.error;
    } else if (numArgs == 9) {
      var puzzle = argResults!.rest;
      futoshiki = Futoshiki(puzzle);
      error = futoshiki.error;
    } else {
      error = '$program: Wrong number of arguments';
    }

    if (error == null) {
      futoshiki!.solve();
    } else {
      print(error);
      print('${runner!.usage}');
      exitCode = 1;
      return;
    }
  }
}
