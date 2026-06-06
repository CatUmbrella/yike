part of 'event_detail_content.dart';

class _StepsCard extends StatelessWidget {
  const _StepsCard({
    required this.compact,
    required this.event,
    required this.controllers,
    required this.onStepChanged,
    required this.onStepCompletionChanged,
  });

  final bool compact;
  final Event event;
  final List<TextEditingController> controllers;
  final void Function(int index, String value) onStepChanged;
  final void Function(int index, bool completed) onStepCompletionChanged;

  @override
  Widget build(BuildContext context) {
    final steps = event.steps;
    final completedCount = steps.where((step) => step.completed).length;
    final progress = steps.isEmpty ? 0.0 : completedCount / steps.length;
    final maxVisibleRows = compact ? 3.15 : 3.6;
    final rowHeight = compact ? 56.0 : 60.0;
    final listHeight = steps.isEmpty
        ? 56.0
        : math.min(steps.length.toDouble(), maxVisibleRows) * rowHeight;

    return _DetailCard(
      compact: compact,
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 18 : 22,
        compact ? 18 : 22,
        compact ? 16 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(compact: compact, title: '怎么做', subtitle: '（分步骤执行）'),
          SizedBox(height: compact ? 10 : 14),
          if (steps.isEmpty)
            SizedBox(
              height: listHeight,
              child: Center(
                child: Text(
                  '暂无步骤',
                  style: TextStyle(
                    color: ArrangeStyle.textSecondary,
                    fontSize: compact ? 15 : 16,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: listHeight,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: steps.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: steps[index].completed
                      ? Colors.transparent
                      : ArrangeStyle.border,
                  indent: compact ? 36 : 42,
                ),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final checked = step.completed;
                  return _StepTile(
                    compact: compact,
                    checked: checked,
                    step: step,
                    controller: controllers[index],
                    onChanged: (value) => onStepChanged(index, value),
                    onCheckedChanged: (value) =>
                        onStepCompletionChanged(index, value),
                  );
                },
              ),
            ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            '已完成 $completedCount/${steps.length} 步骤',
            style: TextStyle(
              color: ArrangeStyle.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: compact ? 5 : 6,
              backgroundColor: ArrangeStyle.accentSoft,
              valueColor: const AlwaysStoppedAnimation(ArrangeStyle.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.compact,
    required this.checked,
    required this.step,
    required this.controller,
    required this.onChanged,
    required this.onCheckedChanged,
  });

  final bool compact;
  final bool checked;
  final StepItem step;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onCheckedChanged;

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 10.0 : 12.0;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 8),
      decoration: BoxDecoration(
        color: checked ? ArrangeStyle.accentSofter : Colors.transparent,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            checked: checked,
            label: '${_stepPrefix(step.stepOrder)}完成状态',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCheckedChanged(!checked),
              child: Padding(
                padding: EdgeInsets.all(compact ? 4 : 5),
                child: _StepCheckMark(checked: checked, compact: compact),
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _stepPrefix(step.stepOrder),
                  style: TextStyle(
                    color: ArrangeStyle.textPrimary,
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    minLines: 1,
                    maxLines: 2,
                    cursorColor: ArrangeStyle.accent,
                    style: TextStyle(
                      color: ArrangeStyle.textPrimary,
                      fontSize: compact ? 14 : 15,
                      height: 1.25,
                    ),
                    decoration: const InputDecoration.collapsed(
                      hintText: '填写具体步骤',
                      hintStyle: TextStyle(color: ArrangeStyle.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            formatEventDuration(step.estimatedMin),
            style: TextStyle(
              color: checked ? ArrangeStyle.accent : ArrangeStyle.textSecondary,
              fontSize: compact ? 13 : 14,
              fontWeight: checked ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCheckMark extends StatelessWidget {
  const _StepCheckMark({required this.checked, required this.compact});

  final bool checked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 20.0 : 22.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? ArrangeStyle.accent : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? ArrangeStyle.accent : const Color(0xFFB8C2D0),
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: compact ? 14 : 15,
            )
          : null,
    );
  }
}

String _stepPrefix(int stepOrder) {
  const numerals = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
  if (stepOrder > 0 && stepOrder <= 10) {
    return '第${numerals[stepOrder]}步：';
  }
  return '第$stepOrder步：';
}
