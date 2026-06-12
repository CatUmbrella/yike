import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/event_formatters.dart';
import '../../event_input/widgets/event_duration_picker_sheet.dart';
import '../../../models/pomodoro_models.dart';
import '../../../shared/pomodoro_constants.dart';
import '../pomodoro_style.dart';
import '../widgets/tomato_icon.dart';

Future<bool?> showHistorySessionDialog({
  required BuildContext context,
  required PomodoroHistoryDetail detail,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: _HistorySessionCard(detail: detail),
    ),
  );
}

class _HistorySessionCard extends StatefulWidget {
  const _HistorySessionCard({required this.detail});

  final PomodoroHistoryDetail detail;

  @override
  State<_HistorySessionCard> createState() => _HistorySessionCardState();
}

class _HistorySessionCardState extends State<_HistorySessionCard> {
  late final List<TextEditingController> _stepControllers;
  late final List<int> _stepMinutes;

  PomodoroHistoryDetail get detail => widget.detail;

  @override
  void initState() {
    super.initState();
    _stepControllers = detail.event.steps
        .map((step) => TextEditingController(text: step.description))
        .toList();
    _stepMinutes = detail.event.steps.map((step) => step.estimatedMin).toList();
  }

  @override
  void dispose() {
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: screenHeight * 0.86,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: PomodoroStyle.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
              boxShadow: [
                BoxShadow(
                  color: PomodoroStyle.accent.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(detail: detail),
                        if (detail.event.purpose.trim().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _Purpose(text: detail.event.purpose.trim()),
                        ],
                        if (detail.event.steps.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          const _SectionTitle('怎么做:'),
                          const SizedBox(height: 10),
                          _StepList(
                            stepOrders: detail.event.steps
                                .map((step) => step.stepOrder)
                                .toList(),
                            stepRecords: detail.stepRecords,
                            controllers: _stepControllers,
                            minutes: _stepMinutes,
                            onDurationTap: _editStepDuration,
                          ),
                        ],
                        const SizedBox(height: 22),
                        _SessionSummary(detail: detail),
                        const SizedBox(height: 24),
                        _RecordSection(
                          title: '打断:',
                          emptyText: '暂无打断',
                          children: detail.interruptions
                              .map(
                                (item) => _TimedRecordRow(
                                  text: item.reason,
                                  elapsedSec: item.elapsedSec,
                                  createdAt: item.createdAt,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        _RecordSection(
                          title: '想法:',
                          emptyText: '暂无想法',
                          children: detail.ideas
                              .map(
                                (item) => _TimedRecordRow(
                                  text: item.content,
                                  elapsedSec: item.elapsedSec,
                                  createdAt: item.createdAt,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                  child: _CloseButton(onTap: _close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editStepDuration(int index) async {
    _dismissKeyboard();
    final selected = await showEventDurationPickerSheet(
      context: context,
      initialMinutes: _stepMinutes[index],
    );
    if (selected == null || !mounted) return;
    setState(() => _stepMinutes[index] = selected);
  }

  void _close() {
    final event = detail.event;
    var changed = false;
    for (var i = 0; i < event.steps.length; i++) {
      final description = _stepControllers[i].text.trim();
      if (event.steps[i].description != description) {
        event.steps[i].description = description;
        changed = true;
      }
      if (event.steps[i].estimatedMin != _stepMinutes[i]) {
        event.steps[i].estimatedMin = _stepMinutes[i];
        changed = true;
      }
    }
    Navigator.pop(context, changed);
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final PomodoroHistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final event = detail.event;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '事件：',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: eventDisplayTitle(event)),
                TextSpan(
                  text: event.completedAt == null ? '（未完成）' : '（完成）',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '预计用时： '),
              TextSpan(
                text: _formatMinutes(event.totalMinutes),
                style: const TextStyle(
                  color: PomodoroStyle.accentDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          style: const TextStyle(
            color: PomodoroStyle.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Purpose extends StatelessWidget {
  const _Purpose({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '目的： ',
                style: TextStyle(
                  color: PomodoroStyle.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: text,
                style: const TextStyle(
                  color: PomodoroStyle.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: PomodoroStyle.border),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: PomodoroStyle.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({
    required this.stepOrders,
    required this.stepRecords,
    required this.controllers,
    required this.minutes,
    required this.onDurationTap,
  });

  final List<int> stepOrders;
  final List<PomodoroStepRecord> stepRecords;
  final List<TextEditingController> controllers;
  final List<int> minutes;
  final ValueChanged<int> onDurationTap;

  @override
  Widget build(BuildContext context) {
    final recordsByOrder = {
      for (final record in stepRecords) record.stepOrder: record,
    };
    return Column(
      children: List.generate(
        controllers.length,
        (index) => _StepRow(
          index: index,
          isLast: index == controllers.length - 1,
          record: recordsByOrder[stepOrders[index]],
          controller: controllers[index],
          minutes: minutes[index],
          onDurationTap: () => onDurationTap(index),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.isLast,
    required this.record,
    required this.controller,
    required this.minutes,
    required this.onDurationTap,
  });

  final int index;
  final bool isLast;
  final PomodoroStepRecord? record;
  final TextEditingController controller;
  final int minutes;
  final VoidCallback onDurationTap;

  @override
  Widget build(BuildContext context) {
    final actualDurationSec = record?.durationSec;
    final hasActualDuration = actualDurationSec != null;
    final displayMinutes = hasActualDuration
        ? _minutesFromSeconds(actualDurationSec)
        : minutes;
    final completed = record?.completed ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          height: 58,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (!isLast)
                Positioned(
                  top: 32,
                  bottom: -2,
                  child: Container(width: 1, color: const Color(0xFFD8E6F8)),
                ),
              Positioned(
                top: 5,
                child: _StepIndexCircle(
                  number: index + 1,
                  completed: completed,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(
                      color: PomodoroStyle.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                      contentPadding: EdgeInsets.only(top: 7, bottom: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StepDurationLabel(
                  label: hasActualDuration ? '实际用时：' : '预计耗时：',
                  minutes: displayMinutes,
                  onTap: hasActualDuration ? null : onDurationTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndexCircle extends StatelessWidget {
  const _StepIndexCircle({required this.number, required this.completed});

  final int number;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final foreground = completed ? PomodoroStyle.textSecondary : Colors.white;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? Colors.transparent : PomodoroStyle.accent,
        shape: BoxShape.circle,
        border: Border.all(
          color: completed ? const Color(0xFFB8C4D4) : PomodoroStyle.accent,
          width: 1.4,
        ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _StepDurationLabel extends StatelessWidget {
  const _StepDurationLabel({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: 112,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FittedBox(
          alignment: Alignment.centerRight,
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: _formatMinutes(minutes),
                  style: const TextStyle(
                    color: PomodoroStyle.accentDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              color: PomodoroStyle.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.detail});

  final PomodoroHistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final actualMinutes = (detail.session.durationSec / 60).ceil().clamp(
      0,
      9999,
    );
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '实际用时： ',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text:
                      '${_formatMinutes(actualMinutes)} / ${_formatMinutes(detail.event.totalMinutes)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        _TomatoCount(count: _tomatoCount(detail.session)),
      ],
    );
  }
}

class _RecordSection extends StatelessWidget {
  const _RecordSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(
              color: PomodoroStyle.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ...children,
      ],
    );
  }
}

class _TimedRecordRow extends StatelessWidget {
  const _TimedRecordRow({
    required this.text,
    required this.elapsedSec,
    required this.createdAt,
  });

  final String text;
  final int elapsedSec;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final elapsedMinute = (elapsedSec / 60).ceil().clamp(0, 9999);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: _BlueDot(size: 10),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 9),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: PomodoroStyle.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PomodoroStyle.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '时间： 第$elapsedMinute分钟  ${DateFormat('HH:mm').format(createdAt)}',
                    style: const TextStyle(
                      color: Color(0xFF2B4E88),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueDot extends StatelessWidget {
  const _BlueDot({this.size = 12});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PomodoroStyle.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: PomodoroStyle.accent.withValues(alpha: 0.2),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _TomatoCount extends StatelessWidget {
  const _TomatoCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    if (count > 3) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TomatoIcon(size: 28),
          const SizedBox(width: 4),
          Text(
            '×$count',
            style: const TextStyle(
              color: PomodoroStyle.accentDeep,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
          child: const TomatoIcon(size: 28),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: PomodoroStyle.accent.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            Icons.close_rounded,
            color: PomodoroStyle.textPrimary,
            size: 34,
          ),
        ),
      ),
    );
  }
}

String _formatMinutes(int minutes) {
  final safeMinutes = minutes.clamp(0, 9999);
  return formatEventDuration(safeMinutes);
}

int _minutesFromSeconds(int seconds) {
  if (seconds <= 0) return 0;
  return (seconds / 60).ceil().clamp(0, 9999).toInt();
}

int _tomatoCount(PomodoroSession session) {
  if (session.tomatoCount > 0) return session.tomatoCount;
  if (session.durationSec <= 0) return 0;
  return (session.durationSec ~/ PomodoroConstants.tomatoSeconds).clamp(0, 999);
}
