import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wallpaper_model.dart';
import '../models/link_model.dart';

import '../services/User_data.dart';
import '../services/provider.dart';

import '../widgets/glowing_button.dart';
import '../widgets/tracks_list.dart';
import '../widgets/marquee.dart';

class WallpaperManagerView extends StatefulWidget {
  final WallpaperModel wallpaper;
  final VoidCallback onClose;

  const WallpaperManagerView({
    super.key,
    required this.wallpaper,
    required this.onClose,
  });

  @override
  WallpaperManagerViewState createState() => WallpaperManagerViewState();
}

class WallpaperManagerViewState extends State<WallpaperManagerView>
    with SingleTickerProviderStateMixin {
  List<Link> _addedTracks = [];
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  TrackModel? playingTrack;
  final UserData _userData = UserData();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _loadTracks();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void setLoadingState(bool loading) {
    setStateIfMounted(() => isLoading = loading);
  }

  @override
  void didUpdateWidget(covariant WallpaperManagerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallpaper.id != widget.wallpaper.id) {
      _loadTracks();
    }
  }

  Future<void> _loadTracks() async {
    setLoadingState(true);
    try {
      var tracks = await _userData.loadTracksForWallpaper(widget.wallpaper.id);
      setStateIfMounted(() {
        _addedTracks = tracks;
        isLoading = false;
      });
    } catch (e) {
      setLoadingState(false);
      // Handle error (e.g., show a message to the user)
    }
  }

  bool existsInTracks() {
    return _addedTracks.any((track) =>
        track.title == playingTrack?.title &&
        track.artist == playingTrack?.artist);
  }

  Future<void> _linkTrack() async {
    if (!isLoading && playingTrack != null) {
      setLoadingState(true);

      try {
        await _userData.linkTrack(playingTrack!, widget.wallpaper.id);
        _loadTracks();

        Provider.of<TrackProvider>(context, listen: false)
            .updateTrackWallpapers();
      } catch (e) {
        setLoadingState(false);
        // Handle error (e.g., show a message to the user)
      }
    }
  }

  Future<void> _removeTrackFromWallpaper(int index) async {
    if (isLoading || _addedTracks.isEmpty) return;

    setLoadingState(true);
    try {
      await _userData.removeTrack(
          _addedTracks[index].linkID, widget.wallpaper.id);
      setStateIfMounted(() {
        _addedTracks.removeAt(index);
        isLoading = false;
      });

      if (playingTrack != null) {
        Provider.of<TrackProvider>(context, listen: false)
            .updateTrackWallpapers();
      }
    } catch (e) {
      setLoadingState(false);
      // Handle error (e.g., show a message to the user)
    }
  }

  Future<void> _confirmAndClearAllTracks() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: Text(
              "This will permanently delete all tracks linked to ${widget.wallpaper.title}."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Clear"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setLoadingState(true);
      try {
        await _userData.deleteWallpaperLinks(widget.wallpaper.id);
        setStateIfMounted(() {
          _addedTracks.clear();
          isLoading = false;
        });

        if (existsInTracks()) {
          Provider.of<TrackProvider>(context, listen: false)
              .updateTrackWallpapers();
        }
      } catch (e) {
        setLoadingState(false);
        // Handle error (e.g., show a message to the user)
      }
    }
  }

  Future<void> _closeView() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTrackActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Consumer<TrackProvider>(
          builder: (context, trackProvider, child) {
            playingTrack = trackProvider.playingTrack;
            return playingTrack != null && !isLoading
                ? !existsInTracks()
                    ? GlowingButton(
                        onPressed: _linkTrack,
                        label: 'Link track',
                      )
                    : const Text(
                        'Already linked',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                : const SizedBox.shrink();
          },
        ),
        ElevatedButton(
          onPressed: _confirmAndClearAllTracks,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.red[900]),
          ),
          child: const Text(
            "Clear List",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaperImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.wallpaper.image;

    return SlideTransition(
      position: _offsetAnimation,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarqueeText(
                        text: widget.wallpaper.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(child: _buildWallpaperImage(imagePath)),
                      const SizedBox(height: 68),
                    ],
                  ),
                ),
                const SizedBox(width: 100),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      Expanded(
                        child: TracksList(
                          isLoading: isLoading,
                          addedTracks: _addedTracks,
                          onRemoveTrack: _removeTrackFromWallpaper,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTrackActions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 0,
            left: 0,
            child: Center(
              child: SizedBox(
                width: 60,
                child: IconButton(
                  onPressed: _closeView,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
