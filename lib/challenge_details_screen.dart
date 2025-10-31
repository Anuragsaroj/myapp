import 'package:flutter/material.dart' hide Badge;
import 'package:myapp/awards_screen.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  final Challenge challenge;

  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.description,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            if (challenge.status == ChallengeStatus.completed && challenge.reward != null) ...[
              const Text(
                'Reward',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(challenge.reward!.icon, color: Colors.amber),
                  title: Text(challenge.reward!.name),
                  subtitle: Text(challenge.reward!.description),
                ),
              ),
            ] else if (challenge.status == ChallengeStatus.upcoming) ...[
              const Text(
                'Complete this challenge to earn a reward!',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
