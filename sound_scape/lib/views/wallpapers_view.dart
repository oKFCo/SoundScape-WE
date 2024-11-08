import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:math';

import '../services/wallpapers_fetcher.dart';
import '../models/wallpaper_model.dart';

class WallpapersView extends StatefulWidget {
  final Function(WallpaperModel) onWallpaperSelected;

  const WallpapersView({super.key, required this.onWallpaperSelected});

  @override
  WallpapersViewState createState() => WallpapersViewState();
}

class WallpapersViewState extends State<WallpapersView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late Future<List<WallpaperModel>> wallpapers;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadWallpapers();
  }

  void loadWallpapers() {
    setState(() {
      wallpapers = fetchWallpapers();
    });
  }

  void showWallpaperManager(WallpaperModel wallpaper) {
    widget.onWallpaperSelected(wallpaper);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchAndRefreshBar(context),
              Expanded(
                child: FutureBuilder<List<WallpaperModel>>(
                  future: wallpapers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }
                    final filteredWallpapers =
                        _getFilteredWallpapers(snapshot.data!);
                    if (filteredWallpapers.isEmpty) {
                      return const Center(
                          child: Text('No wallpapers match your search.'));
                    }
                    return _buildWallpaperGrid(filteredWallpapers);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndRefreshBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 8.0),
          Tooltip(
            message: 'Reload Wallpapers',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: loadWallpapers,
            ),
          ),
        ],
      ),
    );
  }

  List<WallpaperModel> _getFilteredWallpapers(List<WallpaperModel> wallpapers) {
    return wallpapers
        .where(
            (wallpaper) => wallpaper.title.toLowerCase().contains(searchQuery))
        .toList();
  }

  Widget _buildWallpaperGrid(List<WallpaperModel> wallpapers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 20.0,
        ),
        itemCount: wallpapers.length,
        itemBuilder: (context, index) {
          final wallpaper = wallpapers[index];
          return _buildWallpaperItem(wallpaper);
        },
      ),
    );
  }

  Widget _buildWallpaperItem(WallpaperModel wallpaper) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () => showWallpaperManager(wallpaper),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: isHovered
                    ? [
                        const BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8.0,
                            spreadRadius: 2.0)
                      ]
                    : [],
                image: DecorationImage(
                  image: FileImage(File(wallpaper.image)),
                  fit: BoxFit.cover,
                  colorFilter: isHovered
                      ? ColorFilter.mode(
                          Colors.black.withOpacity(0.5), BlendMode.darken)
                      : null,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _buildWallpaperTitle(wallpaper.title),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWallpaperTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (Random().nextInt(100) == 0)
            Image.asset(
              'assets/Crying-Cat.png',
              width: 300,
              height: 300,
            ),
          const SizedBox(height: 16.0),
          const Text("No wallpapers found."),
        ],
      ),
    );
  }
}
