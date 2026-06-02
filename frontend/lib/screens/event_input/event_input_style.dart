import 'package:flutter/material.dart';

enum EventInputSizeClass { compact, regular, expanded }

class EventInputStyle {
  static const background = Color(0xFFF4F9FF);
  static const card = Colors.white;
  static const accent = Color(0xFF0A84FF);
  static const accentSoft = Color(0xFFEAF4FF);
  static const border = Color(0xFFD5E8FF);
  static const textPrimary = Color(0xFF1D1D1F);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE2E8F0);
  static const errorBg = Color(0xFFFFF3E0);
  static const errorBorder = Color(0xFFFFCC80);
  static const errorIcon = Color(0xFFEF6C00);
  static const errorText = Color(0xFFE65100);
  static const errorIconSize = 18.0;

  static const cardRadius = 28.0;
  static const controlRadius = 24.0;

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0A84FF).withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

class EventInputMetrics {
  const EventInputMetrics._({
    required this.sizeClass,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.navHeight,
    required this.navLeadingGap,
    required this.navIconSize,
    required this.navTitleSize,
    required this.inputPadding,
    required this.inputTextSize,
    required this.inputButtonWidth,
    required this.inputButtonHeight,
    required this.inputButtonFontSize,
    required this.cardRadius,
    required this.cardPadding,
    required this.cardGap,
    required this.cardTitleSize,
    required this.sectionTitleSize,
    required this.bodyTextSize,
    required this.durationLabelSize,
    required this.durationValueSize,
    required this.stepLabelWidth,
    required this.stepTimelineHeight,
    required this.actionBarHeight,
    required this.addIconSize,
    required this.micButtonSize,
    required this.micIconSize,
    required this.bottomPadding,
  });

  final EventInputSizeClass sizeClass;
  final double maxContentWidth;
  final double horizontalPadding;
  final double navHeight;
  final double navLeadingGap;
  final double navIconSize;
  final double navTitleSize;
  final EdgeInsets inputPadding;
  final double inputTextSize;
  final double inputButtonWidth;
  final double inputButtonHeight;
  final double inputButtonFontSize;
  final double cardRadius;
  final EdgeInsets cardPadding;
  final double cardGap;
  final double cardTitleSize;
  final double sectionTitleSize;
  final double bodyTextSize;
  final double durationLabelSize;
  final double durationValueSize;
  final double stepLabelWidth;
  final double stepTimelineHeight;
  final double actionBarHeight;
  final double addIconSize;
  final double micButtonSize;
  final double micIconSize;
  final double bottomPadding;

  bool get isCompact => sizeClass == EventInputSizeClass.compact;
  bool get isExpanded => sizeClass == EventInputSizeClass.expanded;

  double contentWidthFor(double availableWidth) {
    return availableWidth.clamp(0.0, maxContentWidth).toDouble();
  }

  static EventInputMetrics forWidth(double width) {
    if (width < 390) {
      return const EventInputMetrics._(
        sizeClass: EventInputSizeClass.compact,
        maxContentWidth: 390,
        horizontalPadding: 14,
        navHeight: 52,
        navLeadingGap: 8,
        navIconSize: 24,
        navTitleSize: 16,
        inputPadding: EdgeInsets.fromLTRB(16, 15, 14, 13),
        inputTextSize: 16,
        inputButtonWidth: 94,
        inputButtonHeight: 34,
        inputButtonFontSize: 14,
        cardRadius: 22,
        cardPadding: EdgeInsets.fromLTRB(16, 18, 16, 14),
        cardGap: 12,
        cardTitleSize: 21,
        sectionTitleSize: 15,
        bodyTextSize: 13,
        durationLabelSize: 12,
        durationValueSize: 13,
        stepLabelWidth: 58,
        stepTimelineHeight: 68,
        actionBarHeight: 50,
        addIconSize: 36,
        micButtonSize: 62,
        micIconSize: 40,
        bottomPadding: 12,
      );
    }

    if (width < 700) {
      return const EventInputMetrics._(
        sizeClass: EventInputSizeClass.regular,
        maxContentWidth: 620,
        horizontalPadding: 22,
        navHeight: 58,
        navLeadingGap: 18,
        navIconSize: 28,
        navTitleSize: 18,
        inputPadding: EdgeInsets.fromLTRB(20, 18, 18, 16),
        inputTextSize: 18,
        inputButtonWidth: 104,
        inputButtonHeight: 38,
        inputButtonFontSize: 16,
        cardRadius: 28,
        cardPadding: EdgeInsets.fromLTRB(22, 22, 22, 18),
        cardGap: 16,
        cardTitleSize: 25,
        sectionTitleSize: 16,
        bodyTextSize: 14,
        durationLabelSize: 14,
        durationValueSize: 15,
        stepLabelWidth: 72,
        stepTimelineHeight: 72,
        actionBarHeight: 58,
        addIconSize: 42,
        micButtonSize: 70,
        micIconSize: 46,
        bottomPadding: 18,
      );
    }

    return const EventInputMetrics._(
      sizeClass: EventInputSizeClass.expanded,
      maxContentWidth: 680,
      horizontalPadding: 28,
      navHeight: 64,
      navLeadingGap: 18,
      navIconSize: 28,
      navTitleSize: 20,
      inputPadding: EdgeInsets.fromLTRB(24, 20, 22, 18),
      inputTextSize: 18,
      inputButtonWidth: 110,
      inputButtonHeight: 40,
      inputButtonFontSize: 16,
      cardRadius: 30,
      cardPadding: EdgeInsets.fromLTRB(26, 24, 26, 20),
      cardGap: 18,
      cardTitleSize: 26,
      sectionTitleSize: 16,
      bodyTextSize: 15,
      durationLabelSize: 14,
      durationValueSize: 16,
      stepLabelWidth: 80,
      stepTimelineHeight: 74,
      actionBarHeight: 60,
      addIconSize: 44,
      micButtonSize: 72,
      micIconSize: 48,
      bottomPadding: 22,
    );
  }

  static EventInputMetrics of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<EventInputLayoutScope>();
    return scope?.metrics ?? forWidth(MediaQuery.sizeOf(context).width);
  }
}

class EventInputLayoutScope extends InheritedWidget {
  const EventInputLayoutScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  final EventInputMetrics metrics;

  @override
  bool updateShouldNotify(EventInputLayoutScope oldWidget) {
    return metrics != oldWidget.metrics;
  }
}
