import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import 'template_constants.dart';
import 'template_create_controller.dart';
import 'template_create_exit.dart';
import 'template_create_step2_page.dart';
import 'template_style.dart';
import 'widgets/template_keyboard_dismiss.dart';
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
        final size = MediaQuery.sizeOf(context);
        final compact = size.height < 760 || size.width < 390;
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: TemplateStyle.background,
          body: TemplateKeyboardDismiss(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  compact ? 8 : 10,
                  compact ? 16 : 20,
                  compact ? 14 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepOneTopBar(
                      onBack: () =>
                          handleTemplateCreateExit(context, _controller),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    SizedBox(
                      height: compact ? 150 : 174,
                      child: _RoundedInputPanel(
                        child: _TemplateOverviewFields(
                          templateName: _controller.templateName,
                          templateGoal: _controller.templateGoal,
                          onNameChanged: _controller.updateTemplateName,
                          onGoalChanged: _controller.updateTemplateGoal,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Expanded(
                      child: _RoundedInputPanel(
                        keyboardAware: true,
                        padding: EdgeInsets.fromLTRB(
                          compact ? 22 : 28,
                          compact ? 18 : 22,
                          compact ? 16 : 20,
                          compact ? 16 : 20,
                        ),
                        child: _StageListFields(
                          stages: _controller.stages,
                          stageTokens: _controller.stageTokens,
                          onAddStage: _controller.addStage,
                          onDeleteStage: _confirmDeleteStage,
                          onStageNameChanged: _controller.updateStageName,
                          onStageGoalChanged: _controller.updateStageGoal,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    TemplatePrimaryButton(
                      label: '下一步',
                      onPressed: _controller.canContinueStep1
                          ? _openStep2
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteStage(Object stageToken) async {
    dismissTemplateKeyboard();
    final index = _controller.indexOfStageToken(stageToken);
    final stageLabel = index == -1 ? '该阶段' : stageDisplayName(index + 1);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除阶段'),
        content: Text('确认删除$stageLabel吗？该阶段下的内容会被直接删除，无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '删除',
              style: TextStyle(color: TemplateStyle.warning),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _controller.deleteStageByToken(stageToken);
    }
  }

  Future<void> _openStep2() async {
    _controller.startStageEditing();
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

class _StepOneTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _StepOneTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_left_rounded,
                  size: 38,
                  color: TemplateStyle.accent,
                ),
                SizedBox(width: 2),
                Text(
                  '模板',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TemplateStyle.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedInputPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool keyboardAware;

  const _RoundedInputPanel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(28, 24, 28, 22),
    this.keyboardAware = false,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardPadding = keyboardBottom * 0.42 + 24;
    final scrollPadding = keyboardAware && keyboardBottom > 0
        ? padding.copyWith(bottom: padding.bottom + keyboardPadding)
        : padding;
    return Container(
      decoration: BoxDecoration(
        color: TemplateStyle.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TemplateStyle.border),
        boxShadow: TemplateStyle.itemShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Scrollbar(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: scrollPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TemplateOverviewFields extends StatelessWidget {
  final String templateName;
  final String templateGoal;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onGoalChanged;

  const _TemplateOverviewFields({
    required this.templateName,
    required this.templateGoal,
    required this.onNameChanged,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InlineInputRow(
          label: '模板名称：',
          hintText: '请输入模板名称',
          initialValue: templateName,
          maxLength: templateNameMaxLength,
          onChanged: onNameChanged,
        ),
        const SizedBox(height: 24),
        _InlineInputRow(
          label: '总目标：',
          hintText: '请输入总目标',
          initialValue: templateGoal,
          maxLength: templateGoalMaxLength,
          onChanged: onGoalChanged,
        ),
      ],
    );
  }
}

class _StageListFields extends StatelessWidget {
  final List<TemplateStage> stages;
  final List<Object> stageTokens;
  final VoidCallback onAddStage;
  final ValueChanged<Object> onDeleteStage;
  final void Function(int index, String value) onStageNameChanged;
  final void Function(int index, String value) onStageGoalChanged;

  const _StageListFields({
    required this.stages,
    required this.stageTokens,
    required this.onAddStage,
    required this.onDeleteStage,
    required this.onStageNameChanged,
    required this.onStageGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, stage) in stages.indexed) _buildStageEditor(i, stage),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: '新增阶段',
            onPressed: onAddStage,
            style: IconButton.styleFrom(
              fixedSize: const Size(42, 42),
              backgroundColor: TemplateStyle.surface,
              foregroundColor: TemplateStyle.accent,
              elevation: 3,
              shadowColor: const Color(0x22000000),
              side: const BorderSide(color: TemplateStyle.border),
            ),
            icon: const Icon(Icons.add_rounded, size: 27),
          ),
        ),
      ],
    );
  }

  Widget _buildStageEditor(int index, TemplateStage stage) {
    final token = index < stageTokens.length ? stageTokens[index] : stage;
    return _StageEditor(
      key: ValueKey(token),
      index: index,
      stage: stage,
      onNameChanged: (value) => onStageNameChanged(index, value),
      onGoalChanged: (value) => onStageGoalChanged(index, value),
      onDelete: () => onDeleteStage(token),
    );
  }
}

class _StageEditor extends StatelessWidget {
  final int index;
  final TemplateStage stage;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onDelete;

  const _StageEditor({
    super.key,
    required this.index,
    required this.stage,
    required this.onNameChanged,
    required this.onGoalChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StageTimeline(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${stageDisplayName(index + 1)}：',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TemplateStyle.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '删除${stageDisplayName(index + 1)}',
                        onPressed: onDelete,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 21,
                          color: TemplateStyle.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _StageInputRow(
                    label: '名称',
                    hintText: '请输入名称',
                    initialValue: stage.name,
                    maxLength: templateStageNameMaxLength,
                    onChanged: onNameChanged,
                  ),
                  const SizedBox(height: 18),
                  _StageInputRow(
                    label: '目标',
                    hintText: '请输入目标',
                    initialValue: stage.goal,
                    maxLength: templateStageGoalMaxLength,
                    onChanged: onGoalChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 17,
          height: 17,
          decoration: const BoxDecoration(
            color: TemplateStyle.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: Container(width: 1, color: const Color(0xFFD8DEE8))),
      ],
    );
  }
}

class _InlineInputRow extends StatelessWidget {
  final String label;
  final String hintText;
  final String initialValue;
  final int maxLength;
  final ValueChanged<String> onChanged;

  const _InlineInputRow({
    required this.label,
    required this.hintText,
    required this.initialValue,
    required this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: TemplateStyle.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: _UnderlineTextField(
            hintText: hintText,
            initialValue: initialValue,
            maxLength: maxLength,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _StageInputRow extends StatelessWidget {
  final String label;
  final String hintText;
  final String initialValue;
  final int maxLength;
  final ValueChanged<String> onChanged;

  const _StageInputRow({
    required this.label,
    required this.hintText,
    required this.initialValue,
    required this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: TemplateStyle.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: TemplateStyle.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: _UnderlineTextField(
            hintText: hintText,
            initialValue: initialValue,
            maxLength: maxLength,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _UnderlineTextField extends StatelessWidget {
  final String hintText;
  final String initialValue;
  final int maxLength;
  final ValueChanged<String> onChanged;

  const _UnderlineTextField({
    required this.hintText,
    required this.initialValue,
    required this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLength: maxLength,
      maxLines: 1,
      onChanged: onChanged,
      onTapOutside: (_) => dismissTemplateKeyboard(),
      onTap: () => ensureTemplateInputVisible(context),
      scrollPadding: templateInputScrollPadding(context),
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: TemplateStyle.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: Color(0xFFAAB4C3),
        ),
        contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD8DEE8)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD8DEE8)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: TemplateStyle.accent, width: 1.4),
        ),
      ),
    );
  }
}
