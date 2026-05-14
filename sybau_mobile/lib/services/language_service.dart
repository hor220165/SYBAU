import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SybauLanguage {
  de('de'),
  en('en');

  const SybauLanguage(this.code);

  final String code;

  static SybauLanguage fromCode(String? code) {
    return code == SybauLanguage.en.code ? SybauLanguage.en : SybauLanguage.de;
  }
}

class LanguageService {
  static const String _storageKey = 'sybau.language';

  static final ValueNotifier<SybauLanguage> current =
      ValueNotifier<SybauLanguage>(SybauLanguage.de);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    current.value = SybauLanguage.fromCode(prefs.getString(_storageKey));
  }

  static Future<void> setLanguage(SybauLanguage language) async {
    if (current.value == language) return;
    current.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, language.code);
  }

  static String text({required String de, required String en}) {
    return current.value == SybauLanguage.en ? en : de;
  }
}
