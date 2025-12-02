import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/services/recently_played_service.dart';

import '../My App Themes/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  void _checkAndRequestPermissions() async {
    final hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: true,
    );
    if (hasPermission) {
      _loadFavorites();
      _loadRecentlyPlayed();
    }
  }

  void _loadFavorites() async {
    final favoriteIds = await _favoritesService.getFavoriteSongIds();
    if (favoriteIds.isNotEmpty) {
      final allSongs = await _audioQuery.querySongs();
      final favoriteSongs =
          allSongs.where((song) => favoriteIds.contains(song.id)).toList();
      if (mounted) {
        setState(() {
          _favoriteSongs = favoriteSongs;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "RaagMusic",
            style: TextStyle(
              color: Color(0xffF8AB02),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: FutureBuilder<List<SongModel>>(
          future: _audioQuery.querySongs(
            sortType: SongSortType.TITLE,
            orderType: OrderType.DESC_OR_GREATER,
            uriType: UriType.EXTERNAL,
            ignoreCase: true,
          ),
          builder: (context, item) {
            if (item.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (item.data == null || item.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No Songs Found",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final songs = item.data!;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick picks",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
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
                        itemCount: songs.length > 9 ? 9 : songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return GestureDetector(
                            onTap: () {
                              _audioHandler.playSongs(
                                songs,
                                index,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(song: song),
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
                                    nullArtworkWidget: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8.0),
                                        color: Colors.grey[800],
                                      ),
                                      width: 60,
                                      height: 60,
                                      child: Icon(
                                        CupertinoIcons.double_music_note,
                                        color: Colors.white,
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "Unknown Artist",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
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
                        const Text(
                          "Recently played",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
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
                            "See all",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 190,
                      child: _recentlyPlayedSongs.isEmpty 
                        ? const Center(
                          child: Text('No recently played songs.', style: TextStyle(color: Colors.white, fontSize: 16),),
                        )
                        : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentlyPlayedSongs.length > 15
                            ? 15
                            : _recentlyPlayedSongs.length,
                        itemBuilder: (context, index) {
                          final song = _recentlyPlayedSongs[index];
                          return GestureDetector(
                            onTap: () {
                              _audioHandler.playSongs(
                                _recentlyPlayedSongs,
                                index,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlayerScreen(song: song, playlistSource: "Recently Played"),
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
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    song.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song.artist ?? "Unknown Artist",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
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
                        const Text(
                          "Favorites",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllSongsScreen(
                                  isFavorites: true,
                                  title: "Favorites",
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "See all",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 190,
                      child: _favoriteSongs.isEmpty
                          ? const Center(
                              child: Text(
                                'No favorite songs yet.',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _favoriteSongs.length,
                              itemBuilder: (context, index) {
                                final song = _favoriteSongs[index];
                                return GestureDetector(
                                  onTap: () {
                                    _audioHandler.playSongs(
                                      _favoriteSongs,
                                      index,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayerScreen(
                                          song: song,
                                          playlistSource: 'Favorites',
                                        ),
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
                                              color: Colors.white,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          song.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "Unknown Artist",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
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
                    const Text(
                      "Last session",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
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
                        itemCount: songs.length > 9 ? 9 : songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return GestureDetector(
                            onTap: () {
                              _audioHandler.playSongs(
                                songs,
                                index,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(song: song),
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
                                    nullArtworkWidget: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8.0),
                                        color: Colors.grey[800],
                                      ),
                                      width: 60,
                                      height: 60,
                                      child: Icon(
                                        CupertinoIcons.double_music_note,
                                        color: Colors.white,
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? "Unknown Artist",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
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
