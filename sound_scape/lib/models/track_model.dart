import 'dart:convert';
import 'dart:typed_data';

class TrackModel {
  final String title;
  final String artist;
  Uint8List image;
  bool isPlaying;

  TrackModel({
    required this.title,
    required this.artist,
    required this.image,
    this.isPlaying = false,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      title: json['Title'],
      artist: json['Artist'],
      image: base64Decode(json['Thumbnail64string']),
      isPlaying: json['PlaybackStatus'] == 'Playing',
    );
  }
}
