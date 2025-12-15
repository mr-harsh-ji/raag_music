import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:get_it/get_it.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/widgets/song_options_menu.dart';
import '../player_screen.dart';

class AlbumScreen extends StatefulWidget {
  final String album;

  const AlbumScreen({super.key, required this.album});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _albumSongs = [];
  final _audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;

  @override
  void initState() {
    super.initState();
    _loadAlbumSongs();
  }

  void _loadAlbumSongs() async {
    final allSongs = await _audioQuery.querySongs();
    setState(() {
      _albumSongs = allSongs.where((song) => song.album == widget.album).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album),
      ),
      body: _albumSongs.isEmpty
          ? const Center(child: Text('No songs found in this album.'))
          : ListView.builder(
              itemCount: _albumSongs.length,
              itemBuilder: (context, index) {
                final song = _albumSongs[index];
                return ListTile(
                  leading: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const Icon(Icons.music_note),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? 'Unknown Artist'),
                  trailing: SongOptionsMenu(song: song),
                  onTap: () {
                    _audioHandler.playSongs(_albumSongs, index);
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
