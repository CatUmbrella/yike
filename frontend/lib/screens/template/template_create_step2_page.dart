import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import 'template_constants.dart';
import 'template_create_controller.dart';
import 'template_create_exit.dart';
import 'template_create_step3_page.dart';
import 'template_formatters.dart';
import 'template_style.dart';
import 'widgets/template_create_top_bar.dart';
import 'widgets/template_form_panel.dart';
import 'widgets/template_primary_button.dart';

class TemplateCreateStep2Page extends StatelessWidget {
  final TemplateCreateController controller;

  const TemplateCreateStep2Page({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final stage = controller.currentStage;
        return Scaffold(
          backgroundColor: TemplateStyle.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TemplateCreateTopBar(
                    title:
                        '拆解${stageDisplayName(controller.currentStageIndex + 1)}',
                    onBackToTemplates: () =>
                        handleTemplateCreateExit(context, controller),
                    onPrevious: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 14),
                  TemplateFormPanel(
                    title: '阶段信息',
                    child: Column(
                      children: [
                        TemplateTextField(
                          label: '阶段名称',
                          initialValue: stage.name,
                          maxLength: templateStageNameMaxLength,
                          onChanged: (value) => controller.updateStageName(
                            controller.currentStageIndex,
                            value,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TemplateTextField(
                          label: '阶段目标',
                          initialValue: stage.goal,
                          maxLength: templateStageGoalMaxLength,
                          maxLines: 2,
                          onChanged: (value) => controller.updateStageGoal(
                            controller.currentStageIndex,
                            value,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '预计用时：${formatTemplateDuration(stage.calculatedMinutes)}',
                            style: const TextStyle(
                              color: TemplateStyle.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TemplateFormPanel(
                    title: '目标拆解',
                    child: Column(
                      children: [
                        for (var i = 0; i < stage.events.length; i++)
                          _StageEventEditor(
                            key: ValueKey(
                              'stage-event-${controller.currentStageIndex}-$i',
                            ),
                            index: i,
                            event: stage.events[i],
                            onTitleChanged: (value) => controller
                                .updateCurrentStageEventTitle(i, value),
                            onPurposeChanged: (value) => controller
                                .updateCurrentStageEventPurpose(i, value),
                            onMinutesChanged: (minutes) => controller
                                .updateCurrentStageEventMinutes(i, minutes),
                            onDelete: () =>
                                controller.deleteCurrentStageEvent(i),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            tooltip: '新增事件',
                            onPressed: controller.addEventToCurrentStage,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TemplatePrimaryButton(
                    label:
                        controller.currentStageIndex <
                            controller.stages.length - 1
                        ? '下一阶段'
                        : '进入总览',
                    onPressed: controller.canContinueStep2
                        ? () => _goNext(context)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _goNext(BuildContext context) async {
    await controller.saveDraft();
    final enterOverview = controller.moveToNextStageOrOverview();
    if (!context.mounted || !enterOverview) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateCreateStep3Page(controller: controller),
      ),
    );
  }
}

class _StageEventEditor extends StatelessWidget {
  final int index;
  final TemplateStageEvent event;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onPurposeChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onDelete;

  const _StageEventEditor({
    super.key,
    required this.index,
    required this.event,
    required this.onTitleChanged,
    required this.onPurposeChanged,
    required this.onMinutesChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemplateStyle.accentSofter,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TemplateStyle.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '事件${chineseOrderLabel(index + 1)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: '删除事件',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          TemplateTextField(
            label: '事件标题',
            initialValue: event.title,
            onChanged: onTitleChanged,
          ),
          const SizedBox(height: 10),
          TemplateTextField(
            label: '目的',
            initialValue: event.purpose,
            maxLines: 2,
            onChanged: onPurposeChanged,
          ),
          const SizedBox(height: 10),
          TemplateTextField(
            label: '预计耗时（分钟）',
            initialValue: event.estimatedMinutes.toString(),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final minutes = int.tryParse(value);
              if (minutes != null) onMinutesChanged(minutes);
            },
          ),
        ],
      ),
    );
  }
}
