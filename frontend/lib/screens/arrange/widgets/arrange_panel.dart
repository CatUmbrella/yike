import 'package:flutter/material.dart';

import '../arrange_style.dart';

class ArrangePanel extends StatelessWidget {
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double? radius;
  final Widget child;

  const ArrangePanel({
    super.key,
    required this.margin,
    required this.padding,
    this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedRadius =
        radius ??
        ArrangeLayoutMetrics.forWidth(
          MediaQuery.sizeOf(context).width,
        ).panelRadius;
    final borderRadius = BorderRadius.circular(resolvedRadius);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: ArrangeStyle.surface,
        borderRadius: borderRadius,
        border: Border.all(color: ArrangeStyle.border),
        boxShadow: ArrangeStyle.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
