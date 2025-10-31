import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/game_difficulty.dart';
import 'package:myapp/sudoku_game.dart';
import 'package:myapp/daily_challenge_screen.dart';
import 'difficulty_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameDifficulty _currentDifficulty = GameDifficulty.easy;
  int _bestEasy = 0;
  int _bestMedium = 0;
  int _bestHard = 0;
  int _bestExpert = 0;
  int _overallBest = 0;
  bool _hasSavedGame = false;
  bool _hasSavedDailyChallenge = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _loadBestScores(prefs),
      _checkForSavedGame(prefs),
      _checkForSavedDailyChallenge(prefs),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkForSavedDailyChallenge([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    final dailyChallengeJson = prefs.getString('daily_challenge_in_progress');

    if (dailyChallengeJson == null) {
      _hasSavedDailyChallenge = false;
      return;
    }

    try {
      final dailyChallengeData = jsonDecode(dailyChallengeJson);
      final savedDateStr = dailyChallengeData['date'] as String?;
      if (savedDateStr == null) {
        // Handle legacy data without a date, assume it's expired
        await prefs.remove('daily_challenge_in_progress');
        _hasSavedDailyChallenge = false;
        return;
      }

      final savedDate = DateTime.parse(savedDateStr);
      final now = DateTime.now();
      final isToday = savedDate.year == now.year &&
          savedDate.month == now.month &&
          savedDate.day == now.day;

      if (isToday) {
        _hasSavedDailyChallenge = true;
      } else {
        await prefs.remove('daily_challenge_in_progress');
        _hasSavedDailyChallenge = false;
      }
    } catch (e) {
      // If there's an error decoding, remove the invalid data
      await prefs.remove('daily_challenge_in_progress');
      _hasSavedDailyChallenge = false;
    }
  }

  Future<void> _checkForSavedGame([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    _hasSavedGame = prefs.containsKey('saved_game');
  }

  Future<void> _loadBestScores([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    _bestEasy = prefs.getInt('best_easy') ?? 0;
    _bestMedium = prefs.getInt('best_medium') ?? 0;
    _bestHard = prefs.getInt('best_hard') ?? 0;
    _bestExpert = prefs.getInt('best_expert') ?? 0;
    _calculateOverallBest();
  }

  Future<void> _reloadProgress() async {
    setState(() {
      _isLoading = true;
    });
    await _loadInitialData();
  }

  void _calculateOverallBest() {
    _overallBest = [_bestEasy, _bestMedium, _bestHard, _bestExpert]
        .reduce((a, b) => a > b ? a : b);
  }

  Future<void> _updateCompletionCount(GameDifficulty difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (difficulty) {
      case GameDifficulty.easy:
        key = 'easyCompleted';
        break;
      case GameDifficulty.medium:
        key = 'mediumCompleted';
        break;
      case GameDifficulty.hard:
        key = 'hardCompleted';
        break;
      case GameDifficulty.expert:
        return; // No count for expert
    }
    int currentCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentCount + 1);
  }

  Future<void> _updateBestScore(GameDifficulty difficulty, int score) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    int currentBest;
    switch (difficulty) {
      case GameDifficulty.easy:
        key = 'best_easy';
        currentBest = _bestEasy;
        break;
      case GameDifficulty.medium:
        key = 'best_medium';
        currentBest = _bestMedium;
        break;
      case GameDifficulty.hard:
        key = 'best_hard';
        currentBest = _bestHard;
        break;
      case GameDifficulty.expert:
        key = 'best_expert';
        currentBest = _bestExpert;
        break;
    }

    if (score > currentBest) {
      await prefs.setInt(key, score);
      if (!mounted) return;
      setState(() {
        switch (difficulty) {
          case GameDifficulty.easy:
            _bestEasy = score;
            break;
          case GameDifficulty.medium:
            _bestMedium = score;
            break;
          case GameDifficulty.hard:
            _bestHard = score;
            break;
          case GameDifficulty.expert:
            _bestExpert = score;
            break;
        }
        _calculateOverallBest();
      });
      // Show high score animation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New High Score! 🎉')),
      );
    }
  }

  void _navigateToGame(GameDifficulty difficulty, {bool continueGame = false}) {
    setState(() {
      _currentDifficulty = difficulty;
    });
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => SudokuGameScreen(
              difficulty: difficulty
                  .toString()
                  .split('.')
                  .last, // Convert enum to string
              continueGame: continueGame,
              onGameWon: (score) {
                _updateBestScore(difficulty, score);
                _updateCompletionCount(difficulty);
                // The pop is handled inside the dialog in SudokuGameScreen
              },
            ),
          ),
        )
        .then((_) =>
            _checkForSavedGame()); // Re-check for saved game when we return
  }

  Future<void> _continueGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGameString = prefs.getString('saved_game');
    if (savedGameString == null) return;

    final savedGame = jsonDecode(savedGameString);
    final difficultyString = savedGame['difficulty'];

    // Find the enum value from the string
    final difficulty = GameDifficulty.values.firstWhere(
      (e) => e.toString().split('.').last == difficultyString,
      orElse: () => GameDifficulty.easy, // Fallback
    );

    _navigateToGame(difficulty, continueGame: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final selectedDifficulty =
                    await showModalBottomSheet<GameDifficulty>(
                  context: context,
                  builder: (BuildContext context) {
                    return DifficultyScreen(
                      onScreenClosed: () => _reloadProgress(),
                      currentDifficulty: _currentDifficulty,
                    );
                  },
                  backgroundColor: Colors.transparent,
                );

                if (selectedDifficulty != null) {
                  _navigateToGame(selectedDifficulty, continueGame: false);
                }
              },
              child: const Text('New Game'),
            ),
            const SizedBox(height: 20),
            if (_hasSavedGame) ...[
              ElevatedButton(
                onPressed: _continueGame,
                child: const Text('Continue Game'),
              ),
              const SizedBox(height: 20),
            ],
            if (_hasSavedDailyChallenge) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const DailyChallengeScreen(continueGame: true),
                    ),
                  );
                },
                child: const Text('Continue Daily Challenge'),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const DailyChallengeScreen()),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Daily Challenge'),
            ),
            const SizedBox(height: 40),
            _buildBestScoresCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBestScoresCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('🏆 Best Scores',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Overall: $_overallBest',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreColumn('😊', 'Easy', _bestEasy),
                _buildScoreColumn('🤔', 'Medium', _bestMedium),
                _buildScoreColumn('😠', 'Hard', _bestHard),
                _buildScoreColumn('🤯', 'Expert', _bestExpert,
                    isLocked: _bestExpert == 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreColumn(String icon, String title, int score,
      {bool isLocked = false}) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(isLocked ? '—' : score.toString()),
      ],
    );
  }
}
