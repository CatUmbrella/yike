import 'package:flutter/material.dart';

import '../../models/template_models.dart';
import 'template_constants.dart';
import 'template_create_controller.dart';
import 'template_create_exit.dart';
import 'template_create_step4_page.dart';
import 'template_style.dart';
import 'widgets/template_keyboard_dismiss.dart';
import 'widgets/template_primary_button.dart';

class TemplateCreateStep3Page extends StatelessWidget {
  final TemplateCreateController controller;

  const TemplateCreateStep3Page({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
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
                    _StepThreeTopBar(
                      onBack: () =>
                          handleTemplateCreateExit(context, controller),
                      onPrevious: () => Navigator.pop(context),
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    _OverviewHeader(eventCount: controller.eventCount),
                    SizedBox(height: compact ? 12 : 14),
                    Expanded(
                      child: _OverviewTreePanel(
                        stages: controller.stages,
                        compact: compact,
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    TemplatePrimaryButton(
                      label: '下一阶段',
                      onPressed: () => _openStep4(context),
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

  Future<void> _openStep4(BuildContext context) async {
    controller.moveToStep(4);
    await controller.saveDraft();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateCreateStep4Page(controller: controller),
      ),
    );
  }
}

class _StepThreeTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onPrevious;

  const _StepThreeTopBar({required this.onBack, required this.onPrevious});

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

class _OverviewHeader extends StatelessWidget {
  final int eventCount;

  const _OverviewHeader({required this.eventCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const Text(
          '总览',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: TemplateStyle.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '共$eventCount件事',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: TemplateStyle.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _OverviewTreePanel extends StatelessWidget {
  final List<TemplateStage> stages;
  final bool compact;

  const _OverviewTreePanel({required this.stages, required this.compact});

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 16,
              compact ? 16 : 18,
              compact ? 14 : 16,
              compact ? 16 : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  _OverviewStageSection(stage: stages[i], compact: compact),
                  if (i != stages.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: compact ? 12 : 14,
                      ),
                      child: const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                ],
                if (stages.isEmpty)
                  const Center(
                    child: Text(
                      '暂无阶段',
                      style: TextStyle(color: TemplateStyle.textSecondary),
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

class _OverviewStageSection extends StatelessWidget {
  final TemplateStage stage;
  final bool compact;

  const _OverviewStageSection({required this.stage, required this.compact});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 22 : 24,
            child: Column(
              children: [
                Container(
                  width: compact ? 14 : 16,
                  height: compact ? 14 : 16,
                  decoration: const BoxDecoration(
                    color: TemplateStyle.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 7),
                Expanded(
                  child: Container(width: 1, color: const Color(0xFFD8E2EF)),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OverviewLine(
                  label: '${stageDisplayName(stage.stageOrder)}：',
                  body: stage.name,
                  labelWidth: compact ? 64 : 70,
                  duration: _minutesText(_stageCalculatedMinutes(stage)),
                  labelStyle: _stageTitleStyle(compact),
                  bodyStyle: _stageTitleStyle(compact),
                ),
                SizedBox(height: compact ? 8 : 10),
                _OverviewLine(
                  indent: compact ? 4 : 6,
                  label: '目的：',
                  body: stage.goal,
                  labelWidth: compact ? 42 : 46,
                  labelStyle: _bodyStrongStyle(compact),
                  bodyStyle: _bodyStyle(compact),
                  reserveDuration: false,
                ),
                for (
                  var eventIndex = 0;
                  eventIndex < stage.events.length;
                  eventIndex++
                )
                  _OverviewEventSection(
                    event: stage.events[eventIndex],
                    eventIndex: eventIndex,
                    compact: compact,
                  ),
                if (stage.events.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 4 : 6,
                      top: compact ? 8 : 10,
                    ),
                    child: const Text(
                      '该阶段暂无事件',
                      style: TextStyle(color: TemplateStyle.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewEventSection extends StatelessWidget {
  final TemplateStageEvent event;
  final int eventIndex;
  final bool compact;

  const _OverviewEventSection({
    required this.event,
    required this.eventIndex,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverviewLine(
            indent: compact ? 2 : 4,
            bulletSize: 7,
            label: '${chineseOrderLabel(eventIndex + 1)}：',
            body: event.title,
            labelWidth: compact ? 34 : 38,
            labelStyle: _eventTitleStyle(compact),
            bodyStyle: _eventTitleStyle(compact),
            reserveDuration: false,
          ),
          SizedBox(height: compact ? 6 : 8),
          _OverviewLine(
            indent: compact ? 20 : 24,
            bulletSize: 5,
            label: '目的：',
            body: event.purpose,
            labelWidth: compact ? 38 : 42,
            labelStyle: _bodyStyle(compact),
            bodyStyle: _bodyStyle(compact),
            reserveDuration: false,
          ),
          for (var stepIndex = 0; stepIndex < event.steps.length; stepIndex++)
            Padding(
              padding: EdgeInsets.only(top: compact ? 6 : 8),
              child: _OverviewLine(
                indent: compact ? 20 : 24,
                bulletSize: 5,
                label: '${_stepName(stepIndex)}：',
                body: event.steps[stepIndex].description,
                labelWidth: compact ? 54 : 60,
                duration: _minutesText(
                  event.steps[stepIndex].estimatedMinutes,
                  blankWhenZero: true,
                ),
                labelStyle: _bodyStyle(compact),
                bodyStyle: _bodyStyle(compact),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewLine extends StatelessWidget {
  final double indent;
  final double? bulletSize;
  final String label;
  final String body;
  final double labelWidth;
  final String? duration;
  final TextStyle labelStyle;
  final TextStyle bodyStyle;
  final bool reserveDuration;

  const _OverviewLine({
    this.indent = 0,
    this.bulletSize,
    required this.label,
    required this.body,
    required this.labelWidth,
    this.duration,
    required this.labelStyle,
    required this.bodyStyle,
    this.reserveDuration = true,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final durationWidth = compact ? 38.0 : 46.0;
    final durationText = duration ?? '';
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bulletSize != null) ...[
            SizedBox(
              width: compact ? 10 : 12,
              child: Padding(
                padding: EdgeInsets.only(top: compact ? 7 : 7.5),
                child: Center(
                  child: Container(
                    width: bulletSize,
                    height: bulletSize,
                    decoration: const BoxDecoration(
                      color: TemplateStyle.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: compact ? 6 : 7),
          ],
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: labelStyle,
            ),
          ),
          Expanded(child: Text(body, style: bodyStyle, softWrap: true)),
          if (reserveDuration) ...[
            SizedBox(width: compact ? 6 : 8),
            SizedBox(
              width: durationWidth,
              child: Text(
                durationText,
                textAlign: TextAlign.right,
                style: _durationStyle(compact),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle _stageTitleStyle(bool compact) {
  return TextStyle(
    fontSize: compact ? 16 : 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: TemplateStyle.textPrimary,
  );
}

TextStyle _eventTitleStyle(bool compact) {
  return TextStyle(
    fontSize: compact ? 14 : 15,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: TemplateStyle.textPrimary,
  );
}

TextStyle _bodyStrongStyle(bool compact) {
  return TextStyle(
    fontSize: compact ? 13 : 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: TemplateStyle.textPrimary,
  );
}

TextStyle _bodyStyle(bool compact) {
  return TextStyle(
    fontSize: compact ? 12 : 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: TemplateStyle.textPrimary,
  );
}

TextStyle _durationStyle(bool compact) {
  return TextStyle(
    fontSize: compact ? 12 : 13,
    height: 1.35,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    color: TemplateStyle.accent,
  );
}

String _stepName(int index) {
  const names = ['第一步', '第二步', '第三步', '第四步', '第五步', '第六步'];
  if (index < names.length) return names[index];
  return '第${index + 1}步';
}

int _stageCalculatedMinutes(TemplateStage stage) {
  final eventTotal = stage.events.fold<int>(
    0,
    (sum, event) => sum + _eventCalculatedMinutes(event),
  );
  return eventTotal > 0 ? eventTotal : stage.estimatedMinutes;
}

int _eventCalculatedMinutes(TemplateStageEvent event) {
  final stepTotal = event.steps.fold<int>(
    0,
    (sum, step) => sum + step.estimatedMinutes,
  );
  return stepTotal > 0 ? stepTotal : event.estimatedMinutes;
}

String _minutesText(int minutes, {bool blankWhenZero = false}) {
  final safeMinutes = minutes < 0 ? 0 : minutes;
  if (safeMinutes == 0 && blankWhenZero) return '';
  return '${safeMinutes}m';
}
