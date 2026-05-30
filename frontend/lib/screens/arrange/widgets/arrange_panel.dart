import 'package:flutter/material.dart';

class ArrangePanel extends StatelessWidget {
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Widget child;

  const ArrangePanel({
    super.key,
    required this.margin,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
