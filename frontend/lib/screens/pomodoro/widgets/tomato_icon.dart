import 'package:flutter/material.dart';

class TomatoIcon extends StatelessWidget {
  const TomatoIcon({super.key, this.size = 28, this.showBackground = false});

  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final image = ClipOval(
      child: Image.asset(
        'assets/images/tomato_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _FallbackTomato(size: size),
      ),
    );

    if (!showBackground) return image;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: image,
    );
  }
}

class _FallbackTomato extends StatelessWidget {
  const _FallbackTomato({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.circle_rounded,
        color: const Color(0xFFE94235),
        size: size,
      ),
    );
  }
}
