import 'package:flutter/material.dart';

import '../template_style.dart';

class TemplateListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final Widget? detail;

  const TemplateListCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.onTap,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: TemplateStyle.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemplateStyle.border),
              boxShadow: TemplateStyle.itemShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TemplateStyle.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: TemplateStyle.textSecondary,
                        ),
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Wrap(spacing: 2, children: actions),
                    ],
                  ],
                ),
                if (detail != null) ...[const SizedBox(height: 12), detail!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TemplateTextCardAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const TemplateTextCardAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(38, 30),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: color ?? TemplateStyle.textSecondary,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class TemplateCardAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const TemplateCardAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color ?? TemplateStyle.accent),
    );
  }
}
