import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../services/database.dart';
import '../event_detail.dart';
import '../event_input.dart';
import 'arrange_constants.dart';
import 'arrange_helpers.dart';
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

class _ArrangePageState extends State<ArrangePage> {
  final _pageController = PageController(initialPage: initialEventPage);
  final _calendarPageController = PageController(
    initialPage: initialCalendarPage,
  );

  int _pageIndex = initialEventPage;
  int _calendarPageIndex = initialCalendarPage;
  bool _showQuadrant = false;

  List<Event> _inboxEvents = [];
  List<Event> _calendarEvents = [];
  List<Event> _completedEvents = [];
  List<Event> _deletedEvents = [];

  int get _tabIndex => _pageIndex % 3;

  int get _weekOffset => _calendarPageIndex - initialCalendarPage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _calendarPageController.dispose();
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
    _pageController.animateToPage(
      base + tabIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final eventHeight = (constraints.maxHeight * 0.35)
                .clamp(220.0, 258.0)
                .toDouble();
            return Column(
              children: [
                SizedBox(height: eventHeight, child: _buildEventBox()),
                const SizedBox(height: 14),
                Expanded(child: _buildCalendarBox()),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventBox() {
    return EventBox(
      tabIndex: _tabIndex,
      pageController: _pageController,
      eventsForPage: _eventsForPage,
      onPageChanged: (i) => setState(() => _pageIndex = i),
      onTabTap: _goToTab,
      onBlankTap: _openInput,
      onOpen: _openDetail,
      onComplete: _completeEvent,
      onRestore: _restoreEvent,
    );
  }

  Widget _buildCalendarBox() {
    return ArrangePanel(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: CalendarTitle(
                  title: _showQuadrant ? '四象限' : '日历',
                  dateText: dateRangeTextForWeekOffset(_weekOffset),
                  actionText: _showQuadrant ? '日历 >' : '四象限 >',
                  onActionTap: () =>
                      setState(() => _showQuadrant = !_showQuadrant),
                ),
              ),
              Expanded(
                child: _showQuadrant
                    ? const QuadrantView()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              PageView.builder(
                                controller: _calendarPageController,
                                itemCount: arrangePageCount,
                                onPageChanged: (page) {
                                  setState(() => _calendarPageIndex = page);
                                },
                                itemBuilder: (context, page) {
                                  final weekOffset = page - initialCalendarPage;
                                  return CalendarGrid(
                                    monday: mondayForWeekOffset(weekOffset),
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
          if (!_showQuadrant) _buildCalendarButtons(),
        ],
      ),
    );
  }

  Widget _buildCalendarButtons() {
    return Positioned(
      right: 0,
      bottom: 10,
      child: Row(
        children: [
          if (_weekOffset != 0) ...[
            RoundButton(
              icon: Icons.keyboard_return,
              color: Colors.red.shade400,
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
            color: Colors.grey.shade700,
            onTap: _openInput,
          ),
        ],
      ),
    );
  }
}
