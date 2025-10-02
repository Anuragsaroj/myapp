import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class FloatingScore {
  final String text;
  final Key key;
  final int row;
  final int col;

  FloatingScore({required this.text, required this.row, required this.col}) : key = UniqueKey();
}

class SudokuGameScreen extends StatefulWidget {
  final String difficulty;
  final Function(int score) onGameWon;
  final bool continueGame;

  const SudokuGameScreen({
    super.key,
    required this.difficulty,
    required this.onGameWon,
    this.continueGame = false,
  });

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> with WidgetsBindingObserver {
  late List<List<int>> _grid;
  late List<List<int>> _initialGrid; // To store the original puzzle
  late List<List<int>> _solution;
  late List<List<Set<int>>> _pencilMarks;
  final List<Map<String, int>> _moveHistory = [];

  int _selectedRow = -1;
  int _selectedCol = -1;

  int _selectedNumberPadValue = -1; // New state for selected number in pad

  int _score = 0;
  int _mistakes = 0;
  final int _maxMistakes = 3;
  int _hintsUsed = 0;
  final int _maxHints = 3;

  final List<double> _blockCompletionProgress = List.generate(9, (_) => 0.0);
  Map<int, int> _numberCounts = {}; // To store counts of each number (1-9)
  List<bool> _isBlockPreviouslyCompleted = List.generate(9, (_) => false); // Track previously completed blocks
  List<bool> _isRowPreviouslyCompleted = List.generate(9, (_) => false);
  List<bool> _isColPreviouslyCompleted = List.generate(9, (_) => false);
  final List<FloatingScore> _floatingScores = [];

  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isTimerRunning = false;
  bool _isPencilMode = false;

  void _togglePencil() {
    setState(() {
      _isPencilMode = !_isPencilMode;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.continueGame) {
      _loadGameState();
    } else {
      _initPuzzle();
      _clearGameState(); // Clear any previous state for a new game
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveGameState();
    }
  }

  void _startTimer() {
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _pauseTimer() {
    if (_isTimerRunning) {
      _timer.cancel();
      setState(() {
        _isTimerRunning = false;
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final gameState = {
      'difficulty': widget.difficulty,
      'grid': _grid,
      'initialGrid': _initialGrid,
      'solution': _solution,
      'pencilMarks': _pencilMarks.map((row) => row.map((set) => set.toList()).toList()).toList(),
      'score': _score,
      'mistakes': _mistakes,
      'secondsElapsed': _secondsElapsed,
      'hintsUsed': _hintsUsed,
      'isBlockPreviouslyCompleted': _isBlockPreviouslyCompleted,
      'isRowPreviouslyCompleted': _isRowPreviouslyCompleted,
      'isColPreviouslyCompleted': _isColPreviouslyCompleted,
    };
    await prefs.setString('saved_game', jsonEncode(gameState));
  }

  Future<void> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGame = prefs.getString('saved_game');
    if (savedGame != null) {
      final gameState = jsonDecode(savedGame);
      setState(() {
        _grid = (gameState['grid'] as List).map((row) => (row as List).map((i) => i as int).toList()).toList();
        _initialGrid =
            (gameState['initialGrid'] as List).map((row) => (row as List).map((i) => i as int).toList()).toList();
        _solution =
            (gameState['solution'] as List).map((row) => (row as List).map((i) => i as int).toList()).toList();
        _pencilMarks = (gameState['pencilMarks'] as List)
            .map((row) =>
                (row as List).map((list) => (list as List).map((i) => i as int).toSet()).toList())
            .toList();
        _score = gameState['score'];
        _mistakes = gameState['mistakes'];
        _secondsElapsed = gameState['secondsElapsed'];
        _hintsUsed = gameState['hintsUsed'];
        _isBlockPreviouslyCompleted = List<bool>.from(gameState['isBlockPreviouslyCompleted']);
        _isRowPreviouslyCompleted = List<bool>.from(gameState['isRowPreviouslyCompleted']);
        _isColPreviouslyCompleted = List<bool>.from(gameState['isColPreviouslyCompleted']);
        _updateNumberCounts();
      });
    } else {
      _initPuzzle();
    }
  }

  Future<void> _clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_game');
  }

  void _initPuzzle() {
    // Dummy puzzle (replace with your generator or puzzle DB)
    _initialGrid = [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ];
    _grid = _initialGrid.map((row) => List<int>.from(row)).toList();
    _solution = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ]; // Dummy solution
    _pencilMarks = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    _updateNumberCounts(); // Initialize number counts
    _checkAllCompletion();
  }

  void _updateNumberCounts() {
    _numberCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final value = _grid[r][c];
        if (value != 0) {
          _numberCounts[value] = (_numberCounts[value] ?? 0) + 1;
        }
      }
    }
  }

  void _onCellTap(int row, int col) {
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
      _selectedNumberPadValue = _grid[row][col]; // Highlight the number in the pad if cell has a value
    });
  }

  void _onNumberInput(int number) {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_initialGrid[_selectedRow][_selectedCol] != 0) return; // Prevent changing initial numbers

    if (_isPencilMode) {
      setState(() {
        if (_pencilMarks[_selectedRow][_selectedCol].contains(number)) {
          _pencilMarks[_selectedRow][_selectedCol].remove(number);
        } else {
          _pencilMarks[_selectedRow][_selectedCol].add(number);
        }
      });
      return;
    }

    final oldValue = _grid[_selectedRow][_selectedCol];
    if (oldValue == number) return; // No change, no need to record history or setState

    setState(() {
      _moveHistory.add({
        'row': _selectedRow,
        'col': _selectedCol,
        'value': oldValue,
      });

      _grid[_selectedRow][_selectedCol] = number;
      _selectedNumberPadValue = number; // Update selected number in pad
      // Example scoring logic
      if (number == _solution[_selectedRow][_selectedCol]) {
        _score += 10;
        _showFloatingScoreAnimation("+10", _selectedRow, _selectedCol);
      } else {
        _mistakes++;
        _score -= 5;
        _showFloatingScoreAnimation("-5", _selectedRow, _selectedCol);
        if (_mistakes >= _maxMistakes) {
          _showGameOverDialog();
        }
      }
      _updateNumberCounts(); // Update number counts after input
      _checkAllCompletion();
      if (_isPuzzleComplete()) {
        _showCongratulationsDialog();
      }
    });
  }

  void _undoMove() {
    if (_moveHistory.isEmpty) return;
    final lastMove = _moveHistory.removeLast();
    final row = lastMove['row']!;
    final col = lastMove['col']!;
    final value = lastMove['value']!;
    setState(() {
      _grid[row][col] = value;
      _updateNumberCounts();
      _checkAllCompletion();
    });
  }

  void _eraseValue() {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_initialGrid[_selectedRow][_selectedCol] != 0) return;

    final oldValue = _grid[_selectedRow][_selectedCol];
    if (oldValue == 0) return; // Already empty

    setState(() {
      _moveHistory.add({
        'row': _selectedRow,
        'col': _selectedCol,
        'value': oldValue,
      });
      _grid[_selectedRow][_selectedCol] = 0;
      _updateNumberCounts();
      _checkAllCompletion();
    });
  }

  bool _isPuzzleComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_grid[r][c] == 0 || _grid[r][c] != _solution[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  void _showFloatingScoreAnimation(String text, int row, int col) {
    final newScore = FloatingScore(text: text, row: row, col: col);
    setState(() {
      _floatingScores.add(newScore);
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _floatingScores.removeWhere((s) => s.key == newScore.key);
        });
      }
    });
  }

  bool _isBlockCorrectlyCompleted(int blockRow, int blockCol) {
    final Set<int> numbersInBlock = {};
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final row = blockRow * 3 + r;
        final col = blockCol * 3 + c;
        final value = _grid[row][col];
        if (value == 0) {
          return false; // Not complete if there's an empty cell
        }
        if (numbersInBlock.contains(value)) {
          return false; // Not complete if there's a duplicate
        }
        numbersInBlock.add(value);
      }
    }
    return true; // All cells are filled and unique
  }

  void _checkAllCompletion() {
    // Check blocks
    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        final blockIndex = blockRow * 3 + blockCol;
        if (!_isBlockPreviouslyCompleted[blockIndex] && _isBlockCorrectlyCompleted(blockRow, blockCol)) {
          setState(() {
            _isBlockPreviouslyCompleted[blockIndex] = true;
            _score += 50;
            _showFloatingScoreAnimation("+50✨", _selectedRow, _selectedCol);
          });
        }
      }
    }
    // Check rows
    for (int r = 0; r < 9; r++) {
      if (!_isRowPreviouslyCompleted[r] && _isRowCorrectlyCompleted(r)) {
        setState(() {
          _isRowPreviouslyCompleted[r] = true;
          _score += 50;
          _showFloatingScoreAnimation("+50✨", _selectedRow, _selectedCol);
        });
      }
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      if (!_isColPreviouslyCompleted[c] && _isColumnCorrectlyCompleted(c)) {
        setState(() {
          _isColPreviouslyCompleted[c] = true;
          _score += 50;
          _showFloatingScoreAnimation("+50✨", _selectedRow, _selectedCol);
        });
      }
    }
  }

  bool _isRowCorrectlyCompleted(int r) {
    final Set<int> numbers = {};
    for (int c = 0; c < 9; c++) {
      final value = _grid[r][c];
      if (value == 0 || numbers.contains(value)) return false;
      numbers.add(value);
    }
    return true;
  }

  bool _isColumnCorrectlyCompleted(int c) {
    final Set<int> numbers = {};
    for (int r = 0; r < 9; r++) {
      final value = _grid[r][c];
      if (value == 0 || numbers.contains(value)) return false;
      numbers.add(value);
    }
    return true;
  }

  double _getBlockCompletionPercentage(int blockRow, int blockCol) {
    int filledCells = 0;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        final row = blockRow * 3 + r;
        final col = blockCol * 3 + c;
        if (_grid[row][col] != 0) {
          filledCells++;
        }
      }
    }
    return filledCells / 9.0; // Assuming 9 cells per block
  }


  void _showCongratulationsDialog() {
    _pauseTimer();
    _clearGameState();

    int timeBonus = 0;
    if (_secondsElapsed < 15 * 60) {
      // < 15 min
      timeBonus = 100;
    } else if (_secondsElapsed <= 30 * 60) {
      // 15-30 min
      timeBonus = 50;
    } else {
      // > 30 min
      timeBonus = 20;
    }
    _score += 200 + timeBonus; // Puzzle completion + time bonus

    widget.onGameWon(_score);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Congratulations!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Puzzle Complete: +200"),
            Text("Time Bonus: +$timeBonus"),
            const SizedBox(height: 20),
            Text("Final Score: $_score", style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initPuzzle();
            },
            child: const Text("New Game"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to main menu
            },
            child: const Text("Main Menu"),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    _pauseTimer();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("❌ Game Over"),
        content: const Text("You've made 3 mistakes!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _mistakes = 0;
              });
              _startTimer();
            },
            child: const Text("Second Chance"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to main menu
            },
            child: const Text("New Game"),
          ),
        ],
      ),
    );
  }

  void _useHint() {
    if (_hintsUsed >= _maxHints) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("No More Hints"),
          content: const Text("You have used all 3 hints."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final List<Map<String, int>> emptyCells = [];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_grid[r][c] == 0) {
          emptyCells.add({'row': r, 'col': c});
        }
      }
    }

    if (emptyCells.isEmpty) {
      return; // No empty cells left
    }

    final random = Random();
    final cell = emptyCells[random.nextInt(emptyCells.length)];
    final row = cell['row']!;
    final col = cell['col']!;

    setState(() {
      _grid[row][col] = _solution[row][col];
      _hintsUsed++;
      _updateNumberCounts();
      _checkAllCompletion();
      if (_isPuzzleComplete()) {
        _showCongratulationsDialog();
      }
    });
  }

  // ---------- BUILDING THE GRID ----------
  Widget _buildGrid() {
    return Container(
      padding: const EdgeInsets.all(4), // Reduced padding for overall grid
      child: GridView.builder(
        itemCount: 81,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final col = index % 9;
          final value = _grid[row][col];
          final initialValue = _initialGrid[row][col];

          final isSelected = row == _selectedRow && col == _selectedCol;
          final isHighlighted = (_selectedRow != -1 && _selectedCol != -1) &&
              (row == _selectedRow || col == _selectedCol ||
                  (row ~/ 3 == _selectedRow ~/ 3 && col ~/ 3 == _selectedCol ~/ 3));

          final isNumberSelected = _selectedNumberPadValue != -1 && value != 0 && value == _selectedNumberPadValue;

          final blockIndex = (row ~/ 3) * 3 + (col ~/ 3);
          final blockProgress = _blockCompletionProgress[blockIndex];

          Color cellColor = Theme.of(context).colorScheme.surface;
          if (isHighlighted || isNumberSelected) {
            cellColor = Colors.blue.withOpacity(0.12);
          }
          if (isSelected) {
            cellColor = Colors.blue.withOpacity(0.25);
          }

          List<BoxShadow>? boxShadow; // No shadows

          return GestureDetector(
            onTap: () => _onCellTap(row, col),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: cellColor,
                boxShadow: boxShadow,
                border: (isSelected && _isPencilMode)
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0)
                    : Border(
                        top: BorderSide(
                            color: row % 3 == 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).dividerColor,
                            width: row % 3 == 0 ? 2 : 1),
                        left: BorderSide(
                            color: col % 3 == 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).dividerColor,
                            width: col % 3 == 0 ? 2 : 1),
                        right: BorderSide(
                            color: (col + 1) % 3 == 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).dividerColor,
                            width: (col + 1) % 3 == 0 ? 2 : 1),
                        bottom: BorderSide(
                            color: (row + 1) % 3 == 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).dividerColor,
                            width: (row + 1) % 3 == 0 ? 2 : 1),
                      ),
              ),
              child: Stack(
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    final double base = constraints.maxWidth;
                    final double numberFontSize = base * 0.55;
                    final double pencilFontSize = base * 0.25;

                    return Stack(
                      children: [
                        if (value == 0)
                          _buildPencilMarksGrid(row, col, pencilFontSize)
                        else
                          Center(
                            child: Text(
                              value.toString(),
                              style: TextStyle(
                                fontSize: numberFontSize.clamp(14.0, 36.0),
                                fontWeight: FontWeight.bold,
                                color: initialValue != 0
                                    ? Theme.of(context).colorScheme.onSurface
                                    : value == _solution[row][col]
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (row % 3 == 0 && col % 3 == 0) // Top-left cell of a 3x3 block
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Text(
                              '${(blockProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: base * 0.15,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Pencil marks in 3x3 mini-grid
  Widget _buildPencilMarksGrid(int row, int col, double fontSize) {
    final marks = _pencilMarks[row][col];
    return FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (r) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (c) {
            final num = r * 3 + c + 1;
            return SizedBox(
              width: fontSize * 1.2,
              height: fontSize * 1.4,
              child: Text(
                marks.contains(num) ? num.toString() : '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        );
      }),
      ),
    );
  }

  // ---------- NUMBER PAD ----------
  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          final number = index + 1;
          final isNumberSelected = _selectedNumberPadValue == number;
          final count = _numberCounts[number] ?? 0;
          final isFullyUsed = count >= 9; // Assuming 9 occurrences means fully used

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TextButton(
                onPressed: isFullyUsed
                    ? null
                    : () {
                        setState(() {
                          _selectedNumberPadValue = number;
                        });
                        _onNumberInput(number);
                      },
                style: TextButton.styleFrom(
                  backgroundColor: isNumberSelected
                      ? Theme.of(context).colorScheme.primary.withAlpha(51)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isFullyUsed
                        ? Theme.of(context).colorScheme.onSurface.withAlpha(77)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBlockCompletionProgressBar(),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildGrid(),
                        ..._buildFloatingScores(constraints),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.undo, "Undo", _undoMove),
                  _buildActionButton(Icons.delete_outline, "Erase", _eraseValue),
                  _buildActionButton(Icons.edit_note, "Notes", _togglePencil, isActive: _isPencilMode),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        onPressed: _hintsUsed >= _maxHints ? null : _useHint,
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.lightbulb, size: 24),
                            if (_hintsUsed < _maxHints)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    '${_maxHints - _hintsUsed}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: const Text("Hint", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          elevation: 4, // Shadow
                          shadowColor: Theme.of(context).shadowColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildNumberPad(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, {bool isActive = false}) {
    final activeBackgroundColor = Theme.of(context).colorScheme.primary;
    final activeForegroundColor = Theme.of(context).colorScheme.onPrimary;
    final inactiveBackgroundColor = Theme.of(context).colorScheme.surface;
    final inactiveForegroundColor = Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            foregroundColor: isActive ? activeForegroundColor : inactiveForegroundColor,
            backgroundColor: isActive ? activeBackgroundColor : inactiveBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            elevation: 4, // Shadow
            shadowColor: Theme.of(context).shadowColor,
          ),
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _saveGameState();
                  Navigator.of(context).pop();
                },
              ),
              Text(
                widget.difficulty,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.transparent), // Placeholder for alignment
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard("Score", "$_score", Icons.star, Theme.of(context).colorScheme.secondary),
              _buildInfoCard(
                  "Mistakes", "$_mistakes/$_maxMistakes", Icons.favorite, Theme.of(context).colorScheme.error),
              _buildTimerCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            children: [
              Text("Timer", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Theme.of(context).colorScheme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_secondsElapsed),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockCompletionProgressBar() {
    double totalProgress = _blockCompletionProgress.reduce((a, b) => a + b) / 9.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion: ${(totalProgress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalProgress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingScores(BoxConstraints constraints) {
    final cellSize = (constraints.maxWidth - 8) / 9; // 4 padding on each side

    return _floatingScores.map((score) {
      return Positioned(
        left: score.col * cellSize + 4, // +4 for padding
        top: score.row * cellSize + 4, // +4 for padding
        width: cellSize,
        height: cellSize,
        child: TweenAnimationBuilder<double>(
          key: score.key,
          tween: Tween(begin: 1.0, end: 0.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -50 * (1 - value)), // Move up
              child: Opacity(
                opacity: value, // Fade out
                child: child,
              ),
            );
          },
          child: Center(
            child: Text(
              score.text,
              style: TextStyle(
                color: score.text.startsWith('+')
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: const [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black26,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
