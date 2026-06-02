import 'package:flutter/material.dart';

class ArrangeStyle {
  static const background = Color(0xFFF4F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFF0A84FF);
  static const accentSoft = Color(0xFFEAF4FF);
  static const accentSofter = Color(0xFFF3F9FF);
  static const textPrimary = Color(0xFF26344D);
  static const textSecondary = Color(0xFF5E6A7D);
  static const border = Color(0xFFDDEAF8);
  static const gridLine = Color(0xFFE5EEF8);
  static const eventBoxTitleSize = 20.0;
  static const returnToToday = Color(0xFFEF5350);

  static const panelShadow = [
    BoxShadow(color: Color(0x1A5C8FC5), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static const itemShadow = [
    BoxShadow(color: Color(0x105C8FC5), blurRadius: 10, offset: Offset(0, 4)),
  ];
}

class ArrangeEventColors {
  final Color accent;
  final Color soft;
  final Color softer;
  final Color border;
  final Color badge;

  const ArrangeEventColors({
    required this.accent,
    required this.soft,
    required this.softer,
    required this.border,
    required this.badge,
  });
}

class ArrangeQuadrantStyle {
  final String id;
  final String title;
  final String axisTitle;
  final IconData icon;
  final ArrangeEventColors colors;

  const ArrangeQuadrantStyle({
    required this.id,
    required this.title,
    required this.axisTitle,
    required this.icon,
    required this.colors,
  });
}

class ArrangeQuadrants {
  static const defaultColors = ArrangeEventColors(
    accent: ArrangeStyle.accent,
    soft: ArrangeStyle.accentSoft,
    softer: ArrangeStyle.accentSofter,
    border: Color(0xFFB8DBFF),
    badge: Color(0xFFEAF4FF),
  );

  static const urgentImportant = ArrangeQuadrantStyle(
    id: 'urgent_important',
    title: '紧急且重要',
    axisTitle: '重要且紧急',
    icon: Icons.priority_high_rounded,
    colors: ArrangeEventColors(
      accent: Color(0xFFFF3B6B),
      soft: Color(0xFFFFE8EF),
      softer: Color(0xFFFFF4F7),
      border: Color(0xFFFFC7D4),
      badge: Color(0xFFFFDCE5),
    ),
  );

  static const urgentNotImportant = ArrangeQuadrantStyle(
    id: 'urgent_not_important',
    title: '紧急不重要',
    axisTitle: '不重要但紧急',
    icon: Icons.priority_high_rounded,
    colors: ArrangeEventColors(
      accent: Color(0xFFFFB02E),
      soft: Color(0xFFFFF2D7),
      softer: Color(0xFFFFFAEF),
      border: Color(0xFFFFDF9E),
      badge: Color(0xFFFFECC4),
    ),
  );

  static const notUrgentImportant = ArrangeQuadrantStyle(
    id: 'not_urgent_important',
    title: '不紧急但重要',
    axisTitle: '重要不紧急',
    icon: Icons.star_rounded,
    colors: ArrangeEventColors(
      accent: Color(0xFF8A3FFC),
      soft: Color(0xFFF0E7FF),
      softer: Color(0xFFFAF6FF),
      border: Color(0xFFDCC8FF),
      badge: Color(0xFFEADFFF),
    ),
  );

  static const notUrgentNotImportant = ArrangeQuadrantStyle(
    id: 'not_urgent_not_important',
    title: '不紧急不重要',
    axisTitle: '不重要不紧急',
    icon: Icons.remove_rounded,
    colors: ArrangeEventColors(
      accent: Color(0xFF5ACB3E),
      soft: Color(0xFFE8F8E4),
      softer: Color(0xFFF5FCF2),
      border: Color(0xFFC9EDC0),
      badge: Color(0xFFDDF4D7),
    ),
  );

  static const displayOrder = [
    urgentNotImportant,
    urgentImportant,
    notUrgentNotImportant,
    notUrgentImportant,
  ];

  static const _all = [
    urgentImportant,
    urgentNotImportant,
    notUrgentImportant,
    notUrgentNotImportant,
  ];

  static ArrangeQuadrantStyle? forValue(String? value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return null;

    if (_matchesUrgentImportant(normalized)) return urgentImportant;
    if (_matchesUrgentNotImportant(normalized)) return urgentNotImportant;
    if (_matchesNotUrgentImportant(normalized)) return notUrgentImportant;
    if (_matchesNotUrgentNotImportant(normalized)) {
      return notUrgentNotImportant;
    }

    for (final quadrant in _all) {
      if (normalized == _normalize(quadrant.id) ||
          normalized == _normalize(quadrant.title) ||
          normalized == _normalize(quadrant.axisTitle)) {
        return quadrant;
      }
    }
    return null;
  }

  static ArrangeEventColors colorsFor(String? value) {
    return forValue(value)?.colors ?? defaultColors;
  }

  static bool sameQuadrant(String? value, ArrangeQuadrantStyle quadrant) {
    return forValue(value)?.id == quadrant.id;
  }

  static String _normalize(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[\s_\-]+'),
      '',
    );
  }

  static bool _matchesUrgentImportant(String value) {
    return (value.contains('重要') &&
            value.contains('紧急') &&
            !value.contains('不重要') &&
            !value.contains('不紧急')) ||
        value == 'urgentimportant' ||
        value == 'importanturgent';
  }

  static bool _matchesUrgentNotImportant(String value) {
    return (value.contains('不重要') &&
            value.contains('紧急') &&
            !value.contains('不紧急')) ||
        value == 'urgentnotimportant' ||
        value == 'notimportanturgent' ||
        value == 'unimportanturgent';
  }

  static bool _matchesNotUrgentImportant(String value) {
    return (value.contains('重要') &&
            value.contains('不紧急') &&
            !value.contains('不重要')) ||
        value == 'noturgentimportant' ||
        value == 'importantnoturgent';
  }

  static bool _matchesNotUrgentNotImportant(String value) {
    return (value.contains('不重要') && value.contains('不紧急')) ||
        value == 'noturgentnotimportant' ||
        value == 'notimportantnoturgent' ||
        value == 'unimportantnoturgent';
  }
}

class ArrangeLayoutMetrics {
  final bool compact;
  final double horizontalMargin;
  final double panelRadius;
  final double eventPanelTopMargin;
  final double eventPanelPaddingX;
  final double eventPanelPaddingTop;
  final double eventPanelPaddingBottom;
  final double eventCardHeight;
  final double eventCardGap;
  final double eventTabHeight;
  final double calendarTitleSize;
  final double calendarHeaderHeight;
  final double calendarGridBottomPadding;

