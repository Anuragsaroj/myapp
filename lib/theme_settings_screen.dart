import 'package:flutter/material.dart';
import 'package:myapp/themes.dart';
import 'package:provider/provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: ListView(
        children: [
          Consumer<ThemeManager>(
            builder: (context, themeManager, child) {
              return SegmentedButton<ThemeMode>(
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                ],
                selected: <ThemeMode>{themeManager.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  themeManager.setTheme(newSelection.first);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
