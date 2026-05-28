import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SybauThemeMode { dark, light }

class SybauThemeController {
  static const String _storageKey = 'sybau_theme_mode';

  static final ValueNotifier<SybauThemeMode> mode =
      ValueNotifier<SybauThemeMode>(SybauThemeMode.dark);

  static bool get isLight => mode.value == SybauThemeMode.light;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_storageKey);
    mode.value = storedMode == 'light'
        ? SybauThemeMode.light
        : SybauThemeMode.dark;
  }

  static Future<void> setMode(SybauThemeMode nextMode) async {
    if (mode.value == nextMode) return;
    mode.value = nextMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      nextMode == SybauThemeMode.light ? 'light' : 'dark',
    );
  }
}
