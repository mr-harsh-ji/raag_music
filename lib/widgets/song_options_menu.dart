import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/playlist_service.dart';
import 'package:raag_music/screens/Library%20Screen/album_screen.dart';
import 'package:raag_music/locals/string_extension.dart';

enum SongOption {
  playNext,
  addToQueue,
  addToPlaylist,
  toggleFavorite,
  viewAlbum,
}

class SongOptionsMenu extends StatefulWidget {
  final SongModel song;

  const SongOptionsMenu({super.key, required this.song});

  @override
  State<SongOptionsMenu> createState() => _SongOptionsMenuState();
}

class _SongOptionsMenuState extends State<SongOptionsMenu> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.song.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  String _getMenuTitle(SongOption option) {
    switch (option) {
      case SongOption.playNext:
        return 'Play next';
      case SongOption.addToQueue:
        return 'Add to queue';
      case SongOption.addToPlaylist:
        return 'Add to playlist';
      case SongOption.toggleFavorite:
        return _isFavorite ? 'Remove from favorites' : 'Add to favorites';
      case SongOption.viewAlbum:
        return 'View album';
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
    final playlistService = PlaylistService();

    return PopupMenuButton<SongOption>(
      onSelected: (SongOption result) async {
        switch (result) {
          case SongOption.playNext:
            await audioHandler.playNext(widget.song);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Song will play next')),
            );
            break;
          case SongOption.addToQueue:
            await audioHandler.addToQueue(widget.song);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Song added to queue')),
            );
            break;
          case SongOption.addToPlaylist:
            _showAddToPlaylistDialog(context, playlistService);
            break;
          case SongOption.toggleFavorite:
            await _favoritesService.toggleFavorite(widget.song.id);
            setState(() {
              _isFavorite = !_isFavorite;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isFavorite
                    ? 'Added to favorites'
                    : 'Removed from favorites'),
              ),
            );
            break;
          case SongOption.viewAlbum:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AlbumScreen(album: widget.song.album ?? "Unknown Album"),
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SongOption>>[
        ...SongOption.values.map((option) {
          return PopupMenuItem<SongOption>(
            value: option,
            child: Text(_getMenuTitle(option)),
          );
        })
      ],
    );
  }

  void _showAddToPlaylistDialog(
      BuildContext context, PlaylistService playlistService) async {
    final playlists = await playlistService.getPlaylists();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: playlists.isEmpty
              ? const Text("No playlist found, create one in the library tab")
              : Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: playlists.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      final playlist = playlists[index];
                      return ListTile(
                        title: Text(playlist.name),
                        onTap: () async {
                          await playlistService.addSongToPlaylist(
                              playlist.name, widget.song.id);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Added to playlist: ${playlist.name}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
