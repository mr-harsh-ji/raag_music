import 'package:on_audio_query/on_audio_query.dart';

class PathHelper {
  static Map<String, List<SongModel>> categorizeSongsByFolder(
      List<SongModel> songs) {
    final Map<String, List<SongModel>> folderSongs = {};
    for (final song in songs) {
      // Normalize path separators to handle Windows and Unix-like systems
      final path = song.data.replaceAll('\\', '/');
      if (path.contains('/')) {
        final directoryPath = path.substring(0, path.lastIndexOf('/'));
        if (folderSongs.containsKey(directoryPath)) {
          folderSongs[directoryPath]!.add(song);
        } else {
          folderSongs[directoryPath] = [song];
        }
      } else {
        if (folderSongs.containsKey('Others')) {
          folderSongs['Others']!.add(song);
        } else {
          folderSongs['Others'] = [song];
        }
      }
    }
    return folderSongs;
  }
}
