import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere((e) => e.name == theme, orElse: () => ThemeMode.system);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', themeMode.name);
  }
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1E88E5),
      onPrimary: Colors.white,
      surface: Color(0xFFF3F6F9),
      onSurface: Color(0xFF37474F),
      onSurfaceVariant: Color(0xFF78909C),
      error: Color(0xFFE53935),
    ),
    scaffoldBackgroundColor: const Color(0xFFF3F6F9),
    dividerColor: const Color(0xFFD3DCE6),
    textTheme: _textTheme,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF42A5F5),
      onPrimary: Colors.black,
      surface: Color(0xFF121212),
      onSurface: Color(0xFFE0E0E0),
      onSurfaceVariant: Color(0xFF9E9E9E),
      error: Color(0xFFEF5350),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    dividerColor: const Color(0xFF424242),
    textTheme: _textTheme,
  );

  static const TextTheme _textTheme = TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
  );
}

// App Colors (for reference, now driven by theme)
const Color primaryColor = Color(0xFF1E88E5);
const Color selectedCellColor = Color(0xFF42A5F5);
const Color highlightedCellColor = Color(0xFFE3F2FD);
const Color givenNumberColor = Color(0xFF37474F);
const Color userNumberColor = Color(0xFF1E88E5);
const Color conflictColor = Color(0xFFE53935);
const Color pencilMarkColor = Color(0xFF78909C);
const Color buttonIconColor = Color(0xFF546E7A);
const Color buttonTextColor = Color(0xFF546E7A);
const Color gridBackgroundColor = Colors.white;
const Color gridLineColor = Color(0xFFD3DCE6);
const Color thickGridLineColor = Color(0xFFB0BEC5);

// Text Styles
const TextStyle numberTextStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w500,
);

const TextStyle pencilMarkTextStyle = TextStyle(
  fontSize: 10,
  color: pencilMarkColor,
  fontWeight: FontWeight.w500,
);
