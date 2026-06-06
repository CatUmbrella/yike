import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

class EditableUnderlineLine {
  const EditableUnderlineLine({
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

MeasuredUnderlineTextLayout? measureUnderlineTextLayout({
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

List<EditableUnderlineLine> editableUnderlineLinesFor({
  required GlobalKey<EditableTextState> editableKey,
  required String text,
  required int minLines,
  required int? maxLines,
}) {
  final renderEditable = editableKey.currentState?.renderEditable;
  if (renderEditable == null || !renderEditable.hasSize) {
    return const <EditableUnderlineLine>[];
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
  final lines = <EditableUnderlineLine>[];

  for (var index = 0; index < lineCount; index++) {
    final hasMeasuredLine = index < ranges.length;
    final range = hasMeasuredLine ? ranges[index] : null;
    final top = hasMeasuredLine
        ? renderEditable
              .getLocalRectForCaret(TextPosition(offset: range!.start))
              .top
        : firstTop + index * lineHeight;
    lines.add(
      EditableUnderlineLine(
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
