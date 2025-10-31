import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _analyticsConsent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Data Collection Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We collect anonymous data to improve your gameplay experience. This includes gameplay statistics and your preferences.',
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('User Consent'),
            subtitle: const Text('Allow analytics and personalized features'),
            value: _analyticsConsent,
            onChanged: (value) {
              setState(() {
                _analyticsConsent = value;
              });
            },
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Delete My Data'),
            subtitle: const Text('Clear personal data and reset progress'),
            onTap: () {
              // TODO: Implement data deletion
            },
          ),
          ListTile(
            title: const Text('Export My Data'),
            subtitle: const Text('Download your game history and stats'),
            onTap: () {
              // TODO: Implement data export
            },
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Privacy Policy'),
            subtitle: const Text('Read our full privacy policy'),
            onTap: () {
              // TODO: Link to privacy policy
            },
          ),
        ],
      ),
    );
  }
}
