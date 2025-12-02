import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentlyPlayedService {
  static const _key = 'recentlyPlayed';
  static const _maxSongs = 20;

  Future<void> addSong(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentSongs = prefs.getStringList(_key) ?? [];
    
    // Remove if it already exists to move it to the top
    recentSongs.remove(songId.toString());
    
    // Add to the top of the list
    recentSongs.insert(0, songId.toString());

    // Trim the list if it's too long
    if (recentSongs.length > _maxSongs) {
      recentSongs = recentSongs.sublist(0, _maxSongs);
    }

    await prefs.setStringList(_key, recentSongs);
  }

  Future<List<int>> getRecentSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final recentSongsStrings = prefs.getStringList(_key) ?? [];
    return recentSongsStrings.map((id) => int.parse(id)).toList();
  }
}
