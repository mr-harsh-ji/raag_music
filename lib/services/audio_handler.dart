import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:raag_music/services/recently_played_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _audioQuery = OnAudioQuery();

  MyAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackState();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
    _listenForPlayerCompletion();
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
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty || index >= playlist.length) {
        return;
      }
      mediaItem.add(playlist[index]);
      _recentlyPlayedService.addSong(int.parse(playlist[index].id));
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
    });
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
        album: song.album ?? "Unknown Album",
        title: song.title,
        artist: song.artist ?? "Unknown Artist",
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
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    play();
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
    await _playlist.clear();
    
    final mediaItems = songs.map(_songToMediaItem).toList();

    await _playlist.addAll(mediaItems.map(_createAudioSource).toList());
    
    await _player.setAudioSource(_playlist, initialIndex: initialIndex);
    play();
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
