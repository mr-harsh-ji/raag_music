class Playlist {
  String name;
  List<int> songIds;

  Playlist({required this.name, required this.songIds});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'songIds': songIds,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      name: map['name'],
      songIds: List<int>.from(map['songIds']),
    );
  }
}
