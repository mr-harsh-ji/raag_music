import 'package:flutter/material.dart';
import 'package:raag_music/services/lyrics_service.dart';

class LyricsScreen extends StatefulWidget {
  final int songId;

  const LyricsScreen({super.key, required this.songId});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final LyricsService _lyricsService = LyricsService();
  final TextEditingController _lyricsController = TextEditingController();
  bool _isEditing = false;
  String? _lyrics;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    final lyrics = await _lyricsService.getLyrics(widget.songId);
    setState(() {
      _lyrics = lyrics;
      _lyricsController.text = lyrics ?? '';
    });
  }

  Future<void> _saveLyrics() async {
    await _lyricsService.saveLyrics(widget.songId, _lyricsController.text);
    setState(() {
      _lyrics = _lyricsController.text;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: _saveLyrics,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isEditing
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _lyricsController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Create your own lyrics',
                  border: InputBorder.none,
                ),
              ),
            )
          : _lyrics != null && _lyrics!.isNotEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_lyrics!),
                )
              : const Center(
                  child: Text('No lyrics found'),
                ),
    );
  }
}
