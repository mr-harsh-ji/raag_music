import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/models/playlist_model.dart';
import 'package:raag_music/services/playlist_service.dart';

import '../player_screen.dart';
import 'all_songs_screen.dart';

class PlaylistSongsScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistSongsScreen({super.key, required this.playlist});

  @override
  State<PlaylistSongsScreen> createState() => _PlaylistSongsScreenState();
}

class _PlaylistSongsScreenState extends State<PlaylistSongsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _playlistSongs = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();
  }

  void _loadPlaylistSongs() async {
    final allSongs = await _audioQuery.querySongs();
    final playlistSongIds = await _playlistService.getPlaylistSongs(widget.playlist.name);
    setState(() {
      _playlistSongs = allSongs
          .where((song) => playlistSongIds.contains(song.id))
          .toList();
    });
  }

  void _removeSongFromPlaylist(int songId) {
    _playlistService
        .removeSongFromPlaylist(widget.playlist.name, songId)
        .then((_) {
      _loadPlaylistSongs();
    });
  }

  void _navigateToAddSongs() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllSongsScreen(
          title: 'Add Songs to ${widget.playlist.name}',
          isSelectionMode: true,
        ),
      ),
    );

    if (result is List<int>) {
      for (final songId in result) {
        await _playlistService.addSongToPlaylist(widget.playlist.name, songId);
      }
      _loadPlaylistSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness == Brightness.dark
            ? const LinearGradient(
                colors: [Color(0xFF282828), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF2F2F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.playlist.name, style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
              onPressed: _navigateToAddSongs,
            ),
          ],
        ),
        body: _playlistSongs.isEmpty
            ? Center(
                child: Text('No songs in this playlist.',
                    style: Theme.of(context).textTheme.bodyLarge))
            : ListView.builder(
                itemCount: _playlistSongs.length,
                itemBuilder: (context, index) {
                  final song = _playlistSongs[index];
                  return ListTile(
                    title: Text(song.title, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(song.artist ?? 'Unknown Artist', style: Theme.of(context).textTheme.bodySmall),
                    trailing: IconButton(
                      icon: Icon(Icons.remove, color: Theme.of(context).iconTheme.color),
                      onPressed: () => _removeSongFromPlaylist(song.id),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(song: song),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
