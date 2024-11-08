class WallpaperModel {
  final int id;
  final String title;
  final String image;
  final String path;
  bool active;

  WallpaperModel({
    required this.id,
    required this.title,
    required this.image,
    required this.path,
    this.active = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'path': path,
    };
  }

  factory WallpaperModel.fromJson(Map<String, dynamic> json) {
    return WallpaperModel(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      path: json['path'],
    );
  }
}
