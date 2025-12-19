import 'package:shared_preferences/shared_preferences.dart';

class LyricsService {
  Future<String?> getLyrics(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lyrics_$songId');
  }

  Future<void> saveLyrics(int songId, String lyrics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lyrics_$songId', lyrics);
  }
}
