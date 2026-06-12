import 'package:flutter/material.dart';

import '../template_style.dart';

class TemplateSideSelector<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final IconData? Function(T value)? iconBuilder;
  final ValueChanged<T> onSelected;

  const TemplateSideSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    this.iconBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final value in values)
          _SideOption(
            label: labelBuilder(value),
            icon: iconBuilder?.call(value),
            selected: value == selected,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }
}

class _SideOption extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SideOption({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 136,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 22,
                color: selected
                    ? TemplateStyle.accent
                    : TemplateStyle.textSecondary,
              ),
              const SizedBox(height: 6),
            ],
            _VerticalLabel(label: label, selected: selected),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 6 : 0,
              height: selected ? 6 : 0,
              decoration: const BoxDecoration(
                color: TemplateStyle.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalLabel extends StatelessWidget {
  final String label;
  final bool selected;

  const _VerticalLabel({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final rune in label.runes)
          Text(
            String.fromCharCode(rune),
            style: TextStyle(
              height: 1.08,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected
                  ? TemplateStyle.textPrimary
                  : TemplateStyle.textSecondary,
            ),
          ),
      ],
    );
  }
}
