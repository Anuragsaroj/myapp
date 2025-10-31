
import 'package:flutter/material.dart';
import 'package:myapp/models/game_difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int easyToMediumUnlock = 1;
const int mediumToHardUnlock = 1;
const int hardToExpertUnlock = 1;

class DifficultyScreen extends StatefulWidget {
  final VoidCallback? onScreenClosed;
  final GameDifficulty? currentDifficulty;
  const DifficultyScreen({super.key, this.onScreenClosed, this.currentDifficulty});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  int _easyCompleted = 0;
  int _mediumCompleted = 0;
  int _hardCompleted = 0;

  bool _isMediumUnlocked = false;
  bool _isHardUnlocked = false;
  bool _isExpertUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    widget.onScreenClosed?.call();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _easyCompleted = prefs.getInt('easyCompleted') ?? 0;
      _mediumCompleted = prefs.getInt('mediumCompleted') ?? 0;
      _hardCompleted = prefs.getInt('hardCompleted') ?? 0;
      _updateUnlockStatus();
    });
  }

  void _updateUnlockStatus() {
    _isMediumUnlocked = _easyCompleted >= easyToMediumUnlock;
    _isHardUnlocked = _mediumCompleted >= mediumToHardUnlock;
    _isExpertUnlocked = _hardCompleted >= hardToExpertUnlock;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Select Difficulty',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _buildOption(
              context,
              'Easy',
              'Beginner',
              GameDifficulty.easy,
              true,
              _easyCompleted,
              easyToMediumUnlock,
            ),
            _buildOption(
              context,
              'Medium',
              'Challenger',
              GameDifficulty.medium,
              _isMediumUnlocked,
              _mediumCompleted,
              mediumToHardUnlock,
            ),
            _buildOption(
              context,
              'Hard',
              'Expert',
              GameDifficulty.hard,
              _isHardUnlocked,
              _hardCompleted,
              hardToExpertUnlock,
            ),
            _buildOption(
              context,
              'Expert',
              'Master',
              GameDifficulty.expert,
              _isExpertUnlocked,
              0,
              0,
            ),
            const Divider(),
            _buildRestartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    String description,
    GameDifficulty? difficulty,
    bool isUnlocked,
    int completedCount,
    int requiredToUnlockNext,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = widget.currentDifficulty == difficulty;

    String? unlockMessage;
    if (!isUnlocked) {
      if (difficulty == GameDifficulty.medium) {
        unlockMessage = 'Complete $easyToMediumUnlock Easy game to unlock';
      } else if (difficulty == GameDifficulty.hard) {
        unlockMessage = 'Complete $mediumToHardUnlock Medium game to unlock';
      } else if (difficulty == GameDifficulty.expert) {
        unlockMessage = 'Complete $hardToExpertUnlock Hard game to unlock';
      }
    }

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withAlpha(51) : (isUnlocked ? colorScheme.primary.withAlpha(26) : Colors.transparent),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? colorScheme.primary : (isUnlocked ? colorScheme.primary : Colors.grey.withAlpha(128)),
            width: isSelected ? 3.0 : 2.0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: isUnlocked
              ? Icon(Icons.check_circle, color: colorScheme.primary)
              : const Icon(Icons.lock, color: Colors.grey),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? theme.textTheme.bodyLarge?.color : Colors.grey,
            ),
          ),
          subtitle: Text(description),
          trailing: isUnlocked
              ? (requiredToUnlockNext > 0
                  ? Text(
                      '$completedCount/$requiredToUnlockNext',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    )
                  : null)
              : (unlockMessage != null
                  ? IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.grey),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(unlockMessage!)),
                        );
                      },
                    )
                  : null),
          onTap: isUnlocked ? () => Navigator.of(context).pop(difficulty) : null,
        ),
      ),
    );
  }

  Widget _buildRestartButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.refresh),
      title: const Text('Restart'),
      onTap: () => Navigator.of(context).pop(),
    );
  }
}
