import 'package:flutter/material.dart';

class GameSettingsScreen extends StatelessWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settings'),
      ),
      body: ListView(
        children: const [
          // TODO: Add game-specific settings here
          ListTile(
            title: Text('Difficulty'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}
