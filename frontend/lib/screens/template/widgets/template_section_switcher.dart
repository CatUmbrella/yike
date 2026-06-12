import 'package:flutter/material.dart';

import '../../../models/template_models.dart';
import '../template_constants.dart';
import '../template_style.dart';

class TemplateSectionSwitcher extends StatelessWidget {
  final TemplateSection selected;
  final ValueChanged<TemplateSection> onSelected;

  const TemplateSectionSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (final section in TemplateSection.values)
            Expanded(
              child: _SectionButton(
                label: templateSectionLabel(section),
                selected: selected == section,
                onTap: () => onSelected(section),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SectionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? TemplateStyle.accent
                      : TemplateStyle.textSecondary,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: selected ? 26 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: TemplateStyle.accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
