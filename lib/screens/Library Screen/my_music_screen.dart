import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/helpers/path_helper.dart';
import 'package:raag_music/screens/Library%20Screen/all_songs_screen.dart';

import '../../My App Themes/app_theme.dart';

class MyMusicScreen extends StatefulWidget {
  const MyMusicScreen({super.key});

  @override
  State<MyMusicScreen> createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    _songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final folderSongs = PathHelper.categorizeSongsByFolder(_songs);
    final folders = folderSongs.keys.toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Music'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final songsInFolder = folderSongs[folder]!;
                  final folderName = folder.split('/').last;

                  return ListTile(
                    leading: const Icon(Icons.folder, color: Colors.white, size: 40),
                    title: Text(folderName, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${songsInFolder.length} songs', style: const TextStyle(color: Colors.white70)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllSongsScreen(
                            songs: songsInFolder,
                            title: folderName,
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
