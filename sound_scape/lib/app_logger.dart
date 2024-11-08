import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  static final Logger _logger = Logger('AppLogger');
  static File? _logFile;

  factory AppLogger() => _instance;

  AppLogger._internal() {
    _setupLogging();
  }

  Future<void> _setupLogging() async {
    Logger.root.level = Level.ALL;

    final directory = await getApplicationDocumentsDirectory();
    final logDirectory = Directory('${directory.path}/SoundScape');

    if (!await logDirectory.exists()) {
      await logDirectory.create(recursive: true);
    }

    _logFile = File('${logDirectory.path}/app.log');

    Logger.root.onRecord.listen((record) {
      final logMessage =
          '${record.level.name}: ${record.time}: ${record.message}';
      _writeToFile(logMessage);
    });
  }

  Future<void> _writeToFile(String message) async {
    if (_logFile != null) {
      await _logFile!.writeAsString('$message\n', mode: FileMode.append);
    }
  }

  void info(String message) {
    _logger.info(message);
  }

  void warning(String message) {
    _logger.warning(message);
  }

  void error(String message) {
    _logger.severe(message);
  }
}
