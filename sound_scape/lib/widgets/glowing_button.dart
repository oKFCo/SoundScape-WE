import 'package:flutter/material.dart';

class GlowingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const GlowingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.textStyle,
    this.padding,
  });

  @override
  GlowingButtonState createState() => GlowingButtonState();
}

Color getBrightestColor(Color color, {double factor = 0.2}) {
  // Ensure the factor is within a reasonable range (0.0 to 1.0)
  factor = factor.clamp(0.0, 1.0);

  // Blend the color with white by adjusting the RGB values
  int r = (color.red + (255 - color.red) * factor).toInt();
  int g = (color.green + (255 - color.green) * factor).toInt();
  int b = (color.blue + (255 - color.blue) * factor).toInt();

  return Color.fromRGBO(r, g, b, color.opacity);
}

class GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -5.0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                getBrightestColor(theme.primaryColor),
                theme.primaryColor,
              ],
              stops: const [0.0, 0.5, 1],
              begin: Alignment(_animation.value, 0.0),
              end: Alignment(_animation.value + 1, 0.0),
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColorDark.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: widget.textStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
