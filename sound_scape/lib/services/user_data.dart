import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/link_model.dart';
import '../models/track_model.dart';
import '../app_logger.dart';

class UserData {
  static final UserData _instance = UserData._internal();
  static final _logger = AppLogger();
  factory UserData() => _instance;

  static Database? _database;

  UserData._internal();

  /// Gets the instance of the database, initializes if not already done.
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB();
      _logger.info('Database initialized successfully.');
    } catch (e) {
      _logger.error('Failed to initialize database: $e');
    }
    return _database!;
  }

  /// Initializes the database.
  Future<Database> _initDB() async {
    Directory appDataDir = await getApplicationDocumentsDirectory();
    String path = join(appDataDir.path, '/SoundScape/SSuser_data.db');
    _logger.info('Database path: $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE WallpaperLinks (
            linkID INTEGER PRIMARY KEY AUTOINCREMENT,
            wallpaperID varchar(40),
            title varchar(255),
            artist varchar(255),
            image64 MEDIUMTEXT
          )
        ''');
        _logger.info('Database table created successfully.');
      },
    );
  }

  /// Loads tracks associated with a specific wallpaper.
  Future<List<Link>> loadTracksForWallpaper(int wallpaperID) async {
    try {
      final db = await database;
      final List<Map<String, Object?>> sqlData = await db.rawQuery(
          "SELECT * FROM WallpaperLinks WHERE wallpaperID='$wallpaperID'");

      // Map SQL rows to Link objects
      List<Link> links = sqlData.map((row) => Link.fromMap(row)).toList();

      return links;
    } catch (e) {
      _logger.error('Error loading tracks for wallpaper: $e');
      return [];
    }
  }

  /// Loads wallpapers associated with a specific track.
  Future<List<int>> loadWallpapersForTrack(String title, String artist) async {
    try {
      final db = await database;
      final List<Map<String, Object?>> query = await db.rawQuery(
          "SELECT wallpaperID FROM WallpaperLinks WHERE title=? AND artist=?",
          [title, artist]);

      List<int> wallpaperIDs = query.map((wallpaper) {
        return int.parse(wallpaper['wallpaperID'] as String);
      }).toList();

      return wallpaperIDs;
    } catch (e) {
      _logger.error('Error loading wallpapers for track: $e');
      return [];
    }
  }

  /// Links a track to a wallpaper.
  Future<int> linkTrack(TrackModel track, int wallpaperID) async {
    final db = await database;
    try {
      Uint8List compressedBytes = await compute(_compressImage, track.image);
      String compressedImage64 = base64Encode(compressedBytes);

      int result = await db.rawInsert(
        'INSERT INTO WallpaperLinks (wallpaperID, title, artist, image64) VALUES (?, ?, ?, ?)',
        [wallpaperID, track.title, track.artist, compressedImage64],
      );

      _logger.info('Track linked successfully with ID: $result');
      return result;
    } catch (e) {
      _logger.error(
          'Error linking track: ${e.toString().replaceAll(RegExp(r'base64,.*'), '[Image 64 data hidden]')}');
      return -1;
    }
  }

  /// Removes a track link.
  Future<void> removeTrack(int linkID, int wallpaperID) async {
    try {
      final db = await database;
      await db.rawDelete("DELETE FROM WallpaperLinks WHERE linkID='$linkID'");
      _logger.info('Track link removed successfully.');
    } catch (e) {
      _logger.error('Error removing track: $e');
    }
  }

  /// Deletes all links associated with a specific wallpaper.
  Future<void> deleteWallpaperLinks(int wallpaperID) async {
    try {
      final db = await database;
      await db.rawDelete(
          "DELETE FROM WallpaperLinks WHERE wallpaperID='$wallpaperID'");
      _logger.info('Wallpaper links deleted successfully.');
    } catch (e) {
      _logger.error('Error deleting wallpaper links: $e');
    }
  }

  /// Clears all data from the database.
  Future<void> clearDatabase() async {
    try {
      final db = await database;
      await db.delete('WallpaperLinks');
      _logger.info('Database cleared successfully.');
    } catch (e) {
      _logger.error('Error clearing database: $e');
    }
  }

  /// Compresses the thumbnails of the tracks (because why not).
  Future<Uint8List> _compressImage(Uint8List imageData) async {
    try {
      img.Image? originalImage = img.decodeImage(imageData);
      if (originalImage != null) {
        img.Image compressedImage =
            img.copyResize(originalImage, width: 100, height: 100);
        return Uint8List.fromList(img.encodeJpg(compressedImage, quality: 94));
      }
      return imageData;
    } catch (e) {
      _logger.error('Error compressing image: $e');
      return imageData;
    }
  }
}
