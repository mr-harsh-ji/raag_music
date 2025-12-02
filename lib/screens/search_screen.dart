import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/audio_handler.dart';

import 'Library Screen/all_songs_screen.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
  final FocusNode _searchFocusNode = FocusNode();
  List<SongModel> _allSongs = [];
  List<SongModel> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllSongs();
    _searchController.addListener(_filterSongs);
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSongs);
    _searchController.dispose();
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchAllSongs() async {
    List<SongModel> songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    if (mounted) {
      setState(() {
        _allSongs = songs;
      });
    }
  }

  void _filterSongs() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = [];
      } else {
        _filteredSongs = _allSongs.where((song) {
          return song.title.toLowerCase().contains(query) || (song.artist?.toLowerCase() ?? '').contains(query);
        }).toList();
      }
    });
  }

  bool get _isSearching => _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF282828), Color(0xFF000000)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search for songs, artists, albums...",
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                    )
                  : null,
            ),
          ),
          bottom: _searchFocusNode.hasFocus
              ? null
              : TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: "Albums"),
                    Tab(text: "Artists"),
                  ],
                ),
        ),
        body: _searchFocusNode.hasFocus ? _buildSearchResults() : _buildLibraryView(),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_isSearching) {
      return Container();
    }

    if (_filteredSongs.isEmpty) {
      return const Center(
        child: Text("No results found.", style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return ListTile(
          leading: QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(song.artist ?? "Unknown Artist", style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            _audioHandler.playSongs(_filteredSongs, index);
            Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(song: song)));
          },
        );
      },
    );
  }

  Widget _buildLibraryView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAlbumView(),
        _buildArtistView(),
      ],
    );
  }

  Widget _buildAlbumView() {
    return FutureBuilder<List<AlbumModel>>(
      future: _audioQuery.queryAlbums(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      builder: (context, item) {
        if (item.hasError) {
          return Center(child: Text(item.error.toString(), style: const TextStyle(color: Colors.white)));
        }
        if (item.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final albums = item.data;
        if (albums == null || albums.isEmpty) {
          return const Center(child: Text("No Albums Found", style: TextStyle(color: Colors.white)));
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return GestureDetector(
              onTap: () async {
                List<SongModel> albumSongs = await _audioQuery.queryAudiosFrom(
                  AudiosFromType.ALBUM_ID,
                  album.id
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllSongsScreen(
                      songs: albumSongs,
                      title: album.album,
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QueryArtworkWidget(
                      id: album.id,
                      type: ArtworkType.ALBUM,
                      artworkWidth: double.infinity,
                      artworkHeight: 150,
                      nullArtworkWidget: const Icon(Icons.album, color: Colors.white, size: 150),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        album.album,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        album.artist ?? "Unknown Artist",
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistView() {
    return FutureBuilder<List<ArtistModel>>(
      future: _audioQuery.queryArtists(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      builder: (context, item) {
        if (item.hasError) {
          return Center(child: Text(item.error.toString(), style: const TextStyle(color: Colors.white)));
        }
        if (item.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final artists = item.data;
        if (artists == null || artists.isEmpty) {
          return const Center(child: Text("No Artists Found", style: TextStyle(color: Colors.white)));
        }
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              onTap: () async {
                List<SongModel> artistSongs = await _audioQuery.queryAudiosFrom(
                  AudiosFromType.ARTIST_ID,
                  artist.id
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllSongsScreen(
                      songs: artistSongs,
                      title: artist.artist,
                    ),
                  ),
                );
              },
              leading: QueryArtworkWidget(
                id: artist.id,
                type: ArtworkType.ARTIST,
                nullArtworkWidget: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                artist.artist,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${artist.numberOfAlbums} Albums | ${artist.numberOfTracks} Songs",
                style: const TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        );
      },
    );
  }
}
