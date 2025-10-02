import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:myapp/sudoku_game.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late DateTime _displayDate;
  bool _isCompletedForDisplayDate = false;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _displayDate = DateTime.now();
    _loadChallengeStatus();
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

    // Check and reset streak if the last completed day was not yesterday
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
          difficulty: 'Hard', // Daily challenges are usually hard
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
    // Update streak
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
    // Show reward dialog
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
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back from game screen
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Win Daily Challenges'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _navigateToPreviousDay,
                ),
                Text(
                  DateFormat('MMMM d, yyyy').format(_displayDate),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _navigateToNextDay,
                ),
              ],
            ),
            const Icon(
              Icons.emoji_events,
              size: 150,
              color: Colors.amber,
            ),
            FutureBuilder<List<bool>>(
              future: _getCompletionStatusForWeek(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final completionStatus = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final dayDate = _displayDate
                        .subtract(Duration(days: 3 - index));
                    final isCompleted = completionStatus[index];
                    final isFuture = dayDate.isAfter(DateTime.now());
                    final isDisplayingDate = dayDate.year == _displayDate.year &&
                        dayDate.month == _displayDate.month &&
                        dayDate.day == _displayDate.day;

                    Color circleColor = Colors.grey.shade300;
                    IconData iconData = Icons.sentiment_satisfied_alt;
                    Color iconColor = Colors.white;

                    if (isDisplayingDate) {
                      circleColor = Theme.of(context).primaryColor;
                    }

                    if (isCompleted) {
                      iconData = Icons.check_circle;
                      iconColor = Colors.green;
                    } else if (isFuture) {
                      iconData = Icons.lock;
                      iconColor = Colors.grey;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                        border: isDisplayingDate
                            ? Border.all(
                                color: Theme.of(context).primaryColorDark,
                                width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          color: iconColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(
              width: double.infinity,
              child: Builder(builder: (context) {
                final now = DateTime.now();
                final isToday = _displayDate.year == now.year &&
                    _displayDate.month == now.month &&
                    _displayDate.day == now.day;

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
                  buttonText =
                      _isCompletedForDisplayDate ? 'Completed' : 'Missed';
                  onPressedAction = null;
                }

                return ElevatedButton(
                  onPressed: onPressedAction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: Text(buttonText),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
