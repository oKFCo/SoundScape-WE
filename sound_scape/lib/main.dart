import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_tray/system_tray.dart';

import 'dart:io';
import 'dart:ui';

import 'views/wallpapers_view.dart';
import 'views/custom_playlists.dart';
import 'views/settings_screen.dart';
import 'views/wallpaper_manager.dart';

import 'services/spotify_logic.dart';
import 'services/provider.dart';

import 'widgets/spotify_card.dart';
import 'widgets/gear_icon.dart';

import 'models/wallpaper_model.dart';

import 'app_theme.dart';
import 'app_logger.dart';
// Desktop
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

final _logger = AppLogger();
bool isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    await windowManager.ensureInitialized();
    await WindowsSingleInstance.ensureSingleInstance([], "SoundScape");
    WindowOptions windowOptions = const WindowOptions(
      title: "SoundScape",
      minimumSize: Size(1060, 600),
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.focus();
    });

    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(
    ChangeNotifierProvider(
      create: (context) => TrackProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  Future<void> initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? true;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
  }

  void toggleThemeMode(bool isDark) {
    _saveThemeMode(isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: _themeMode,
      home: MainScreen(toggleThemeMode: toggleThemeMode, themeMode: _themeMode),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(bool) toggleThemeMode;
  final ThemeMode themeMode;

  const MainScreen(
      {super.key, required this.toggleThemeMode, required this.themeMode});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, WindowListener {
  int _selectedPageIndex = 0;
  late List<Widget> _pages;
  WallpaperModel? selectedWallpaper;
  final PageController _controller = PageController();
  final AppWindow appWindow = AppWindow();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    startServer();
    initSystemTray();
    _pages = [
      WallpapersView(
        onWallpaperSelected: (wallpaper) {
          setState(() {
            selectedWallpaper = wallpaper;
          });
        },
      ),
      const PlaylistsScreen(),
      StatefulBuilder(
        builder: (context, setState) {
          return SettingsScreen(
            themeMode: widget.themeMode,
            toggleThemeMode: (bool isDark) {
              setState(() {});
              widget.toggleThemeMode(isDark);
            },
          );
        },
      ),
    ];
  }

  Future<void> initSystemTray() async {
    final SystemTray systemTray = SystemTray();

    try {
      String path = Platform.isWindows
          ? 'assets/SoundScape.ico'
          : 'assets/SoundScape.ico';

      await systemTray.initSystemTray(
        title: "SoundScape",
        iconPath: path,
      );

      final trackProvider = Provider.of<TrackProvider>(context, listen: false);

      Future<Menu> createMenu() async {
        final Menu menu = Menu();
        await menu.buildFrom([
          MenuItemCheckbox(
            label: 'Disable functionality',
            checked: !trackProvider.worker.functional,
            onClicked: (menuItem) async {
              try {
                trackProvider.worker
                    .resetFunctionality(trackProvider.playingTrack != null);

                Menu updatedMenu = await createMenu();
                await systemTray.setContextMenu(updatedMenu);
              } catch (e) {
                _logger.error('Error while handling onClicked: $e');
              }
            },
          ),
          MenuItemLabel(
              label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
          MenuItemLabel(label: 'Exit', onClicked: (menuItem) => exit(0)),
        ]);
        return menu;
      }

      Menu initialMenu = await createMenu();
      await systemTray.setContextMenu(initialMenu);

      systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
        } else if (eventName == kSystemTrayEventRightClick) {
          Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
        }
      });
    } catch (e) {
      _logger.error('Error in initSystemTray: $e');
    }
  }

  @override
  void onWindowClose() async {
    appWindow.hide();
  }

  void hideWallpaperManager() {
    setState(() {
      selectedWallpaper = null;
    });
  }

  void _onItemTapped(int index) async {
    if (_selectedPageIndex != index) {
      _controller.jumpToPage(index);
      setState(() {
        _selectedPageIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    updateContext(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PageView(
                      controller: _controller,
                      onPageChanged: _onItemTapped,
                      children: _pages,
                    ),
                    if (_selectedPageIndex != 2)
                      SettingsIcon(onItemTapped: _onItemTapped),
                    if (_selectedPageIndex == 2)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                            onPressed: () {
                              _onItemTapped(0);
                            },
                          ),
                        ),
                      ),
                    if (selectedWallpaper != null)
                      Stack(
                        children: [
                          ClipRect(
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                              child: WallpaperManagerView(
                                wallpaper: selectedWallpaper!,
                                onClose: hideWallpaperManager,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 5,
            child: Consumer<TrackProvider>(
              builder: (context, trackProvider, child) {
                final track = trackProvider.playingTrack;
                if (track == null) {
                  return const SizedBox.shrink();
                }
                final trackWallpapers = trackProvider.trackWallpapers;
                return SpotifyWidget(
                  track: track,
                  trackWallpapers: trackWallpapers,
                  onShowWallpaperManager: (wallpaper) {
                    if (selectedWallpaper != wallpaper) {
                      setState(() {
                        selectedWallpaper = wallpaper;
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
