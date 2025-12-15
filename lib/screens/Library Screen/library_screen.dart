import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:raag_music/services/recently_played_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raag_music/widgets/my_drawer.dart';

import 'all_songs_screen.dart';
import 'my_music_screen.dart';
import '../player_screen.dart';
import 'playlists_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final _audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
  final RecentlyPlayedService _recentlyPlayedService = RecentlyPlayedService();
  List<SongModel> _recentlyPlayedSongs = [];
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadRecentlyPlayed();
    _loadUserName();
  }

  void _loadRecentlyPlayed() async {
    final recentSongIds = await _recentlyPlayedService.getRecentSongs();
    if (recentSongIds.isNotEmpty) {
      final allSongs = await _audioQuery.querySongs();
      final recentlyPlayedSongs = allSongs
          .where((song) => recentSongIds.contains(song.id))
          .toList()
        ..sort((a, b) => recentSongIds
            .indexOf(a.id)
            .compareTo(recentSongIds.indexOf(b.id)));
      if (mounted) {
        setState(() {
          _recentlyPlayedSongs = recentlyPlayedSongs;
        });
      }
    }
  }

  void _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "";
    });
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
        key: _scaffoldKey,
        drawer: const MyDrawer(),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).iconTheme.color,
              size: 32,
            ),
          ),
          title: Text("Library", style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView(
            children: [
              LibraryItem(
                  icon: Icons.queue_music,
                  text: 'Now Playing',
                  onTap: () {
                    final mediaItem = _audioHandler.mediaItem.value;
                    if (mediaItem != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PlayerScreen()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No song is currently playing.'),
                      ));
                    }
                  }),
              LibraryItem(
                  icon: Icons.history,
                  text: 'Last Session',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllSongsScreen(songs: _recentlyPlayedSongs, title: "Last Session"))),
              ),
              LibraryItem(
                  icon: Icons.favorite,
                  text: 'Favorites',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllSongsScreen(isFavorites: true, title: "Favorites"))),
              ),
              LibraryItem(
                  icon: Icons.music_note,
                  text: 'My Music',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyMusicScreen()))),
              LibraryItem(icon: Icons.playlist_play, text: 'Playlists', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistsScreen()))),
            ], 
          ),
        ),
      ),
    );
  }
}

class LibraryItem extends StatelessWidget {
  const LibraryItem({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).iconTheme.color, size: 36),
            const SizedBox(width: 20),
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
