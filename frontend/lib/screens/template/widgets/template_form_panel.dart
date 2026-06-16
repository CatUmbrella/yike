import 'package:flutter/material.dart';

import '../template_style.dart';
import 'template_keyboard_dismiss.dart';

class TemplateFormPanel extends StatelessWidget {
  final String? title;
  final Widget child;

  const TemplateFormPanel({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemplateStyle.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TemplateStyle.border),
        boxShadow: TemplateStyle.itemShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: TemplateStyle.sectionTitleStyle(context)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class TemplateTextField extends StatelessWidget {
  final String label;
  final String initialValue;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  const TemplateTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTapOutside: (_) => dismissTemplateKeyboard(),
      onTap: () => ensureTemplateInputVisible(context),
      scrollPadding: templateInputScrollPadding(context),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: TemplateStyle.accentSofter,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TemplateStyle.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TemplateStyle.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TemplateStyle.accent),
        ),
      ),
    );
  }
}
