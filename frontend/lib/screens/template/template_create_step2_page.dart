import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import '../event_input/event_input_style.dart';
import '../event_input/widgets/event_duration_formatter.dart';
import '../event_input/widgets/event_duration_picker_sheet.dart';
import 'template_constants.dart';
import 'template_create_controller.dart';
import 'template_create_exit.dart';
import 'template_create_step3_page.dart';
import 'template_style.dart';
import 'widgets/template_keyboard_dismiss.dart';
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
        final size = MediaQuery.sizeOf(context);
        final compact = size.height < 760 || size.width < 390;
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: TemplateStyle.background,
          body: TemplateKeyboardDismiss(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = EventInputMetrics.forWidth(
                    constraints.maxWidth,
                  );
                  return EventInputLayoutScope(
                    metrics: metrics,
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
                          _StepTwoTopBar(
                            onBack: () =>
                                handleTemplateCreateExit(context, controller),
                            onPrevious: () => Navigator.pop(context),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          SizedBox(
                            height: compact ? 178 : 194,
                            child: _StageSummaryPanel(
                              stageIndex: controller.currentStageIndex,
                              stage: stage,
                              compact: compact,
                              onNameChanged: (value) =>
                                  controller.updateStageName(
                                    controller.currentStageIndex,
                                    value,
                                  ),
                              onGoalChanged: (value) =>
                                  controller.updateStageGoal(
                                    controller.currentStageIndex,
                                    value,
                                  ),
                            ),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          Expanded(
                            child: _StageEventsPanel(
                              stageIndex: controller.currentStageIndex,
                              events: stage.events,
                              keyboardBottom: MediaQuery.viewInsetsOf(
                                context,
                              ).bottom,
                              onAddEvent: controller.addEventToCurrentStage,
                              onDeleteEvent: controller.deleteCurrentStageEvent,
                              onTitleChanged:
                                  controller.updateCurrentStageEventTitle,
                              onPurposeChanged:
                                  controller.updateCurrentStageEventPurpose,
                              onMinutesChanged:
                                  controller.updateCurrentStageEventMinutes,
                              onAddStep: controller.addStepToCurrentStageEvent,
                              onStepDescriptionChanged: controller
                                  .updateCurrentStageEventStepDescription,
                              onStepMinutesChanged:
                                  controller.updateCurrentStageEventStepMinutes,
                              onDeleteStep:
                                  controller.deleteCurrentStageEventStep,
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 16),
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
                  );
                },
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

class _StepTwoTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onPrevious;

  const _StepTwoTopBar({required this.onBack, required this.onPrevious});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          InkWell(
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
          const Spacer(),
          TextButton(
            onPressed: onPrevious,
            style: TextButton.styleFrom(
              foregroundColor: TemplateStyle.accent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('上一步'),
          ),
        ],
      ),
    );
  }
}

class _StageSummaryPanel extends StatelessWidget {
  final int stageIndex;
  final TemplateStage stage;
  final bool compact;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onGoalChanged;

