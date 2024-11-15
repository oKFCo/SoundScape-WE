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

  bool _identicalTracks(TrackModel? track1, TrackModel? track2) {
    if (track1 == track2) {
      return true;
    }

    if (track1 == null || track2 == null) {
      return false;
    }

    if (track1.title == track2.title && track1.artist == track2.artist) {
      return true;
    }

    return false;
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
  Future<void> updateTrackWallpapers([bool resetTimer = false]) async {
    await loadAvatarsForTrack();
    await worker.resetQueue(
        trackWallpapers, playingTrack?.isPlaying ?? false, resetTimer);
    notifyListeners();
  }

  /// Updates the currently playing track and associated wallpapers.
  Future<void> updatePlayingTrack(TrackModel? track) async {
    if (track == null) {
      _playingTrack = null;
      notifyListeners();
      return;
    }

    bool identical = _identicalTracks(_playingTrack, track);
    if (identical) {
      updateActiveWallpaper(null);
      worker.resetQueue(trackWallpapers, track.isPlaying, false);
      return;
    }

    // Update the playing track and load its wallpapers
    _playingTrack = track;
    await updateTrackWallpapers(true);
  }
}
