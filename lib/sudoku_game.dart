import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:myapp/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

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
  final bool isDailyChallenge;

  const SudokuGameScreen({
    super.key,
    required this.difficulty,
    required this.onGameWon,
    this.continueGame = false,
    this.isDailyChallenge = false,
  });

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> with WidgetsBindingObserver {
  bool _isGameFinished = false;
  late List<List<int>> _grid;
  late List<List<int>> _initialGrid;
  late List<List<int>> _solution;
  late List<List<Set<int>>> _pencilMarks;
  late List<List<bool>> _lockedCells;
  final List<Map<String, int>> _moveHistory = [];

  int _selectedRow = -1;
  int _selectedCol = -1;

  int _score = 0;
  int _mistakes = 0;
  final int _maxMistakes = 3;
  int _hintsUsedToday = 0;
  final int _maxHintsPerDay = 3;

  Map<int, int> _numberCounts = {};
  List<bool> _isBlockPreviouslyCompleted = List.generate(9, (_) => false);
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
    _loadHintData();
    if (widget.continueGame) {
      _loadGameState();
    } else {
      _initPuzzle();
      _clearGameState();
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    if (!_isGameFinished) {
      _saveGameState();
    }
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
    final key = widget.isDailyChallenge ? 'daily_challenge_in_progress' : 'saved_game';
    final gameState = {
      'date': widget.isDailyChallenge ? DateTime.now().toIso8601String() : null,
      'difficulty': widget.difficulty,
      'grid': _grid,
      'initialGrid': _initialGrid,
      'solution': _solution,
      'pencilMarks': _pencilMarks.map((row) => row.map((set) => set.toList()).toList()).toList(),
      'score': _score,
      'mistakes': _mistakes,
      'secondsElapsed': _secondsElapsed,
      'isBlockPreviouslyCompleted': _isBlockPreviouslyCompleted,
      'isRowPreviouslyCompleted': _isRowPreviouslyCompleted,
      'isColPreviouslyCompleted': _isColPreviouslyCompleted,
      'lockedCells': _lockedCells,
    };
    await prefs.setString(key, jsonEncode(gameState));
  }

  Future<void> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.isDailyChallenge ? 'daily_challenge_in_progress' : 'saved_game';
    final savedGame = prefs.getString(key);
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
        _isBlockPreviouslyCompleted = List<bool>.from(gameState['isBlockPreviouslyCompleted']);
        _isRowPreviouslyCompleted = List<bool>.from(gameState['isRowPreviouslyCompleted']);
        _isColPreviouslyCompleted = List<bool>.from(gameState['isColPreviouslyCompleted']);
        _lockedCells = (gameState['lockedCells'] as List)
            .map((row) => (row as List).map((i) => i as bool).toList())
            .toList();
        _updateNumberCounts();
      });
    } else {
      _initPuzzle();
    }
  }

  Future<void> _clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.isDailyChallenge ? 'daily_challenge_in_progress' : 'saved_game';
    await prefs.remove(key);
  }

  void _startNewGame() {
    setState(() {
      _score = 0;
      _mistakes = 0;
      _secondsElapsed = 0;
      _isBlockPreviouslyCompleted = List.generate(9, (_) => false);
      _isRowPreviouslyCompleted = List.generate(9, (_) => false);
      _isColPreviouslyCompleted = List.generate(9, (_) => false);
      _moveHistory.clear();
      _selectedRow = -1;
      _selectedCol = -1;
      _isPencilMode = false;
      _floatingScores.clear();
      _initPuzzle();
      if (_isTimerRunning) {
        _timer.cancel();
      }
      _startTimer();
    });
  }

  void _initPuzzle() {
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
    ];
    _pencilMarks = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    _lockedCells = List.generate(9, (_) => List.generate(9, (_) => false));
    _updateNumberCounts();
  }

  void _updateNumberCounts() {
    _numberCounts = {for (var i = 1; i <= 9; i++) i: 0};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final value = _grid[r][c];
        if (value != 0) _numberCounts[value] = (_numberCounts[value] ?? 0) + 1;
      }
    }
  }

  void _onCellTap(int row, int col) {
    if (_lockedCells[row][col]) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumberInput(int number) {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_initialGrid[_selectedRow][_selectedCol] != 0 || _lockedCells[_selectedRow][_selectedCol]) return;

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
    if (oldValue == number) return;

    Vibration.vibrate(duration: 50);

    setState(() {
      _moveHistory.add({
        'row': _selectedRow,
        'col': _selectedCol,
        'value': oldValue,
      });

      _grid[_selectedRow][_selectedCol] = number;

      if (number == _solution[_selectedRow][_selectedCol]) {
        SoundService.playTapSound();
        _score += 10;
        _lockedCells[_selectedRow][_selectedCol] = true;
        _showFloatingScoreAnimation("+10", _selectedRow, _selectedCol);
      } else {
        _mistakes++;
        _score -= 5;
        _showFloatingScoreAnimation("-5", _selectedRow, _selectedCol);

        // Keep the incorrect number on the board for a moment before clearing it
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _grid[_selectedRow][_selectedCol] = 0; // Clear the incorrect number
              _updateNumberCounts();
            });
          }
        });

        if (_mistakes >= _maxMistakes) {
          _showGameOverDialog();
        } else if (_mistakes == _maxMistakes - 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Be careful! One more mistake and it's game over."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      _updateNumberCounts();
      if (_isPuzzleComplete()) _showCongratulationsDialog();
    });
  }

  bool _isPuzzleComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_grid[r][c] == 0 || _grid[r][c] != _solution[r][c]) return false;
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

  void _showCongratulationsDialog() {
    _isGameFinished = true;
    _pauseTimer();
    _clearGameState();
    int timeBonus = 0;
    if (_secondsElapsed < 15 * 60) {
      timeBonus = 100;
    } else if (_secondsElapsed <= 30 * 60) {
      timeBonus = 50;
    } else {
      timeBonus = 20;
    }
    _score += 200 + timeBonus;
    widget.onGameWon(_score);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Congratulations!"),
        content: Text("You've completed the puzzle!\nScore: $_score"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text("New Game"),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    _isGameFinished = true;
    _pauseTimer();
    _clearGameState();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Game Over"),
        content: const Text("You've made too many mistakes."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startNewGame();
            },
            child: const Text("New Game"),
          ),
        ],
      ),
    );
  }

  void _showHint() {
    if (_hintsUsedToday >= _maxHintsPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You've used all your hints for today."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    List<Map<String, int>> emptyCells = [];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_grid[r][c] == 0) {
          emptyCells.add({'row': r, 'col': c});
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final random = Random();
      final cell = emptyCells[random.nextInt(emptyCells.length)];
      final row = cell['row']!;
      final col = cell['col']!;
      final solutionValue = _solution[row][col];

      setState(() {
        _grid[row][col] = solutionValue;
        _lockedCells[row][col] = true;
        _score -= 20;
        _hintsUsedToday++;
        _saveHintData();
        _updateNumberCounts();
        if (_isPuzzleComplete()) _showCongratulationsDialog();
      });
    }
  }

  void _undoMove() {
    if (_moveHistory.isNotEmpty) {
      final lastMove = _moveHistory.removeLast();
      final row = lastMove['row']!;
      final col = lastMove['col']!;
      final value = lastMove['value']!;

      setState(() {
        _grid[row][col] = value;
        _updateNumberCounts();
      });
    }
  }

  Future<void> _loadHintData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastHintDate = prefs.getString('lastHintDate');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastHintDate == today) {
      _hintsUsedToday = prefs.getInt('hintsUsedToday') ?? 0;
    } else {
      await prefs.setString('lastHintDate', today);
      await prefs.setInt('hintsUsedToday', 0);
    }
  }

  Future<void> _saveHintData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hintsUsedToday', _hintsUsedToday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.difficulty} Sudoku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _moveHistory.isNotEmpty ? _undoMove : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mistakes: $_mistakes/$_maxMistakes', style: const TextStyle(fontSize: 16)),
                Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Score: $_score', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
                      itemCount: 81,
                      itemBuilder: (context, index) {
                        final row = index ~/ 9;
                        final col = index % 9;
                        return _buildCell(row, col);
                      },
                    ),
                    ..._floatingScores.map((s) => _buildFloatingScore(s)),
                  ],
                ),
              ),
            ),
          ),
          _buildNumberPad(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final value = _grid[row][col];
    final isSelected = row == _selectedRow && col == _selectedCol;
    final isLocked = _initialGrid[row][col] != 0;
    final isPeer =
        !isSelected && (_selectedRow != -1 && (row == _selectedRow || col == _selectedCol || (row ~/ 3 == _selectedRow ~/ 3 && col ~/ 3 == _selectedCol ~/ 3)));
    final isSameValue = _selectedRow != -1 && _selectedCol != -1 && value != 0 && value == _grid[_selectedRow][_selectedCol];
    final isIncorrect = value != 0 && value != _solution[row][col] && !isLocked;

    Color? cellColor;
    if (isSelected) {
      cellColor = Theme.of(context).primaryColor.withAlpha(77);
    } else if (isPeer) {
      cellColor = Colors.grey.shade200;
    } else if (isSameValue) {
      cellColor = Theme.of(context).primaryColor.withAlpha(38);
    }

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          border: Border(
            top: BorderSide(width: row % 3 == 0 ? 1.5 : 0.5, color: Colors.black),
            left: BorderSide(width: col % 3 == 0 ? 1.5 : 0.5, color: Colors.black),
            right: BorderSide(width: col == 8 ? 1.5 : 0.5, color: Colors.black),
            bottom: BorderSide(width: row == 8 ? 1.5 : 0.5, color: Colors.black),
          ),
        ),
        child: Center(
          child: _buildCellContent(row, col, value, isLocked, isIncorrect),
        ),
      ),
    );
  }

  Widget _buildCellContent(int row, int col, int value, bool isLocked, bool isIncorrect) {
    if (value != 0) {
      return Text(
        '$value',
        style: TextStyle(
          fontSize: 24,
          fontWeight: isLocked ? FontWeight.bold : FontWeight.normal,
          color: isIncorrect ? Colors.red : (isLocked ? Colors.black : Theme.of(context).primaryColor),
        ),
      );
    } else if (_pencilMarks[row][col].isNotEmpty) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemBuilder: (context, index) {
          final number = index + 1;
          return Center(
            child: Text(
              _pencilMarks[row][col].contains(number) ? '$number' : '',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          );
        },
        itemCount: 9,
        physics: const NeverScrollableScrollPhysics(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      child: FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(9, (index) {
            final number = index + 1;
            final isComplete = (_numberCounts[number] ?? 0) >= 9;
            return GestureDetector(
              onTap: isComplete ? null : () => _onNumberInput(number),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isComplete ? Colors.grey.shade300 : Theme.of(context).primaryColor,
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 22,
                    color: isComplete ? Colors.grey.shade500 : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.edit,
            label: "Pencil",
            onPressed: _togglePencil,
            isSelected: _isPencilMode,
          ),
          _buildIconButton(
            icon: Icons.lightbulb_outline,
            label: "Hint",
            onPressed: _showHint,
          ),
          _buildIconButton(
            icon: Icons.delete_outline,
            label: "Erase",
            onPressed: () => _onNumberInput(0),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required String label, required VoidCallback onPressed, bool isSelected = false}) {
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 28, color: color),
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildFloatingScore(FloatingScore score) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth / 9;
      return TweenAnimationBuilder<double>(
        key: score.key,
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, value, child) {
          return Positioned(
            top: score.row * size + size / 2 - 15,
            left: score.col * size + size / 2 - 15,
            child: Opacity(
              opacity: 1.0 - value,
              child: Transform.translate(
                offset: Offset(0, -value * 30),
                child: Text(
                  score.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: score.text.startsWith('+') ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
