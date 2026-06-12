import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import 'template_constants.dart';
import 'template_create_controller.dart';
import 'template_create_exit.dart';
import 'template_create_step2_page.dart';
import 'template_style.dart';
import 'widgets/template_create_top_bar.dart';
import 'widgets/template_form_panel.dart';
import 'widgets/template_primary_button.dart';

class TemplateCreateStep1Page extends StatefulWidget {
  final TaskTemplate? initialTemplate;

  const TemplateCreateStep1Page({super.key, this.initialTemplate});

  @override
  State<TemplateCreateStep1Page> createState() =>
      _TemplateCreateStep1PageState();
}

class _TemplateCreateStep1PageState extends State<TemplateCreateStep1Page> {
  late final TemplateCreateController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTemplate;
    _controller = initial == null
        ? TemplateCreateController.newDraft()
        : TemplateCreateController.fromTemplate(initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
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
                    title: '创建模板',
                    onBackToTemplates: () =>
                        handleTemplateCreateExit(context, _controller),
                  ),
                  const SizedBox(height: 14),
                  TemplateFormPanel(
                    title: '模板总题目',
                    child: Column(
                      children: [
                        TemplateTextField(
                          label: '模板名称',
                          initialValue: _controller.templateName,
                          maxLength: templateNameMaxLength,
                          onChanged: _controller.updateTemplateName,
                        ),
                        const SizedBox(height: 10),
                        TemplateTextField(
                          label: '总目标',
                          initialValue: _controller.templateGoal,
                          maxLength: templateGoalMaxLength,
                          maxLines: 3,
                          onChanged: _controller.updateTemplateGoal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TemplateFormPanel(
                    title: '划分阶段',
                    child: Column(
                      children: [
                        for (var i = 0; i < _controller.stages.length; i++)
                          _StageEditor(
                            key: ValueKey(
                              'stage-$i-${_controller.stages[i].stageOrder}',
                            ),
                            index: i,
                            stage: _controller.stages[i],
                            canDelete: _controller.stages.length > 1,
                            onNameChanged: (value) =>
                                _controller.updateStageName(i, value),
                            onGoalChanged: (value) =>
                                _controller.updateStageGoal(i, value),
                            onDelete: () => _confirmDeleteStage(i),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            tooltip: '新增阶段',
                            onPressed: _controller.addStage,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TemplatePrimaryButton(
                    label: '下一步',
                    onPressed: _controller.canContinueStep1 ? _openStep2 : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteStage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除阶段'),
        content: const Text('删除该阶段后，该阶段下的目标和步骤都会被删除。确认删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed == true) _controller.deleteStage(index);
  }

  Future<void> _openStep2() async {
    if (_controller.currentStage.events.isEmpty) {
      _controller.addEventToCurrentStage();
    }
    _controller.moveToStep(2);
    await _controller.saveDraft();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateCreateStep2Page(controller: _controller),
      ),
    );
  }
}

class _StageEditor extends StatelessWidget {
  final int index;
  final TemplateStage stage;
  final bool canDelete;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onDelete;

  const _StageEditor({
    super.key,
    required this.index,
    required this.stage,
    required this.canDelete,
    required this.onNameChanged,
    required this.onGoalChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stageDisplayName(index + 1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: TemplateStyle.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: '删除阶段',
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          TemplateTextField(
            label: '阶段名称',
            initialValue: stage.name,
            maxLength: templateStageNameMaxLength,
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 10),
          TemplateTextField(
            label: '阶段目标',
            initialValue: stage.goal,
            maxLength: templateStageGoalMaxLength,
            maxLines: 2,
            onChanged: onGoalChanged,
          ),
        ],
      ),
    );
  }
}
