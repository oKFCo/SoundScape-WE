import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_at_startup/launch_at_startup.dart'; // Windows only

import '../services/wallpapers_fetcher.dart';
import '../services/spotify_logic.dart';

import '../widgets/duration_picker.dart';
import '../widgets/reset_database.dart';

import 'dart:io';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(bool) toggleThemeMode;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.toggleThemeMode,
  });

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _basePathController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final FocusNode _basePathFocusNode = FocusNode();
  final FocusNode _portFocusNode = FocusNode();
  bool _loadOnStartup = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loadOnStartup = await launchAtStartup.isEnabled();
    setState(() {
      _basePathController.text = prefs.getString('basePath') ?? '';
      _portController.text = prefs.getString('socketPort') ?? '5000';
      _loadOnStartup = loadOnStartup;
    });
  }

  Future<void> _saveBasePath() async {
    if (_basePathController.text.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('basePath', _basePathController.text);
      _showSnackBar('Wallpaper Engine path saved.');
    }
  }

  Future<void> _savePort() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? existingPort = prefs.getString('socketPort');

      if (existingPort != _portController.text) {
        await prefs.setString('socketPort', _portController.text);
        _showSnackBar('Socket port saved, port changed.');
        startServer();
      } else {
        _showSnackBar('Socket port saved, but no change.');
      }
    }
  }

  Future<void> _autoDetectBasePath() async {
    setState(() {
      isLoading = true;
    });

    String? detectedPath = getWallpaperEnginePath();
    if (detectedPath != null) {
      setState(() {
        _basePathController.text = detectedPath;
      });
      _showSnackBar('Wallpaper Engine path auto-detected');
      await _saveBasePath();
      await fetchWallpapers();
    } else {
      _showSnackBar('Wallpaper Engine not found');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _toggleStartup(bool value) async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loadOnStartup', value);
    if (value) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }

    setState(() {
      _loadOnStartup = value;
      isLoading = false;
    });
  }

  Future<void> _restartExplorer() async {
    try {
      String explorerPath = r'C:\Windows\explorer.exe';

      await Process.run('taskkill', ['/f', '/im', 'explorer.exe']);
      await Process.run(explorerPath, []);
      _showSnackBar('Restarted Windows Explorer successfully.');
    } catch (e) {
      _showSnackBar('Failed to restart Windows Explorer: $e');
    }
  }

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Can't See Wallpapers?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If you can\'t see your wallpapers, try the following:\n\n'
                '- Ensure the Wallpaper Engine path is correct.\n'
                '- Check if Wallpaper Engine is running.\n'
                '- Restart Windows Explorer.\n'
                '- Restart the application and try again.',
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _restartExplorer();
                },
                child: const Text(
                  'Restart Windows Explorer',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  void dispose() {
    _basePathController.dispose();
    _portController.dispose();
    _basePathFocusNode.dispose();
    _portFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (isLoading) const Center(child: CircularProgressIndicator()),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(32.0),
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _basePathController,
                            focusNode: _basePathFocusNode,
                            maxLength: 256,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Wallpaper Engine Path',
                              hintText:
                                  'Enter the path to your Wallpaper Engine installation',
                              prefixIcon: Icon(Icons.folder),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: isLoading ? null : _saveBasePath,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: isLoading ? null : _autoDetectBasePath,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search),
                              SizedBox(width: 8),
                              Text('Auto Detect'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: _portController,
                              focusNode: _portFocusNode,
                              maxLength: 5,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Socket Port',
                                hintText:
                                    'Enter the port number for the socket',
                                prefixIcon: Icon(Icons.settings_ethernet),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Port field cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: isLoading ? null : _savePort,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: const Text("Dark Mode"),
                      subtitle:
                          const Text("Toggle dark theme for the application."),
                      trailing: Switch(
                        value: widget.themeMode == ThemeMode.dark,
                        onChanged: (bool value) {
                          widget.toggleThemeMode(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.rocket_launch),
                      title: const Text("Load on Startup"),
                      subtitle: const Text(
                          "Enable or disable app loading on system startup."),
                      trailing: Switch(
                        value: _loadOnStartup,
                        onChanged: _toggleStartup,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text("Can't see wallpapers?"),
                      subtitle: const Text("Troubleshooting tips"),
                      onTap: _showTroubleshootingDialog,
                    ),
                    const SizedBox(height: 20),
                    const DurationPicker(),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: ResetDatabaseButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
