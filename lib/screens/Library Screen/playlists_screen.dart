import 'package:flutter/material.dart';
import 'package:raag_music/models/playlist_model.dart';
import 'package:raag_music/services/playlist_service.dart';
import 'package:raag_music/screens/Library%20Screen/playlist_songs_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() async {
    final playlists = await _playlistService.getPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  void _createPlaylist() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Create Playlist', style: Theme.of(context).textTheme.titleLarge),
          content: TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Playlist Name',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final newPlaylist = Playlist(name: name, songIds: []);
                  _playlistService.createPlaylist(newPlaylist).then((_) {
                    _loadPlaylists();
                    Navigator.pop(context);
                  });
                }
              },
              child: Text('Create', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _deletePlaylist(String playlistName) {
    _playlistService.deletePlaylist(playlistName).then((_) {
      _loadPlaylists();
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Playlists', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
        ),
        body: _playlists.isEmpty
            ? Center(
                child: Text('No playlists found.',
                    style: Theme.of(context).textTheme.bodyLarge))
            : ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    title: Text(playlist.name,
                        style: Theme.of(context).textTheme.bodyLarge),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Theme.of(context).iconTheme.color),
                      onPressed: () => _deletePlaylist(playlist.name),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlaylistSongsScreen(playlist: playlist),
                      ),
                    ).then((_) => _loadPlaylists()),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createPlaylist,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
