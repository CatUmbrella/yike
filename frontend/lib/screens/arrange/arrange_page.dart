import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../event_detail.dart';
import '../event_input.dart';
import 'arrange_constants.dart';
import 'arrange_controller.dart';
import 'arrange_helpers.dart';
import 'arrange_style.dart';
import 'widgets/arrange_panel.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/calendar_page_divider.dart';
import 'widgets/calendar_title.dart';
import 'widgets/draggable_add_button.dart';
import 'widgets/event_box.dart';
import 'widgets/quadrant_view.dart';
import 'widgets/round_button.dart';

class ArrangePage extends StatefulWidget {
  final bool active;
  final int refreshToken;
  final ValueChanged<bool>? onEventDragChanged;
  final Offset? addButtonOffset;
  final ValueChanged<Offset>? onAddButtonOffsetChanged;

  const ArrangePage({
    super.key,
    this.active = true,
    this.refreshToken = 0,
    this.onEventDragChanged,
    this.addButtonOffset,
    this.onAddButtonOffsetChanged,
  });

  @override
  State<ArrangePage> createState() => _ArrangePageState();
}

class _ArrangePageState extends State<ArrangePage>
    with SingleTickerProviderStateMixin {
  final _controller = ArrangeController();
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
    _controller.load();
  }

  @override
  void didUpdateWidget(covariant ArrangePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken ||
        (!oldWidget.active && widget.active)) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _calendarPageController.dispose();
    _calendarFlipController.dispose();
    super.dispose();
  }

  Future<void> _openInput() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EventInputScreen()),
    );
    if (changed != false) _controller.load();
  }

  Future<void> _openDetail(Event event) async {
    if (event.id == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id!)),
    );
    if (changed != false) _controller.load();
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
    await _controller.markCompleted(event);
  }

  Future<void> _restoreEvent(Event event) async {
    await _controller.restoreEvent(event);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArrangeStyle.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final metrics = ArrangeLayoutMetrics.forWidth(
                  constraints.maxWidth,
                );
                final eventHeight = metrics.eventHeightFor(
                  constraints.maxHeight,
                );
                final gap = metrics.compact ? 10.0 : 14.0;
                return Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: eventHeight, child: _buildEventBox()),
                        SizedBox(height: gap),
                        Expanded(child: _buildCalendarBox(metrics)),
                        SizedBox(height: metrics.compact ? 10 : 14),
                      ],
                    ),
                    DraggableAddButton(
                      constraints: constraints,
                      offset: widget.addButtonOffset,
                      onOffsetChanged:
                          widget.onAddButtonOffsetChanged ?? (_) {},
                      onTap: _openInput,
                    ),
                  ],
                );
              },
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
      eventsForPage: _controller.eventsForPage,
      onPageChanged: _handleEventPageChanged,
      onTabTap: _goToTab,
      onBlankTap: _openInput,
      onOpen: _openDetail,
      onComplete: _completeEvent,
      onRestore: _restoreEvent,
      onEventDragStarted: () => widget.onEventDragChanged?.call(true),
      onEventDragEnded: () => widget.onEventDragChanged?.call(false),
    );
  }

  Widget _buildCalendarBox(ArrangeLayoutMetrics metrics) {
    final calendarFace = _buildCalendarPanel(metrics, showQuadrant: false);
    final quadrantFace = _buildCalendarPanel(metrics, showQuadrant: true);

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
          child: IndexedStack(
            index: showQuadrant ? 1 : 0,
            children: [calendarFace, quadrantFace],
          ),
        );
      },
    );
  }

  Widget _buildCalendarPanel(
    ArrangeLayoutMetrics metrics, {
    required bool showQuadrant,
  }) {
    return ArrangePanel(
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
                        events: _controller.inboxEvents,
                        onEventTap: _openDetail,
                        onEventDrop: _controller.dropEventToQuadrant,
                      )
                    : _buildCalendarGrid(),
              ),
            ],
          ),
          if (!showQuadrant && _weekOffset != 0)
            _buildReturnToTodayButton(metrics),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return LayoutBuilder(
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
                  onBlankTap: () => _showComingSoon('日历详情页即将实现'),
                  eventsForCell: _controller.eventsForCell,
                  onEventDrop: _controller.dropEventToCell,
                  onEventTap: _openDetail,
                  onEventComplete: _completeEvent,
                  onEventDragStarted: () =>
                      widget.onEventDragChanged?.call(true),
                  onEventDragEnded: () =>
                      widget.onEventDragChanged?.call(false),
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
    );
  }

  Widget _buildReturnToTodayButton(ArrangeLayoutMetrics metrics) {
    final buttonSize = _floatingButtonSize(metrics);
    return Positioned(
      right: 14 + buttonSize + 8,
      bottom: 16,
      child: RoundButton(
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
    );
  }

  double _floatingButtonSize(ArrangeLayoutMetrics metrics) {
    return metrics.compact ? 54.0 : 62.0;
  }
}
