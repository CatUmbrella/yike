import 'package:flutter/material.dart';

import '../arrange/arrange_style.dart';

class TemplateStyle {
  static const background = Color(0xFFFAFAFC);
  static const surface = Color(0xFFFFFFFF);
  static const accent = ArrangeStyle.accent;
  static const accentSoft = Color(0xFFEFF5FF);
  static const accentSofter = Color(0xFFF7FAFF);
  static const textPrimary = ArrangeStyle.textPrimary;
  static const textSecondary = Color(0xFF667085);
  static const border = Color(0xFFE5E7EB);
  static const warning = Color(0xFFEF5350);
  static const sidebar = Color(0xFFF4F4F5);
  static const searchFill = Color(0xFFF3F4F6);

  static const panelShadow = [
    BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const itemShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ) ??
        const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        );
  }

  static TextStyle sectionTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ) ??
        const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        );
  }
}

class TemplateMetrics {
  final bool compact;
  final double horizontalPadding;
  final double sideWidth;
  final double cardRadius;

  const TemplateMetrics._({
    required this.compact,
    required this.horizontalPadding,
    required this.sideWidth,
    required this.cardRadius,
  });

  factory TemplateMetrics.forWidth(double width) {
    final compact = width < 390;
    return TemplateMetrics._(
      compact: compact,
      horizontalPadding: compact ? 16 : 20,
      sideWidth: compact ? 54 : 60,
      cardRadius: compact ? 14 : 16,
    );
  }
}
