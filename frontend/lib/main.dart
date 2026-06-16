import 'dart:async';

import 'package:flutter/material.dart';

import 'models/event.dart';
import 'repositories/event_repository.dart';
import 'screens/arrange/arrange_style.dart';
import 'screens/arrange_page.dart';
import 'screens/data_page.dart';
import 'screens/pomodoro_page.dart';
import 'screens/template_page.dart';

void main() => runApp(const YiKeApp());

class YiKeApp extends StatelessWidget {
  const YiKeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '一刻',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: ArrangeStyle.accent,
        useMaterial3: true,
        scaffoldBackgroundColor: ArrangeStyle.background,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EventRepository _eventRepository = const EventRepository();
  int _index = 0;
  int _arrangeRefreshToken = 0;
  bool _eventDragActive = false;
  bool _undoDeleteVisible = false;
  int? _undoDeletedEventId;
  Offset? _addButtonOffset;
  Timer? _undoDeleteTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_runStartupDataRepairs());
  }

  @override
  void dispose() {
    _undoDeleteTimer?.cancel();
    super.dispose();
  }

  Future<void> _runStartupDataRepairs() async {
    try {
      await _eventRepository.backfillStepCompletionsFromPomodoroRecords();
    } catch (_) {
      // Keep startup usable if the local database is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ArrangePage(
        active: _index == 0,
        refreshToken: _arrangeRefreshToken,
        onEventDragChanged: _setEventDragActive,
        addButtonOffset: _addButtonOffset,
        onAddButtonOffsetChanged: _setAddButtonOffset,
      ),
      PomodoroPage(
        active: _index == 1,
        addButtonOffset: _addButtonOffset,
        onAddButtonOffsetChanged: _setAddButtonOffset,
      ),
      TemplatePage(active: _index == 2),
      const DataPage(),
    ];
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: pages),
          _UndoDeleteHandle(
            visible: _undoDeleteVisible,
            onTap: _undoLastDelete,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  void _setEventDragActive(bool active) {
    if (_eventDragActive == active) return;
    setState(() => _eventDragActive = active);
  }

  void _setAddButtonOffset(Offset offset) {
    setState(() => _addButtonOffset = offset);
  }

  Future<void> _softDeleteDraggedEvent(Event event) async {
    final eventId = event.id;
    if (eventId == null) return;

    await _eventRepository.softDeleteEvent(eventId);
    if (!mounted) return;
    setState(() {
      _eventDragActive = false;
      _arrangeRefreshToken++;
      _undoDeleteVisible = true;
      _undoDeletedEventId = eventId;
    });
    _restartUndoDeleteTimer();
  }

  Future<void> _undoLastDelete() async {
    final eventId = _undoDeletedEventId;
    if (eventId == null) return;

    _undoDeleteTimer?.cancel();
    await _eventRepository.restoreEvent(eventId);
    if (!mounted) return;
    setState(() {
      _undoDeleteVisible = false;
      _undoDeletedEventId = null;
      _arrangeRefreshToken++;
    });
  }

  void _restartUndoDeleteTimer() {
    _undoDeleteTimer?.cancel();
    _undoDeleteTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _undoDeleteVisible = false;
        _undoDeletedEventId = null;
      });
    });
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    const labels = ['安排', '番茄钟', '模板', '数据'];
    final height = compact ? 52.0 : 56.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 24,
          6,
          compact ? 14 : 24,
          8,
        ),
        child: SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSlide(
                offset: _eventDragActive ? const Offset(0, 1.18) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  scale: _eventDragActive ? 0.94 : 1,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: _NavigationCapsule(
                    height: height,
                    compact: compact,
                    labels: labels,
                    selectedIndex: _index,
                    onTap: (i) {
                      if (_index == i) return;
                      setState(() => _index = i);
                    },
                  ),
                ),
              ),
              if (_eventDragActive)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, height * 1.18 * value),
                      child: child,
                    );
                  },
                  child: _DeleteDropCapsule(
                    height: height,
                    onAccept: _softDeleteDraggedEvent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UndoDeleteHandle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const _UndoDeleteHandle({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final width = compact ? 70.0 : 78.0;
    final height = compact ? 48.0 : 54.0;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: visible ? -18 : -width - 4,
                top: constraints.maxHeight * 0.68,
                width: width,
                height: height,
                child: IgnorePointer(
                  ignoring: !visible,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F5),
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(height / 2),
                        ),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                        boxShadow: ArrangeStyle.panelShadow,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: compact ? 14 : 16),
                          child: const Icon(
                            Icons.undo_rounded,
                            color: Color(0xFFEF5350),
                            size: 28,
                          ),
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

class _NavigationCapsule extends StatelessWidget {
  final double height;
  final bool compact;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavigationCapsule({
    required this.height,
    required this.compact,
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: ArrangeStyle.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: ArrangeStyle.border),
        boxShadow: ArrangeStyle.panelShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / labels.length;
          final indicatorHeight = compact ? 38.0 : 42.0;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                left: itemWidth * selectedIndex + 2,
                width: itemWidth - 4,
                height: indicatorHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ArrangeStyle.accentSoft,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: SizedBox(
                        height: indicatorHeight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: compact ? 15 : 17,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected
                                    ? ArrangeStyle.accent
                                    : ArrangeStyle.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeleteDropCapsule extends StatelessWidget {
  final double height;
  final ValueChanged<Event> onAccept;

  const _DeleteDropCapsule({required this.height, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Event>(
      onWillAcceptWithDetails: (details) => details.data.id != null,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: height,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFE9EC) : const Color(0xFFFFF3F5),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: active ? const Color(0xFFEF5350) : const Color(0xFFFFCDD2),
            ),
            boxShadow: ArrangeStyle.panelShadow,
          ),
          child: Center(
            child: AnimatedScale(
              scale: active ? 1.08 : 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF5350),
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}
