import 'package:flutter/material.dart';
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
      },
    );
  }
}