  const _StageSummaryPanel({
    required this.stageIndex,
    required this.stage,
    required this.compact,
    required this.onNameChanged,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TemplateRoundedPanel(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 24,
        compact ? 18 : 22,
        compact ? 20 : 24,
        compact ? 16 : 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _InlineEditRow(
            key: ValueKey('step2-stage-name-$stageIndex'),
            label: '${stageDisplayName(stageIndex + 1)}：',
            value: stage.name,
            hintText: '请输入阶段名称',
            maxLength: templateStageNameMaxLength,
            compact: compact,
            onChanged: onNameChanged,
          ),
          _InlineEditRow(
            key: ValueKey('step2-stage-goal-$stageIndex'),
            label: '目标：',
            value: stage.goal,
            hintText: '请输入目标',
            maxLength: templateStageGoalMaxLength,
            compact: compact,
            onChanged: onGoalChanged,
          ),
          _InlineReadOnlyRow(
            label: '预计耗时：',
            value: _formatDuration(stage.calculatedMinutes),
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _StageEventsPanel extends StatelessWidget {
  final int stageIndex;
  final List<TemplateStageEvent> events;
  final double keyboardBottom;
  final VoidCallback onAddEvent;
  final ValueChanged<int> onDeleteEvent;
  final void Function(int eventIndex, String value) onTitleChanged;
  final void Function(int eventIndex, String value) onPurposeChanged;
  final void Function(int eventIndex, int minutes) onMinutesChanged;
  final ValueChanged<int> onAddStep;
  final void Function(int eventIndex, int stepIndex, String value)
  onStepDescriptionChanged;
  final void Function(int eventIndex, int stepIndex, int minutes)
  onStepMinutesChanged;
  final void Function(int eventIndex, int stepIndex) onDeleteStep;

  const _StageEventsPanel({
    required this.stageIndex,
    required this.events,
    required this.keyboardBottom,
    required this.onAddEvent,
    required this.onDeleteEvent,
    required this.onTitleChanged,
    required this.onPurposeChanged,
    required this.onMinutesChanged,
    required this.onAddStep,
    required this.onStepDescriptionChanged,
    required this.onStepMinutesChanged,
    required this.onDeleteStep,
  });

  @override
  Widget build(BuildContext context) {
    final scrollBottom = keyboardBottom > 0 ? keyboardBottom + 56 : 18.0;
    return _TemplateRoundedPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Scrollbar(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20, 22, 20, scrollBottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < events.length; i++) ...[
                  _TemplateEventEditor(
                    key: ValueKey('step2-event-$stageIndex-$i'),
                    index: i,
                    event: events[i],
                    onTitleChanged: (value) => onTitleChanged(i, value),
                    onPurposeChanged: (value) => onPurposeChanged(i, value),
                    onMinutesChanged: (minutes) => onMinutesChanged(i, minutes),
                    onAddStep: () => onAddStep(i),
                    onStepDescriptionChanged: (stepIndex, value) =>
                        onStepDescriptionChanged(i, stepIndex, value),
                    onStepMinutesChanged: (stepIndex, minutes) =>
                        onStepMinutesChanged(i, stepIndex, minutes),
                    onDeleteStep: (stepIndex) => onDeleteStep(i, stepIndex),
                    onDelete: () => onDeleteEvent(i),
                  ),
                  if (i != events.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: EventInputStyle.divider),
                    ),
                ],
                if (events.isNotEmpty) const SizedBox(height: 18),
                _AddEventButton(onPressed: onAddEvent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateEventEditor extends StatelessWidget {
  final int index;
  final TemplateStageEvent event;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onPurposeChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onAddStep;
  final void Function(int stepIndex, String value) onStepDescriptionChanged;
  final void Function(int stepIndex, int minutes) onStepMinutesChanged;
  final ValueChanged<int> onDeleteStep;
  final VoidCallback onDelete;

  const _TemplateEventEditor({
    super.key,
    required this.index,
    required this.event,
    required this.onTitleChanged,
    required this.onPurposeChanged,
    required this.onMinutesChanged,
    required this.onAddStep,
    required this.onStepDescriptionChanged,
    required this.onStepMinutesChanged,
    required this.onDeleteStep,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _SyncedUnderlineField(
                key: ValueKey('event-title-$index'),
                value: event.title,
                hintText: '事件名称',
                style: TextStyle(
                  fontSize: metrics.cardTitleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: TemplateStyle.textPrimary,
                ),
                hintStyle: TextStyle(
                  fontSize: metrics.cardTitleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.grey.shade400,
                ),
                onChanged: onTitleChanged,
              ),
            ),
            SizedBox(width: metrics.isCompact ? 8 : 12),
            _DurationButton(
              minutes: event.estimatedMinutes,
              onChanged: onMinutesChanged,
            ),
          ],
        ),
        SizedBox(height: metrics.isCompact ? 8 : 10),
        const Divider(height: 1, color: EventInputStyle.divider),
        SizedBox(height: metrics.isCompact ? 10 : 12),
        _PurposeRow(value: event.purpose, onChanged: onPurposeChanged),
        SizedBox(height: metrics.isCompact ? 14 : 18),
        const _SectionTitle(label: '怎么做:'),
        SizedBox(height: metrics.isCompact ? 10 : 12),
        if (event.steps.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: metrics.isCompact ? 22 : 26,
              bottom: metrics.isCompact ? 12 : 14,
            ),
            child: Text(
              '暂无子任务，点击加号添加',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: metrics.bodyTextSize,
              ),
            ),
          )
        else
          for (var stepIndex = 0; stepIndex < event.steps.length; stepIndex++)
            _TemplateStepEditor(
              key: ValueKey('event-$index-step-$stepIndex'),
              stepIndex: stepIndex,
              step: event.steps[stepIndex],
              isLast: stepIndex == event.steps.length - 1,
              onDescriptionChanged: (value) =>
                  onStepDescriptionChanged(stepIndex, value),
              onMinutesChanged: (minutes) =>
                  onStepMinutesChanged(stepIndex, minutes),
              onEmpty: () => onDeleteStep(stepIndex),
            ),
        Row(
          children: [
            IconButton(
              tooltip: '添加子任务',
              onPressed: onAddStep,
              icon: Icon(Icons.add_rounded, size: metrics.isCompact ? 23 : 25),
              color: EventInputStyle.accent,
              style: IconButton.styleFrom(
                side: const BorderSide(color: EventInputStyle.accent),
                fixedSize: Size.square(metrics.isCompact ? 31 : 34),
                padding: EdgeInsets.zero,
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                minimumSize: Size(metrics.isCompact ? 56 : 62, 32),
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.isCompact ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: TextStyle(
                  fontSize: metrics.isCompact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('删除'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    return Row(
      children: [
        const _BlueBullet(size: 9),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: EventInputStyle.textPrimary,
            fontSize: metrics.sectionTitleSize,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _PurposeRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PurposeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: metrics.isCompact ? 9 : 10),
          child: const _BlueBullet(size: 9),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.only(top: metrics.isCompact ? 3 : 4),
          child: Text(
            '目的:',
            style: TextStyle(
              fontSize: metrics.sectionTitleSize,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              color: EventInputStyle.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SyncedUnderlineField(
            value: value,
            hintText: '这件事的目的',
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: TextStyle(
              fontSize: metrics.bodyTextSize,
              height: 1.35,
              color: EventInputStyle.textPrimary,
            ),
            hintStyle: TextStyle(
              fontSize: metrics.bodyTextSize,
              color: const Color(0xFFAAB4C3),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TemplateStepEditor extends StatelessWidget {
  final int stepIndex;
  final TemplateStageEventStep step;
  final bool isLast;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onEmpty;

  const _TemplateStepEditor({
    super.key,
    required this.stepIndex,
    required this.step,
    required this.isLast,
    required this.onDescriptionChanged,
    required this.onMinutesChanged,
    required this.onEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: metrics.isCompact ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 14, child: _StepTimeline(isLast: isLast)),
          SizedBox(width: metrics.isCompact ? 8 : 10),
          SizedBox(
            width: metrics.stepLabelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                '${_stepName(stepIndex)}:',
                style: TextStyle(
                  fontSize: metrics.bodyTextSize,
                  fontWeight: FontWeight.w500,
                  color: EventInputStyle.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SyncedUnderlineField(
              value: step.description,
              hintText: '',
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: metrics.bodyTextSize,
                height: 1.35,
                color: EventInputStyle.textPrimary,
              ),
              onChanged: onDescriptionChanged,
              onEmpty: onEmpty,
            ),
          ),
          SizedBox(width: metrics.isCompact ? 8 : 10),
          _DurationButton(
            minutes: step.estimatedMinutes,
            compact: true,
            onChanged: onMinutesChanged,
          ),
        ],
      ),
    );
  }
}

String _stepName(int index) {
  const names = ['第一步', '第二步', '第三步', '第四步', '第五步', '第六步'];
  if (index < names.length) return names[index];
  return '第${index + 1}步';
}

class _InlineEditRow extends StatelessWidget {
  final String label;
  final String value;
  final String hintText;
  final int maxLength;
  final bool compact;
  final ValueChanged<String> onChanged;

  const _InlineEditRow({
    super.key,
    required this.label,
    required this.value,
    required this.hintText,
    required this.maxLength,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidth = compact ? 106.0 : 124.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w800,
              color: TemplateStyle.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: _SyncedUnderlineField(
            value: value,
            hintText: hintText,
            maxLength: maxLength,
            style: TextStyle(
              fontSize: compact ? 17 : 18,
              fontWeight: FontWeight.w600,
              color: TemplateStyle.textPrimary,
            ),
            hintStyle: TextStyle(
              fontSize: compact ? 17 : 18,
              color: const Color(0xFFAAB4C3),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _InlineReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _InlineReadOnlyRow({
    required this.label,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidth = compact ? 106.0 : 124.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w800,
              color: TemplateStyle.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: compact ? 17 : 18,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: TemplateStyle.accent,
          ),
        ),
      ],
    );
  }
}

class _SyncedUnderlineField extends StatefulWidget {
  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onEmpty;
  final int? maxLength;
  final int? maxLines;
  final TextInputType keyboardType;
  final TextStyle? style;
  final TextStyle? hintStyle;

  const _SyncedUnderlineField({
    super.key,
    required this.value,
    required this.hintText,
    required this.onChanged,
    this.onEmpty,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.style,
    this.hintStyle,
  });

  @override
  State<_SyncedUnderlineField> createState() => _SyncedUnderlineFieldState();
}

class _SyncedUnderlineFieldState extends State<_SyncedUnderlineField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _SyncedUnderlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        const TextStyle(fontSize: 16, color: TemplateStyle.textPrimary);
    final hintStyle =
        widget.hintStyle ?? style.copyWith(color: const Color(0xFFAAB4C3));
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onTapOutside: (_) => dismissTemplateKeyboard(),
      onTap: () => ensureTemplateInputVisible(context),
      scrollPadding: templateInputScrollPadding(context),
      cursorColor: TemplateStyle.accent,
      style: style,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: widget.hintText,
        hintStyle: hintStyle,
        contentPadding: const EdgeInsets.fromLTRB(0, 5, 0, 7),
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

  void _handleFocusChanged() {
    if (!mounted) return;
    if (_focusNode.hasFocus) {
      ensureTemplateInputVisible(context);
    } else if (_controller.text.trim().isEmpty) {
      widget.onEmpty?.call();
    }
  }
}

class _DurationButton extends StatelessWidget {
  final int minutes;
  final bool compact;
  final ValueChanged<int> onChanged;

  const _DurationButton({
    required this.minutes,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    return Semantics(
      button: true,
      label: '修改预计耗时',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          dismissTemplateKeyboard();
          final selectedMinutes = await showEventDurationPickerSheet(
            context: context,
            initialMinutes: minutes,
          );
          if (selectedMinutes != null) onChanged(selectedMinutes);
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: compact ? 8 : 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                Text(
                  '预计耗时：',
                  style: TextStyle(
                    color: EventInputStyle.textPrimary,
                    fontSize: metrics.durationLabelSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                formatEventDuration(minutes),
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact
                      ? metrics.bodyTextSize
                      : metrics.durationValueSize,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: EventInputStyle.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEventButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddEventButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: TemplateStyle.accent,
          side: const BorderSide(color: Color(0xFFD4E4FA), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}

class _TemplateRoundedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _TemplateRoundedPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: TemplateStyle.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TemplateStyle.border),
        boxShadow: TemplateStyle.itemShadow,
      ),
      child: child,
    );
  }
}

class _BlueBullet extends StatelessWidget {
  final double size;

  const _BlueBullet({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: EventInputStyle.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StepTimeline extends StatelessWidget {
  final bool isLast;

  const _StepTimeline({required this.isLast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Column(
        children: [
          const SizedBox(height: 7),
          const _BlueBullet(size: 9),
          if (!isLast) ...[
            const SizedBox(height: 5),
            Expanded(child: Container(width: 1, color: EventInputStyle.border)),
          ],
        ],
      ),
    );
  }
}

String _formatDuration(int minutes) {
  final safeMinutes = minutes < 0 ? 0 : minutes;
  if (safeMinutes < 60) return '${safeMinutes}min';
  final hours = safeMinutes ~/ 60;
  final rest = safeMinutes % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}min';
}
