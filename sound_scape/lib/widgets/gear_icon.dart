import 'package:flutter/material.dart';

class SettingsIcon extends StatefulWidget {
  final Function(int) onItemTapped;

  const SettingsIcon({super.key, required this.onItemTapped});

  @override
  SettingsIconState createState() => SettingsIconState();
}

class SettingsIconState extends State<SettingsIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _settingsIconController;

  static const double iconTop = 20.0;
  static const double iconLeft = 20.0;

  @override
  void initState() {
    super.initState();
    _settingsIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _settingsIconController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovering) {
    if (_isHovering != isHovering) {
      setState(() => _isHovering = isHovering);
      if (isHovering && !_settingsIconController.isAnimating) {
        _settingsIconController.repeat();
      } else {
        _settingsIconController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoverColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);
    return Positioned(
      top: iconTop,
      left: iconLeft,
      child: InkWell(
        onTap: () {
          widget.onItemTapped(2);
        },
        onHover: _handleHover,
        child: Tooltip(
          message: 'Settings',
          child: Semantics(
            label: 'Settings Icon',
            child: RotationTransition(
              turns: _settingsIconController,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _isHovering ? hoverColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8), // Padding for icon space
                child: const Icon(
                  Icons.settings,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
