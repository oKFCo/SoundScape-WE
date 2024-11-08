import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) => ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color.fromARGB(235, 62, 19, 104),
        scaffoldBackgroundColor: const Color(0xFFf2f2f2).withOpacity(0.8),
        snackBarTheme: SnackBarThemeData(
          width: MediaQuery.of(context).size.width * 0.3,
          backgroundColor: Colors.white70,
          contentTextStyle: const TextStyle(color: Colors.black, fontSize: 16),
          actionTextColor: Colors.blue,
          elevation: 6.0,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFFf2f2f2),
          selectedIconTheme: IconThemeData(color: Color(0xFF7B1FA2)),
        ),
      );

  static ThemeData darkTheme(BuildContext context) => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xA83E1368),
        scaffoldBackgroundColor: const Color(0xFF121212),
        snackBarTheme: SnackBarThemeData(
          width: MediaQuery.of(context).size.width * 0.3,
          backgroundColor: Colors.black87,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
          actionTextColor: Colors.yellow,
          elevation: 6.0,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1F1F1F),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF1F1F1F),
          selectedIconTheme: IconThemeData(color: Color(0xFFCE93D8)),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
}
