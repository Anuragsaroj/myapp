import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/awards_screen.dart';
import 'package:myapp/avatar_selection_screen.dart';
import 'package:myapp/settings_screen.dart';
import 'package:myapp/statistics_screen.dart';
import 'package:myapp/rules_screen.dart';
import 'package:myapp/help_screen.dart';
import 'package:myapp/privacy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _gamesPlayed = 0;
  String _version = '';
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadVersion();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAvatar = prefs.getString('selectedAvatar');
    });
  }

  Future<void> _saveAvatar(String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAvatar', avatar);
    setState(() {
      _selectedAvatar = avatar;
    });
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gamesPlayed = (prefs.getInt('easyCompleted') ?? 0) +
          (prefs.getInt('mediumCompleted') ?? 0) +
          (prefs.getInt('hardCompleted') ?? 0);
    });
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

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
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 30),
          _buildGameInfoCard(context),
          const SizedBox(height: 20),
          _buildSettingsCard(context),
          const SizedBox(height: 20),
          _buildPrivacyCard(context),
          const SizedBox(height: 20),
          _buildSupportCard(context),
          const SizedBox(height: 40),
          _buildAppVersion(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AvatarSelectionScreen(
                  onAvatarSelected: (avatar) {
                    _saveAvatar(avatar);
                  },
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue,
            child: _selectedAvatar != null
                ? ClipOval(
                    child: Image.asset(
                      _selectedAvatar!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    ),
                  )
                : const Text('U', style: TextStyle(fontSize: 32, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Games Played: $_gamesPlayed',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameInfoCard(BuildContext context) {
    return _buildMenuGroup(
      'Game Info',
      [
        _buildMenuItem(Icons.emoji_events, 'Awards', context),
        _buildMenuItem(Icons.bar_chart, 'Statistics', context),
        _buildMenuItem(Icons.gavel, 'Rules', context),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return _buildMenuGroup(
      'Settings',
      [
        _buildMenuItem(Icons.settings, 'Game Settings', context),
        _buildMenuItem(Icons.palette, 'Theme', context),
        _buildMenuItem(Icons.volume_up, 'Sound', context),
      ],
    );
  }

  Widget _buildPrivacyCard(BuildContext context) {
    return _buildMenuGroup(
      'Privacy',
      [
        _buildMenuItem(Icons.privacy_tip, 'Privacy', context),
      ],
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return _buildMenuGroup(
      'Support',
      [
        _buildMenuItem(Icons.help, 'Help', context),
        _buildMenuItem(Icons.info, 'About Game', context),
        _buildMenuItem(Icons.feedback, 'Feedback', context),
      ],
    );
  }

  Widget _buildMenuGroup(String title, List<Widget> items) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (title == 'Awards') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AwardsScreen()),
          );
        }
        if (title == 'Game Settings') {
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
        if (title == 'Feedback') {
          _launchFeedbackEmail();
        }
        if (title == 'Privacy') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyScreen()),
          );
        }
      },
    );
  }

  void _launchFeedbackEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {
        'subject': 'Sudoku App Feedback',
      },
    );

    if (!await launchUrl(emailLaunchUri)) {
      // Handle the error here, e.g., by showing a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client.'),
          ),
        );
      }
    }
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
                Text('Version: $_version'),
                const SizedBox(height: 10),
                const Text('Developed by: Gemini'),
                const SizedBox(height: 10),
                const Text(
                    'This is a classic Sudoku game designed to challenge your logic and puzzle-solving skills. Enjoy a clean interface, multiple difficulty levels, and track your progress with best scores and completion stats.'),
                const SizedBox(height: 20),
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

  Widget _buildAppVersion() {
    return Text(
      'Version $_version',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.grey),
    );
  }
}
