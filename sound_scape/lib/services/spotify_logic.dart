import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:SoundScape/app_logger.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'provider.dart';

const String processExe = 'SS_Fetcher.exe';
final _logger = AppLogger();

/// Checks if the fetcher process is currently running.
Future<bool> isProcessRunning() async {
  try {
    final result = await Process.run('tasklist', []);
    return result.stdout.toString().contains(processExe);
  } catch (e) {
    _logger.error('Error checking if fetcher is running: $e');
    return false;
  }
}

/// Starts the fetcher process.
Future<void> startProcess(String processPath, String port) async {
  await killProcessIfRunning();

  try {
    await Process.start(processPath, [port], runInShell: true);
  } catch (e) {
    _logger.error('Error starting fetcher: $e');
  }
}

/// Kills the fetcher process if it's running.
Future<void> killProcessIfRunning() async {
  if (await isProcessRunning()) {
    try {
      await Process.run('taskkill', ['/F', '/IM', processExe],
          runInShell: true);
    } catch (e) {
      _logger.error('Error killing Fetcher: $e');
    }
  }
}

late BuildContext registeredContext;
ServerSocket? _server;

/// Updates the global BuildContext reference.
void updateContext(BuildContext context) {
  registeredContext = context;
}

/// Starts the server to listen for incoming connections.
void startServer() async {
  if (_server != null) {
    await _server!.close();
  }

  final prefs = await SharedPreferences.getInstance();
  final port = prefs.getString('socketPort') ?? '5000';

  try {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, int.parse(port));
    _logger.info('Server listening on port $port');

    startProcess(
        '${p.dirname(Platform.resolvedExecutable)}/fetcher/$processExe', port);

    await for (var socket in _server!) {
      _logger.info('New client connected');
      handleClient(socket);
    }
  } catch (e) {
    _logger.error('Error starting server: $e');
  }
}

/// Handles incoming client connections and processes their data.
void handleClient(Socket socket) {
  final address = socket.remoteAddress.address;
  final port = socket.remotePort;
  _logger.info('Connection from $address:$port');

  String buffer = '';

  socket.listen(
    (data) {
      buffer += utf8.decode(data);

      // Check if buffer contains complete JSON objects
      while (buffer.contains('\n')) {
        int newlineIndex = buffer.indexOf('\n');

        String message = buffer.substring(0, newlineIndex);

        buffer = buffer.substring(newlineIndex + 1);

        // Process the complete message
        try {
          // JSON check to see if message starts with `{` and ends with `}`
          if (message.trim().startsWith('{') && message.trim().endsWith('}')) {
            final jsonData = jsonDecode(message);
            TrackModel playingTrack = TrackModel.fromJson(jsonData);
            Provider.of<TrackProvider>(registeredContext, listen: false)
                .updatePlayingTrack(playingTrack);
          }
        } catch (e) {
          _logger.error('Error parsing JSON: $e');
        }
      }
    },
    onDone: () {
      _logger.warning('Client disconnected');
      socket.destroy();
    },
    onError: (error) {
      _logger.error('Socket error: $error');
      socket.destroy();
    },
  );
}
