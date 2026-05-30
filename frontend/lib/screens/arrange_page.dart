import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database.dart';
import 'event_detail.dart';
import 'event_input.dart';

typedef _CellDropHandler = Future<void> Function(
  Event event,
  DateTime day,
  _TimeSlot slot,
  int insertIndex,
);

class ArrangePage extends StatefulWidget {
  const ArrangePage({super.key});

  @override
  State<ArrangePage> createState() => _ArrangePageState();
}

class _ArrangePageState extends State<ArrangePage> {
  static const _initialEventPage = 15000;
  static const _initialCalendarPage = 15000;
  final _pageController = PageController(initialPage: _initialEventPage);
  final _calendarPageController =
      PageController(initialPage: _initialCalendarPage);

  int _pageIndex = _initialEventPage;
  int _calendarPageIndex = _initialCalendarPage;
  bool _showQuadrant = false;

  List<Event> _inboxEvents = [];
  List<Event> _calendarEvents = [];
  List<Event> _completedEvents = [];
  List<Event> _deletedEvents = [];

  static const _tabs = ['事件箱', '已完成', '回收站'];
  static const _weekLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const _timeSlots = [
    _TimeSlot('0:00', '8:00', 5),
    _TimeSlot('8:00', '10:00', 7),
    _TimeSlot('10:00', '12:00', 9),
    _TimeSlot('12:00', '16:00', 9),
    _TimeSlot('16:00', '20:00', 7),
    _TimeSlot('20:00', '24:00', 5),
  ];

  int get _tabIndex => _pageIndex % 3;

  int get _weekOffset => _calendarPageIndex - _initialCalendarPage;

