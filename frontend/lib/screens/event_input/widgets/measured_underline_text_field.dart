import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    this.underlineOffset = 3,
    this.textAreaInset = 0,
    this.fullWidthLine = false,
    this.minLineHeight = 1.48,
    this.onTextLayoutChanged,
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
  final double underlineOffset;
  final double textAreaInset;
  final bool fullWidthLine;
  final double minLineHeight;
  final ValueChanged<MeasuredUnderlineTextLayout>? onTextLayoutChanged;

  @override
  State<MeasuredUnderlineTextField> createState() =>
      _MeasuredUnderlineTextFieldState();
}

class _MeasuredUnderlineTextFieldState
    extends State<MeasuredUnderlineTextField> {
  final _editableKey = GlobalKey<EditableTextState>();
  MeasuredUnderlineTextLayout? _lastTextLayout;
  bool _layoutCallbackScheduled = false;

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
    _scheduleTextLayoutCallback();
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

    return Padding(
      padding: widget.contentPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (widget.controller.text.isEmpty && widget.hintText.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Text(widget.hintText, style: effectiveHintStyle),
              ),
            ),
          CustomPaint(
            painter: _MeasuredUnderlinePainter(
              editableKey: _editableKey,
              text: widget.controller.text,
              hintText: widget.hintText,
              textStyle: effectiveStyle,
              hintStyle: effectiveHintStyle,
              focused: widget.focusNode.hasFocus,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              enabledLineColor: widget.enabledLineColor,
              focusedLineColor: widget.focusedLineColor,
              minUnderlineWidth: widget.minUnderlineWidth,
              underlineExtension: widget.underlineExtension,
              underlineOffset: widget.underlineOffset,
              textAreaInset: widget.textAreaInset,
              fullWidthLine: widget.fullWidthLine,
            ),
            child: EditableText(
              key: _editableKey,
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              cursorColor: widget.cursorColor,
              backgroundCursorColor: Colors.grey.shade300,
              selectionColor: widget.cursorColor.withValues(alpha: 0.22),
              style: effectiveStyle,
              strutStyle: StrutStyle.fromTextStyle(
                effectiveStyle,
                forceStrutHeight: true,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleTextLayoutCallback() {
    if (_layoutCallbackScheduled || widget.onTextLayoutChanged == null) return;
    _layoutCallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutCallbackScheduled = false;
      if (!mounted) return;
      final renderEditable = _editableKey.currentState?.renderEditable;
      if (renderEditable == null || !renderEditable.hasSize) return;

      final layout = _layoutFromRenderEditable(
        renderEditable: renderEditable,
        text: widget.controller.text,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
      );
      if (layout == null || layout == _lastTextLayout) return;
      _lastTextLayout = layout;
      widget.onTextLayoutChanged?.call(layout);
    });
  }

  void _refresh() {
    _scheduleTextLayoutCallback();
    if (mounted) setState(() {});
  }

  TextStyle _styleWithMinimumLineHeight(TextStyle style, double minLineHeight) {
    final currentHeight = style.height;
    if (currentHeight != null && currentHeight >= minLineHeight) return style;
    return style.copyWith(height: minLineHeight);
  }
}

class MeasuredUnderlineTextLayout {
  const MeasuredUnderlineTextLayout({
    required this.text,
    required this.lineCount,
    required this.lineHeight,
    required this.lastLineWidth,
  });

  final String text;
  final int lineCount;
  final double lineHeight;
  final double lastLineWidth;

  @override
  bool operator ==(Object other) {
    return other is MeasuredUnderlineTextLayout &&
        text == other.text &&
        lineCount == other.lineCount &&
        lineHeight == other.lineHeight &&
        lastLineWidth == other.lastLineWidth;
  }

  @override
  int get hashCode {
    return Object.hash(text, lineCount, lineHeight, lastLineWidth);
  }
}

MeasuredUnderlineTextLayout? _layoutFromRenderEditable({
  required RenderEditable renderEditable,
  required String text,
  required int minLines,
  required int? maxLines,
}) {
  final lineRanges = _lineRangesFor(renderEditable, text);
  final measuredLineCount = math.max(1, lineRanges.length);
  final requestedLineCount = math.max(minLines, measuredLineCount);
  final lineCount = maxLines == null
      ? requestedLineCount
      : math.min(requestedLineCount, maxLines);
  final lineHeight = renderEditable.preferredLineHeight;
  final lastLineWidth = lineRanges.isEmpty
      ? 0.0
      : _lineWidthFor(renderEditable, lineRanges.last);

  return MeasuredUnderlineTextLayout(
    text: text,
    lineCount: lineCount,
    lineHeight: lineHeight,
    lastLineWidth: lastLineWidth,
  );
}

List<TextSelection> _lineRangesFor(RenderEditable renderEditable, String text) {
  if (text.isEmpty) {
    return const <TextSelection>[];
  }

  final ranges = <TextSelection>[];
  for (var offset = 0; offset <= text.length; offset++) {
    final range = renderEditable.getLineAtOffset(TextPosition(offset: offset));
    if (!range.isValid) continue;
    final alreadyMeasured =
        ranges.isNotEmpty &&
        range.start == ranges.last.start &&
        range.end == ranges.last.end;
    if (!alreadyMeasured) {
      ranges.add(range);
    }
  }
  return ranges;
}

double _lineWidthFor(RenderEditable renderEditable, TextSelection range) {
  if (!range.isValid) return 0;

  final startOffset = math.max(0, range.start);
  final endOffset = math.max(startOffset, range.end);
  final startRect = renderEditable.getLocalRectForCaret(
    TextPosition(offset: startOffset),
  );
  final endRect = renderEditable.getLocalRectForCaret(
    TextPosition(offset: endOffset, affinity: TextAffinity.upstream),
  );

  return math.max(0.0, endRect.left - startRect.left);
}

List<_EditableLine> _editableLinesFor({
  required GlobalKey<EditableTextState> editableKey,
  required String text,
  required int minLines,
  required int? maxLines,
}) {
  final renderEditable = editableKey.currentState?.renderEditable;
  if (renderEditable == null || !renderEditable.hasSize) {
    return const <_EditableLine>[];
  }

  final ranges = _lineRangesFor(renderEditable, text);
  final measuredLineCount = math.max(1, ranges.length);
  final requestedLineCount = math.max(minLines, measuredLineCount);
  final lineCount = maxLines == null
      ? requestedLineCount
      : math.min(requestedLineCount, maxLines);
  final lineHeight = renderEditable.preferredLineHeight;
  final firstTop = ranges.isEmpty
      ? 0.0
      : renderEditable
            .getLocalRectForCaret(TextPosition(offset: ranges.first.start))
            .top;
  final lines = <_EditableLine>[];
  for (var index = 0; index < lineCount; index++) {
    final hasMeasuredLine = index < ranges.length;
    final range = hasMeasuredLine ? ranges[index] : null;
    final top = hasMeasuredLine
        ? renderEditable
              .getLocalRectForCaret(TextPosition(offset: range!.start))
              .top
        : firstTop + index * lineHeight;
    lines.add(
      _EditableLine(
        top: top,
        height: lineHeight,
        left: hasMeasuredLine
            ? renderEditable
                  .getLocalRectForCaret(TextPosition(offset: range!.start))
                  .left
            : 0.0,
        width: hasMeasuredLine ? _lineWidthFor(renderEditable, range!) : 0.0,
      ),
    );
  }
  return lines;
}

class _EditableLine {
  const _EditableLine({
    required this.top,
    required this.height,
    required this.left,
    required this.width,
  });

  final double top;
  final double height;
  final double left;
  final double width;
}

class _MeasuredUnderlinePainter extends CustomPainter {
  const _MeasuredUnderlinePainter({
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

    final editableLines = _editableLinesFor(
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
    List<_EditableLine> lines,
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
  bool shouldRepaint(covariant _MeasuredUnderlinePainter oldDelegate) {
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
