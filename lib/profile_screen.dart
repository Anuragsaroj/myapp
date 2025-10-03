import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/awards_screen.dart';
import 'package:myapp/settings_screen.dart';
import 'package:myapp/statistics_screen.dart';
import 'package:myapp/rules_screen.dart';
import 'package:myapp/help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Me', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuGroup([
            _buildMenuItem(Icons.emoji_events, 'Awards', context),
          ]),
          const SizedBox(height: 16),
          _buildMenuGroup([
            _buildMenuItem(Icons.bar_chart, 'Statistics', context),
            _buildMenuItem(Icons.settings, 'Settings', context),
            _buildMenuItem(Icons.menu_book, 'Rules', context),
          ]),
          const SizedBox(height: 16),
          _buildMenuGroup([
            _buildMenuItem(Icons.help_outline, 'Help', context),
            _buildMenuItem(Icons.info_outline, 'About Game', context),
            _buildMenuItem(Icons.privacy_tip_outlined, 'Privacy Rights', context),
            _buildMenuItem(Icons.verified_user_outlined, 'Privacy Preferences', context),
          ]),
          const SizedBox(height: 16),
          _buildMenuGroup([
            _buildMenuItem(Icons.calculate, 'Math Puzzle', context),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (title == 'Awards') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AwardsScreen()),
          );
        }
        if (title == 'Settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        }
        if (title == 'Statistics') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StatisticsScreen()),
          );
        }
        if (title == 'Rules') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RulesScreen()),
          );
        }
        if (title == 'Help') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpScreen()),
          );
        }
        if (title == 'About Game') {
          _showAboutDialog(context);
        }
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Sudoku'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Version: 1.0.0'),
                const SizedBox(height: 10),
                const Text('Developed by: Anurag Saroj'),
                const SizedBox(height: 10),
                const Text(
                    'This is a classic Sudoku game designed to challenge your logic and puzzle-solving skills. Enjoy a clean interface, multiple difficulty levels, and track your progress with best scores and completion stats.'),
                const SizedBox(height: 20),
                InkWell(
                  child: const Text(
                    'My GitHub Profile',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                  onTap: () => launchUrl(Uri.parse('https://github.com/Anuragsaroj')),
                ),
                const SizedBox(height: 10),
                InkWell(
                  child: const Text(
                    'User\'s GitHub Profile',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                  onTap: () => launchUrl(Uri.parse('https://github.com/my-github-profile')),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