  DateTime _mondayForOffset(int weekOffset) {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(thisMonday.year, thisMonday.month, thisMonday.day)
        .add(Duration(days: weekOffset * 7));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = await LocalDatabase.getEvents();
    final deleted = await LocalDatabase.getDeletedEvents();
    if (!mounted) return;

    setState(() {
      _inboxEvents = active.where((e) => e.status == 'inbox').toList();
      _calendarEvents = active
          .where((e) => e.scheduledDate != null && e.timeSlot != null)
          .toList();
      _completedEvents = active.where((e) => e.status == 'completed').toList();
      _deletedEvents = deleted;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _calendarPageController.dispose();
    super.dispose();
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

  List<Event> _eventsForCell(DateTime day, _TimeSlot slot) {
    final date = _dateKey(day);
    return _eventsForCellByKey(date, slot.key);
  }

  List<Event> _eventsForCellByKey(String date, String timeSlot) {
    final events = _calendarEvents
        .where((e) => e.scheduledDate == date && e.timeSlot == timeSlot)
        .toList();
    events.sort(_compareCalendarEvents);
    return events;
  }

  int _compareCalendarEvents(Event a, Event b) {
    final order = a.calendarOrder.compareTo(b.calendarOrder);
    if (order != 0) return order;

    final created = a.createdAt.compareTo(b.createdAt);
    if (created != 0) return created;

    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  Future<void> _dropEventToCell(
    Event event,
    DateTime day,
    _TimeSlot slot,
    int insertIndex,
  ) async {
    final targetDate = _dateKey(day);
    final targetSlot = slot.key;
    final sourceDate = event.scheduledDate;
    final sourceSlot = event.timeSlot;
    final sameCell = sourceDate == targetDate && sourceSlot == targetSlot;
    if (sameCell) return;

    final currentTargetEvents = _eventsForCellByKey(targetDate, targetSlot);
    var targetIndex =
        insertIndex.clamp(0, currentTargetEvents.length).toInt();

    final targetEvents =
        currentTargetEvents.where((e) => e.id != event.id).toList();
    targetIndex = targetIndex.clamp(0, targetEvents.length).toInt();

    event.scheduledDate = targetDate;
    event.timeSlot = targetSlot;
    if (event.status != 'completed') event.status = 'arranged';
    targetEvents.insert(targetIndex, event);

    if (sourceDate != null && sourceSlot != null) {
      final sourceEvents = _eventsForCellByKey(sourceDate, sourceSlot)
          .where((e) => e.id != event.id)
          .toList();
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

  String _dateRangeText() {
    final monday = _mondayForOffset(_weekOffset);
    final sunday = monday.add(const Duration(days: 6));
    return '${monday.month}.${monday.day}-${sunday.month}.${sunday.day}';
  }

  String _dateKey(DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$year-$month-$date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final eventHeight =
                (constraints.maxHeight * 0.35).clamp(220.0, 258.0).toDouble();
            return Column(
              children: [
                SizedBox(
                  height: eventHeight,
                  child: _buildEventBox(),
                ),
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
    final canOpenInput = _tabIndex == 0;

    return _Panel(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canOpenInput ? _openInput : null,
            child: SizedBox(
              width: double.infinity,
              height: 24,
              child: Center(
                child: Text(
                  _tabs[_tabIndex],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 30000,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _pageIndex = i),
              itemBuilder: (context, page) {
                return _EventList(
                  events: _eventsForPage(page),
                  isDeleted: page % 3 == 2,
                  canDrag: page % 3 == 0,
                  canComplete: page % 3 == 0,
                  canOpenInput: page % 3 == 0,
                  onBlankTap: _openInput,
                  onOpen: _openDetail,
                  onComplete: _completeEvent,
                  onRestore: _restoreEvent,
                );
              },
            ),
          ),
          _EventBoxTabs(
            tabs: _tabs,
            selectedIndex: _tabIndex,
            onTap: _goToTab,
            onBlankTap: canOpenInput ? _openInput : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBox() {
    return _Panel(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _CalendarTitle(
                  title: _showQuadrant ? '四象限' : '日历',
                  dateText: _dateRangeText(),
                  actionText: _showQuadrant ? '日历 >' : '四象限 >',
                  onActionTap: () =>
                      setState(() => _showQuadrant = !_showQuadrant),
                ),
              ),
              Expanded(
                child: _showQuadrant
                    ? const _QuadrantView()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              PageView.builder(
                                controller: _calendarPageController,
                                itemCount: 30000,
                                onPageChanged: (page) {
                                  setState(() => _calendarPageIndex = page);
                                },
                                itemBuilder: (context, page) {
                                  final weekOffset =
                                      page - _initialCalendarPage;
                                  return _CalendarGrid(
                                    monday: _mondayForOffset(weekOffset),
                                    weekLabels: _weekLabels,
                                    timeSlots: _timeSlots,
                                    onBlankTap: () =>
                                        _showComingSoon('日历详情页即将实现'),
                                    eventsForCell: _eventsForCell,
                                    onEventDrop: _dropEventToCell,
                                    onEventTap: _openDetail,
                                    onEventComplete: _completeEvent,
                                  );
                                },
                              ),
                              _CalendarPageDivider(
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
            _RoundButton(
              icon: Icons.keyboard_return,
              color: Colors.red.shade400,
              onTap: () {
                _calendarPageController.animateToPage(
                  _initialCalendarPage,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          _RoundButton(
            icon: Icons.add,
            color: Colors.grey.shade700,
            onTap: _openInput,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Widget child;

  const _Panel({
    required this.margin,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<Event> events;
  final bool isDeleted;
  final bool canDrag;
  final bool canComplete;
  final bool canOpenInput;
  final VoidCallback onBlankTap;
  final ValueChanged<Event> onOpen;
  final ValueChanged<Event> onComplete;
  final ValueChanged<Event> onRestore;

  const _EventList({
    required this.events,
    required this.isDeleted,
    required this.canDrag,
    required this.canComplete,
    required this.canOpenInput,
    required this.onBlankTap,
    required this.onOpen,
    required this.onComplete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final list = Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.only(right: 2, bottom: 5),
        itemCount: events.isEmpty ? 1 : events.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (events.isEmpty) {
            return SizedBox(
              height: 148,
              child: Center(
                child: Text(
                  canOpenInput ? '点击空白处添加事件' : '暂无事件',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            );
          }

          if (index == events.length) {
            return const SizedBox(height: 70);
          }

          final event = events[index];
          return _EventCard(
            event: event,
            isDeleted: isDeleted,
            canDrag: canDrag && event.status == 'inbox',
            onTap: isDeleted ? null : () => onOpen(event),
            onDoubleTap: canComplete ? () => onComplete(event) : null,
            onDragCanceled: () => onOpen(event),
            onRestore: isDeleted ? () => onRestore(event) : null,
          );
        },
      ),
    );

    if (!canOpenInput) return list;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBlankTap,
      child: list,
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final bool isDeleted;
  final bool canDrag;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDragCanceled;
  final VoidCallback? onRestore;

  const _EventCard({
    required this.event,
    required this.isDeleted,
    required this.canDrag,
    this.onTap,
    this.onDoubleTap,
    this.onDragCanceled,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(opacity: 1);
    if (!canDrag) return card;

    return LongPressDraggable<Event>(
      data: event,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          offset: const Offset(-38, -6),
          child: _EventDragFeedback(event: event),
        ),
      ),
      childWhenDragging: _buildCard(opacity: 0.32),
      onDraggableCanceled: (_, __) => onDragCanceled?.call(),
      child: card,
    );
  }

  Widget _buildCard({required double opacity}) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.title.isEmpty ? '(无标题)' : event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              if (isDeleted && onRestore != null)
                GestureDetector(
                  onTap: onRestore,
                  child: const Text(
                    '恢复',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(
                  _durationText(event.totalMinutes),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDragFeedback extends StatelessWidget {
  final Event event;

  const _EventDragFeedback({required this.event});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final width = _lerp(210, 76, value);
        final height = _lerp(34, 12, value);
        final radius = _lerp(8, 6, value);
        final horizontalPadding = _lerp(10, 3, value);
        final fontSize = _lerp(14, 6.5, value);
        final dotSize = _lerp(16, 0, value);
        final dotGap = _lerp(10, 0, value);

        return Opacity(
          opacity: _lerp(0.9, 0.78, value),
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: 1 - value,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: dotGap),
                Expanded(
                  child: Text(
                    event.summary.isNotEmpty ? event.summary : event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _lerp(double begin, double end, double value) {
    return begin + (end - begin) * value;
  }
}

class _EventBoxTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onBlankTap;

  const _EventBoxTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.onBlankTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _TabBlankArea(onTap: onBlankTap)),
        ...List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              width: 52,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.grey.shade300 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tabs[i],
                style: const TextStyle(fontSize: 10),
              ),
            ),
          );
        }),
        Expanded(child: _TabBlankArea(onTap: onBlankTap)),
      ],
    );
  }
}

class _TabBlankArea extends StatelessWidget {
  final VoidCallback? onTap;

  const _TabBlankArea({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(height: 20),
    );
  }
}

class _CalendarTitle extends StatelessWidget {
  final String title;
  final String dateText;
  final String actionText;
  final VoidCallback onActionTap;

  const _CalendarTitle({
    required this.title,
    required this.dateText,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(dateText, style: const TextStyle(fontSize: 10)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(actionText, style: const TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  static const double _timeAxisWidth = 32;

  final DateTime monday;
  final List<String> weekLabels;
  final List<_TimeSlot> timeSlots;
  final VoidCallback onBlankTap;
  final List<Event> Function(DateTime day, _TimeSlot slot) eventsForCell;
  final _CellDropHandler onEventDrop;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event> onEventComplete;

  const _CalendarGrid({
    required this.monday,
    required this.weekLabels,
    required this.timeSlots,
    required this.onBlankTap,
    required this.eventsForCell,
    required this.onEventDrop,
    required this.onEventTap,
    required this.onEventComplete,
  });

  @override
  Widget build(BuildContext context) {
    final lastRow = timeSlots.length;
    final lastColumn = weekLabels.length;

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              _GridCell(
                width: _timeAxisWidth,
                row: 0,
                column: 0,
                lastRow: lastRow,
                lastColumn: lastColumn,
                child: const SizedBox.shrink(),
              ),
              ...List.generate(7, (i) {
                final day = monday.add(Duration(days: i));
                return Expanded(
                  child: _GridCell(
                    row: 0,
                    column: i + 1,
                    lastRow: lastRow,
                    lastColumn: lastColumn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          weekLabels[i],
                          style: const TextStyle(fontSize: 8),
                        ),
                        const SizedBox(width: 1),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            '/${day.day}',
                            style: const TextStyle(fontSize: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: List.generate(timeSlots.length, (rowIndex) {
              final slot = timeSlots[rowIndex];
              final row = rowIndex + 1;
              return Expanded(
                flex: slot.rowFlex,
                child: Row(
                  children: [
                    _GridCell(
                      width: _timeAxisWidth,
                      row: row,
                      column: 0,
                      lastRow: lastRow,
                      lastColumn: lastColumn,
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: _TimeAxisLabel(slot: slot),
                    ),
                    ...List.generate(7, (columnIndex) {
                      final day = monday.add(Duration(days: columnIndex));
                      return Expanded(
                        child: _CalendarCell(
                          row: row,
                          column: columnIndex + 1,
                          lastRow: lastRow,
                          lastColumn: lastColumn,
                          events: eventsForCell(day, slot),
                          onBlankTap: onBlankTap,
                          onEventDrop: (event, insertIndex) {
                            return onEventDrop(event, day, slot, insertIndex);
                          },
                          onEventTap: onEventTap,
                          onEventComplete: onEventComplete,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final int row;
  final int column;
  final int lastRow;
  final int lastColumn;
  final double? width;
  final EdgeInsets padding;
  final Color? color;
  final Widget child;

  const _GridCell({
    required this.row,
    required this.column,
    required this.lastRow,
    required this.lastColumn,
    required this.child,
    this.width,
    this.padding = EdgeInsets.zero,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          left: column == 0
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade600),
          top: BorderSide(color: Colors.grey.shade600),
          right: BorderSide.none,
          bottom: BorderSide.none,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _TimeAxisLabel extends StatelessWidget {
  final _TimeSlot slot;

  const _TimeAxisLabel({required this.slot});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 7,
      height: 0.95,
      color: Colors.grey.shade900,
    );

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot.start, style: textStyle),
            Text(
              '-',
              style: textStyle.copyWith(color: Colors.grey.shade600),
            ),
            Text(slot.end, style: textStyle),
          ],
        ),
      ),
    );
  }
}

class _CalendarPageDivider extends StatelessWidget {
  final PageController controller;
  final int pageIndex;
  final double width;

  const _CalendarPageDivider({
    required this.controller,
    required this.pageIndex,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page = controller.hasClients
            ? controller.page ?? pageIndex.toDouble()
            : pageIndex.toDouble();
        final fraction = page - page.floorToDouble();
        final distanceFromRest =
            fraction < 0.5 ? fraction : 1.0 - fraction;
        if (distanceFromRest < 0.001) return const SizedBox.shrink();

        final rawLeft = (1.0 - fraction) * width;
        final maxLeft = width > 1 ? width - 1 : 0.0;
        final left = rawLeft.clamp(0.0, maxLeft).toDouble();

        return Positioned(
          left: left,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 1,
              color: Colors.grey.shade600,
            ),
          ),
        );
      },
    );
  }
}

class _CalendarCell extends StatefulWidget {
  final int row;
  final int column;
  final int lastRow;
  final int lastColumn;
  final List<Event> events;
  final VoidCallback onBlankTap;
  final Future<void> Function(Event event, int insertIndex) onEventDrop;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event> onEventComplete;

  const _CalendarCell({
    required this.row,
    required this.column,
    required this.lastRow,
    required this.lastColumn,
    required this.events,
    required this.onBlankTap,
    required this.onEventDrop,
    required this.onEventTap,
    required this.onEventComplete,
  });

  @override
  State<_CalendarCell> createState() => _CalendarCellState();
}

class _CalendarCellState extends State<_CalendarCell> {
  final _cellKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Event>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final box = _cellKey.currentContext?.findRenderObject() as RenderBox?;
        final localY = box?.globalToLocal(details.offset).dy ?? 0;
        widget.onEventDrop(
          details.data,
          _insertIndexForDy(localY, widget.events.length),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          key: _cellKey,
          behavior: HitTestBehavior.opaque,
          onTap: widget.onBlankTap,
          child: _GridCell(
            row: widget.row,
            column: widget.column,
            lastRow: widget.lastRow,
            lastColumn: widget.lastColumn,
            padding: const EdgeInsets.all(2),
            color: isHovering ? Colors.grey.shade100 : null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const itemExtent = 13.0;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.events.map((event) {
                    return _CalendarEventChip(
                      event: event,
                      onTap: () => widget.onEventTap(event),
                      onDoubleTap: event.status == 'completed'
                          ? null
                          : () => widget.onEventComplete(event),
                    );
                  }).toList(),
                );

                if (widget.events.length * itemExtent <=
                    constraints.maxHeight) {
                  return content;
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: content,
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _insertIndexForDy(double dy, int eventCount) {
    const itemExtent = 13.0;
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    return ((dy + scrollOffset) / itemExtent)
        .round()
        .clamp(0, eventCount)
        .toInt();
  }
}

class _CalendarEventChip extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _CalendarEventChip({
    required this.event,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: _buildChip(opacity: 1),
    );

    return LongPressDraggable<Event>(
      data: event,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0.92),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0.78),
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            builder: (context, opacity, child) {
              return Opacity(opacity: opacity, child: child);
            },
            child: SizedBox(width: 68, child: _buildChip(opacity: 1)),
          ),
        ),
      ),
      childWhenDragging: _buildChip(opacity: 0.32),
      child: child,
    );
  }

  Widget _buildChip({required double opacity}) {
    final completed = event.status == 'completed';
    final stateOpacity = completed ? 0.45 : 1.0;
    return Opacity(
      opacity: opacity * stateOpacity,
      child: Container(
        height: 12,
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: completed ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: completed ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        child: Text(
          event.summary.isNotEmpty ? event.summary : event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 6.5,
            color: completed ? Colors.grey.shade700 : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _QuadrantView extends StatelessWidget {
  const _QuadrantView();

  @override
  Widget build(BuildContext context) {
    const labels = ['重要且紧急', '重要不紧急', '不重要但紧急', '不重要不紧急'];
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      crossAxisCount: 2,
      childAspectRatio: 1.15,
      children: labels.map((label) {
        return Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade600)),
          child: Text(label, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade500),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}

class _TimeSlot {
  final String start;
  final String end;
  final int rowFlex;

  const _TimeSlot(this.start, this.end, this.rowFlex);

  String get key => '$start-$end';
}

String _durationText(int minutes) {
  if (minutes <= 0) return '';
  if (minutes < 60) return '${minutes}m';

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h${rest}m';
}
