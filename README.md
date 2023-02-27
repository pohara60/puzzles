# Tetonor Puzzle Solver in Dart

Command line application to solve Tetonor puzzles, as printed in The Times.

## Introduction

**Tetonor** provides a command line tool for solving Tetonor puzzles.

## Command Line Example

The command line tool has one option as described in the help text, run:

```bash
$ dart run Tetonor --help
Tetonor solver.

Usage: tetonor <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  solve   Solve puzzle specifieid by <cells> and <operands>, which are strings with a list of 16 numbers. Operands may include 0 for undetermined values.

Run "tetonor help <command>" for more information about a command.
```

Here is an example puzzle.

```bash
$ dart run Tetonor solve "28,92,30,180,126,24,170,29,24,140,25,95,144,27,224,39" "1,2,0,5,7,0,12,12,14,16,0,18,19,0,0,0"
Cells:
28 [(1,28)]
92 [(4,23)]
30 []
180 [(2,90), (9,20), (10,18), (12,15)]
126 [(6,21), (7,18)]
24 [(1,24)]
170 [(5,34), (10,17)]
29 [(1,29)]
24 [(1,24)]
140 [(4,35), (7,20), (10,14)]
25 []
95 [(5,19)]
144 [(6,24), (9,16), (12,12)]
27 [(1,27)]
224 [(7,32), (14,16)]
39 []
Operands: 1, 2, (2,5), 5, 7, (7,12), 12, 12, 14, 16, (16,18), 18, 19, (19,99), (19,99), (19,99)

Cells:
28 = 1 * 28, 92 = 2 + 90, 30 = 14 + 16, 180 = 2 * 90, 126 = 7 * 18, 24 = 12 + 12, 170 = 10 * 17, 29 = 1 + 28, 24 = 5 + 19, 140 = 4 * 35, 25 = 7 + 18, 95 = 5 * 19, 144 = 12 * 12, 27 = 10 + 17, 224 = 14 * 16, 39 = 4 + 35
Operands: 1, 2, 4, 5, 7, 10, 12, 12, 14, 16, 17, 18, 19, 28, 35, 90

Solution Products: 1, Solutions: 1
```

The output is as follows:

-   The puzzle Cells, each is shown with those factors of the cell whose sum corresponds to another cell value
-   The puzzle Operands, wildcards are shown as a range of possible values
-   Each Solution shows the Cell products/sums, and the resulting Operands
-   The summary shows the number of different choices for the 8 cells that are products, and the total number of solutions

This example shows the same puzzle cells, but with all the operands as wildcards:

```bash
dart run Tetonor solve "28,92,30,180,126,24,170,29,24,140,25,95,144,27,224,39" "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
Cells:
28 [(1,28)]
92 [(4,23)]
30 []
180 [(2,90), (9,20), (10,18), (12,15)]
126 [(6,21), (7,18)]
24 [(1,24)]
170 [(5,34), (10,17)]
29 [(1,29)]
24 [(1,24)]
140 [(4,35), (7,20), (10,14)]
25 []
95 [(5,19)]
144 [(6,24), (9,16), (12,12)]
27 [(1,27)]
224 [(7,32), (14,16)]
39 []
Operands: (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99), (1,99)

Cells:
28 = 1 * 28, 92 = 2 + 90, 30 = 6 + 24, 180 = 2 * 90, 126 = 7 * 18, 24 = 10 + 14, 170 = 10 * 17, 29 = 1 + 28, 24 = 5 + 19, 140 = 10 * 14, 25 = 7 + 18, 95 = 5 * 19, 144 = 6 * 24, 27 = 10 + 17, 224 = 7 * 32, 39 = 7 + 32
Operands: 1, 2, 5, 6, 7, 7, 10, 10, 14, 17, 18, 19, 24, 28, 32, 90

Cells:
28 = 1 * 28, 92 = 2 + 90, 30 = 14 + 16, 180 = 2 * 90, 126 = 6 * 21, 24 = 10 + 14, 170 = 5 * 34, 29 = 1 + 28, 24 = 5 + 19, 140 = 10 * 14, 25 = 9 + 16, 95 = 5 * 19, 144 = 9 * 16, 27 = 6 + 21, 224 = 14 * 16, 39 = 5 + 34
Operands: 1, 2, 5, 5, 6, 9, 10, 14, 14, 16, 16, 19, 21, 28, 34, 90

Cells:
28 = 1 * 28, 92 = 2 + 90, 30 = 14 + 16, 180 = 2 * 90, 126 = 7 * 18, 24 = 12 + 12, 170 = 5 * 34, 29 = 1 + 28, 24 = 5 + 19, 140 = 7 * 20, 25 = 7 + 18, 95 = 5 * 19, 144 = 12 * 12, 27 = 7 + 20, 224 = 14 * 16, 39 = 5 + 34
Operands: 1, 2, 5, 5, 7, 7, 12, 12, 14, 16, 18, 19, 20, 28, 34, 90

Cells:
28 = 1 * 28, 92 = 2 + 90, 30 = 14 + 16, 180 = 2 * 90, 126 = 7 * 18, 24 = 12 + 12, 170 = 10 * 17, 29 = 1 + 28, 24 = 5 + 19, 140 = 4 * 35, 25 = 7 + 18, 95 = 5 * 19, 144 = 12 * 12, 27 = 10 + 17, 224 = 14 * 16, 39 = 4 + 35
Operands: 1, 2, 4, 5, 7, 10, 12, 12, 14, 16, 17, 18, 19, 28, 35, 90

Solution Products: 1, Solutions: 4
```

There are 4 solutions with different operands. The same 8 cells are computed as products in all 4 solutions, but of course the products are different.

## Algorithm

The algorithm is as follows:

1. Initialise the puzzle, computing the bounds for operand wildcards, and the viable factors for each cell
2. Get the cells that have viable factors, these are candidates as products
3. Choose 8 cells from the candidate products in turn, solving with the 8 other cells as sums
4. The solver tries each of the factors of the next candidate product cell  
   4.1. Finds operands for the factor values, trying both fixed and wildcard operands  
   4.2. It adds the product cell and the corresponding sum cell to the solution  
   4.3. Recursivley solves the remaining product cells
