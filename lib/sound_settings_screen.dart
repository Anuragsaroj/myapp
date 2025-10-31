import 'package:flutter/material.dart';
import 'package:myapp/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSoundSettings();
  }

  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _updateSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound'),
      ),
      body: SwitchListTile(
        title: const Text('Sound'),
        secondary: const Icon(Icons.volume_up),
        value: _soundEnabled,
        onChanged: (bool value) {
          setState(() {
            _soundEnabled = value;
          });
          _updateSoundSetting(value);
          if (value) {
            SoundService.playTapSound();
          }
        },
      ),
    );
  }
}
