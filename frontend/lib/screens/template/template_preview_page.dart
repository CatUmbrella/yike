import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import 'template_constants.dart';
import 'template_formatters.dart';
import 'template_style.dart';

class TemplatePreviewPage extends StatelessWidget {
  final TaskTemplate template;

  const TemplatePreviewPage({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemplateStyle.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('模板'),
                  ),
                  Expanded(
                    child: Text(
                      '预览',
                      textAlign: TextAlign.center,
                      style: TemplateStyle.titleStyle(context),
                    ),
                  ),
                  const SizedBox(width: 78),
                ],
              ),
              const SizedBox(height: 14),
              _PreviewPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: TemplateStyle.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.goal,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: TemplateStyle.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MetaChip(
                      label: '阶段关系：${templateRelationLabel(template.relation)}',
                    ),
                    const SizedBox(height: 6),
                    _MetaChip(label: '共 ${template.eventCount} 个事件'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final stage in template.stages) ...[
                _PreviewPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${stageDisplayName(stage.stageOrder)}：${stage.name}',
                              style: TemplateStyle.sectionTitleStyle(context),
                            ),
                          ),
                          Text(
                            formatTemplateDuration(stage.calculatedMinutes),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: TemplateStyle.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stage.goal,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: TemplateStyle.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final event in stage.events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PreviewEvent(event: event),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (template.notices.isNotEmpty)
                _PreviewPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '注意事项',
                        style: TemplateStyle.sectionTitleStyle(context),
                      ),
                      const SizedBox(height: 10),
                      for (final notice in template.notices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${notice.noticeOrder}. ${notice.content}',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: TemplateStyle.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final Widget child;

  const _PreviewPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TemplateStyle.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TemplateStyle.border),
        boxShadow: TemplateStyle.itemShadow,
      ),
      child: child,
    );
  }
}

class _PreviewEvent extends StatelessWidget {
  final TemplateStageEvent event;

  const _PreviewEvent({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemplateStyle.accentSofter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemplateStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TemplateStyle.textPrimary,
                  ),
                ),
              ),
              Text(
                formatTemplateDuration(event.estimatedMinutes),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TemplateStyle.accent,
                ),
              ),
            ],
          ),
          if (event.purpose.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.purpose,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: TemplateStyle.textSecondary,
              ),
            ),
          ],
          if (event.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final step in event.steps)
              Text(
                '${step.stepOrder}. ${step.description}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: TemplateStyle.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TemplateStyle.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: TemplateStyle.accent,
        ),
      ),
    );
  }
}
