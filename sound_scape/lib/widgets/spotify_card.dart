import 'package:flutter/material.dart';
import 'package:SoundScape/models/track_model.dart';

import '../models/wallpaper_model.dart';

import 'avatar_group.dart';
import 'marquee.dart';

class SpotifyWidget extends StatefulWidget {
  final TrackModel track;
  final void Function(WallpaperModel) onShowWallpaperManager;
  final List<WallpaperModel> trackWallpapers;

  const SpotifyWidget({
    super.key,
    required this.track,
    required this.trackWallpapers,
    required this.onShowWallpaperManager,
  });

  @override
  SpotifyWidgetState createState() => SpotifyWidgetState();
}

class SpotifyWidgetState extends State<SpotifyWidget> {
  static const double imageSize = 50.0;
  static const double titleFontSize = 15.0;
  static const double subtitleFontSize = 12.0;
  static const double titleWidthFactor = 3.0;

  LinearGradient _getGradient(ThemeData theme) {
    return LinearGradient(
      colors: [
        const Color(0xFF1DB954),
        theme.primaryColor,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.track.title.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final double cardWidth = MediaQuery.of(context).size.width;
    final double titleWidth = cardWidth / titleWidthFactor;

    return Container(
      width: MediaQuery.of(context).size.width / 2 - 65,
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        gradient: _getGradient(theme),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.memory(
              widget.track.image,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: titleWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MarqueeText(
                  text: widget.track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.track.artist,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: subtitleFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: OverlappingAvatarGroup(
              overlappingFactor: 1.2,
              avatars: widget.trackWallpapers,
              onAvatarClick: widget.onShowWallpaperManager,
            ),
          ),
        ],
      ),
    );
  }
}
