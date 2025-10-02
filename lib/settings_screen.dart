import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final theme = prefs.getString('theme') ?? 'system';
      _themeMode = ThemeMode.values.firstWhere((e) => e.name == theme, orElse: () => ThemeMode.system);
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General'),
          SwitchListTile(
            title: const Text('Sound'),
            secondary: const Icon(Icons.volume_up),
            value: _soundEnabled,
            onChanged: (bool value) {
              setState(() {
                _soundEnabled = value;
              });
              _updateSetting('sound_enabled', value);
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            secondary: const Icon(Icons.notifications),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _updateSetting('notifications_enabled', value);
            },
          ),
          _buildSectionHeader('Theme'),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                setState(() {
                  _themeMode = value;
                });
                _updateSetting('theme', value.name);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                setState(() {
                  _themeMode = value;
                });
                _updateSetting('theme', value.name);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                setState(() {
                  _themeMode = value;
                });
                _updateSetting('theme', value.name);
              }
            },
          ),
          _buildSectionHeader('Language'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text('Español'),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('Français'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  _updateSetting('language', value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
