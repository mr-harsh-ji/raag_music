import 'package:shared_preferences/shared_preferences.dart';

class BlacklistService {
  static const String _blacklistKey = 'blacklisted_songs';

  Future<void> hideSong(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final blacklist = prefs.getStringList(_blacklistKey) ?? [];
    if (!blacklist.contains(songId.toString())) {
      blacklist.add(songId.toString());
      await prefs.setStringList(_blacklistKey, blacklist);
    }
  }

  Future<List<int>> getBlacklistedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final blacklist = prefs.getStringList(_blacklistKey) ?? [];
    return blacklist.map((id) => int.parse(id)).toList();
  }

  Future<void> restoreSong(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final blacklist = prefs.getStringList(_blacklistKey) ?? [];
    blacklist.remove(songId.toString());
    await prefs.setStringList(_blacklistKey, blacklist);
  }
}
