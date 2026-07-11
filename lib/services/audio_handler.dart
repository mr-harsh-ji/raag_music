import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/blacklist_service.dart';
import 'package:raag_music/services/recently_played_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locals/string_extension.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.raagmusic.app.channel.audio',
      androidNotificationChannelName: 'Raag Music',
      androidNotificationOngoing: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _recentlyPlayedService = RecentlyPlayedService();
  final _blacklistService = BlacklistService();
  final _audioQuery = OnAudioQuery();
  bool _isChangingPlaylist = false;
  List<SongModel> _cachedSongs = [];
  bool _isScanning = false;

  MyAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackState();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
    _listenForPlayerCompletion();
  }

  Future<List<SongModel>> fetchAllSongs() async {
    if (_cachedSongs.isNotEmpty) return _cachedSongs;
    if (_isScanning) {
      while (_isScanning) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedSongs;
    }

    _isScanning = true;
    try {
      final hasPermission = await _audioQuery.permissionsStatus();
      if (!hasPermission) {
        _isScanning = false;
        return [];
      }

      final allSongs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final blacklistedIds = await _blacklistService.getBlacklistedIds();
      _cachedSongs = allSongs.where((song) => !blacklistedIds.contains(song.id)).toList();
    } catch (e) {
      print("Scan Error: $e");
    } finally {
      _isScanning = false;
    }
    return _cachedSongs;
  }

  void clearCache() {
    _cachedSongs = [];
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  void _notifyAudioHandlerAboutPlaybackState() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      _updatePlaybackState();
    });
    
    _player.loopModeStream.listen((_) => _updatePlaybackState());
    _player.shuffleModeEnabledStream.listen((_) => _updatePlaybackState());
  }

  void _updatePlaybackState() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode]!,
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    ));
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      _updateMediaItem();
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((sequenceState) {
      final sequence = sequenceState?.sequence;
      if (sequence == null || sequence.isEmpty) {
        queue.add([]);
        return;
      }
      final newQueue = sequence.map((s) => s.tag as MediaItem).toList();
      queue.add(newQueue);
      _updateMediaItem();
    });
  }

  void _updateMediaItem() {
    if (_isChangingPlaylist) return;
    
    final index = _player.currentIndex;
    final playlist = queue.value;
    if (index == null || playlist.isEmpty || index >= playlist.length) {
      return;
    }
    final currentItem = playlist[index];
    if (mediaItem.value?.id != currentItem.id) {
      mediaItem.add(currentItem);
      _recentlyPlayedService.addSong(int.parse(currentItem.id));
    }
  }

  void _listenForPlayerCompletion() {
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSource = mediaItems.map(_createAudioSource);
    _playlist.addAll(audioSource.toList());
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  Future<void> addToQueue(SongModel song) async {
    final mediaItem = _songToMediaItem(song);
    if (_playlist.length == 0) {
      await playSongs([song], 0);
    } else {
      await addQueueItems([mediaItem]);
    }
  }

  Future<void> playNext(SongModel song) async {
    final mediaItem = _songToMediaItem(song);
     if (_playlist.length == 0) {
      await playSongs([song], 0);
    } else {
      final currentIndex = _player.currentIndex;
      if (currentIndex != null) {
        _playlist.insert(currentIndex + 1, _createAudioSource(mediaItem));
        final newQueue = queue.value..insert(currentIndex + 1, mediaItem);
        queue.add(newQueue);
      } else {
        await playSongs([song, ...queue.value.map(_mediaItemToSongModel)], 0);
      }
    }
  }

  UriAudioSource _createAudioSource(MediaItem mediaItem) {
    return AudioSource.uri(
      Uri.parse(mediaItem.extras!['url'] as String),
      tag: mediaItem,
    );
  }

  MediaItem _songToMediaItem(SongModel song) {
    return MediaItem(
        id: song.id.toString(),
        album: song.album ?? "unknown_album".tr,
        title: song.title,
        artist: song.artist ?? "unknown_artist".tr,
        duration: Duration(milliseconds: song.duration ?? 0),
        artUri: song.id > 0 ? Uri.parse('content://media/external/audio/media/${song.id}/albumart') : null,
        extras: {'url': song.uri!},
      );
  }

  SongModel _mediaItemToSongModel(MediaItem mediaItem) {
    return SongModel({
      '_id': int.parse(mediaItem.id),
      'title': mediaItem.title,
      'artist': mediaItem.artist,
      'album': mediaItem.album,
      'duration': mediaItem.duration?.inMilliseconds,
      '_uri': mediaItem.extras!['url'],
    });
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.setShuffleModeEnabled(true);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    await play();
  }

  @override
  Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    final stopOnClose = prefs.getBool('stopOnClose') ?? true;
    if (stopOnClose) {
      await _player.stop();
      mediaItem.add(null);
      await super.stop();
    }
  }

  Future<void> playSongs(List<SongModel> songs, int initialIndex) async {
    if (songs.isEmpty) return;

    _isChangingPlaylist = true;
    final mediaItems = songs.map(_songToMediaItem).toList();
    queue.add(mediaItems);

    await _playlist.clear();
    await _playlist.addAll(
      mediaItems.map(_createAudioSource).toList(),
    );

    await _player.setAudioSource(
      _playlist,
      initialIndex: initialIndex,
    );

    _isChangingPlaylist = false;
    _updateMediaItem();
    await play();
  }

  Future<void> scan() async {
    final songs = await _audioQuery.querySongs();
    final filteredSongs = songs.where((song) => song.size > 100 * 1024).toList();
    final mediaItems = filteredSongs.map(_songToMediaItem).toList();
    await _playlist.clear();
    await _playlist.addAll(mediaItems.map(_createAudioSource).toList());
    queue.add(mediaItems);
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
     _playlist.move(oldIndex, newIndex);
  }
  
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  AudioPlayer get player => _player;
}
