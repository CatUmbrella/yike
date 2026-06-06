import 'package:flutter/material.dart';

import '../../shared/event_formatters.dart';
import 'dialogs/history_session_dialog.dart';
import 'pomodoro_history_controller.dart';
import 'pomodoro_models.dart';
import 'pomodoro_repository.dart';
import 'pomodoro_style.dart';
import 'widgets/tomato_icon.dart';

class PomodoroHistoryPage extends StatefulWidget {
  const PomodoroHistoryPage({super.key});

  @override
  State<PomodoroHistoryPage> createState() => _PomodoroHistoryPageState();
}

class _PomodoroHistoryPageState extends State<PomodoroHistoryPage> {
  late final PomodoroHistoryController controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    controller = PomodoroHistoryController()..load();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: PomodoroStyle.background,
          appBar: AppBar(
            title: const Text(
              '番茄钟',
              style: TextStyle(
                color: PomodoroStyle.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            foregroundColor: PomodoroStyle.textPrimary,
            backgroundColor: PomodoroStyle.background,
            elevation: 0,
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HistorySearchField(
                    controller: _searchController,
                    onSubmitted: controller.updateSearchQuery,
                  ),
                  const SizedBox(height: 28),
                  _MonthSelector(controller: controller),
                  const SizedBox(height: 18),
                  Expanded(
                    child: controller.loading
                        ? const Center(child: CircularProgressIndicator())
                        : _HistoryList(controller: controller),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistorySearchField extends StatelessWidget {
  const _HistorySearchField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: PomodoroStyle.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: PomodoroStyle.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: PomodoroStyle.textSecondary,
              size: 34,
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 58),
          hintText: '可以搜索日期或者事件名称',
          hintStyle: TextStyle(
            color: PomodoroStyle.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.controller});

  final PomodoroHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final month =
        '${controller.selectedMonth.year}年${controller.selectedMonth.month}月';
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _pickMonth(context),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
        label: Text(month),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0D47A1),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _MonthPickerSheet(initialMonth: controller.selectedMonth),
    );
    if (picked != null) {
      await controller.selectMonth(picked);
    }
  }
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: PomodoroStyle.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PomodoroStyle.border),
          boxShadow: PomodoroStyle.panelShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_year年',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PomodoroStyle.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final selected =
                    _year == widget.initialMonth.year &&
                    month == widget.initialMonth.month;
                return FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, DateTime(_year, month)),
                  style: FilledButton.styleFrom(
                    backgroundColor: selected
                        ? PomodoroStyle.accent
                        : PomodoroStyle.accentSofter,
                    foregroundColor: selected
                        ? Colors.white
                        : PomodoroStyle.accentDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('$month月'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.controller});

  final PomodoroHistoryController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.sections.isEmpty) {
      return const Center(
        child: Text(
          '暂无历史记录',
          style: TextStyle(
            color: PomodoroStyle.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: controller.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = controller.sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: sectionIndex == 0 ? 0 : 18,
                bottom: 12,
              ),
              child: Text(
                section.title,
                style: const TextStyle(
                  color: PomodoroStyle.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            for (final item in section.items)
              _HistoryCard(item: item, onTap: () => _openDetail(context, item)),
          ],
        );
      },
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    PomodoroHistoryListItem item,
  ) async {
    final repository = PomodoroRepository();
    final detail = await repository.loadHistoryDetail(item);
    if (!context.mounted) return;
    final changed = await showHistorySessionDialog(
      context: context,
      detail: detail,
    );
    if (changed == true) {
      await repository.saveHistoryEventEdit(
        detail.event,
        sessionId: detail.session.id,
      );
      await controller.load();
    }
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onTap});

  final PomodoroHistoryListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: PomodoroStyle.accent.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _BlueDot(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              eventDisplayTitle(item.event),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PomodoroStyle.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.completed ? '(完成)' : '(未完成)',
                            style: const TextStyle(
                              color: PomodoroStyle.accentDeep,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            '打断次数： ${item.interruptionCount}',
                            style: _metaTextStyle,
                          ),
                          const Spacer(),
                          Text('想法： ${item.ideaCount}', style: _metaTextStyle),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _TomatoCount(count: item.tomatoCount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _metaTextStyle = TextStyle(
  color: Color(0xFF2B4E88),
  fontSize: 15,
  fontWeight: FontWeight.w600,
);

class _BlueDot extends StatelessWidget {
  const _BlueDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: PomodoroStyle.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: PomodoroStyle.accent.withValues(alpha: 0.24),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _TomatoCount extends StatelessWidget {
  const _TomatoCount({required this.count});

  static const _iconSize = 24.0;
  static const _iconGap = 4.0;
  static const _reservedWidth = _iconSize * 3 + _iconGap * 2;

  final int count;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (count <= 0) {
      content = const SizedBox.shrink();
    } else if (count > 3) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TomatoIcon(size: _iconSize),
          const SizedBox(width: _iconGap),
          Text(
            '×$count',
            style: const TextStyle(
              color: PomodoroStyle.accentDeep,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) => Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : _iconGap),
            child: const TomatoIcon(size: _iconSize),
          ),
        ),
      );
    }

    return SizedBox(
      width: _reservedWidth,
      child: Align(alignment: Alignment.centerRight, child: content),
    );
  }
}
