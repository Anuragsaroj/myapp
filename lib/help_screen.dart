import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _showReportProblemDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report a Problem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Please describe the issue you are facing. Our team will look into it as soon as possible.'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Describe your issue here...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you would typically send the report to a server
                // or a logging service.
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const ExpansionTile(
            leading: Icon(Icons.help_outline),
            title: Text('How is the score calculated?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Your score is a combination of a base completion score, a time bonus, and a difficulty multiplier. The faster you complete the puzzle on higher difficulties, the better your score!',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            leading: Icon(Icons.help_outline),
            title: Text('What happens if I make a mistake?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You are allowed up to 3 mistakes. If you make a third mistake, the game ends. You will have the option to try again with a \'Second Chance\' or start a new game.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            leading: Icon(Icons.help_outline),
            title: Text('How do daily challenges work?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'A new daily challenge is available every 24 hours. Completing them earns you unique trophies and helps you build up your completion streak.',
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showReportProblemDialog(context),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report a Problem'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
