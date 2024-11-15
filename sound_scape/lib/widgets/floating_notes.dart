import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class FloatingMusicNotes extends StatefulWidget {
  final double size;
  final Color color;
  final int intervalms;
  final int numIcons;
  final double travelDistance;

  const FloatingMusicNotes({
    super.key,
    required this.size,
    required this.color,
    required this.intervalms,
    this.numIcons = 5,
    this.travelDistance = 50.0,
  });

  @override
  FloatingMusicNotesState createState() => FloatingMusicNotesState();
}

class FloatingMusicNotesState extends State<FloatingMusicNotes>
    with TickerProviderStateMixin {
  late final Timer _timer;
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(milliseconds: widget.intervalms), (timer) {
      _addNewWave();
    });
  }

  void _addNewWave() {
    final controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    final animation = Tween(begin: 0.0, end: 1.0).animate(controller);

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _controllers.remove(controller);
          _animations.remove(animation);
        });
        controller.dispose();
      }
    });

    setState(() {
      _controllers.add(controller);
      _animations.add(animation);
    });

    controller.forward();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: _animations.map((animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: List.generate(widget.numIcons, (index) {
                final angle = 2 * pi * index / widget.numIcons;
                final x = cos(angle) * widget.travelDistance * animation.value;
                final y = sin(angle) * widget.travelDistance * animation.value;

                return Opacity(
                  opacity: 1.0 - animation.value,
                  child: Transform.translate(
                    offset: Offset(x, y),
                    child: Icon(
                      Icons.music_note,
                      color: widget.color,
                      size: widget.size,
                    ),
                  ),
                );
              }),
            );
          },
        );
      }).toList(),
    );
  }
}
