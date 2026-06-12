import 'package:flutter/material.dart';

import '../template_style.dart';

class TemplateCreateTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBackToTemplates;
  final VoidCallback? onPrevious;

  const TemplateCreateTopBar({
    super.key,
    required this.title,
    required this.onBackToTemplates,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBackToTemplates,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('模板'),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TemplateStyle.titleStyle(context),
          ),
        ),
        SizedBox(
          width: 82,
          child: onPrevious == null
              ? const SizedBox.shrink()
              : TextButton(onPressed: onPrevious, child: const Text('上一步')),
        ),
      ],
    );
  }
}
