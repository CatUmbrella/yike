import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../event_input/widgets/event_duration_picker_sheet.dart';
import 'pomodoro_dialog_shell.dart';
import '../../../models/pomodoro_models.dart';
import '../pomodoro_style.dart';

Future<IdeaToInboxDraft?> showIdeaToInboxCardDialog({
  required BuildContext context,
  required PomodoroIdea idea,
  required int orderIndex,
}) {
  return showDialog<IdeaToInboxDraft>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) {
      return _IdeaToInboxCard(idea: idea, orderIndex: orderIndex);
    },
  );
}

class _IdeaToInboxCard extends StatefulWidget {
  const _IdeaToInboxCard({required this.idea, required this.orderIndex});

  final PomodoroIdea idea;
  final int orderIndex;

  @override
  State<_IdeaToInboxCard> createState() => _IdeaToInboxCardState();
}

class _IdeaToInboxCardState extends State<_IdeaToInboxCard> {
  late final TextEditingController _titleController;
  late final TextEditingController _purposeController;
  final List<_EditableStepDraft> _steps = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.idea.content);
    _purposeController = TextEditingController();
    _addStep();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentHeight = (MediaQuery.sizeOf(context).height * 0.72).clamp(
      360.0,
      560.0,
    );
    return PomodoroDialogShell(
      title: '想法',
      maxWidth: 430,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      onClose: _skip,
      child: SizedBox(
        height: contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TitleRow(
                      orderIndex: widget.orderIndex,
                      controller: _titleController,
                    ),
                    const SizedBox(height: 20),
                    _LabeledInput(
                      label: '目的:',
                      controller: _purposeController,
                      hintText: '为了...',
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('怎么做:'),
                    const SizedBox(height: 10),
                    _StepList(steps: _steps, onDurationTap: _editDuration),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _addStep,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: PomodoroStyle.accent,
                        iconSize: 22,
                        visualDensity: VisualDensity.compact,
                        tooltip: '添加步骤',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '是否加入事件箱?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PomodoroStyle.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DecisionButton(
                    label: '否',
                    primary: false,
                    onTap: _skip,
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: _DecisionButton(
                    label: '是',
                    primary: true,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addStep() {
    setState(() {
      _steps.add(_EditableStepDraft(order: _steps.length + 1));
    });
  }

  Future<void> _editDuration(int index) async {
    final selected = await showEventDurationPickerSheet(
      context: context,
      initialMinutes: _steps[index].minutes,
    );
    if (selected == null || !mounted) return;
    setState(() => _steps[index].minutes = selected);
  }

  void _skip() {
    Navigator.pop(
      context,
      IdeaToInboxDraft(
        idea: widget.idea,
        title: _normalizedTitle(),
        purpose: _purposeController.text.trim(),
        steps: _stepItems(),
        shouldAddToInbox: false,
      ),
    );
  }

  void _submit() {
    Navigator.pop(
      context,
      IdeaToInboxDraft(
        idea: widget.idea,
        title: _normalizedTitle(),
        purpose: _purposeController.text.trim(),
        steps: _stepItems(),
        shouldAddToInbox: true,
      ),
    );
  }

  String _normalizedTitle() {
    final title = _titleController.text.trim();
    return title.isEmpty ? widget.idea.content : title;
  }

  List<StepItem> _stepItems() {
    final items = <StepItem>[];
    for (final step in _steps) {
      final description = step.controller.text.trim();
      if (description.isEmpty && step.minutes <= 0) continue;
      items.add(
        StepItem(
          stepOrder: items.length + 1,
          description: description,
          estimatedMin: step.minutes,
        ),
      );
    }
    return items;
  }
}

class _EditableStepDraft {
  _EditableStepDraft({required this.order})
    : controller = TextEditingController(),
      minutes = 0;

  final int order;
  final TextEditingController controller;
  int minutes;

  void dispose() {
    controller.dispose();
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.orderIndex, required this.controller});

  final int orderIndex;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$orderIndex',
            style: const TextStyle(
              color: PomodoroStyle.accentDeep,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 1,
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: PomodoroStyle.border),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: PomodoroStyle.border),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: PomodoroStyle.accent),
              ),
              contentPadding: EdgeInsets.only(bottom: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: _BlueDot(size: 9),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: PomodoroStyle.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: PomodoroStyle.textSecondary),
              isDense: true,
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: PomodoroStyle.border),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: PomodoroStyle.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: PomodoroStyle.accent),
              ),
              contentPadding: const EdgeInsets.only(bottom: 7),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BlueDot(size: 9),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: PomodoroStyle.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps, required this.onDurationTap});

  final List<_EditableStepDraft> steps;
  final ValueChanged<int> onDurationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        return _StepRow(
          step: step,
          isLast: index == steps.length - 1,
          onDurationTap: () => onDurationTap(index),
        );
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isLast,
    required this.onDurationTap,
  });

  final _EditableStepDraft step;
  final bool isLast;
  final VoidCallback onDurationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 48,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (!isLast)
                Positioned(
                  top: 16,
                  bottom: -4,
                  child: Container(width: 1, color: const Color(0xFFBDD5FF)),
                ),
              const Positioned(top: 8, child: _BlueDot(size: 8, muted: true)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '第${step.order}步:',
                    style: const TextStyle(
                      color: PomodoroStyle.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: step.controller,
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(
                      color: PomodoroStyle.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: PomodoroStyle.border),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: PomodoroStyle.border),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: PomodoroStyle.accent),
                      ),
                      contentPadding: EdgeInsets.only(bottom: 7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onDurationTap,
                  style: TextButton.styleFrom(
                    foregroundColor: PomodoroStyle.textSecondary,
                    minimumSize: const Size(46, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '${step.minutes}min',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? PomodoroStyle.accentDeep : Colors.white,
          foregroundColor: primary ? Colors.white : PomodoroStyle.textPrimary,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          side: BorderSide(
            color: primary ? PomodoroStyle.accentDeep : PomodoroStyle.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: primary ? 0 : 2,
          shadowColor: PomodoroStyle.accent.withValues(alpha: 0.08),
        ),
        child: Text(label),
      ),
    );
  }
}

class _BlueDot extends StatelessWidget {
  const _BlueDot({this.size = 9, this.muted = false});

  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: muted ? const Color(0xFF738EB7) : PomodoroStyle.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}
