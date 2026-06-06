import 'package:flutter/material.dart';

import '../pomodoro_models.dart';
import '../pomodoro_style.dart';

class PomodoroTimerControls extends StatelessWidget {
  const PomodoroTimerControls({
    super.key,
    required this.status,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
  });

  final PomodoroTimerStatus status;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) {
    final running = status == PomodoroTimerStatus.running;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: running ? onPause : onResume,
            icon: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(running ? '暂停专注' : '继续专注'),
            style: FilledButton.styleFrom(
              backgroundColor: PomodoroStyle.accentDeep,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(29),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _HoldToEndButton(onCompleted: onEnd),
      ],
    );
  }
}

class _HoldToEndButton extends StatefulWidget {
  const _HoldToEndButton({required this.onCompleted});

  final Future<void> Function() onCompleted;

  @override
  State<_HoldToEndButton> createState() => _HoldToEndButtonState();
}

class _HoldToEndButtonState extends State<_HoldToEndButton>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 2);

  late final AnimationController _controller;
  bool _holding = false;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completeHold();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_ending || _holding) return;
    setState(() => _holding = true);
    _controller.forward(from: 0);
  }

  void _cancelHold() {
    if (_ending) return;
    setState(() => _holding = false);
    _controller.animateBack(
      0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  Future<void> _completeHold() async {
    if (_ending) return;
    setState(() {
      _holding = false;
      _ending = true;
    });
    try {
      await widget.onCompleted();
    } finally {
      if (mounted) {
        _controller.value = 0;
        setState(() => _ending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _startHold(),
      onPointerUp: (_) => _cancelHold(),
      onPointerCancel: (_) => _cancelHold(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _controller.value,
                    child: Container(color: const Color(0xFFFFD9DF)),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _ending
                              ? Icons.hourglass_top_rounded
                              : Icons.touch_app_rounded,
                          color: const Color(0xFFE8505B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _ending
                              ? '结束中'
                              : _holding
                              ? '继续按住结束专注'
                              : '长按 2 秒结束专注',
                          style: const TextStyle(
                            color: Color(0xFFE8505B),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
