import 'dart:convert';
import 'dart:typed_data';

class Link {
  final int linkID;
  final String wallpaperID;
  final String title;
  final String artist;
  final Uint8List image;

  Link({
    required this.linkID,
    required this.wallpaperID,
    required this.title,
    required this.artist,
    required this.image,
  });

  // Create a Link object from a Map
  factory Link.fromMap(Map<String, dynamic> map) {
    return Link(
      linkID: map['linkID'], // Extract linkID from the map
      wallpaperID: map['wallpaperID'],
      title: map['title'],
      artist: map['artist'],
      image: base64Decode(map['image64']), // Assuming this is already Uint8List
    );
  }

  // Create a Link object from a JSON string
  factory Link.fromJson(String source) => Link.fromMap(json.decode(source));
}
