import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'measured_underline_layout.dart';

class MeasuredUnderlinePainter extends CustomPainter {
  const MeasuredUnderlinePainter({
    required this.editableKey,
    required this.text,
    required this.hintText,
    required this.textStyle,
    required this.hintStyle,
    required this.focused,
    required this.minLines,
    required this.maxLines,
    required this.enabledLineColor,
    required this.focusedLineColor,
    required this.minUnderlineWidth,
    required this.underlineExtension,
    required this.underlineOffset,
    required this.textAreaInset,
    required this.fullWidthLine,
  });

  final GlobalKey<EditableTextState> editableKey;
  final String text;
  final String hintText;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final bool focused;
  final int minLines;
  final int? maxLines;
  final Color enabledLineColor;
  final Color focusedLineColor;
  final double minUnderlineWidth;
  final double underlineExtension;
  final double underlineOffset;
  final double textAreaInset;
  final bool fullWidthLine;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = focused ? focusedLineColor : enabledLineColor
      ..strokeWidth = focused ? 1.2 : 1;

    final editableLines = editableUnderlineLinesFor(
      editableKey: editableKey,
      text: text,
      minLines: minLines,
      maxLines: maxLines,
    );
    if (editableLines.isNotEmpty) {
      _paintEditableLines(canvas, linePaint, size, editableLines);
      return;
    }

    _paintFallbackLines(canvas, linePaint, size);
  }

  void _paintEditableLines(
    Canvas canvas,
    Paint linePaint,
    Size size,
    List<EditableUnderlineLine> lines,
  ) {
    for (final line in lines) {
      final lineLeft = fullWidthLine ? 0.0 : line.left;
      final lineWidth = fullWidthLine
          ? size.width
          : math.max(
              minUnderlineWidth,
              math.min(line.width + underlineExtension, size.width - lineLeft),
            );
      _drawLine(
        canvas,
        linePaint,
        size,
        line.top + line.height + underlineOffset,
        startX: lineLeft,
        width: lineWidth,
      );
    }
  }

  void _paintFallbackLines(Canvas canvas, Paint linePaint, Size size) {
    final measureTextWidth = math.max(
      0.0,
      size.width - (fullWidthLine ? 0.0 : textAreaInset),
    );
    if (measureTextWidth <= 0 || size.width <= 0) return;

    final isPlaceholder = text.isEmpty;
    final paintText = isPlaceholder ? hintText : text;
    final style = isPlaceholder ? hintStyle : textStyle;
    final textPainter = TextPainter(
      text: TextSpan(text: paintText.isEmpty ? ' ' : paintText, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: measureTextWidth);

    final lines = textPainter.computeLineMetrics();
    final fallbackLine = _fallbackLineMetrics(style);
    final firstBaseline = lines.isEmpty
        ? fallbackLine.baseline
        : lines.first.baseline;
    final lineHeight = lines.isEmpty ? fallbackLine.height : lines.first.height;
    final requestedLineCount = math.max(minLines, math.max(1, lines.length));
    final lineCount = maxLines == null
        ? requestedLineCount
        : math.min(requestedLineCount, maxLines!);

    for (var index = 0; index < lineCount; index++) {
      final hasMeasuredLine = index < lines.length;
      final lineLeft = fullWidthLine
          ? 0.0
          : hasMeasuredLine
          ? lines[index].left
          : 0.0;
      final lineWidth = fullWidthLine
          ? size.width
          : hasMeasuredLine
          ? math.max(
              minUnderlineWidth,
              math.min(lines[index].width + underlineExtension, size.width),
            )
          : minUnderlineWidth;
      final baseline = hasMeasuredLine
          ? lines[index].baseline
          : firstBaseline + index * lineHeight;
      _drawLine(
        canvas,
        linePaint,
        size,
        baseline + underlineOffset,
        startX: lineLeft,
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
    final x1 = math.max(0.0, startX ?? 0.0);
    final x2 = math.min(size.width, x1 + (width ?? minUnderlineWidth));
    canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
  }

  _FallbackLineMetrics _fallbackLineMetrics(TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: 'A', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final lines = textPainter.computeLineMetrics();
    if (lines.isEmpty) {
      final height = (style.fontSize ?? 14) * 1.35;
      return _FallbackLineMetrics(height: height, baseline: height * 0.8);
    }
    return _FallbackLineMetrics(
      height: lines.first.height,
      baseline: lines.first.baseline,
    );
  }

  @override
  bool shouldRepaint(covariant MeasuredUnderlinePainter oldDelegate) {
    return editableKey != oldDelegate.editableKey ||
        text != oldDelegate.text ||
        hintText != oldDelegate.hintText ||
        textStyle != oldDelegate.textStyle ||
        hintStyle != oldDelegate.hintStyle ||
        focused != oldDelegate.focused ||
        maxLines != oldDelegate.maxLines ||
        enabledLineColor != oldDelegate.enabledLineColor ||
        focusedLineColor != oldDelegate.focusedLineColor ||
        minUnderlineWidth != oldDelegate.minUnderlineWidth ||
        underlineExtension != oldDelegate.underlineExtension ||
        underlineOffset != oldDelegate.underlineOffset ||
        textAreaInset != oldDelegate.textAreaInset ||
        fullWidthLine != oldDelegate.fullWidthLine ||
        minLines != oldDelegate.minLines;
  }
}

class _FallbackLineMetrics {
  const _FallbackLineMetrics({required this.height, required this.baseline});

  final double height;
  final double baseline;
}
