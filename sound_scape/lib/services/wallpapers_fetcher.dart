import 'dart:convert';
import 'dart:io';

import 'package:win32_registry/win32_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SoundScape/app_logger.dart';
import 'package:path/path.dart' as p;

import '../models/wallpaper_model.dart';

// Only supports Windows for now

final _logger = AppLogger();

/// Validates the Wallpaper Engine path.
Future<Directory?> validateWEPath() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String basePath = prefs.getString('basePath') ?? '';
    final parts = basePath.split('\\');
    final steamLibraryIndex = parts.lastIndexOf('steamapps');
    Directory? directory;

    if (steamLibraryIndex != -1) {
      final workshopPath =
          '${p.joinAll(parts.sublist(0, steamLibraryIndex + 1))}\\workshop\\content\\431960\\';
      directory = Directory(workshopPath);

      if (!await directory.exists()) {
        _logger.info('Workshop directory does not exist: $workshopPath');
      }
    }
    return directory;
  } catch (e) {
    _logger.error('Error validating WE path: $e');
    return null;
  }
}

/// Extracts the wallpaper ID from a given path.
String getWallpaperIDFromPath(String path) {
  final normalizedPath = p.normalize(path);
  return p.basename(normalizedPath);
}

/// Retrieves the Wallpaper Engine installation path from the Windows registry.
String? getWallpaperEnginePath() {
  try {
    final key = Registry.openPath(RegistryHive.currentUser,
        path: r'Software\WallpaperEngine');
    final wallpaperEnginePath = key.getValueAsString('InstallPath');
    key.close();

    return wallpaperEnginePath;
  } catch (e) {
    _logger.error('Error accessing registry: ${e.toString()}');
    return null;
  }
}

/// Fetches wallpaper data for a given wallpaper ID.
Future<WallpaperModel?> getWallpaperData(int wallpaperID) async {
  try {
    Directory? directory = await validateWEPath();
    if (directory != null) {
      final folder = Directory(p.join(directory.path, wallpaperID.toString()));
      final jsonFilePath = p.join(folder.path, 'project.json');
      final jsonFile = File(jsonFilePath);

      if (await jsonFile.exists()) {
        final jsonString = await jsonFile.readAsString();
        final jsonData = jsonDecode(jsonString);
        final previewFile = await findPreviewFile(folder);

        if (previewFile != null) {
          return WallpaperModel(
            id: wallpaperID,
            title: jsonData['title'] ?? '',
            image: previewFile.path,
            path: folder.path,
          );
        }
      }
    }
    return null;
  } catch (e) {
    _logger.error('Error fetching wallpaper data: $e');
    return null;
  }
}

/// Fetches all available wallpapers.
Future<List<WallpaperModel>> fetchWallpapers() async {
  final List<WallpaperModel> wallpapers = [];
  try {
    Directory? directory = await validateWEPath();
    if (directory != null) {
      final List<FileSystemEntity> folders = await directory.list().toList();

      for (var folder in folders) {
        if (folder is Directory) {
          final jsonFilePath = p.join(folder.path, 'project.json');
          final jsonFile = File(jsonFilePath);

          if (await jsonFile.exists()) {
            final jsonString = await jsonFile.readAsString();
            final jsonData = jsonDecode(jsonString);
            final int id = int.parse(getWallpaperIDFromPath(folder.path));
            final String title = jsonData['title'] ?? 'Untitled';
            final previewFile = await findPreviewFile(folder);

            if (previewFile != null) {
              wallpapers.add(
                WallpaperModel(
                  id: id,
                  title: title,
                  image: previewFile.path,
                  path: folder.path,
                ),
              );
            }
          }
        }
      }

      if (wallpapers.isEmpty) {
        throw Exception("No wallpapers found");
      }
    }
  } catch (e) {
    _logger.error('Error fetching wallpapers: $e');
    throw Exception("Failed to fetch wallpapers");
  }

  return wallpapers;
}

/// Finds a preview file with supported extensions in the given folder.
Future<File?> findPreviewFile(Directory folder) async {
  final List<String> extensions = ['jpg', 'jpeg', 'png', 'bmp', 'gif'];

  for (var extension in extensions) {
    final previewPath = p.join(folder.path, 'preview.$extension');
    final previewFile = File(previewPath);
    if (await previewFile.exists()) {
      return previewFile;
    }
  }
  return null;
}
