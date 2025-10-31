import 'package:flutter/material.dart';
import 'package:myapp/game_settings_screen.dart';
import 'package:myapp/sound_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Game Settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GameSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Sound'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SoundSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
