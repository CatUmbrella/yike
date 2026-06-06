import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../event_detail.dart';
import '../event_input.dart';
import '../arrange/widgets/draggable_add_button.dart';
import 'pomodoro_home_controller.dart';
import 'pomodoro_models.dart';
import 'pomodoro_style.dart';
import 'pomodoro_timer_page.dart';
import 'pomodoro_history_page.dart';
import 'widgets/pomodoro_event_box.dart';
import 'widgets/pomodoro_history_preview.dart';
import 'widgets/pomodoro_start_panel.dart';
import 'widgets/pomodoro_timer_display.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({
    super.key,
    this.active = true,
    this.addButtonOffset,
    this.onAddButtonOffsetChanged,
  });

  final bool active;
  final Offset? addButtonOffset;
  final ValueChanged<Offset>? onAddButtonOffsetChanged;

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with WidgetsBindingObserver {
  static const _autoRefreshDebounce = Duration(seconds: 1);

  late final PomodoroHomeController _controller;
  Timer? _activeHandleTimer;
  DateTime? _lastAutoRefreshAt;
  bool _autoRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PomodoroHomeController()..load();
    _activeHandleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.active) _controller.tickActiveSession();
    });
  }

  @override
  void didUpdateWidget(covariant PomodoroPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _refreshIfNeeded();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active) {
      _refreshIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeHandleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final compact = width < 390;
        return Scaffold(
          backgroundColor: PomodoroStyle.background,
          body: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _controller.load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          compact ? 16 : 20,
                          16,
                          compact ? 16 : 20,
                          compact ? 20 : 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PomodoroHeader(compact: compact),
                            SizedBox(height: compact ? 16 : 20),
                            PomodoroHistoryPreview(
                              items: _controller.recentSessions,
                              onViewAll: _openHistory,
                            ),
                            const SizedBox(height: 16),
                            PomodoroEventBox(
                              events: _controller.candidateEvents,
                              selectedEventId: _controller.selectedEventId,
                              onSelect: _controller.selectEvent,
                              onOpenDetail: _openDetail,
                            ),
                            const SizedBox(height: 16),
                            PomodoroStartPanel(
                              selectedEvent: _controller.selectedEvent,
                              onStart: _openTimer,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_controller.loading)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    DraggableAddButton(
                      constraints: constraints,
                      offset: widget.addButtonOffset,
                      onOffsetChanged:
                          widget.onAddButtonOffsetChanged ?? (_) {},
                      onTap: _openInput,
                    ),
                    _ActivePomodoroHandle(
                      snapshot: _controller.activeSession,
                      onTap: _openActiveTimer,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInput() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EventInputScreen()),
    );
    if (changed == true) {
      await _controller.load();
    }
  }

  Future<void> _refreshIfNeeded() async {
    if (_autoRefreshing || !mounted || !widget.active) return;
    final now = DateTime.now();
    final last = _lastAutoRefreshAt;
    if (last != null && now.difference(last) < _autoRefreshDebounce) return;

    _lastAutoRefreshAt = now;
    _autoRefreshing = true;
    try {
      await _controller.load(silent: true);
    } finally {
      _autoRefreshing = false;
    }
  }

  Future<void> _openTimer() async {
    final event = _controller.selectedEvent;
    final id = event?.id;
    if (event == null || id == null) return;
    final active = _controller.activeSession;
    if (active != null && active.event.id != id) {
      _showActiveSessionBlockedMessage();
      return;
    }

    await _pushTimer(
      eventId: id,
      initialEvent: active?.event ?? event,
      source: PomodoroStartSource.home,
    );
  }

  Future<void> _openActiveTimer() async {
    final active = _controller.activeSession;
    final eventId = active?.event.id;
    if (active == null || eventId == null) return;
    await _pushTimer(
      eventId: eventId,
      initialEvent: active.event,
      source: PomodoroStartSource.home,
    );
  }

  Future<void> _pushTimer({
    required int eventId,
    Event? initialEvent,
    required PomodoroStartSource source,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PomodoroTimerPage(
          eventId: eventId,
          initialEvent: initialEvent,
          source: source,
        ),
      ),
    );
    await _controller.load();
  }

  void _showActiveSessionBlockedMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已有番茄钟正在进行，请先返回并结束当前专注')));
  }

  Future<void> _openDetail(Event event) async {
    final eventId = event.id;
    if (eventId == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId)),
    );
    if (changed == true) {
      await _controller.load();
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PomodoroHistoryPage()),
    );
  }
}

class _ActivePomodoroHandle extends StatelessWidget {
  const _ActivePomodoroHandle({required this.snapshot, required this.onTap});

  final PomodoroTaskSnapshot? snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = snapshot;
    final compact = MediaQuery.sizeOf(context).width < 390;
    final width = compact ? 124.0 : 138.0;
    final height = compact ? 50.0 : 54.0;
    final visible = current != null;
    final elapsed = current?.session.durationSec ?? 0;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: visible ? -16 : -width - 8,
                top: constraints.maxHeight * 0.70,
                width: width,
                height: height,
                child: IgnorePointer(
                  ignoring: !visible,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(height / 2),
                        ),
                        border: Border.all(color: const Color(0xFFCFE3FF)),
                        boxShadow: PomodoroStyle.panelShadow,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 22,
                          right: compact ? 12 : 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.timer_rounded,
                              color: PomodoroStyle.accentDeep,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              PomodoroTimerDisplay.formatElapsed(elapsed),
                              style: TextStyle(
                                color: PomodoroStyle.accentDeep,
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PomodoroHeader extends StatelessWidget {
  const _PomodoroHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      '番茄钟',
      style: TextStyle(
        color: PomodoroStyle.textPrimary,
        fontSize: compact ? 24 : 28,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
    );
  }
}
