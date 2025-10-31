import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:myapp/sudoku_game.dart';

class DailyChallengeScreen extends StatefulWidget {
  final bool continueGame;
  const DailyChallengeScreen({super.key, this.continueGame = false});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _displayDate;
  bool _isCompletedForDisplayDate = false;
  int _streak = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    _displayDate = DateTime.now();
    _loadChallengeStatus();

    if (widget.continueGame) {
      _isResuming = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playDailyChallenge(continueGame: true);
      });
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadChallengeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _getDateKey(_displayDate);

    setState(() {
      _isCompletedForDisplayDate = prefs.getBool(dateKey) ?? false;
      _streak = prefs.getInt('daily_streak') ?? 0;
    });

    final lastCompletedDateStr = prefs.getString('last_completed_date');
    if (lastCompletedDateStr != null) {
      final lastCompletedDate = DateTime.parse(lastCompletedDateStr);
      final today = DateTime.now();
      final difference = today.difference(lastCompletedDate).inDays;
      if (difference > 1) {
        await prefs.setInt('daily_streak', 0);
        setState(() {
          _streak = 0;
        });
      }
    }
  }

  void _navigateToPreviousDay() {
    setState(() {
      _displayDate = _displayDate.subtract(const Duration(days: 1));
    });
    _loadChallengeStatus();
  }

  void _navigateToNextDay() {
    setState(() {
      _displayDate = _displayDate.add(const Duration(days: 1));
    });
    _loadChallengeStatus();
  }

  void _playDailyChallenge({bool continueGame = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SudokuGameScreen(
          difficulty: 'Hard',
          isDailyChallenge: true,
          continueGame: continueGame,
          onGameWon: (score) {
            _markAsCompleted();
          },
        ),
      ),
    );
  }

  Future<void> _saveAward() async {
    final prefs = await SharedPreferences.getInstance();
    final awards = prefs.getStringList('awards') ?? [];
    final today = DateTime.now();
    final award =
        '${DateFormat('yyyy-MM-dd').format(today)}|Daily Challenge|trophy';
    awards.add(award);
    await prefs.setStringList('awards', awards);
  }

  Future<void> _markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _getDateKey(now);
    await prefs.setBool(todayKey, true);

    final lastCompletedDateStr = prefs.getString('last_completed_date');
    int newStreak = 1;
    if (lastCompletedDateStr != null) {
      final lastCompletedDate = DateTime.parse(lastCompletedDateStr);
      final yesterday = now.subtract(const Duration(days: 1));
      if (DateFormat('yyyy-MM-dd').format(lastCompletedDate) ==
          DateFormat('yyyy-MM-dd').format(yesterday)) {
        newStreak = (_streak) + 1;
      }
    }
    await prefs.setInt('daily_streak', newStreak);
    await prefs.setString('last_completed_date', now.toIso8601String());
    await _saveAward();
    setState(() {
      _isCompletedForDisplayDate = true;
      _streak = newStreak;
    });

    _animationController.forward(from: 0.0);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Challenge Complete!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("You've earned a new trophy!"),
            const SizedBox(height: 10),
            Text("Your streak is now: $_streak day(s)"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Awesome!"),
          ),
        ],
      ),
    );
  }

  Future<List<bool>> _getCompletionStatusForWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final weekDates = List.generate(7, (index) {
      return _displayDate.subtract(Duration(days: 3 - index));
    });

    final statusList = <bool>[];
    for (final date in weekDates) {
      final dateKey = _getDateKey(date);
      statusList.add(prefs.getBool(dateKey) ?? false);
    }
    return statusList;
  }

  @override
  Widget build(BuildContext context) {
    if (_isResuming) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenges'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDateNavigator(),
            _buildTrophyAndBonus(),
            _buildWeekView(),
            _buildStreakCounter(),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isNextDayAvailable = !_displayDate.isAtSameMomentAs(today);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 28),
          onPressed: _navigateToPreviousDay,
        ),
        Text(
          DateFormat('MMMM d, yyyy').format(_displayDate),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios,
              size: 28,
              color: isNextDayAvailable
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.grey),
          onPressed: isNextDayAvailable ? _navigateToNextDay : null,
        ),
      ],
    );
  }

  Widget _buildTrophyAndBonus() {
    return Column(
      children: [
        ScaleTransition(
          scale: _animation,
          child: Icon(
            _isCompletedForDisplayDate ? Icons.emoji_events : Icons.emoji_events_outlined,
            size: 150,
            color: _isCompletedForDisplayDate ? Colors.amber.shade600 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Weekly Bonus"),
                content: const Text("Complete all 7 challenges in a week to earn a special reward!"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Colors.green),
                SizedBox(width: 8),
                Text("Weekly Bonus", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    return FutureBuilder<List<bool>>(
      future: _getCompletionStatusForWeek(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 60);
        }
        final completionStatus = snapshot.data!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final dayDate = _displayDate.subtract(Duration(days: 3 - index));
            final isCompleted = completionStatus[index];
            final isFuture = dayDate.isAfter(DateTime.now());
            final isDisplaying = dayDate.day == _displayDate.day;

            return Opacity(
              opacity: isFuture ? 0.5 : 1.0,
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(dayDate),
                    style: TextStyle(
                        fontWeight:
                            isDisplaying ? FontWeight.bold : FontWeight.normal),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isCompleted ? Icons.star : (isFuture ? Icons.lock_outline : Icons.circle_outlined),
                    color: isCompleted ? Colors.amber.shade700 : Colors.grey.shade500,
                    size: 32,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStreakCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            "Current Streak: $_streak Day${_streak == 1 ? '' : 's'}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final displayDay =
        DateTime(_displayDate.year, _displayDate.month, _displayDate.day);

    if (displayDay.isAfter(today)) {
      return _buildChallengeLocked();
    } else {
      return _buildPlayButton(displayDay.isAtSameMomentAs(today));
    }
  }

  Widget _buildChallengeLocked() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock,
            size: 60,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Challenge Locked',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(bool isToday) {
    String buttonText;
    VoidCallback? onPressedAction;
    Color? backgroundColor;
    Color? foregroundColor;

    if (isToday) {
      if (_isCompletedForDisplayDate) {
        buttonText = 'Completed';
        onPressedAction = null;
        backgroundColor = Colors.grey.shade300;
        foregroundColor = Colors.grey.shade700;
      } else {
        buttonText = 'Start Challenge';
        onPressedAction = () => _playDailyChallenge();
      }
    } else {
      // Past date
      if (_isCompletedForDisplayDate) {
        buttonText = 'Completed';
        backgroundColor = Colors.grey.shade300;
        foregroundColor = Colors.grey.shade700;
      } else {
        buttonText = 'Missed';
        backgroundColor = Colors.grey.shade300;
        foregroundColor = Colors.grey.shade700;
      }
      onPressedAction = null;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressedAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        child: Text(buttonText),
      ),
    );
  }
}
