
import 'package:flutter/material.dart';
import 'package:myapp/models/game_difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int easyToMediumUnlock = 5;
const int mediumToHardUnlock = 5;
const int hardToExpertUnlock = 5;

class DifficultyScreen extends StatefulWidget {
  final VoidCallback? onScreenClosed;
  const DifficultyScreen({super.key, this.onScreenClosed});

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
            _buildOption(
              context,
              'Easy',
              GameDifficulty.easy,
              true,
              _easyCompleted,
              easyToMediumUnlock,
            ),
            _buildDivider(),
            _buildOption(
              context,
              'Medium',
              GameDifficulty.medium,
              _isMediumUnlocked,
              _mediumCompleted,
              mediumToHardUnlock,
            ),
            _buildDivider(),
            _buildOption(
              context,
              'Hard',
              GameDifficulty.hard,
              _isHardUnlocked,
              _hardCompleted,
              hardToExpertUnlock,
            ),
            _buildDivider(),
            _buildOption(
              context,
              'Expert',
              GameDifficulty.expert,
              _isExpertUnlocked,
              0,
              0,
            ),
            _buildDivider(),
            _buildOption(context, 'Restart', null, true, 0, 0, isRestart: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    GameDifficulty? difficulty,
    bool isUnlocked,
    int completedCount,
    int requiredToUnlockNext, {
    bool isRestart = false,
  }) {
    final bool isPlayable = isUnlocked || isRestart;
    final Color textColor = isRestart
        ? Colors.blue
        : (isPlayable ? Theme.of(context).textTheme.bodyLarge!.color! : Colors.grey);
    final Color iconColor = isPlayable ? Theme.of(context).colorScheme.primary : Colors.grey;

    String? unlockText;
    if (!isUnlocked && !isRestart) {
      if (difficulty == GameDifficulty.medium) {
        unlockText = 'Complete $easyToMediumUnlock Easy games to unlock';
      } else if (difficulty == GameDifficulty.hard) {
        unlockText = 'Complete $mediumToHardUnlock Medium games to unlock';
      } else if (difficulty == GameDifficulty.expert) {
        unlockText = 'Complete $hardToExpertUnlock Hard games to unlock';
      }
    }

    return InkWell(
      onTap: isPlayable
          ? () {
              if (isRestart) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop(difficulty);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (!isPlayable && !isRestart)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.lock_outline, size: 20, color: iconColor),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (unlockText != null)
                      Text(
                        unlockText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (isUnlocked && !isRestart && requiredToUnlockNext > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$completedCount / $requiredToUnlockNext Completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Colors.grey,
    );
  }
}
