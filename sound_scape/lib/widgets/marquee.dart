import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
  });

  bool _willTextOverflow({
    required String text,
    TextStyle? style,
    required double maxWidth,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  double _calculateTextHeight(TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.height;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle = style ??
        (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
            .copyWith(fontSize: 24);
    final double textHeight = _calculateTextHeight(effectiveStyle);

    return SizedBox(
      height: textHeight, // Set the height to match calculated text height
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final isOverflowing = _willTextOverflow(
              text: text, style: effectiveStyle, maxWidth: maxWidth);

          return isOverflowing
              ? Marquee(
                  text: text,
                  scrollAxis: Axis.horizontal,
                  blankSpace: 50.0,
                  velocity: 50.0,
                  pauseAfterRound: const Duration(seconds: 3),
                  style: effectiveStyle,
                )
              : Text(
                  text,
                  style: effectiveStyle,
                );
        },
      ),
    );
  }
}
