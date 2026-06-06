import 'package:flutter/material.dart';

import 'pomodoro_dialog_shell.dart';
import '../pomodoro_style.dart';

Future<bool?> showPomodoroEndConfirmDialog({required BuildContext context}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) {
      return PomodoroDialogShell(
        title: '结束',
        onClose: () => Navigator.pop(context),
        child: const _EndConfirmContent(),
      );
    },
  );
}

class _EndConfirmContent extends StatelessWidget {
  const _EndConfirmContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 30),
        const Text(
          '是否完成任务？',
          style: TextStyle(
            color: PomodoroStyle.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 38),
        Row(
          children: [
            Expanded(
              child: _DecisionButton(
                label: '否',
                primary: false,
                onTap: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _DecisionButton(
                label: '是',
                primary: true,
                onTap: () => Navigator.pop(context, true),
              ),
            ),
          ],
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
      height: 58,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? PomodoroStyle.accentDeep : Colors.white,
          foregroundColor: primary ? Colors.white : PomodoroStyle.textPrimary,
          textStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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
