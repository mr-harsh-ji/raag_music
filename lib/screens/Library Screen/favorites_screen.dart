import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/widgets/song_options_menu.dart';

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
          title: Text('Favorites', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _playAll,
              child: Text('Play All', style: TextStyle(color: Theme.of(context).primaryColor)),
            )
          ],
        ),
        body: _favoriteSongs.isEmpty
            ? Center(
                child: Text(
                  'No favorite songs yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
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
                      nullArtworkWidget: Icon(
                        Icons.music_note,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      song.artist ?? 'Unknown Artist',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: SongOptionsMenu(song: song),
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
