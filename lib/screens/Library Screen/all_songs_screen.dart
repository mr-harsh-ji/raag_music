import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/widgets/song_options_menu.dart';

import '../../locals/string_extension.dart';
import '../player_screen.dart';

class AllSongsScreen extends StatefulWidget {
  final List<SongModel>? songs;
  final String title; // this is now a KEY
  final bool isFavorites;
  final bool isSelectionMode;

  const AllSongsScreen({
    super.key,
    this.songs,
    this.title = "all_songs",
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
    if (mounted) setState(() => _isLoading = true);
    _songs = await _audioQuery.querySongs();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFavoriteSongs() async {
    if (mounted) setState(() => _isLoading = true);

    final favoriteIds = await _favoritesService.getFavoriteSongIds();
    if (favoriteIds.isNotEmpty) {
      final allSongs = await _audioQuery.querySongs();
      _songs = allSongs.where((s) => favoriteIds.contains(s.id)).toList();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _playAll() async {
    if (_songs.isNotEmpty) {
      await _audioHandler.playSongs(_songs, 0);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title.tr,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          if (!widget.isSelectionMode)
            TextButton(
              onPressed: _playAll,
              child: Text(
                "play_all".tr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          if (widget.isSelectionMode)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _selectedSongIds.toList()),
              child: Text(
                "done".tr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? Center(
        child: Text(
          "no_items_found"
              .tr
              .replaceAll(
            "{title}",
            widget.title.tr,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      )
          : ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          final isSelected =
          _selectedSongIds.contains(song.id);

          return ListTile(
            leading: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkBorder:
              BorderRadius.circular(4),
              nullArtworkWidget: Icon(
                Icons.music_note,
                color: Theme.of(context)
                    .iconTheme
                    .color,
              ),
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist ??
                  "unknown_artist".tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: widget.isSelectionMode
                ? Checkbox(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  v!
                      ? _selectedSongIds
                      .add(song.id)
                      : _selectedSongIds
                      .remove(song.id);
                });
              },
            )
                : SongOptionsMenu(song: song),
            onTap: () async {
              if (widget.isSelectionMode) {
                setState(() {
                  isSelected
                      ? _selectedSongIds
                      .remove(song.id)
                      : _selectedSongIds
                      .add(song.id);
                });
              } else {
                await _audioHandler.playSongs(
                    _songs, index);
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const PlayerScreen(),
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
