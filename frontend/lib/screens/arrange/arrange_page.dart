import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../services/database.dart';
import '../event_detail.dart';
import '../event_input.dart';
import 'arrange_constants.dart';
import 'arrange_helpers.dart';
import 'arrange_style.dart';
import 'widgets/arrange_panel.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/calendar_page_divider.dart';
import 'widgets/calendar_title.dart';
import 'widgets/event_box.dart';
import 'widgets/quadrant_view.dart';
import 'widgets/round_button.dart';

class ArrangePage extends StatefulWidget {
  const ArrangePage({super.key});

  @override
  State<ArrangePage> createState() => _ArrangePageState();
}

class _ArrangePageState extends State<ArrangePage>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController(initialPage: initialEventPage);
  final _calendarPageController = PageController(
    initialPage: initialCalendarPage,
  );
  late final AnimationController _calendarFlipController;
  late final Animation<double> _calendarFlipAnimation;

  int _pageIndex = initialEventPage;
  int _calendarPageIndex = initialCalendarPage;
  int? _eventTabAnimationTargetPage;
  int? _eventTabAnimationTargetTab;
  int _eventTabAnimationSerial = 0;
  bool _visibleCalendarSideIsQuadrant = false;
  bool _targetCalendarSideIsQuadrant = false;
  int _calendarFlipSerial = 0;

  List<Event> _inboxEvents = [];
  List<Event> _calendarEvents = [];
  List<Event> _completedEvents = [];
  List<Event> _deletedEvents = [];

  int get _tabIndex => _pageIndex % 3;

  int get _displayTabIndex => _eventTabAnimationTargetTab ?? _tabIndex;

  int get _weekOffset => _calendarPageIndex - initialCalendarPage;

  @override
  void initState() {
    super.initState();
    _calendarFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _calendarFlipAnimation = CurvedAnimation(
      parent: _calendarFlipController,
      curve: Curves.easeInOutCubic,
    );
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _calendarPageController.dispose();
    _calendarFlipController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final active = await LocalDatabase.getEvents();
      final deleted = await LocalDatabase.getDeletedEvents();
      if (!mounted) return;

      setState(() {
        _inboxEvents = active.where((e) => e.status != 'completed').toList();
        _calendarEvents = active
            .where((e) => e.scheduledDate != null && e.timeSlot != null)
            .toList();
        _completedEvents = active
            .where((e) => e.status == 'completed')
            .toList();
        _deletedEvents = deleted;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inboxEvents = [];
        _calendarEvents = [];
        _completedEvents = [];
        _deletedEvents = [];
      });
    }
  }

  Future<void> _openInput() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventInputScreen()),
    );
    _load();
  }

  Future<void> _openDetail(Event event) async {
    if (event.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id!)),
    );
    _load();
  }

  Future<void> _completeEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('事件已完成'),
        content: Text('「${event.title}」是否标记为已完成？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    event.status = 'completed';
    event.completedAt = DateTime.now().toIso8601String();
    await LocalDatabase.saveEvent(event);
    _load();
  }

  Future<void> _restoreEvent(Event event) async {
    if (event.id == null) return;
    await LocalDatabase.restoreEvent(event.id!);
    _load();
  }

  void _goToTab(int tabIndex) {
    final base = _pageIndex - _tabIndex;
    final targetPage = base + tabIndex;
    if (targetPage == _pageIndex) return;

    final animationSerial = ++_eventTabAnimationSerial;
    setState(() {
      _eventTabAnimationTargetPage = targetPage;
      _eventTabAnimationTargetTab = tabIndex;
    });

    _pageController
        .animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        )
        .whenComplete(
          _completeCurrentAnimation(
            serial: animationSerial,
            currentSerial: () => _eventTabAnimationSerial,
            updateState: () {
              _pageIndex = targetPage;
              _eventTabAnimationTargetPage = null;
              _eventTabAnimationTargetTab = null;
            },
          ),
        );
  }

  VoidCallback _completeCurrentAnimation({
    required int serial,
    required int Function() currentSerial,
    required VoidCallback updateState,
    VoidCallback? afterState,
  }) {
    return () {
      if (!mounted || serial != currentSerial()) return;
      setState(updateState);
      afterState?.call();
    };
  }

  void _handleEventPageChanged(int page) {
    setState(() {
      _pageIndex = page;
      if (_eventTabAnimationTargetPage == null ||
          page == _eventTabAnimationTargetPage) {
        _eventTabAnimationTargetPage = null;
        _eventTabAnimationTargetTab = null;
      }
    });
  }

  void _setCalendarSide(bool showQuadrant) {
    if (_calendarFlipController.isAnimating) return;
    if (showQuadrant == _visibleCalendarSideIsQuadrant) return;

    final animationSerial = ++_calendarFlipSerial;
    setState(() => _targetCalendarSideIsQuadrant = showQuadrant);

    _calendarFlipController
        .forward(from: 0)
        .whenComplete(
          _completeCurrentAnimation(
            serial: animationSerial,
            currentSerial: () => _calendarFlipSerial,
            updateState: () {
              _visibleCalendarSideIsQuadrant = showQuadrant;
              _targetCalendarSideIsQuadrant = showQuadrant;
            },
            afterState: _calendarFlipController.reset,
          ),
        );
  }

  void _showComingSoon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<Event> _eventsForPage(int page) {
    switch (page % 3) {
      case 1:
        return _completedEvents;
      case 2:
        return _deletedEvents;
      default:
        return _inboxEvents;
    }
  }

  List<Event> _eventsForCell(DateTime day, ArrangeTimeSlot slot) {
    return _eventsForCellByKey(dateKey(day), slot.key);
  }

  List<Event> _eventsForCellByKey(String date, String timeSlot) {
    final events = _calendarEvents
        .where((e) => e.scheduledDate == date && e.timeSlot == timeSlot)
        .toList();
    events.sort(compareCalendarEvents);
    return events;
  }

  Future<void> _dropEventToCell(
    Event event,
    DateTime day,
    ArrangeTimeSlot slot,
    int insertIndex,
  ) async {
    final targetDate = dateKey(day);
    final targetSlot = slot.key;
    final sourceDate = event.scheduledDate;
    final sourceSlot = event.timeSlot;
    if (sourceDate == targetDate && sourceSlot == targetSlot) return;

    final currentTargetEvents = _eventsForCellByKey(targetDate, targetSlot);
    var targetIndex = insertIndex.clamp(0, currentTargetEvents.length).toInt();

    final targetEvents = currentTargetEvents
        .where((e) => e.id != event.id)
        .toList();
    targetIndex = targetIndex.clamp(0, targetEvents.length).toInt();

    event.scheduledDate = targetDate;
    event.timeSlot = targetSlot;
    event.status = 'arranged';
    targetEvents.insert(targetIndex, event);

    if (sourceDate != null && sourceSlot != null) {
      final sourceEvents = _eventsForCellByKey(
        sourceDate,
        sourceSlot,
      ).where((e) => e.id != event.id).toList();
      await _saveCellOrder(sourceEvents, sourceDate, sourceSlot);
    }

    await _saveCellOrder(targetEvents, targetDate, targetSlot);
    await _load();
  }

  Future<void> _saveCellOrder(
    List<Event> events,
    String date,
    String timeSlot,
  ) async {
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      event.scheduledDate = date;
      event.timeSlot = timeSlot;
      event.calendarOrder = i;
      await LocalDatabase.saveEvent(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArrangeStyle.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = ArrangeLayoutMetrics.forWidth(constraints.maxWidth);
            final eventHeight = metrics.eventHeightFor(constraints.maxHeight);
            final gap = metrics.compact ? 10.0 : 14.0;
            return Column(
              children: [
                SizedBox(height: eventHeight, child: _buildEventBox()),
                SizedBox(height: gap),
                Expanded(child: _buildCalendarBox(metrics)),
                SizedBox(height: metrics.compact ? 10 : 14),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventBox() {
    return EventBox(
      tabIndex: _displayTabIndex,
      pageController: _pageController,
      eventsForPage: _eventsForPage,
      onPageChanged: _handleEventPageChanged,
      onTabTap: _goToTab,
      onBlankTap: _openInput,
      onOpen: _openDetail,
      onComplete: _completeEvent,
      onRestore: _restoreEvent,
    );
  }

  Widget _buildCalendarBox(ArrangeLayoutMetrics metrics) {
    return AnimatedBuilder(
      animation: _calendarFlipAnimation,
      builder: (context, child) {
        final value = _calendarFlipAnimation.value;
        final animating = _calendarFlipController.isAnimating;
        final firstHalf = !animating || value < 0.5;
        final showQuadrant = firstHalf
            ? _visibleCalendarSideIsQuadrant
            : _targetCalendarSideIsQuadrant;
        final angle = firstHalf
            ? (math.pi / 2) * (value * 2)
            : (-math.pi / 2) + (math.pi / 2) * ((value - 0.5) * 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: ArrangePanel(
            margin: EdgeInsets.symmetric(horizontal: metrics.horizontalMargin),
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.compact ? 18 : 24,
                        metrics.compact ? 4 : 6,
                        metrics.compact ? 18 : 24,
                        0,
                      ),
                      child: CalendarTitle(
                        title: showQuadrant ? '四象限' : '日历',
                        dateText: dateRangeTextForWeekOffset(_weekOffset),
                        actionText: showQuadrant ? '日历 >' : '四象限 >',
                        onActionTap: () => _setCalendarSide(!showQuadrant),
                      ),
                    ),
                    Expanded(
                      child: showQuadrant
                          ? QuadrantView(
                              events: _inboxEvents,
                              onEventTap: _openDetail,
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    PageView.builder(
                                      controller: _calendarPageController,
                                      itemCount: arrangePageCount,
                                      onPageChanged: (page) {
                                        setState(
                                          () => _calendarPageIndex = page,
                                        );
                                      },
                                      itemBuilder: (context, page) {
                                        final weekOffset =
                                            page - initialCalendarPage;
                                        return CalendarGrid(
                                          monday: mondayForWeekOffset(
                                            weekOffset,
                                          ),
                                          weekLabels: arrangeWeekLabels,
                                          timeSlots: arrangeTimeSlots,
                                          onBlankTap: () =>
                                              _showComingSoon('日历详情页即将实现'),
                                          eventsForCell: _eventsForCell,
                                          onEventDrop: _dropEventToCell,
                                          onEventTap: _openDetail,
                                          onEventComplete: _completeEvent,
                                        );
                                      },
                                    ),
                                    CalendarPageDivider(
                                      controller: _calendarPageController,
                                      pageIndex: _calendarPageIndex,
                                      width: constraints.maxWidth,
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (!showQuadrant) _buildCalendarButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarButtons() {
    return Positioned(
      right: 14,
      bottom: 16,
      child: Row(
        children: [
          if (_weekOffset != 0) ...[
            RoundButton(
              icon: Icons.keyboard_return,
              color: ArrangeStyle.returnToToday,
              onTap: () {
                _calendarPageController.animateToPage(
                  initialCalendarPage,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          RoundButton(
            icon: Icons.add,
            color: ArrangeStyle.accent,
            onTap: _openInput,
          ),
        ],
      ),
    );
  }
}
