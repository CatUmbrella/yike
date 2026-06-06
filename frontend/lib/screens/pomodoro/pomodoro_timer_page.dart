import 'package:flutter/material.dart';

import '../../models/event.dart';
import 'dialogs/idea_to_inbox_card_dialog.dart';
import 'dialogs/pomodoro_end_confirm_dialog.dart';
import 'dialogs/pomodoro_record_input_dialog.dart';
import 'pomodoro_models.dart';
import 'pomodoro_style.dart';
import 'pomodoro_timer_controller.dart';
import 'widgets/pomodoro_lane_panel.dart';
import 'widgets/pomodoro_timer_controls.dart';
import 'widgets/pomodoro_timer_display.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({
    super.key,
    required this.eventId,
    this.initialEvent,
    this.source = PomodoroStartSource.home,
  });

  final int eventId;
  final Event? initialEvent;
  final PomodoroStartSource source;

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  late final PomodoroTimerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PomodoroTimerController()
      ..start(
        eventId: widget.eventId,
        initialEvent: widget.initialEvent,
        source: widget.source,
      );
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
          backgroundColor: PomodoroStyle.background,
          appBar: AppBar(
            title: const Text(
              '番茄钟',
              style: TextStyle(
                color: PomodoroStyle.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            backgroundColor: PomodoroStyle.background,
            elevation: 0,
            foregroundColor: PomodoroStyle.textPrimary,
          ),
          body: _controller.loading
              ? const Center(child: CircularProgressIndicator())
              : _controller.error != null
              ? _TimerErrorView(onBack: () => Navigator.pop(context, false))
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Column(
                      children: [
                        PomodoroTimerDisplay(
                          elapsedSeconds: _controller.elapsedSeconds,
                          status: _controller.status,
                        ),
                        const SizedBox(height: 30),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                PomodoroLanePanel(
                                  label: '+\n打\n断',
                                  height: 124,
                                  onLabelTap: _addInterruption,
                                  child: _RecordList(
                                    emptyText: '暂无打断',
                                    records:
                                        _controller.snapshot?.interruptions
                                            .map(
                                              (item) => _RecordListItem(
                                                text: item.reason,
                                                resolved: item.resolved,
                                              ),
                                            )
                                            .toList() ??
                                        const [],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                PomodoroLanePanel(
                                  label: '+\n想\n法',
                                  height: 124,
                                  onLabelTap: _addIdea,
                                  child: _RecordList(
                                    emptyText: '暂无想法',
                                    records:
                                        _controller.snapshot?.ideas
                                            .map(
                                              (item) => _RecordListItem(
                                                text: item.content,
                                              ),
                                            )
                                            .toList() ??
                                        const [],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                PomodoroLanePanel(
                                  label: '步\n骤',
                                  height: 154,
                                  child: _StepList(controller: _controller),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),
                        PomodoroTimerControls(
                          status: _controller.status,
                          onPause: _controller.pause,
                          onResume: _controller.resume,
                          onEnd: _confirmEnd,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _addInterruption() async {
    final result = await showPomodoroRecordInputDialog(
      context: context,
      kind: PomodoroRecordInputKind.interruption,
      elapsedSeconds: _controller.elapsedSeconds,
    );
    if (result != null) {
      _controller.addInterruption(result.text, resolved: result.resolved);
    }
  }

  Future<void> _addIdea() async {
    final result = await showPomodoroRecordInputDialog(
      context: context,
      kind: PomodoroRecordInputKind.idea,
      elapsedSeconds: _controller.elapsedSeconds,
    );
    if (result != null) _controller.addIdea(result.text);
  }

  Future<void> _confirmEnd() async {
    final taskCompleted = await showPomodoroEndConfirmDialog(context: context);
    if (taskCompleted == null) return;
    await _controller.finish(taskCompleted: taskCompleted);
    await _handleIdeas();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _handleIdeas() async {
    final ideas =
        _controller.snapshot?.ideas
            .where((idea) => !idea.inboxHandled)
            .toList() ??
        const <PomodoroIdea>[];
    for (var i = 0; i < ideas.length; i++) {
      if (!mounted) return;
      final draft = await showIdeaToInboxCardDialog(
        context: context,
        idea: ideas[i],
        orderIndex: i + 1,
      );
      if (draft != null) {
        await _controller.createInboxEventFromIdea(draft);
      }
    }
  }
}

class _TimerErrorView extends StatelessWidget {
  const _TimerErrorView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_off_rounded,
                color: PomodoroStyle.textSecondary,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                '已有番茄钟正在进行',
                style: TextStyle(
                  color: PomodoroStyle.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请先返回当前专注并结束后，再开始新的事件。',
                textAlign: TextAlign.center,
                style: TextStyle(color: PomodoroStyle.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onBack, child: const Text('返回')),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.emptyText, required this.records});

  final String emptyText;
  final List<_RecordListItem> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: PomodoroStyle.textSecondary),
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _BulletText(record: records[index]),
    );
  }
}

class _RecordListItem {
  const _RecordListItem({required this.text, this.resolved = false});

  final String text;
  final bool resolved;
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.record});

  final _RecordListItem record;

  @override
  Widget build(BuildContext context) {
    final color = record.resolved
        ? const Color(0xFFB0BBCD)
        : PomodoroStyle.textPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: record.resolved
                ? const Color(0xFFC7D0DD)
                : const Color(0xFF9EACC1),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            record.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: record.resolved ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.controller});

  final PomodoroTimerController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    final event = snapshot?.event;
    final records = snapshot?.stepRecords ?? const <PomodoroStepRecord>[];
    if (event == null || event.steps.isEmpty) {
      return const Center(
        child: Text(
          '暂无步骤',
          style: TextStyle(color: PomodoroStyle.textSecondary),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: event.steps.length,
      itemBuilder: (context, index) {
        final step = event.steps[index];
        final record = records.firstWhere(
          (item) => item.stepOrder == step.stepOrder,
          orElse: () => PomodoroStepRecord(
            stepOrder: step.stepOrder,
            descriptionSnapshot: step.description,
            estimatedMinSnapshot: step.estimatedMin,
          ),
        );
        return SizedBox(
          height: 40,
          child: Row(
            children: [
              _StepCheck(
                completed: record.completed,
                onTap: record.completed
                    ? null
                    : () => controller.completeStep(step.stepOrder),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: step.description,
                  onFieldSubmitted: (value) =>
                      controller.updateStepDescription(step.stepOrder, value),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: '第 ${index + 1} 步',
                  ),
                  style: TextStyle(
                    color: record.completed
                        ? const Color(0xFFB0BBCD)
                        : PomodoroStyle.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: record.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                child: Text(
                  _actualDurationText(record),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: PomodoroStyle.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _actualDurationText(PomodoroStepRecord record) {
    final durationSec = record.durationSec;
    if (!record.completed || durationSec == null) return '';
    final minutes = (durationSec / 60).ceil().clamp(1, 999);
    return '${minutes}min';
  }
}

class _StepCheck extends StatelessWidget {
  const _StepCheck({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: completed ? PomodoroStyle.accent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: completed ? PomodoroStyle.accent : const Color(0xFFB7C4D6),
            width: 2,
          ),
        ),
        child: completed
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
