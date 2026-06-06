import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'pomodoro_dialog_shell.dart';
import '../pomodoro_style.dart';

enum PomodoroRecordInputKind { interruption, idea }

class PomodoroRecordInputResult {
  const PomodoroRecordInputResult({required this.text, this.resolved = false});

  final String text;
  final bool resolved;
}

Future<PomodoroRecordInputResult?> showPomodoroRecordInputDialog({
  required BuildContext context,
  required PomodoroRecordInputKind kind,
  required int elapsedSeconds,
}) {
  return showDialog<PomodoroRecordInputResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) {
      return _PomodoroRecordInputCard(
        kind: kind,
        elapsedSeconds: elapsedSeconds,
      );
    },
  );
}

class _PomodoroRecordInputCard extends StatefulWidget {
  const _PomodoroRecordInputCard({
    required this.kind,
    required this.elapsedSeconds,
  });

  final PomodoroRecordInputKind kind;
  final int elapsedSeconds;

  @override
  State<_PomodoroRecordInputCard> createState() =>
      _PomodoroRecordInputCardState();
}

class _PomodoroRecordInputCardState extends State<_PomodoroRecordInputCard> {
  late final TextEditingController _controller;
  late final DateTime _createdAt;

  bool get _isInterruption =>
      widget.kind == PomodoroRecordInputKind.interruption;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _createdAt = DateTime.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PomodoroDialogShell(
      title: _isInterruption ? '打断' : '想法',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 26),
          _InputRow(
            label: _isInterruption ? '事件缘由:' : '想法:',
            controller: _controller,
            autofocus: true,
          ),
          const SizedBox(height: 26),
          _TimeRow(
            elapsedSeconds: widget.elapsedSeconds,
            createdAt: _createdAt,
          ),
          const SizedBox(height: 30),
          if (_isInterruption)
            _ResolveActions(onSubmit: _submitInterruption)
          else
            _ConfirmButton(onTap: _submitIdea),
        ],
      ),
    );
  }

  void _submitIdea() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, PomodoroRecordInputResult(text: text));
  }

  void _submitInterruption(bool resolved) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(
      context,
      PomodoroRecordInputResult(text: text, resolved: resolved),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    required this.autofocus,
  });

  final String label;
  final TextEditingController controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 17,
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
              contentPadding: EdgeInsets.only(bottom: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.elapsedSeconds, required this.createdAt});

  final int elapsedSeconds;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final elapsedMinute = elapsedSeconds <= 0
        ? 1
        : (elapsedSeconds / 60).ceil().clamp(1, 9999);
    return Row(
      children: [
        const SizedBox(
          width: 82,
          child: Text(
            '时间:',
            style: TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '第$elapsedMinute分钟',
          style: const TextStyle(
            color: PomodoroStyle.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          DateFormat('HH:mm').format(createdAt),
          style: const TextStyle(
            color: PomodoroStyle.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: PomodoroStyle.accentDeep,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text('确定'),
      ),
    );
  }
}

class _ResolveActions extends StatelessWidget {
  const _ResolveActions({required this.onSubmit});

  final ValueChanged<bool> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 82,
          child: Text(
            '解决:',
            style: TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _ResolveButton(
                  label: '已解决',
                  selected: true,
                  onTap: () => onSubmit(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResolveButton(
                  label: '先记录待解决',
                  selected: false,
                  onTap: () => onSubmit(false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResolveButton extends StatelessWidget {
  const _ResolveButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: selected ? PomodoroStyle.accentDeep : Colors.white,
          foregroundColor: selected ? Colors.white : PomodoroStyle.textPrimary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          side: BorderSide(
            color: selected ? PomodoroStyle.accentDeep : PomodoroStyle.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: selected ? 0 : 2,
          shadowColor: PomodoroStyle.accent.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(Icons.check_circle_rounded, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
