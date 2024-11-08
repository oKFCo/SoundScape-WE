import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SoundScape/app_logger.dart';
import '../models/wallpaper_model.dart';
import 'wallpapers_fetcher.dart';

final _logger = AppLogger();

class WEworker {
  List<WallpaperModel> wallpapers = [];
  Timer? _wallpaperTimer;
  int _currentWallpaperIndex = 0;
  bool functional = true;
  final Function(WallpaperModel?) onWallpaperSet;

  WEworker({required this.onWallpaperSet});

  /// Toggles the functionality of the wallpaper fetcher.
  void resetFunctionality(bool fetcherIsWorking) {
    functional = !functional;
    if (fetcherIsWorking) {
      if (functional) {
        _currentWallpaperIndex =
            (_currentWallpaperIndex + 1) % wallpapers.length;
        setWallpaper();
      } else {
        onWallpaperSet(null);
      }
    }
  }

  /// Resets the wallpaper queue based on the currently playing track.
  Future<void> resetQueue(
      List<WallpaperModel> trackWallpapers, bool trackPlaying) async {
    if (!trackPlaying) {
      _wallpaperTimer?.cancel();
      return;
    }
    try {
      wallpapers = trackWallpapers;

      if (wallpapers.isEmpty) {
        _wallpaperTimer?.cancel();
        return;
      } else if (wallpapers.length > 1) {
        if (_wallpaperTimer == null) {
          startWallpaperTimer();
        }
      }

      // Set the initial wallpaper
      setWallpaper();
    } catch (e) {
      _logger.error('Error resetting queue: $e');
    }
  }

  /// Starts the wallpaper timer to change wallpapers periodically.
  Future<void> startWallpaperTimer() async {
    _wallpaperTimer?.cancel();
    _currentWallpaperIndex = 0;
    if (wallpapers.isNotEmpty) {
      int minutes = 1;
      int seconds = 0;

      try {
        final prefs = await SharedPreferences.getInstance();
        final waitTime = prefs.getStringList('waitTime');
        if (waitTime != null) {
          minutes = int.parse(waitTime[0]);
          seconds = int.parse(waitTime[1]);
        }
        int intervalSeconds = minutes * 60 + seconds;

        _wallpaperTimer = Timer.periodic(
          Duration(seconds: intervalSeconds),
          (Timer timer) {
            if (wallpapers.isNotEmpty) {
              _currentWallpaperIndex =
                  (_currentWallpaperIndex + 1) % wallpapers.length;
              setWallpaper();
            }
          },
        );
      } catch (e) {
        _logger.error('Error starting wallpaper timer: $e');
      }
    }
  }

  /// Sets the current wallpaper using the Wallpaper Engine.
  Future<void> setWallpaper() async {
    if (wallpapers.isEmpty || !functional) return;
    String? wEngine = getWallpaperEnginePath();
    WallpaperModel currentWallpaper = wallpapers[_currentWallpaperIndex];
    String wallpaperPath = currentWallpaper.path;

    final List<String> arguments = [
      '/C',
      '$wEngine -control openWallpaper -file $wallpaperPath/project.json',
    ];

    try {
      final results = await Process.run('cmd.exe', arguments);
      if (results.exitCode == 0) {
        onWallpaperSet(currentWallpaper);
      } else {
        _logger.error('Failed to set wallpaper: ${results.stderr}');
      }
    } catch (e) {
      _logger.error('Error setting wallpaper: $e');
    }
  }

  /// Disposes of the worker and cancels the timer.
  void dispose() {
    _wallpaperTimer?.cancel();
  }
}
