import 'dart:io';

import 'package:flutter/material.dart';

import '../models/wallpaper_model.dart';
import 'floating_notes.dart';

class OverlappingAvatarGroup extends StatelessWidget {
  final List<WallpaperModel> avatars;
  final double size;
  final double overlappingFactor;
  final void Function(WallpaperModel avatar) onAvatarClick;
  final Color activeOutlineColor;
  final Color musicNoteColor;

  const OverlappingAvatarGroup({
    super.key,
    required this.avatars,
    required this.onAvatarClick,
    this.size = 50.0,
    this.overlappingFactor = 2.5,
    this.activeOutlineColor = Colors.lightBlue,
    this.musicNoteColor = Colors.blue,
  });

// loop through extra avatars and see if they are active
  bool isExtraActive(extraAvatars) {
    for (var avatar in extraAvatars) {
      if (avatar.active) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final availableWidth = constraints.maxWidth;
        final maxDisplayedAvatars =
            ((availableWidth - size) / (size / overlappingFactor)).floor();
        final displayedAvatars = avatars.take(maxDisplayedAvatars).toList();
        final extraAvatars = avatars.skip(maxDisplayedAvatars).toList();
        final extraCount = extraAvatars.length;
        double totalWidth = size +
            (displayedAvatars.length - 1) * (size / overlappingFactor) +
            (extraCount > 0 ? (size / overlappingFactor) : 0);

        return Align(
          alignment: Alignment.centerRight,
          child: avatars.isNotEmpty
              ? SizedBox(
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
                                // avatar with music note
                                child: AvatarWithMusicNotes(
                                  imagePath: avatar.image,
                                  size: size,
                                  active: avatar.active,
                                  activeOutlineColor: activeOutlineColor,
                                  musicNoteColor: musicNoteColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (extraCount > 0)
                        Positioned(
                          left: displayedAvatars.length *
                              (size / overlappingFactor),
                          child: GestureDetector(
                            onTapDown: (details) => _showDetailedTooltip(
                                context, extraAvatars, details),
                            child: Tooltip(
                              message: '+$extraCount',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: (isExtraActive(extraAvatars))
                                      ? Border.all(
                                          color: activeOutlineColor,
                                          width: 3.0,
                                        )
                                      : null,
                                ),
                                child: CircleAvatar(
                                  radius: size / 2,
                                  backgroundColor:
                                      const Color.fromARGB(255, 49, 41, 41),
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
                        ),
                    ],
                  ),
                )
              : const Icon(
                  Icons.not_interested,
                  color: Colors.white,
                ),
        );
      },
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
          onTap: () {
            onAvatarClick(avatar);
          },
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                AvatarWithMusicNotes(
                  imagePath: avatar.image,
                  size: 35,
                  active: avatar.active,
                  activeOutlineColor: activeOutlineColor,
                  musicNoteColor: musicNoteColor,
                  musicNotesRows: 1,
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
        );
      }).toList(),
    );
  }
}

// new widget for the circle avatar with floating music notes codium
class AvatarWithMusicNotes extends StatelessWidget {
  final double size;
  final String imagePath;
  final bool active;
  final Color musicNoteColor;
  final Color activeOutlineColor;
  final int musicNotesRows;

  const AvatarWithMusicNotes({
    super.key,
    required this.size,
    required this.imagePath,
    required this.active,
    required this.musicNoteColor,
    required this.activeOutlineColor,
    this.musicNotesRows = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (active)
          FloatingMusicNotes(
            size: 15,
            color: musicNoteColor,
            intervalms: 700,
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: active
                ? Border.all(
                    color: activeOutlineColor,
                    width: 3.0,
                  )
                : null,
          ),
          child: CircleAvatar(
            radius: size / 2,
            backgroundImage: FileImage(File(imagePath)),
            onBackgroundImageError: (_, __) =>
                const AssetImage('assets/placeholder.png'),
          ),
        ),
      ],
    );
  }
}
