import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  Color primaryColor = const Color(0xFF282828);
  Color accentColor = const Color(0xffF8AB02);
  Color textColor = Colors.white;

  ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor.withOpacity(0.7)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
      ),
    ),
  );

  void changePrimary(Color color) {
    primaryColor = color;
    notifyListeners();
  }

  void changeAccent(Color color) {
    accentColor = color;
    notifyListeners();
  }

  void changeText(Color color) {
    textColor = color;
    notifyListeners();
  }
}
