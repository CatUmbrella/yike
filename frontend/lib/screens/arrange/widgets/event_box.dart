import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../arrange_constants.dart';
import '../arrange_style.dart';
import 'arrange_panel.dart';
import 'event_card.dart';

class EventBox extends StatelessWidget {
  final int tabIndex;
  final PageController pageController;
  final List<Event> Function(int page) eventsForPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTabTap;
  final VoidCallback onBlankTap;
  final ValueChanged<Event> onOpen;
  final ValueChanged<Event> onComplete;
  final ValueChanged<Event> onRestore;

  const EventBox({
    super.key,
    required this.tabIndex,
    required this.pageController,
    required this.eventsForPage,
    required this.onPageChanged,
    required this.onTabTap,
    required this.onBlankTap,
    required this.onOpen,
    required this.onComplete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final canOpenInput = tabIndex == 0;
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );

    return ArrangePanel(
      margin: EdgeInsets.fromLTRB(
        metrics.horizontalMargin,
        metrics.eventPanelTopMargin,
        metrics.horizontalMargin,
        0,
      ),
      padding: EdgeInsets.fromLTRB(
        metrics.eventPanelPaddingX,
        metrics.eventPanelPaddingTop,
        metrics.eventPanelPaddingX,
        metrics.eventPanelPaddingBottom,
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canOpenInput ? onBlankTap : null,
            child: SizedBox(
              width: double.infinity,
              height: metrics.compact ? 20 : 22,
              child: Center(
                child: Text(
                  arrangeTabs[tabIndex],
                  style: TextStyle(
                    fontSize: ArrangeStyle.eventBoxTitleSize,
                    fontWeight: FontWeight.w700,
                    color: ArrangeStyle.textPrimary,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.compact ? 4 : 5),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: arrangePageCount,
              physics: const BouncingScrollPhysics(),
              onPageChanged: onPageChanged,
              itemBuilder: (context, page) {
                return _EventList(
                  events: eventsForPage(page),
                  isDeleted: page % 3 == 2,
                  canDrag: page % 3 == 0,
                  canComplete: page % 3 == 0,
                  canOpenInput: page % 3 == 0,
                  onBlankTap: onBlankTap,
                  onOpen: onOpen,
                  onComplete: onComplete,
                  onRestore: onRestore,
                );
              },
            ),
          ),
          _EventBoxTabs(
            tabs: arrangeTabs,
            selectedIndex: tabIndex,
            onTap: onTabTap,
            onBlankTap: canOpenInput ? onBlankTap : null,
          ),
        ],
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
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    final list = Scrollbar(
      radius: const Radius.circular(8),
      thickness: 4,
      child: ListView.separated(
        padding: const EdgeInsets.only(right: 6, bottom: 2),
        itemCount: events.isEmpty ? 1 : events.length,
        separatorBuilder: (_, _) => SizedBox(height: metrics.eventCardGap),
        itemBuilder: (context, index) {
          if (events.isEmpty) {
            return SizedBox(
              height: 148,
              child: Center(
                child: Text(
                  canOpenInput ? '点击空白处添加事件' : '暂无事件',
                  style: const TextStyle(
                    color: ArrangeStyle.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }

          final event = events[index];
          return EventCard(
            event: event,
            isDeleted: isDeleted,
            canDrag: canDrag && event.status != 'completed',
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
    final width = MediaQuery.sizeOf(context).width;
    final metrics = ArrangeLayoutMetrics.forWidth(width);
    final segmentWidth = (width * 0.5).clamp(156.0, 210.0).toDouble();
    final height = metrics.eventTabHeight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _TabBlankArea(onTap: onBlankTap, height: height),
        ),
        Container(
          width: segmentWidth,
          height: height,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: ArrangeStyle.accentSofter,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? ArrangeStyle.accentSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: metrics.compact ? 10 : 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? ArrangeStyle.accent
                              : ArrangeStyle.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _TabBlankArea(onTap: onBlankTap, height: height),
        ),
      ],
    );
  }
}

class _TabBlankArea extends StatelessWidget {
  final VoidCallback? onTap;
  final double height;

  const _TabBlankArea({this.onTap, required this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(height: height),
    );
  }
}
