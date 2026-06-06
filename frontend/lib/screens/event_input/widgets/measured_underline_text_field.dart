import 'package:flutter/material.dart';

import '../event_input_style.dart';
import 'measured_underline_layout.dart';
import 'measured_underline_painter.dart';

export 'measured_underline_layout.dart' show MeasuredUnderlineTextLayout;

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
            painter: MeasuredUnderlinePainter(
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

      final layout = measureUnderlineTextLayout(
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