  const ArrangeLayoutMetrics._({
    required this.compact,
    required this.horizontalMargin,
    required this.panelRadius,
    required this.eventPanelTopMargin,
    required this.eventPanelPaddingX,
    required this.eventPanelPaddingTop,
    required this.eventPanelPaddingBottom,
    required this.eventCardHeight,
    required this.eventCardGap,
    required this.eventTabHeight,
    required this.calendarTitleSize,
    required this.calendarHeaderHeight,
    required this.calendarGridBottomPadding,
  });

  factory ArrangeLayoutMetrics.forWidth(double width) {
    final compact = width < 390;
    return ArrangeLayoutMetrics._(
      compact: compact,
      horizontalMargin: compact ? 14 : 24,
      panelRadius: compact ? 24 : 28,
      eventPanelTopMargin: compact ? 10 : 14,
      eventPanelPaddingX: compact ? 16 : 22,
      eventPanelPaddingTop: compact ? 6 : 8,
      eventPanelPaddingBottom: compact ? 6 : 8,
      eventCardHeight: compact ? 34 : 38,
      eventCardGap: compact ? 5 : 6,
      eventTabHeight: compact ? 20 : 22,
      calendarTitleSize: compact ? 24 : 28,
      calendarHeaderHeight: compact ? 36 : 40,
      calendarGridBottomPadding: compact ? 3 : 4,
    );
  }

  double eventHeightFor(double maxHeight) {
    final target = maxHeight * (compact ? 0.32 : 0.34);
    return target
        .clamp(compact ? 220.0 : 240.0, compact ? 265.0 : 300.0)
        .toDouble();
  }
}
