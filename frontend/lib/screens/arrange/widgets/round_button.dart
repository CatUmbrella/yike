import 'package:flutter/material.dart';

import '../arrange_style.dart';

class RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const RoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    ).compact;
    final size = compact ? 54.0 : 62.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ArrangeStyle.surface,
          shape: BoxShape.circle,
          border: Border.all(color: ArrangeStyle.border),
          boxShadow: ArrangeStyle.panelShadow,
        ),
        child: Icon(icon, color: color, size: compact ? 34 : 40),
      ),
    );
  }
}
