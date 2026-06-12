import 'package:flutter/material.dart';

import 'template_constants.dart';
import 'template_create_controller.dart';
import 'template_create_exit.dart';
import 'template_create_step4_page.dart';
import 'template_formatters.dart';
import 'template_style.dart';
import 'widgets/template_create_top_bar.dart';
import 'widgets/template_form_panel.dart';
import 'widgets/template_primary_button.dart';

class TemplateCreateStep3Page extends StatelessWidget {
  final TemplateCreateController controller;

  const TemplateCreateStep3Page({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: TemplateStyle.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TemplateCreateTopBar(
                    title: '总览',
                    onBackToTemplates: () =>
                        handleTemplateCreateExit(context, controller),
                    onPrevious: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '共 ${controller.eventCount} 个事件',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TemplateStyle.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TemplateFormPanel(
                    title: '模板信息',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          controller.templateName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: TemplateStyle.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.templateGoal,
                          style: const TextStyle(
                            height: 1.45,
                            color: TemplateStyle.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (
                    var stageIndex = 0;
                    stageIndex < controller.stages.length;
                    stageIndex++
                  ) ...[
                    _OverviewStagePanel(
                      stageIndex: stageIndex,
                      controller: controller,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TemplatePrimaryButton(
                    label: '下一阶段',
                    onPressed: () => _openStep4(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openStep4(BuildContext context) async {
    controller.moveToStep(4);
    await controller.saveDraft();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateCreateStep4Page(controller: controller),
      ),
    );
  }
}

class _OverviewStagePanel extends StatelessWidget {
  final int stageIndex;
  final TemplateCreateController controller;

  const _OverviewStagePanel({
    required this.stageIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final stage = controller.stages[stageIndex];
    return TemplateFormPanel(
      title: '${stageDisplayName(stage.stageOrder)}：${stage.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stage.goal,
            style: const TextStyle(
              color: TemplateStyle.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('overview-minutes-$stageIndex'),
            initialValue: stage.calculatedMinutes.toString(),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final minutes = int.tryParse(value);
              if (minutes != null) {
                controller.updateStageEstimatedMinutes(stageIndex, minutes);
              }
            },
            decoration: InputDecoration(
              labelText: '预计耗时（分钟）',
              helperText: formatTemplateDuration(stage.calculatedMinutes),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (
            var eventIndex = 0;
            eventIndex < stage.events.length;
            eventIndex++
          )
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                key: ValueKey('overview-event-$stageIndex-$eventIndex'),
                initialValue: stage.events[eventIndex].title,
                onChanged: (value) => controller.updateOverviewEventTitle(
                  stageIndex,
                  eventIndex,
                  value,
                ),
                decoration: InputDecoration(
                  labelText: '事件${chineseOrderLabel(eventIndex + 1)}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (stage.events.isEmpty)
            const Text(
              '该阶段暂无事件',
              style: TextStyle(color: TemplateStyle.textSecondary),
            ),
        ],
      ),
    );
  }
}
