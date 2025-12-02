import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/audio_handler.dart';

import '../player_screen.dart';

class AllSongsScreen extends StatefulWidget {
  final List<SongModel>? songs;
  final String title;
  final bool isFavorites;

  const AllSongsScreen({
    super.key,
    this.songs,
    this.title = "All Songs",
    this.isFavorites = false,
  });

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  final _audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
  final FavoritesService _favoritesService = FavoritesService();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFavorites) {
      _loadFavoriteSongs();
    } else {
      _songs = List.from(widget.songs ?? []);
    }
  }

  Future<void> _loadFavoriteSongs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final favoriteIds = await _favoritesService.getFavoriteSongIds();
    if (favoriteIds.isNotEmpty) {
      final allSongs = await _audioQuery.querySongs();
      final favoriteSongs =
          allSongs.where((song) => favoriteIds.contains(song.id)).toList();
      if (mounted) {
        setState(() {
          _songs = favoriteSongs;
        });
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playAll() {
    if (_songs.isNotEmpty) {
      _audioHandler.playSongs(_songs, 0);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            song: _songs[0],
            playlistSource: widget.isFavorites ? 'Favorites' : null,
          ),
        ),
      );
    }
  }

  void _removeFavorite(int songId) async {
    await _favoritesService.toggleFavorite(songId);
    setState(() {
      _songs.removeWhere((song) => song.id == songId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282828),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title),
        actions: [
          if (widget.isFavorites)
            TextButton(
              onPressed: _playAll,
              child: const Text('Play All', style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Text(
                    'No ${widget.title.toLowerCase()} songs found.',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return ListTile(
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.circular(4.0),
                        nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist ?? "Unknown Artist",
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: widget.isFavorites
                          ? IconButton(
                              icon: const Icon(Icons.favorite, color: Color(0xffF8AB02)),
                              onPressed: () => _removeFavorite(song.id),
                            )
                          : null,
                      onTap: () {
                        _audioHandler.playSongs(_songs, index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerScreen(
                              song: song,
                              playlistSource: widget.isFavorites ? 'Favorites' : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
