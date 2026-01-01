import 'package:flutter/material.dart';
import 'package:raag_music/locals/lang/en.dart';
import 'package:raag_music/locals/lang/hi.dart';
import 'package:raag_music/locals/lang/ur.dart';

class LanguageProvider with ChangeNotifier {
  Locale _appLocale = const Locale('en');
  Map<String, String> _localizedStrings = en;

  final Map<String, Map<String, String>> _languages = {
    'en': en,
    'hi': hi,
    'ur': ur,
  };

  Locale get appLocale => _appLocale;

  void changeLanguage(Locale newLocale) {
    if (_appLocale == newLocale) {
      return;
    }
    _appLocale = newLocale;
    _localizedStrings = _languages[newLocale.languageCode] ?? en;
    notifyListeners();
  }

  String getTranslatedString(String key) {
    return _localizedStrings[key] ?? key;
  }
}
