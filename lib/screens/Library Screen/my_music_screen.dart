import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/helpers/path_helper.dart';
import 'package:raag_music/screens/Library%20Screen/all_songs_screen.dart';

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
        title: Text('My Music', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Container(
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final songsInFolder = folderSongs[folder]!;
                  final folderName = folder.split('/').last;

                  return ListTile(
                    leading: Icon(Icons.folder, color: Theme.of(context).iconTheme.color, size: 40),
                    title: Text(folderName, style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text('${songsInFolder.length} songs', style: Theme.of(context).textTheme.bodySmall),
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
