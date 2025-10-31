import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:myapp/challenge_details_screen.dart';
import 'package:myapp/models/badge_model.dart';

enum ChallengeStatus { completed, upcoming, inProgress }

class Challenge {
  final String name;
  final String description;
  final ChallengeStatus status;
  final Badge? reward;

  Challenge({
    required this.name,
    required this.description,
    required this.status,
    this.reward,
  });
}

class Streak {
  final String name;
  final String description;
  final int goal;
  final int currentProgress;
  final bool achieved;

  Streak({
    required this.name,
    required this.description,
    required this.goal,
    required this.currentProgress,
    this.achieved = false,
  });
}

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late ConfettiController _confettiController;
  List<Badge> _badges = [];
  List<Streak> _streaks = [];
  List<Challenge> _challenges = [];
  String _sortType = 'All';
  bool _streakRemindersEnabled = false;
  int _gamesWon = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _updateBadges();
    _streaks = _getStreaks();
    _challenges = _getChallenges();
  }

  List<Challenge> _getChallenges() {
    return [
      Challenge(
        name: 'Challenge 1',
        description: 'Complete a puzzle in under 5 minutes.',
        status: ChallengeStatus.completed,
        reward: _badges.isNotEmpty ? _badges[0] : null,
      ),
      Challenge(
        name: 'Challenge 2',
        description: 'Complete a puzzle with no mistakes.',
        status: ChallengeStatus.completed,
        reward: _badges.length > 1 ? _badges[1] : null,
      ),
      Challenge(
        name: 'Challenge 3',
        description: 'Complete three puzzles in a row.',
        status: ChallengeStatus.completed,
        reward: _badges.length > 2 ? _badges[2] : null,
      ),
      Challenge(
        name: 'Upcoming Challenge 1',
        description: 'Complete a puzzle on hard difficulty.',
        status: ChallengeStatus.upcoming,
      ),
      Challenge(
        name: 'Upcoming Challenge 2',
        description: 'Complete a puzzle every day for a week.',
        status: ChallengeStatus.upcoming,
      ),
    ];
  }

  List<Streak> _getStreaks() {
    return [
      Streak(name: 'Streak 1', description: 'Maintain a 5-day streak', goal: 5, currentProgress: 5, achieved: true),
      Streak(name: 'Streak 2', description: 'Maintain a 10-day streak', goal: 10, currentProgress: 10, achieved: true),
      Streak(name: 'Streak 3', description: 'Maintain a 15-day streak', goal: 15, currentProgress: 15, achieved: true),
      Streak(name: 'Streak 4', description: 'Maintain a 20-day streak', goal: 20, currentProgress: 18),
      Streak(name: 'Streak 5', description: 'Maintain a 25-day streak', goal: 25, currentProgress: 18),
    ];
  }

  void _updateBadges() {
    _badges = [
      Badge(name: 'First Win', description: 'Win your first game', icon: Icons.emoji_events, isEarned: _gamesWon >= 1, unlockCriteria: 'Win 1 game', progress: _gamesWon, goal: 1),
      Badge(name: 'Beginner', description: 'Win 10 games', icon: Icons.star, isEarned: _gamesWon >= 10, unlockCriteria: 'Win 10 games', progress: _gamesWon, goal: 10),
      Badge(name: 'Intermediate', description: 'Win 50 games', icon: Icons.military_tech, isEarned: _gamesWon >= 50, unlockCriteria: 'Win 50 games', progress: _gamesWon, goal: 50),
      Badge(name: 'Advanced', description: 'Win 100 games', icon: Icons.shield, isEarned: _gamesWon >= 100, unlockCriteria: 'Win 100 games', progress: _gamesWon, goal: 100),
      Badge(name: 'Expert', description: 'Win 250 games', icon: Icons.workspace_premium, isEarned: _gamesWon >= 250, unlockCriteria: 'Win 250 games', progress: _gamesWon, goal: 250),
      Badge(name: 'Master', description: 'Win 500 games', icon: Icons.school, isEarned: _gamesWon >= 500, unlockCriteria: 'Win 500 games', progress: _gamesWon, goal: 500),
      Badge(name: 'Grandmaster', description: 'Win 1000 games', icon: Icons.bolt, isEarned: _gamesWon >= 1000, unlockCriteria: 'Win 1000 games', progress: _gamesWon, goal: 1000),
      Badge(name: 'Perfect Game', description: 'Win a game with no mistakes', icon: Icons.check_circle, isEarned: _gamesWon >= 1, unlockCriteria: 'Win 1 game with no mistakes', progress: _gamesWon, goal: 1),
      Badge(name: 'Quick Win', description: 'Win a game in under 5 minutes', icon: Icons.timer, isEarned: _gamesWon >= 1, unlockCriteria: 'Win 1 game in under 5 minutes', progress: _gamesWon, goal: 1),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Badges'),
            Tab(text: 'Streaks'),
            Tab(text: 'Challenges'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildBadgesGrid(),
              _buildStreaksList(),
              _buildChallengesList(),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _winGame,
        tooltip: 'Win a Game',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _winGame() {
    final newlyEarnedBadges = <Badge>[];
    setState(() {
      _gamesWon++;
      final oldBadges = _badges.toList();
      _updateBadges();
      for (final newBadge in _badges) {
        final oldBadge = oldBadges.firstWhere((b) => b.name == newBadge.name);
        if (newBadge.isEarned && !oldBadge.isEarned) {
          newlyEarnedBadges.add(newBadge);
        }
      }
    });

    if (newlyEarnedBadges.isNotEmpty) {
      _confettiController.play();
      for (final badge in newlyEarnedBadges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You earned the ${badge.name} badge!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildBadgesGrid() {
    final earnedBadges = _badges.where((badge) => badge.isEarned).length;
    final totalBadges = _badges.length;

    List<Badge> sortedBadges;
    switch (_sortType) {
      case 'Earned':
        sortedBadges = _badges.where((b) => b.isEarned).toList();
        break;
      case 'Locked':
        sortedBadges = _badges.where((b) => !b.isEarned).toList();
        break;
      default:
        sortedBadges = _badges;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$earnedBadges/$totalBadges Badges Earned',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              DropdownButton<String>(
                value: _sortType,
                items: <String>['All', 'Earned', 'Locked']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sortType = newValue!;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: sortedBadges.length,
            itemBuilder: (context, index) {
              return ScaleTransition(
                scale: _animation,
                child: _buildBadgeItem(sortedBadges[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeItem(Badge badge) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(badge.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.description),
                if (!badge.isEarned) ...[
                  const SizedBox(height: 16),
                  Text('Progress: ${badge.progress}/${badge.goal}'),
                  LinearProgressIndicator(
                    value: badge.progress / badge.goal,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: badge.isEarned ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              badge.icon,
              size: 40,
              color: badge.isEarned ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaksList() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Enable Streak Reminders'),
          value: _streakRemindersEnabled,
          onChanged: (bool value) {
            setState(() {
              _streakRemindersEnabled = value;
            });
            if (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Streak reminders enabled!'),
                ),
              );
            }
          },
        ),
        Expanded(
          child: FadeTransition(
            opacity: _animation,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _streaks.length,
              itemBuilder: (context, index) {
                return _buildStreakItem(_streaks[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakItem(Streak streak) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          streak.achieved ? Icons.whatshot : Icons.whatshot_outlined,
          color: streak.achieved ? Colors.orange : Colors.grey,
        ),
        title: Text(streak.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(streak.description),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: streak.currentProgress / streak.goal,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
        trailing: streak.achieved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Text('${streak.currentProgress}/${streak.goal}'),
        onTap: () => _showStreakDetails(streak),
      ),
    );
  }

  void _showStreakDetails(Streak streak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(streak.name),
        content: Text(
          '${streak.description}\n\nProgress: ${streak.currentProgress}/${streak.goal} days',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesList() {
    final completedChallenges = _challenges.where((c) => c.status == ChallengeStatus.completed).toList();
    final upcomingChallenges = _challenges.where((c) => c.status == ChallengeStatus.upcoming).toList();

    return FadeTransition(
      opacity: _animation,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (upcomingChallenges.isNotEmpty) ...[
            const Text(
              'Upcoming Challenges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingChallenges.map((challenge) => _buildChallengeItem(challenge)),
            const SizedBox(height: 24),
          ],
          if (completedChallenges.isNotEmpty) ...[
            const Text(
              'Completed Challenges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...completedChallenges.map((challenge) => _buildChallengeItem(challenge)),
          ],
        ],
      ),
    );
  }

  Widget _buildChallengeItem(Challenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          challenge.status == ChallengeStatus.completed ? Icons.military_tech : Icons.lock_clock,
          color: challenge.status == ChallengeStatus.completed ? Colors.blue : Colors.grey,
        ),
        title: Text(challenge.name),
        subtitle: Text(challenge.status == ChallengeStatus.completed ? 'Completed' : 'Upcoming'),
        trailing: challenge.status == ChallengeStatus.completed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChallengeDetailsScreen(challenge: challenge),
            ),
          );
        },
      ),
    );
  }
}
