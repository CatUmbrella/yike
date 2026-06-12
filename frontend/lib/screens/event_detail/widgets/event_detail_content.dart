import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../shared/event_formatters.dart';
import '../../arrange/arrange_style.dart';
import '../../../models/pomodoro_models.dart';
import '../../../repositories/pomodoro_repository.dart';
import '../../pomodoro/pomodoro_timer_page.dart';

part 'event_detail_metrics.dart';
part 'event_detail_nav.dart';
part 'event_detail_pomodoro.dart';
part 'event_detail_purpose.dart';
part 'event_detail_review.dart';
part 'event_detail_shared.dart';
part 'event_detail_steps.dart';

class EventDetailContent extends StatefulWidget {
  const EventDetailContent({
    super.key,
    required this.event,
    this.keyboardVisible = false,
    required this.reviewController,
    required this.onBack,
    required this.onDelete,
    required this.onEventChanged,
  });

  final Event event;
  final bool keyboardVisible;
  final TextEditingController reviewController;
  final VoidCallback onBack;
  final VoidCallback onDelete;
  final VoidCallback onEventChanged;

  @override
  State<EventDetailContent> createState() => _EventDetailContentState();
}

class _EventDetailContentState extends State<EventDetailContent> {
  late final TextEditingController _purposeController;
  late final List<TextEditingController> _stepControllers;
  late bool _reviewExpanded;

  @override
  void initState() {
    super.initState();
    _purposeController = TextEditingController(text: widget.event.purpose);
    _stepControllers = widget.event.steps
        .map((step) => TextEditingController(text: step.description))
        .toList();
    _reviewExpanded = widget.event.status == 'completed';
  }

  @override
  void dispose() {
    _purposeController.dispose();
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final compact = size.width < 390;
    final horizontalPadding = compact ? 16.0 : 24.0;
    final bottomButtonHeight = compact ? 72.0 : 80.0;
    final bottomGap = math.max(12.0, safeBottom + 10);
    final showPomodoroButton = widget.event.status != 'completed';
    final pomodoroButtonVisible = showPomodoroButton && !widget.keyboardVisible;
    final bottomPadding = pomodoroButtonVisible
        ? bottomButtonHeight + bottomGap + 22
        : bottomGap + 22;

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailNavBar(
                  compact: compact,
                  onBack: widget.onBack,
                  onDelete: widget.onDelete,
                ),
                SizedBox(height: compact ? 16 : 24),
                Text(
                  eventDisplayTitle(widget.event, preferSummary: false),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ArrangeStyle.textPrimary,
                    fontSize: compact ? 22 : 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: compact ? 16 : 24),
                _MetricRow(event: widget.event, compact: compact),
                SizedBox(height: compact ? 24 : 32),
                _PurposeCard(
                  compact: compact,
                  controller: _purposeController,
                  onChanged: _updatePurpose,
                ),
                SizedBox(height: compact ? 16 : 24),
                _StepsCard(
                  compact: compact,
                  event: widget.event,
                  controllers: _stepControllers,
                  onStepChanged: _updateStep,
                  onStepCompletionChanged: _updateStepCompletion,
                ),
                SizedBox(height: compact ? 16 : 24),
                _ReviewCard(
                  compact: compact,
                  expanded: _reviewExpanded,
                  controller: widget.reviewController,
                  onToggle: () {
                    setState(() => _reviewExpanded = !_reviewExpanded);
                  },
                ),
              ],
            ),
          ),
        ),
        if (showPomodoroButton)
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: bottomGap,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.keyboardVisible ? 0 : 1),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: value,
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - value)),
                        child: IgnorePointer(
                          ignoring: value < 0.05,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: _PomodoroButton(
                event: widget.event,
                height: bottomButtonHeight,
                compact: compact,
              ),
            ),
          ),
      ],
    );
  }

  void _updatePurpose(String value) {
    if (widget.event.purpose == value) return;
    widget.event.purpose = value;
    widget.onEventChanged();
  }

  void _updateStep(int index, String value) {
    if (index < 0 || index >= widget.event.steps.length) return;
    final step = widget.event.steps[index];
    if (step.description == value) return;
    step.description = value;
    widget.onEventChanged();
  }

  void _updateStepCompletion(int index, bool completed) {
    if (index < 0 || index >= widget.event.steps.length) return;
    final step = widget.event.steps[index];
    if (step.completed == completed) return;
    setState(() {
      step.completedAt = completed ? DateTime.now().toIso8601String() : null;
    });
    widget.onEventChanged();
  }
}
