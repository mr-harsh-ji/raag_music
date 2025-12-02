import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/services/favorites_service.dart';

import '../../My App Themes/app_theme.dart';
import '../player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final MyAudioHandler _audioHandler =
      GetIt.instance<AudioHandler>() as MyAudioHandler;
  List<SongModel> _favoriteSongs = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteSongs();
  }

  void _loadFavoriteSongs() async {
    final favoriteIds = await _favoritesService.getFavoriteSongIds();
    if (favoriteIds.isNotEmpty) {
      final allSongs = await _audioQuery.querySongs();
      final favoriteSongs =
          allSongs.where((song) => favoriteIds.contains(song.id)).toList();
      if (mounted) {
        setState(() {
          _favoriteSongs = favoriteSongs;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _favoriteSongs = [];
        });
      }
    }
  }

  void _playAll() {
    if (_favoriteSongs.isNotEmpty) {
      _audioHandler.playSongs(_favoriteSongs, 0);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            song: _favoriteSongs[0],
            playlistSource: 'Favorites',
          ),
        ),
      );
    }
  }

  void _removeFavorite(int songId) async {
    await _favoritesService.toggleFavorite(songId);
    _loadFavoriteSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Favorites', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _playAll,
              child: const Text('Play All', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
        body: _favoriteSongs.isEmpty
            ? const Center(
                child: Text(
                  'No favorite songs yet.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: _favoriteSongs.length,
                itemBuilder: (context, index) {
                  final song = _favoriteSongs[index];
                  return ListTile(
                    leading: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      song.artist ?? 'Unknown Artist',
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Color(0xffF8AB02)),
                      onPressed: () => _removeFavorite(song.id),
                    ),
                    onTap: () {
                      _audioHandler.playSongs(_favoriteSongs, index);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            song: song,
                            playlistSource: 'Favorites',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
