import 'dart:async';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:marquee/marquee.dart';
import 'package:raag_music/services/favorites_service.dart';
import 'package:raag_music/widgets/song_options_menu.dart';

import '../services/audio_handler.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
  final FavoritesService _favoritesService = FavoritesService();
  late AudioPlayer _audioPlayer;
  late PageController _pageController;

  bool _isVolumeSliderVisible = false;
  Timer? _volumeHideTimer;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = _audioHandler.player;
    _pageController = PageController(
      initialPage: _audioPlayer.currentIndex ?? 0,
    );

    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _checkIfFavorite(int.parse(mediaItem.id));
      }
    });

    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      final currentIndex = sequenceState.currentIndex;
      if (currentIndex != null &&
          _pageController.hasClients &&
          currentIndex != _pageController.page?.round()) {
        _pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.ease,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _volumeHideTimer?.cancel();
    super.dispose();
  }

  void _checkIfFavorite(int songId) async {
    final isFavorite = await _favoritesService.isFavorite(songId);
    if (mounted) {
      setState(() {
        _isFavorited = isFavorite;
      });
    }
  }

  void _showVolumeSlider() {
    _volumeHideTimer?.cancel();
    if (mounted) setState(() => _isVolumeSliderVisible = true);
    _volumeHideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isVolumeSliderVisible = false);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _playPause() =>
      _audioHandler.playbackState.value.playing ? _audioHandler.pause() : _audioHandler.play();

  void _toggleFavorite() async {
    final mediaItem = _audioHandler.mediaItem.value;
    if (mediaItem != null) {
      await _favoritesService.toggleFavorite(int.parse(mediaItem.id));
      _checkIfFavorite(int.parse(mediaItem.id));
    }
  }

  void _showSpeedSelector(BuildContext context) {
    final speeds = [
      {'value': 0.25, 'label': '0.25x 🐌'},
      {'value': 0.5, 'label': '0.5x 🐢'},
      {'value': 0.75, 'label': '0.75x 🦥'},
      {'value': 1.0, 'label': '1.0x 🙂'},
      {'value': 1.25, 'label': '1.25x 🐕'},
      {'value': 1.5, 'label': '1.5x 🦊'},
      {'value': 1.75, 'label': '1.75x 🐆'},
      {'value': 2.0, 'label': '2.0x 🐇'},
    ];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Speed'),
        backgroundColor: const Color(0xFF282828),
        titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 20),
        children: speeds
            .map(
              (speedData) => SimpleDialogOption(
                onPressed: () {
                  _audioPlayer.setSpeed(speedData['value'] as double);
                  Navigator.pop(context);
                },
                child: Text(
                  speedData['label'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _showUpNextQueue(BuildContext context) {
    final queue = _audioHandler.queue.value;
    if (queue.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Up Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final mediaItem = queue[index];
                  return ListTile(
                    key: ValueKey(mediaItem.id),
                    leading: QueryArtworkWidget(
                      id: int.parse(mediaItem.id),
                      type: ArtworkType.AUDIO,
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      mediaItem.title,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      mediaItem.artist ?? 'Unknown Artist',
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _audioHandler.skipToQueueItem(index);
                      Navigator.pop(context);
                    },
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  _audioHandler.reorderPlaylist(oldIndex, newIndex);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarquee(String text, TextStyle style) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        return textPainter.width > constraints.maxWidth
            ? Marquee(
                text: text,
                style: style,
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 20.0,
                velocity: 50.0,
                pauseAfterRound: const Duration(seconds: 1),
              )
            : Center(
                child: Text(text, style: style, textAlign: TextAlign.center),
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var scrSize = MediaQuery.of(context).size;

    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF282828),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF282828), Color(0xFF000000)],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "PLAYING FROM",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12),
                                  ),
                                  Text(
                                    mediaItem.album ?? 'Unknown Album',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.lyrics, color: Colors.white),
                          ),
                          SongOptionsMenu(song: SongModel({
                            '_id': int.parse(mediaItem.id),
                            'title': mediaItem.title,
                            'artist': mediaItem.artist,
                            'album': mediaItem.album,
                            'duration': mediaItem.duration?.inMilliseconds,
                            '_uri': mediaItem.extras!['url'],
                          })),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: scrSize.height * 0.02),
                  RawGestureDetector(
                    gestures: {
                      VerticalDragGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                        (instance) {
                          instance.onUpdate = (details) {
                            final newVolume = (_audioPlayer.volume -
                                    details.delta.dy / 200)
                                .clamp(0.0, 1.0);
                            _audioPlayer.setVolume(newVolume);
                            _showVolumeSlider();
                          };
                        },
                      ),
                    },
                    child: SizedBox(
                      height: scrSize.height * 0.4,
                      child: StreamBuilder<List<MediaItem>>(
                        stream: _audioHandler.queue,
                        builder: (context, snapshot) {
                          final queue = snapshot.data ?? [];
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: queue.length,
                                onPageChanged: (index) {
                                  _audioHandler.skipToQueueItem(index);
                                },
                                itemBuilder: (context, index) {
                                  final item = queue[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: QueryArtworkWidget(
                                        id: int.parse(item.id),
                                        type: ArtworkType.AUDIO,
                                        artworkWidth: scrSize.width * 0.85,
                                        artworkHeight: scrSize.height * 0.4,
                                        artworkFit: BoxFit.cover,
                                        artworkQuality: FilterQuality.high,
                                        size: 1000,
                                        keepOldArtwork: true,
                                        nullArtworkWidget: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              15.0,
                                            ),
                                            color: Colors.grey[800],
                                          ),
                                          width: scrSize.width * 0.85,
                                          height: scrSize.height * 0.4,
                                          child: const Icon(
                                            CupertinoIcons.double_music_note,
                                            color: Colors.white,
                                            size: 200,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _isVolumeSliderVisible ? 1.0 : 0.0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      width: 80,
                                      height: scrSize.height * 0.30,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      child: StreamBuilder<double>(
                                        stream: _audioPlayer.volumeStream,
                                        builder: (context, volumeSnapshot) {
                                          final volume =
                                              volumeSnapshot.data ??
                                                  _audioPlayer.volume;
                                          return Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  child: Align(
                                                    heightFactor: volume,
                                                    child: Container(
                                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 20,
                                                child: Icon(
                                                  volume > 0.5
                                                      ? Icons.volume_up
                                                      : volume > 0
                                                          ? Icons.volume_down
                                                          : Icons.volume_off,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                              Text(
                                                "${(volume * 100).toStringAsFixed(0)}%",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: scrSize.height * 0.05),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildMarquee(
                              mediaItem.title,
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 35,
                              ),
                            ),
                          ),
                          Container(
                            height: 25,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildMarquee(
                              mediaItem.artist ?? "Unknown Artist",
                              const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isFavorited
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                  color: Theme.of(context).colorScheme.secondary,
                                  onPressed: _toggleFavorite,
                                ),
                                StreamBuilder<double>(
                                  stream: _audioPlayer.speedStream,
                                  builder: (context, snapshot) => TextButton(
                                    onPressed: () =>
                                        _showSpeedSelector(context),
                                    child: Text(
                                      '${snapshot.data ?? 1.0}x',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<PlaybackState>(
                            stream: _audioHandler.playbackState,
                            builder: (context, snapshot) {
                              final playbackState = snapshot.data;
                              final position =
                                  playbackState?.updatePosition ?? Duration.zero;
                              final duration =
                                  mediaItem.duration ?? Duration.zero;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Column(
                                  children: [
                                    Slider(
                                      value: (duration.inSeconds > 0)
                                          ? (position.inSeconds /
                                                  duration.inSeconds)
                                              .clamp(0.0, 1.0)
                                          : 0.0,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (value) => _audioHandler
                                          .seek(duration * value),
                                      activeColor: Theme.of(context).colorScheme.secondary,
                                      inactiveColor: Colors.grey,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(position),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(duration),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StreamBuilder<bool>(
                                  stream: _audioPlayer.shuffleModeEnabledStream,
                                  builder: (context, snapshot) => IconButton(
                                    icon: const Icon(Icons.shuffle),
                                    color: snapshot.data ?? false
                                        ? Theme.of(context).colorScheme.secondary
                                        : const Color(0xff765204),
                                    onPressed: () async {
                                      final enable = !(snapshot.data ?? false);
                                      await _audioPlayer
                                          .setShuffleModeEnabled(enable);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Shuffle ${enable ? "ON" : "OFF"}",
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_previous_rounded),
                                  color: Theme.of(context).colorScheme.secondary,
                                  iconSize: 40,
                                  onPressed: _audioHandler.skipToPrevious,
                                ),
                                StreamBuilder<PlaybackState>(
                                  stream: _audioHandler.playbackState,
                                  builder: (context, snapshot) {
                                    final isPlaying =
                                        snapshot.data?.playing ?? false;
                                    return IconButton(
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_circle_filled_rounded
                                            : Icons.play_circle_fill_rounded,
                                      ),
                                      color: Theme.of(context).colorScheme.secondary,
                                      iconSize: 60,
                                      onPressed: _playPause,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded),
                                  color: Theme.of(context).colorScheme.secondary,
                                  iconSize: 40,
                                  onPressed: _audioHandler.skipToNext,
                                ),
                                StreamBuilder<LoopMode>(
                                  stream: _audioPlayer.loopModeStream,
                                  builder: (context, snapshot) => IconButton(
                                    icon: Icon(
                                      snapshot.data == LoopMode.one
                                          ? Icons.repeat_one
                                          : Icons.repeat,
                                    ),
                                    color: snapshot.data != LoopMode.off
                                        ? Theme.of(context).colorScheme.secondary
                                        : const Color(0xff765204),
                                    onPressed: () {
                                      final newMode =
                                          snapshot.data == LoopMode.off
                                              ? LoopMode.all
                                              : LoopMode.off;
                                      _audioPlayer.setLoopMode(newMode);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Repeat ${newMode != LoopMode.off ? "ON" : "OFF"}",
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: scrSize.height * 0.035),
                          GestureDetector(
                            onTap: () => _showUpNextQueue(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              height: scrSize.height * 0.08,
                              width: scrSize.width * 1,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.chevron_up,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    "Up Next",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
