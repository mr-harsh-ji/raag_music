import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _favoritesKey = 'favorite_songs';

  Future<List<int>> getFavoriteSongIds() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_favoritesKey) ?? [];
    return favoriteIds.map((id) => int.parse(id)).toList();
  }

  Future<void> _saveFavoriteSongIds(List<int> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIdStrings = favoriteIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_favoritesKey, favoriteIdStrings);
  }

  Future<bool> isFavorite(int songId) async {
    final favoriteIds = await getFavoriteSongIds();
    return favoriteIds.contains(songId);
  }

  Future<void> toggleFavorite(int songId) async {
    final favoriteIds = await getFavoriteSongIds();
    if (favoriteIds.contains(songId)) {
      favoriteIds.remove(songId);
    } else {
      favoriteIds.add(songId);
    }
    await _saveFavoriteSongIds(favoriteIds);
  }
}
