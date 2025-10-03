import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:myapp/sudoku_game.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _displayDate = DateTime.now();
    _loadChallengeStatus();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 1.0, end: 1.2).animate(_animationController);
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
    final tomorrow = _displayDate.add(const Duration(days: 1));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    if (!nextDay.isAfter(today)) {
      setState(() {
        _displayDate = tomorrow;
      });
      _loadChallengeStatus();
    }
  }

  void _playDailyChallenge() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SudokuGameScreen(
          difficulty: 'Hard',
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
    final now = DateTime.now();
    final isToday = _displayDate.year == now.year &&
        _displayDate.month == now.month &&
        _displayDate.day == now.day;
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
            _buildTrophy(),
            _buildStreakTracker(),
            _buildPlayButton(isToday),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    final now = DateTime.now();
    final isNextDayAvailable = !_displayDate
        .add(const Duration(days: 1))
        .isAfter(DateTime(now.year, now.month, now.day));

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

  Widget _buildTrophy() {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.emoji_events,
        size: 150,
        color: Colors.amber.shade600,
      ),
    );
  }

  Widget _buildStreakTracker() {
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

            IconData iconData;
            Color iconColor;

            if (isFuture) {
              iconData = Icons.lock_outline;
              iconColor = Colors.grey.shade400;
            } else if (isCompleted) {
              iconData = Icons.star;
              iconColor = Colors.amber.shade700;
            } else {
              iconData = Icons.circle_outlined;
              iconColor = Colors.grey.shade500;
            }

            return Column(
              children: [
                Text(
                  DateFormat('E').format(dayDate).substring(0, 1),
                  style: TextStyle(
                      fontWeight:
                          isDisplaying ? FontWeight.bold : FontWeight.normal),
                ),
                const SizedBox(height: 4),
                Icon(iconData, color: iconColor, size: 32),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildPlayButton(bool isToday) {
    String buttonText;
    VoidCallback? onPressedAction;

    if (isToday) {
      if (_isCompletedForDisplayDate) {
        buttonText = 'Completed';
        onPressedAction = null;
      } else {
        buttonText = 'Play';
        onPressedAction = _playDailyChallenge;
      }
    } else {
      buttonText = _isCompletedForDisplayDate ? 'Completed' : 'Missed';
      onPressedAction = null;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressedAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 247, 245, 245),
          foregroundColor: const Color.fromARGB(255, 32, 142, 245),
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
