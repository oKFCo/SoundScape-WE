import 'package:flutter/material.dart';

import 'dart:io';

import '../models/wallpaper_model.dart';

class OverlappingAvatarGroup extends StatelessWidget {
  final List<WallpaperModel> avatars;
  final double size;
  final double overlappingFactor;
  final int maxDisplayedAvatars;
  final void Function(WallpaperModel avatar) onAvatarClick;
  final Color activeOutlineColor;
  final Color musicNoteColor;

  const OverlappingAvatarGroup({
    super.key,
    required this.avatars,
    required this.onAvatarClick,
    this.size = 50.0,
    this.maxDisplayedAvatars = 3,
    this.overlappingFactor = 2.5,
    this.activeOutlineColor = Colors.blue,
    this.musicNoteColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final displayedAvatars = avatars.take(maxDisplayedAvatars).toList();
    final extraAvatars = avatars.skip(maxDisplayedAvatars).toList();
    final extraCount = extraAvatars.length;

    double totalWidth = size +
        (displayedAvatars.length - 1) * (size / overlappingFactor) +
        (extraCount > 0 ? size : 0); // Account for the size of the +N avatar

    return SizedBox(
      height: size,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...displayedAvatars.asMap().entries.map((entry) {
            int index = entry.key;
            WallpaperModel avatar = entry.value;

            return Positioned(
              left: index * (size / overlappingFactor),
              child: GestureDetector(
                onTap: () {
                  onAvatarClick(avatar);
                },
                child: Tooltip(
                  message: avatar.title,
                  child: Semantics(
                    label: avatar.title,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (avatar.active)
                          FloatingMusicNotes(
                            size: size,
                            color: musicNoteColor,
                          ),
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: avatar.active
                                ? Border.all(
                                    color: activeOutlineColor,
                                    width: 3.0,
                                  )
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: size / 2,
                            backgroundImage: FileImage(File(avatar.image)),
                            onBackgroundImageError: (_, __) =>
                                const AssetImage('assets/placeholder.png'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (extraCount > 0)
            Positioned(
              left: displayedAvatars.length * (size / overlappingFactor),
              child: GestureDetector(
                onTapDown: (details) =>
                    _showDetailedTooltip(context, extraAvatars, details),
                child: Tooltip(
                  message: '+$extraCount',
                  child: CircleAvatar(
                    radius: size / 2,
                    backgroundColor: const Color.fromARGB(255, 49, 41, 41),
                    child: Text(
                      '+$extraCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDetailedTooltip(BuildContext context,
      List<WallpaperModel> extraAvatars, TapDownDetails details) {
    final Offset buttonPosition = details.globalPosition;
    final buttonSize = Size(size, size);
    const menuWidth = 200.0;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx - menuWidth / 2,
        buttonPosition.dy + buttonSize.height / 2,
        buttonPosition.dx + menuWidth / 2,
        buttonPosition.dy - buttonSize.height / 2,
      ),
      items: extraAvatars.map((avatar) {
        return PopupMenuItem(
          child: GestureDetector(
            onTap: () {
              onAvatarClick(avatar);
              Navigator.of(context).pop();
            },
            child: SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: size / 4,
                    backgroundImage: FileImage(File(avatar.image)),
                    onBackgroundImageError: (_, __) =>
                        const AssetImage('assets/placeholder.png'),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      avatar.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class FloatingMusicNotes extends StatefulWidget {
  final double size;
  final Color color;

  const FloatingMusicNotes({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  FloatingMusicNotesState createState() => FloatingMusicNotesState();
}

class FloatingMusicNotesState extends State<FloatingMusicNotes>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    floatAnimation = Tween<double>(begin: 0, end: -widget.size * 0.3)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      await _controller.forward();
      await _controller.reverse();

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Music notes on the right side
              ...List.generate(2, (i) {
                final offsetX = widget.size / 2 + 5.0 + (i * 5.0);
                final offsetY = floatAnimation.value - (i * 20.0);

                return Positioned(
                  left: offsetX,
                  top: offsetY,
                  child: Transform.rotate(
                    angle: _controller.value *
                        (i % 2 == 0 ? -0.5 : 0.5), // Alternate rotation
                    child: Icon(
                      Icons.music_note_outlined,
                      color: widget.color.withOpacity(_controller.value),
                      size: 16.0,
                    ),
                  ),
                );
              }),
              // Mirrored music notes on the left
              ...List.generate(2, (i) {
                final offsetX =
                    widget.size / 2 - 25.0 - (i * 5.0); // Adjust for top left
                final offsetY = floatAnimation.value - (i * 20.0);

                return Positioned(
                  left: offsetX,
                  top: offsetY,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(-1.0, 1.0, 1.0) // Apply horizontal flip
                      ..rotateZ(-_controller.value * (i % 2 == 0 ? 0.5 : -0.5)),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.music_note_outlined,
                      color: widget.color.withOpacity(_controller.value),
                      size: 16.0,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
