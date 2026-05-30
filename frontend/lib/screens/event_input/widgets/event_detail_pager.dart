import 'package:flutter/material.dart';

import '../event_input_state.dart';
import '../event_input_style.dart';
import 'editable_event_detail_card.dart';

class EventDetailPager extends StatelessWidget {
  const EventDetailPager({
    super.key,
    required this.state,
    required this.onDeleteDraft,
    required this.onResetDraft,
    required this.onTitleChanged,
    required this.onSummaryChanged,
    required this.onPurposeChanged,
    required this.onStepDescriptionChanged,
    required this.onStepMinutesChanged,
    required this.onAddStep,
    required this.onRemoveStep,
  });

  final EventInputState state;
  final ValueChanged<int> onDeleteDraft;
  final ValueChanged<int> onResetDraft;
  final void Function(int draftIndex, String value) onTitleChanged;
  final void Function(int draftIndex, String value) onSummaryChanged;
  final void Function(int draftIndex, String value) onPurposeChanged;
  final void Function(int draftIndex, int stepIndex, String value)
  onStepDescriptionChanged;
  final void Function(int draftIndex, int stepIndex, int value)
  onStepMinutesChanged;
  final ValueChanged<int> onAddStep;
  final void Function(int draftIndex, int stepIndex) onRemoveStep;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    if (!state.hasDrafts) {
      return _EmptyEventDetail(parsing: state.parsing);
    }

    return Scrollbar(
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: state.drafts.length,
        separatorBuilder: (_, _) => SizedBox(height: metrics.cardGap),
        itemBuilder: (context, index) {
          final draft = state.drafts[index];
          return EditableEventDetailCard(
            key: ValueKey(draft),
            draftIndex: index,
            draft: draft,
            onDelete: () => onDeleteDraft(index),
            onReset: () => onResetDraft(index),
            onTitleChanged: (value) => onTitleChanged(index, value),
            onSummaryChanged: (value) => onSummaryChanged(index, value),
            onPurposeChanged: (value) => onPurposeChanged(index, value),
            onStepDescriptionChanged: (stepIndex, value) {
              onStepDescriptionChanged(index, stepIndex, value);
            },
            onStepMinutesChanged: (stepIndex, value) {
              onStepMinutesChanged(index, stepIndex, value);
            },
            onAddStep: () => onAddStep(index),
            onRemoveStep: (stepIndex) => onRemoveStep(index, stepIndex),
          );
        },
      ),
    );
  }
}

class _EmptyEventDetail extends StatelessWidget {
  const _EmptyEventDetail({required this.parsing});

  final bool parsing;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return Container(
      width: double.infinity,
      padding: metrics.cardPadding,
      decoration: BoxDecoration(
        color: EventInputStyle.card,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        border: Border.all(color: EventInputStyle.border),
        boxShadow: EventInputStyle.softShadow,
      ),
      child: Center(
        child: Text(
          parsing ? '正在生成事件详情...' : '输入内容后会在这里生成事件详情，也可以先添加自定义事件',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: EventInputStyle.textSecondary,
            height: 1.4,
          ).copyWith(fontSize: metrics.bodyTextSize),
        ),
      ),
    );
  }
}
