import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../event_input_style.dart';

class MeasuredUnderlineTextField extends StatefulWidget {
  const MeasuredUnderlineTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.style,
    required this.onChanged,
    this.hintStyle,
    this.minLines = 1,
    this.maxLines,
    this.keyboardType = TextInputType.text,
    this.cursorColor = EventInputStyle.accent,
    this.contentPadding = EdgeInsets.zero,
    this.enabledLineColor = EventInputStyle.divider,
    this.focusedLineColor = EventInputStyle.accent,
    this.minUnderlineWidth = 72,
    this.underlineExtension = 18,
    this.minLineHeight = 1.48,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextStyle style;
  final ValueChanged<String> onChanged;
  final TextStyle? hintStyle;
  final int minLines;
  final int? maxLines;
  final TextInputType keyboardType;
  final Color cursorColor;
  final EdgeInsets contentPadding;
  final Color enabledLineColor;
  final Color focusedLineColor;
  final double minUnderlineWidth;
  final double underlineExtension;
  final double minLineHeight;

  @override
  State<MeasuredUnderlineTextField> createState() =>
      _MeasuredUnderlineTextFieldState();
}

class _MeasuredUnderlineTextFieldState
    extends State<MeasuredUnderlineTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.focusNode.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant MeasuredUnderlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_refresh);
      widget.focusNode.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = _styleWithMinimumLineHeight(
      widget.style,
      widget.minLineHeight,
    );
    final hintStyle =
        widget.hintStyle ??
        effectiveStyle.copyWith(color: Colors.grey.shade400);
    final effectiveHintStyle = _styleWithMinimumLineHeight(
      hintStyle,
      widget.minLineHeight,
    );

    return CustomPaint(
      painter: _MeasuredUnderlinePainter(
        text: widget.controller.text,
        hintText: widget.hintText,
        textStyle: effectiveStyle,
        hintStyle: effectiveHintStyle,
        focused: widget.focusNode.hasFocus,
        maxLines: widget.maxLines,
        padding: widget.contentPadding,
        enabledLineColor: widget.enabledLineColor,
        focusedLineColor: widget.focusedLineColor,
        minUnderlineWidth: widget.minUnderlineWidth,
        underlineExtension: widget.underlineExtension,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        cursorColor: widget.cursorColor,
        style: effectiveStyle,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: widget.contentPadding,
          hintText: widget.hintText,
          hintStyle: effectiveHintStyle,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  TextStyle _styleWithMinimumLineHeight(TextStyle style, double minLineHeight) {
    final currentHeight = style.height;
    if (currentHeight != null && currentHeight >= minLineHeight) return style;
    return style.copyWith(height: minLineHeight);
  }
}

class _MeasuredUnderlinePainter extends CustomPainter {
  const _MeasuredUnderlinePainter({
    required this.text,
    required this.hintText,
    required this.textStyle,
    required this.hintStyle,
    required this.focused,
    required this.maxLines,
    required this.padding,
    required this.enabledLineColor,
    required this.focusedLineColor,
    required this.minUnderlineWidth,
    required this.underlineExtension,
  });

  final String text;
  final String hintText;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final bool focused;
  final int? maxLines;
  final EdgeInsets padding;
  final Color enabledLineColor;
  final Color focusedLineColor;
  final double minUnderlineWidth;
  final double underlineExtension;

  @override
  void paint(Canvas canvas, Size size) {
    final maxTextWidth = math.max(0.0, size.width - padding.horizontal);
    if (maxTextWidth <= 0) return;

    final isPlaceholder = text.isEmpty;
    final paintText = isPlaceholder ? hintText : text;
    final style = isPlaceholder ? hintStyle : textStyle;
    final painter = TextPainter(
      text: TextSpan(text: paintText.isEmpty ? ' ' : paintText, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxTextWidth);

    final linePaint = Paint()
      ..color = focused ? focusedLineColor : enabledLineColor
      ..strokeWidth = focused ? 1.2 : 1;
    final lines = painter.computeLineMetrics();
    if (lines.isEmpty) {
      _drawLine(canvas, linePaint, size, padding.top + _lineHeight(style));
      return;
    }

    for (final line in lines) {
      final lineWidth = math.max(
        minUnderlineWidth,
        math.min(line.width + underlineExtension, maxTextWidth),
      );
      final y = padding.top + line.baseline + 3;
      _drawLine(
        canvas,
        linePaint,
        size,
        y,
        startX: padding.left + line.left,
        width: lineWidth,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Paint paint,
    Size size,
    double y, {
    double? startX,
    double? width,
  }) {
    final x1 = startX ?? padding.left;
    final x2 = math.min(
      size.width - padding.right,
      x1 + (width ?? minUnderlineWidth),
    );
    canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
  }

  double _lineHeight(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: 'A', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final lines = painter.computeLineMetrics();
    return lines.isEmpty ? (style.fontSize ?? 14) * 1.35 : lines.first.height;
  }

  @override
  bool shouldRepaint(covariant _MeasuredUnderlinePainter oldDelegate) {
    return text != oldDelegate.text ||
        hintText != oldDelegate.hintText ||
        textStyle != oldDelegate.textStyle ||
        hintStyle != oldDelegate.hintStyle ||
        focused != oldDelegate.focused ||
        maxLines != oldDelegate.maxLines ||
        padding != oldDelegate.padding ||
        enabledLineColor != oldDelegate.enabledLineColor ||
        focusedLineColor != oldDelegate.focusedLineColor ||
        minUnderlineWidth != oldDelegate.minUnderlineWidth ||
        underlineExtension != oldDelegate.underlineExtension;
  }
}
