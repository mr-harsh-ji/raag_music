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
import 'package:shared_preferences/shared_preferences.dart';

import '../locals/string_extension.dart';
import '../services/audio_handler.dart';
import 'lyrics_screen.dart';

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
  late SharedPreferences _prefs;

  bool _isVolumeSliderVisible = false;
  Timer? _volumeHideTimer;
  bool _isFavorited = false;
  bool _gestureVolume = true;

  StreamSubscription? _mediaItemSubscription;
  StreamSubscription? _sequenceStateSubscription;
  bool _isSyncingPageController = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = _audioHandler.player;
    _pageController = PageController(
      initialPage: _audioPlayer.currentIndex ?? 0,
    );
    _loadSettings();

    _mediaItemSubscription = _audioHandler.mediaItem.listen((mediaItem) async {
      if (mediaItem != null && mounted) {
        _checkIfFavorite(int.parse(mediaItem.id));

        // Sync PageView when song changes (filtered by AudioHandler's flag)
        final queue = _audioHandler.queue.value;
        final index = queue.indexWhere((item) => item.id == mediaItem.id);
        if (index != -1 &&
            _pageController.hasClients &&
            !_pageController.position.isScrollingNotifier.value &&
            index != _pageController.page?.round()) {
          
          _isSyncingPageController = true;
          final pageDiff = (index - (_pageController.page?.round() ?? 0)).abs();
          
          if (pageDiff > 1) {
            _pageController.jumpToPage(index);
          } else {
            await _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.ease,
            );
          }
          _isSyncingPageController = false;
        }
      }
    });

    _sequenceStateSubscription = _audioPlayer.sequenceStateStream.listen((sequenceState) {
      // Just listen for queue changes if needed, but the sync is now in mediaItem listener
    });
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _gestureVolume = _prefs.getBool('gestureVolume') ?? true;
    });
  }

  @override
  void dispose() {
    _mediaItemSubscription?.cancel();
    _sequenceStateSubscription?.cancel();
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

  void _playPause() {
    _audioHandler.playbackState.value.playing
        ? _audioHandler.pause()
        : _audioHandler.play();
  }

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
        title: Text('select_speed'.tr),
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
    final currentIndex = _audioPlayer.currentIndex ?? 0;
    if (queue.isEmpty || currentIndex >= queue.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_up_next_songs'.tr)),
      );
      return;
    }

    final upNextQueue = queue.sublist(currentIndex + 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'up_next'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: upNextQueue.length,
                itemBuilder: (context, index) {
                  final mediaItem = upNextQueue[index];
                  final realIndex = queue.indexWhere((item) => item.id == mediaItem.id);
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
                      mediaItem.artist ?? 'unknown_artist'.tr,
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      if (realIndex != -1) {
                        _audioHandler.skipToQueueItem(realIndex);
                      }
                      Navigator.pop(context);
                    },
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  final oldRealIndex = queue.indexWhere(
                    (item) => item.id == upNextQueue[oldIndex].id,
                  );

                  final newRealIndex = queue.indexWhere(
                    (item) => item.id == upNextQueue[newIndex].id,
                  );

                  if (oldRealIndex != -1 && newRealIndex != -1) {
                    _audioHandler.reorderPlaylist(oldRealIndex, newRealIndex);
                  }
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
          body: StreamBuilder<MediaItem?>(
            stream: _audioHandler.mediaItem,
            initialData: _audioHandler.mediaItem.value,
            builder: (context, snapshot) {
              final mediaItem = snapshot.data;
              return Column(
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
                              "playing_from".tr,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12),
                            ),
                            Text(
                              mediaItem?.album ?? 'unknown_album'.tr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (mediaItem != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LyricsScreen(
                                      songId: int.parse(mediaItem.id),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.lyrics, color: Colors.white),
                          ),
                          if (mediaItem != null)
                            SongOptionsMenu(
                              song: SongModel({
                                '_id': int.parse(mediaItem.id),
                                'title': mediaItem.title,
                                'artist': mediaItem.artist,
                                'album': mediaItem.album,
                                'duration': mediaItem.duration?.inMilliseconds,
                                '_uri': mediaItem.extras!['url'],
                              }),
                              onDeleted: () {
                                _audioHandler.clearCache();
                                _audioHandler.skipToNext();
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: scrSize.height * 0.01),
                  _gestureVolume
                      ? RawGestureDetector(
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
                          child: buildPlayerControls(scrSize, mediaItem),
                        )
                      : buildPlayerControls(scrSize, mediaItem),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Container(
                                height: 45,
                                child: _buildMarquee(
                                  mediaItem?.title ?? "loading".tr,
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30,
                                  ),
                                ),
                              ),
                              Container(
                                height: 25,
                                child: _buildMarquee(
                                  mediaItem?.artist ?? "unknown_artist".tr,
                                  const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          StreamBuilder<Duration>(
                            stream: _audioPlayer.positionStream,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              final duration =
                                  _audioPlayer.duration ?? mediaItem?.duration ?? Duration.zero;
                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    ),
                                    child: Slider(
                                      value: duration.inMilliseconds > 0
                                          ? position.inMilliseconds
                                              .clamp(0, duration.inMilliseconds)
                                              .toDouble()
                                          : 0.0,
                                      min: 0.0,
                                      max: duration.inMilliseconds.toDouble(),
                                      onChanged: (value) {
                                        _audioHandler.seek(Duration(milliseconds: value.toInt()));
                                      },
                                      activeColor:
                                          Theme.of(context).colorScheme.secondary,
                                      inactiveColor: Colors.white24,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StreamBuilder<bool>(
                                stream: _audioPlayer.shuffleModeEnabledStream,
                                builder: (context, snapshot) => IconButton(
                                  icon: const Icon(Icons.shuffle),
                                  color: snapshot.data ?? false
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.white54,
                                  onPressed: () async {
                                    final enable = !(snapshot.data ?? false);
                                    await _audioPlayer
                                        .setShuffleModeEnabled(enable);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                color: Colors.white,
                                iconSize: 45,
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
                                    iconSize: 75,
                                    onPressed: _playPause,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                color: Colors.white,
                                iconSize: 45,
                                onPressed: _audioHandler.skipToNext,
                              ),
                              StreamBuilder<LoopMode>(
                                stream: _audioPlayer.loopModeStream,
                                builder: (context, snapshot) {
                                  final loopMode = snapshot.data ?? LoopMode.off;
                                  IconData iconData = Icons.repeat;
                                  Color color = Colors.white54;

                                  if (loopMode == LoopMode.one) {
                                    iconData = Icons.repeat_one;
                                    color = Theme.of(context).colorScheme.secondary;
                                  } else if (loopMode == LoopMode.all) {
                                    iconData = Icons.repeat;
                                    color = Theme.of(context).colorScheme.secondary;
                                  }

                                  return IconButton(
                                    icon: Icon(iconData),
                                    color: color,
                                    onPressed: () {
                                      LoopMode nextMode;
                                      if (loopMode == LoopMode.off) {
                                        nextMode = LoopMode.all;
                                      } else if (loopMode == LoopMode.all) {
                                        nextMode = LoopMode.one;
                                      } else {
                                        nextMode = LoopMode.off;
                                      }
                                      _audioPlayer.setLoopMode(nextMode);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showUpNextQueue(context),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.chevron_up, color: Colors.white54, size: 20),
                                Text(
                                  "up_next".tr,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildPlayerControls(Size scrSize, MediaItem? mediaItem) {
    return SizedBox(
      height: scrSize.height * 0.4,
      child: StreamBuilder<List<MediaItem>>(
        stream: _audioHandler.queue,
        builder: (context, snapshot) {
          final queue = snapshot.data ?? [];
          if (mediaItem == null || queue.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: queue.length,
                onPageChanged: (index) {
                  if (!_isSyncingPageController && index != _audioPlayer.currentIndex) {
                    _audioHandler.skipToQueueItem(index);
                  }
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
                        artworkQuality: FilterQuality.low,
                        size: 500,
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
    );
  }
}
