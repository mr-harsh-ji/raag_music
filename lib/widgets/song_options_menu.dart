import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/models/playlist_model.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/playlist_service.dart';
import 'package:raag_music/screens/Library%20Screen/album_screen.dart';

class SongOptionsMenu extends StatelessWidget {
  final SongModel song;

  const SongOptionsMenu({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
    final favoritesService = FavoritesService();
    final playlistService = PlaylistService();

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'play_next':
            await audioHandler.playNext(song);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Song will play next')),
            );
            break;
          case 'add_to_queue':
            await audioHandler.addToQueue(song);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Song added to queue')),
            );
            break;
          case 'add_to_playlist':
            _showAddToPlaylistDialog(context, playlistService);
            break;
          case 'toggle_favorite':
            await favoritesService.toggleFavorite(song.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(await favoritesService.isFavorite(song.id)
                    ? 'Added to favorites'
                    : 'Removed from favorites'),
              ),
            );
            break;
          case 'view_album':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumScreen(album: song.album ?? 'Unknown Album'),
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return {
          'play_next',
          'add_to_queue',
          'add_to_playlist',
          'toggle_favorite',
          'view_album',
        }.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(_getMenuTitle(choice, favoritesService)),
          );
        }).toList();
      },
    );
  }

  String _getMenuTitle(String choice, FavoritesService favoritesService) {
    switch (choice) {
      case 'play_next':
        return 'Play next';
      case 'add_to_queue':
        return 'Add to queue';
      case 'add_to_playlist':
        return 'Add to playlist';
      case 'toggle_favorite':
        return 'Toggle favorite';
      case 'view_album':
        return 'View album';
      default:
        return '';
    }
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
              ? const Text('No playlists available. Create one first!')
              : SizedBox(
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
                              playlist.name, song.id);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${playlist.name}'),
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
