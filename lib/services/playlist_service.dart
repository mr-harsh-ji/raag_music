import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';

class PlaylistService {
  static const String _playlistsKey = 'playlists';

  Future<List<Playlist>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getStringList(_playlistsKey) ?? [];
    final playlists = <Playlist>[];
    for (final jsonString in playlistsJson) {
      try {
        final playlist = Playlist.fromMap(jsonDecode(jsonString));
        playlists.add(playlist);
      } catch (e) {
        // Safely ignore entries that fail to parse
        print('Error decoding playlist: $e');
      }
    }
    return playlists;
  }

  Future<void> createPlaylist(Playlist playlist) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    playlists.add(playlist);
    await _savePlaylists(prefs, playlists);
  }

  Future<void> updatePlaylist(Playlist updatedPlaylist) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.name == updatedPlaylist.name);
    if (index != -1) {
      playlists[index] = updatedPlaylist;
      await _savePlaylists(prefs, playlists);
    }
  }

  Future<void> deletePlaylist(String playlistName) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.name == playlistName);
    await _savePlaylists(prefs, playlists);
  }

  Future<void> addSongToPlaylist(String playlistName, int songId) async {
    final playlists = await getPlaylists();
    final playlist = playlists.firstWhere((p) => p.name == playlistName);
    if (!playlist.songIds.contains(songId)) {
      playlist.songIds.add(songId);
      await updatePlaylist(playlist);
    }
  }

  Future<void> removeSongFromPlaylist(String playlistName, int songId) async {
    final playlists = await getPlaylists();
    final playlist = playlists.firstWhere((p) => p.name == playlistName);
    if (playlist.songIds.contains(songId)) {
      playlist.songIds.remove(songId);
      await updatePlaylist(playlist);
    }
  }

  Future<List<int>> getPlaylistSongs(String playlistName) async {
    final playlists = await getPlaylists();
    final playlist = playlists.firstWhere((p) => p.name == playlistName);
    return playlist.songIds;
  }

  Future<void> _savePlaylists(
      SharedPreferences prefs, List<Playlist> playlists) async {
    final playlistsJson =
        playlists.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_playlistsKey, playlistsJson);
  }
}
