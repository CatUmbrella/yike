import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../arrange_constants.dart';
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

    return ArrangePanel(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canOpenInput ? onBlankTap : null,
            child: SizedBox(
              width: double.infinity,
              height: 24,
              child: Center(
                child: Text(
                  arrangeTabs[tabIndex],
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
    final list = Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.only(right: 2, bottom: 5),
        itemCount: events.isEmpty ? 1 : events.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
              child: Text(tabs[i], style: const TextStyle(fontSize: 10)),
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
