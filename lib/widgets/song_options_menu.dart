import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/services/blacklist_service.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/playlist_service.dart';
import 'package:raag_music/screens/Library Screen/album_screen.dart';
import 'package:raag_music/locals/string_extension.dart';

enum SongOption {
  playNext,
  addToQueue,
  addToPlaylist,
  toggleFavorite,
  viewAlbum,
  removeFromPlaylist,
  removeFromApp,
}

class SongOptionsMenu extends StatefulWidget {
  final SongModel song;
  final String? playlistName;
  final VoidCallback? onDeleted;

  const SongOptionsMenu({
    super.key,
    required this.song,
    this.playlistName,
    this.onDeleted,
  });

  @override
  State<SongOptionsMenu> createState() => _SongOptionsMenuState();
}

class _SongOptionsMenuState extends State<SongOptionsMenu> {
  final FavoritesService _favoritesService = FavoritesService();
  final BlacklistService _blacklistService = BlacklistService();
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
        return 'play_next'.tr;
      case SongOption.addToQueue:
        return 'add_to_queue'.tr;
      case SongOption.addToPlaylist:
        return 'add_to_playlist'.tr;
      case SongOption.toggleFavorite:
        return 'toggle_favorite'.tr;
      case SongOption.viewAlbum:
        return 'view_album'.tr;
      case SongOption.removeFromPlaylist:
        return 'remove_from_playlist'.tr;
      case SongOption.removeFromApp:
        return 'delete'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
    final playlistService = PlaylistService();

    return PopupMenuButton<SongOption>(
      iconColor: Colors.white,
      onSelected: (SongOption result) async {
        switch (result) {
          case SongOption.playNext:
            await audioHandler.playNext(widget.song);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('song_play_next'.tr)),
            );
            break;
          case SongOption.addToQueue:
            await audioHandler.addToQueue(widget.song);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('song_added_queue'.tr)),
            );
            break;
          case SongOption.addToPlaylist:
            _showAddToPlaylistDialog(context, playlistService);
            break;
          case SongOption.toggleFavorite:
            await _favoritesService.toggleFavorite(widget.song.id);
            final isFav = await _favoritesService.isFavorite(widget.song.id);
            if (!mounted) return;
            setState(() {
              _isFavorite = isFav;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isFavorite
                    ? 'added_favorites'.tr
                    : 'removed_favorites'.tr),
              ),
            );
            break;
          case SongOption.viewAlbum:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AlbumScreen(album: widget.song.album ?? "unknown_album".tr),
              ),
            );
            break;
          case SongOption.removeFromPlaylist:
            if (widget.playlistName != null) {
              await playlistService.removeSongFromPlaylist(
                  widget.playlistName!, widget.song.id);
              if (widget.onDeleted != null) widget.onDeleted!();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('song_removed'.tr)),
              );
            }
            break;
          case SongOption.removeFromApp:
            _showHideConfirmDialog(context, audioHandler);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final options = SongOption.values.toList();
        if (widget.playlistName == null) {
          options.remove(SongOption.removeFromPlaylist);
        }
        return options.map((option) {
          return PopupMenuItem<SongOption>(
            value: option,
            child: Text(_getMenuTitle(option)),
          );
        }).toList();
      },
    );
  }

  void _showHideConfirmDialog(BuildContext context, MyAudioHandler audioHandler) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('delete'.tr),
          content: Text('delete_confirm'.tr),
          actions: [
            TextButton(
              child: Text('cancel'.tr),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
              onPressed: () async {
                await _blacklistService.hideSong(widget.song.id);
                audioHandler.clearCache();
                if (widget.onDeleted != null) widget.onDeleted!();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('song_deleted'.tr)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddToPlaylistDialog(
      BuildContext context, PlaylistService playlistService) async {
    final playlists = await playlistService.getPlaylists();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('add_to_playlist'.tr),
          content: playlists.isEmpty
              ? Text("no_playlist".tr)
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
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${widget.song.title} ${'added_to_playlist'.tr} ${playlist.name}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          actions: <Widget>[
            TextButton(
              child: Text('close'.tr),
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
