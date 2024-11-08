import '../services/user_data.dart';
import '../services/wallpapers_fetcher.dart';

import '../models/wallpaper_model.dart';
import '../models/track_model.dart';
export '../models/track_model.dart';

import 'package:flutter/material.dart';
import 'package:SoundScape/app_logger.dart';

import 'engine.dart';

class TrackProvider extends ChangeNotifier {
  TrackModel? _playingTrack;

  final UserData _userData = UserData();
  final AppLogger _logger = AppLogger();
  TrackModel? get playingTrack => _playingTrack;
  List<WallpaperModel> trackWallpapers = [];

  late final WEworker worker;

  TrackProvider() {
    worker = WEworker(onWallpaperSet: updateActiveWallpaper);
  }

  /// Loads wallpapers associated with the currently playing track.
  Future<void> loadAvatarsForTrack() async {
    if (_playingTrack == null) {
      return;
    }
    try {
      List<int> wallpaperIDs = await _userData.loadWallpapersForTrack(
        _playingTrack!.title,
        _playingTrack!.artist,
      );

      List<WallpaperModel> wallpapers = [];
      for (int id in wallpaperIDs) {
        WallpaperModel? wallpaper = await getWallpaperData(id);
        if (wallpaper != null) {
          wallpapers.add(wallpaper);
        }
      }

      trackWallpapers = wallpapers;
      notifyListeners();
    } catch (e) {
      _logger.error('Error loading avatars for track: $e');
    }
  }

  /// Updates the active wallpaper.
  void updateActiveWallpaper(WallpaperModel? wallpaper) {
    for (var w in trackWallpapers) {
      w.active = false;
    }

    if (wallpaper != null) {
      int index = trackWallpapers.indexOf(wallpaper);
      if (index != -1) {
        trackWallpapers[index].active = true;
      }
    }
    notifyListeners();
  }

  /// Updates the list of wallpapers for the current track.
  Future<void> updateTrackWallpapers() async {
    await loadAvatarsForTrack();
    worker.resetQueue(trackWallpapers, playingTrack?.isPlaying ?? false);
    notifyListeners();
  }

  /// Updates the currently playing track and associated wallpapers.
  Future<void> updatePlayingTrack(TrackModel? track) async {
    if (track == null) {
      _playingTrack = null;
      notifyListeners();
      return;
    }

    // Check if the new track is the same as the current track and only update playing status
    if (_playingTrack != null &&
        playingTrack!.title == track.title &&
        _playingTrack!.artist == track.artist) {
      worker.resetQueue(trackWallpapers, track.isPlaying);
      updateActiveWallpaper(null);
      return;
    }

    // Update the playing track and load its wallpapers
    _playingTrack = track;
    await updateTrackWallpapers();
  }
}
