import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/widgets/song_options_menu.dart';

import '../player_screen.dart';

class AllSongsScreen extends StatefulWidget {
  final List<SongModel>? songs;
  final String title;
  final bool isFavorites;
  final bool isSelectionMode;

  const AllSongsScreen({
    super.key,
    this.songs,
    this.title = "All Songs",
    this.isFavorites = false,
    this.isSelectionMode = false,
  });

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  final _audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
  final FavoritesService _favoritesService = FavoritesService();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Set<int> _selectedSongIds = {};
  List<SongModel> _songs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFavorites) {
      _loadFavoriteSongs();
    } else if (widget.songs != null) {
      _songs = List.from(widget.songs!);
    } else {
      _loadAllSongs();
    }
  }

  Future<void> _loadAllSongs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    _songs = await _audioQuery.querySongs();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          if (widget.isFavorites)
            TextButton(
              onPressed: _playAll,
              child: Text('Play All', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          if (widget.isSelectionMode)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedSongIds.toList()),
              child: Text('Done', style: TextStyle(color: Theme.of(context).primaryColor)),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Text(
                    'No ${widget.title.toLowerCase()} songs found.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final isSelected = _selectedSongIds.contains(song.id);
                    return ListTile(
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.circular(4.0),
                        nullArtworkWidget: Icon(Icons.music_note, color: Theme.of(context).iconTheme.color),
                      ),
                      title: Text(
                        song.title,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist ?? "Unknown Artist",
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: widget.isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value!) {
                                    _selectedSongIds.add(song.id);
                                  } else {
                                    _selectedSongIds.remove(song.id);
                                  }
                                });
                              },
                            )
                          : SongOptionsMenu(song: song),
                      onTap: () {
                        if (widget.isSelectionMode) {
                          setState(() {
                            if (isSelected) {
                              _selectedSongIds.remove(song.id);
                            } else {
                              _selectedSongIds.add(song.id);
                            }
                          });
                        } else {
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
                        }
                      },
                    );
                  },
                ),
    );
  }
}
