import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/locals/string_extension.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/recently_played_service.dart';
import 'package:raag_music/widgets/my_drawer.dart';
import 'package:raag_music/widgets/song_options_menu.dart';

import '../services/audio_handler.dart';
import 'Library Screen/all_songs_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final _audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
  final FavoritesService _favoritesService = FavoritesService();
  final RecentlyPlayedService _recentlyPlayedService = RecentlyPlayedService();
  List<SongModel> _favoriteSongs = [];
  List<SongModel> _recentlyPlayedSongs = [];
  List<SongModel> _lastAddedSongs = [];
  List<SongModel> _quickPicksSongs = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<SongModel>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _checkAndRequestPermissions();
  }

  Future<List<SongModel>> _checkAndRequestPermissions() async {
    try {
      final hasPermission = await _audioQuery.checkAndRequest(
        retryRequest: true,
      );
      
      if (hasPermission) {
        final allSongs = await _audioHandler.fetchAllSongs();
        if (mounted) {
          setState(() {
            _lastAddedSongs = allSongs;
            _quickPicksSongs = List.from(allSongs)..shuffle(); // Shuffle for discovery
            _loadFavoritesFromList(allSongs);
            _loadRecentlyPlayedFromList(allSongs);
          });
        }
        return allSongs;
      }
    } catch (e) {
      print("Permission Error: $e");
    }
    return [];
  }

  void _loadFavoritesFromList(List<SongModel> allSongs) async {
    final favoriteIds = await _favoritesService.getFavoriteSongIds();
    if (favoriteIds.isNotEmpty && mounted) {
      setState(() {
        _favoriteSongs = allSongs.where((song) => favoriteIds.contains(song.id)).toList();
      });
    }
  }

  void _loadRecentlyPlayedFromList(List<SongModel> allSongs) async {
    final recentSongIds = await _recentlyPlayedService.getRecentSongs();
    if (recentSongIds.isNotEmpty && mounted) {
      setState(() {
        _recentlyPlayedSongs = allSongs
            .where((song) => recentSongIds.contains(song.id))
            .toList()
          ..sort((a, b) => recentSongIds
              .indexOf(a.id)
              .compareTo(recentSongIds.indexOf(b.id)));
      });
    }
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
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState!.openDrawer(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          title: Text(
            "RaagMusic",
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: FutureBuilder<List<SongModel>>(
          future: _songsFuture,
          builder: (context, item) {
            if (item.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (item.data == null || item.data!.isEmpty) {
              return Center(
                child: Text(
                  "no_Songs_Found".tr,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            final songs = item.data!;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "quick_picks".tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: (70) * 3,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 320,
                        ),
                        itemCount: _quickPicksSongs.length > 9 ? 9 : _quickPicksSongs.length,
                        itemBuilder: (context, index) {
                          final song = _quickPicksSongs[index];
                          return GestureDetector(
                            onTap: () async {
                              final currentMediaItem = _audioHandler.mediaItem.value;
                              if (currentMediaItem != null && 
                                  currentMediaItem.id == _quickPicksSongs[index].id.toString()) {
                                // Already playing, just open player
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PlayerScreen(),
                                  ),
                                );
                                return;
                              }

                              await _audioHandler.playSongs(
                                _quickPicksSongs,
                                index,
                              );
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PlayerScreen(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  QueryArtworkWidget(
                                    id: song.id,
                                    type: ArtworkType.AUDIO,
                                    artworkBorder: BorderRadius.circular(8.0),
                                    artworkWidth: 60,
                                    artworkHeight: 60,
                                    artworkFit: BoxFit.cover,
                                    artworkQuality: FilterQuality.low,
                                    size: 150,
                                    nullArtworkWidget: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8.0),
                                        color: Colors.grey[800],
                                      ),
                                      width: 60,
                                      height: 60,
                                      child: Icon(
                                        CupertinoIcons.double_music_note,
                                        color: Theme.of(context).iconTheme.color,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          song.title,
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "unknown_artist".tr,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SongOptionsMenu(
                                    song: song,
                                    onDeleted: () {
                                      _audioHandler.clearCache();
                                      _checkAndRequestPermissions();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "recently_played".tr,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllSongsScreen(songs: _recentlyPlayedSongs, title: "Recently Played"),
                              ),
                            );
                          },
                          child: Text(
                            "see_all".tr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 190,
                      child: _recentlyPlayedSongs.isEmpty 
                        ? Center(
                          child: Text('no_recently_played_songs'.tr, style: Theme.of(context).textTheme.bodyLarge,),
                        )
                        : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentlyPlayedSongs.length > 15
                            ? 15
                            : _recentlyPlayedSongs.length,
                        itemBuilder: (context, index) {
                          final song = _recentlyPlayedSongs[index];
                          return GestureDetector(
                            onTap: () async {
                              final currentMediaItem = _audioHandler.mediaItem.value;
                              if (currentMediaItem != null && 
                                  currentMediaItem.id == _recentlyPlayedSongs[index].id.toString()) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PlayerScreen(),
                                  ),
                                );
                                return;
                              }

                              await _audioHandler.playSongs(
                                _recentlyPlayedSongs,
                                index,
                              );
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PlayerScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.only(
                                right: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  QueryArtworkWidget(
                                    id: song.id,
                                    type: ArtworkType.AUDIO,
                                    artworkBorder:
                                        BorderRadius.circular(8.0),
                                    artworkWidth: 130,
                                    artworkHeight: 130,
                                    artworkFit: BoxFit.cover,
                                    artworkQuality: FilterQuality.low,
                                    size: 250, // Balanced size for bigger tiles
                                    nullArtworkWidget: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        color: Colors.grey[800],
                                      ),
                                      width: 130,
                                      height: 130,
                                      child: Icon(
                                        CupertinoIcons
                                            .double_music_note,
                                        color: Theme.of(context).iconTheme.color,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    song.title,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song.artist ?? "unknown_artist".tr,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "favorites".tr,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllSongsScreen(
                                  isFavorites: true,
                                  title: "favorites".tr,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "see_all".tr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 190,
                      child: _favoriteSongs.isEmpty
                          ? Center(
                              child: Text(
                                'no_favorite_songs_yet'.tr,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _favoriteSongs.length,
                              itemBuilder: (context, index) {
                                final song = _favoriteSongs[index];
                                return GestureDetector(
                                  onTap: () async {
                                    final currentMediaItem = _audioHandler.mediaItem.value;
                                    if (currentMediaItem != null && 
                                        currentMediaItem.id == _favoriteSongs[index].id.toString()) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const PlayerScreen(),
                                        ),
                                      );
                                      return;
                                    }

                                    await _audioHandler.playSongs(
                                      _favoriteSongs,
                                      index,
                                    );
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PlayerScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 130,
                                    margin: const EdgeInsets.only(
                                      right: 12.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        QueryArtworkWidget(
                                          id: song.id,
                                          type: ArtworkType.AUDIO,
                                          artworkBorder: BorderRadius.circular(8.0),
                                          artworkWidth: 130,
                                          artworkHeight: 130,
                                          artworkFit: BoxFit.cover,
                                          artworkQuality: FilterQuality.low,
                                          size: 250,
                                          nullArtworkWidget: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                  8.0),
                                              color: Colors.grey[800],
                                            ),
                                            width: 130,
                                            height: 130,
                                            child: Icon(
                                              CupertinoIcons.double_music_note,
                                              color: Theme.of(context).iconTheme.color,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          song.title,
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "unknown_artist".tr,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "last_added".tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: (70) * 3,
                      child: _lastAddedSongs.isEmpty
                        ? Center(
                            child: Text(
                            'no_songs_found'.tr,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ))
                        : GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 320,
                        ),
                        itemCount: _lastAddedSongs.length > 9 ? 9 : _lastAddedSongs.length,
                        itemBuilder: (context, index) {
                          final song = _lastAddedSongs[index];
                          return GestureDetector(
                            onTap: () async {
                              final currentMediaItem = _audioHandler.mediaItem.value;
                              if (currentMediaItem != null && 
                                  currentMediaItem.id == _lastAddedSongs[index].id.toString()) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PlayerScreen(),
                                  ),
                                );
                                return;
                              }

                              await _audioHandler.playSongs(
                                _lastAddedSongs,
                                index,
                              );
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PlayerScreen(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 4.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  QueryArtworkWidget(
                                    id: song.id,
                                    type: ArtworkType.AUDIO,
                                    artworkBorder: BorderRadius.circular(8.0),
                                    artworkWidth: 60,
                                    artworkHeight: 60,
                                    artworkFit: BoxFit.cover,
                                    artworkQuality: FilterQuality.low,
                                    size: 150,
                                    nullArtworkWidget: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8.0),
                                        color: Colors.grey[800],
                                      ),
                                      width: 60,
                                      height: 60,
                                      child: Icon(
                                        CupertinoIcons.double_music_note,
                                        color: Theme.of(context).iconTheme.color,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                       mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          song.title,
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "unknown_artist".tr,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SongOptionsMenu(
                                    song: song,
                                    onDeleted: () {
                                      _audioHandler.clearCache();
                                      _checkAndRequestPermissions();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
