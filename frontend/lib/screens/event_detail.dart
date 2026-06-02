import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/database.dart';
import 'arrange/arrange_style.dart';

enum _DetailLoadState { loading, loaded, notFound }

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _reviewController = TextEditingController();
  var _loadState = _DetailLoadState.loading;
  Event? _event;
  bool _closing = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final event = await LocalDatabase.getEventById(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = event;
      _reviewController.text = event?.review ?? '';
      _loadState = event == null
          ? _DetailLoadState.notFound
          : _DetailLoadState.loaded;
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    FocusScope.of(context).unfocus();

    try {
      await _saveReviewIfNeeded();
    } catch (_) {
      if (!mounted) return;
      _closing = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('复盘保存失败，请稍后重试')));
      return;
    }

    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _saveReviewIfNeeded() async {
    final event = _event;
    if (event == null || event.id == null) return;

    final review = _reviewController.text.trim();
    if (review == event.review) return;

    event.review = review;
    await LocalDatabase.saveEvent(event);
  }

  Future<void> _deleteEvent() async {
    final event = _event;
    if (event == null || event.id == null) return;
    final eventTitle = _dialogTitle(event.title);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除事件'),
        content: Text('确定把「$eventTitle」移入回收站吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await LocalDatabase.softDeleteEvent(event.id!);
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        backgroundColor: ArrangeStyle.background,
        appBar: AppBar(
          title: const Text('事件详情'),
          centerTitle: true,
          backgroundColor: ArrangeStyle.background,
          foregroundColor: ArrangeStyle.textPrimary,
          elevation: 0,
          leading: IconButton(
            tooltip: '返回',
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          actions: [
            if (_loadState == _DetailLoadState.loaded)
              IconButton(
                tooltip: '删除',
                onPressed: _deleteEvent,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_loadState) {
      case _DetailLoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _DetailLoadState.notFound:
        return _NotFoundView(onBack: _close);
      case _DetailLoadState.loaded:
        return _DetailContent(
          event: _event!,
          reviewController: _reviewController,
        );
    }
  }

  String _dialogTitle(String title) {
    final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 24) return normalized;
    return '${normalized.substring(0, 24)}...';
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.event, required this.reviewController});

  final Event event;
  final TextEditingController reviewController;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final horizontalPadding = compact ? 14.0 : 22.0;
    final cardPadding = compact ? 18.0 : 22.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 8 : 12,
        horizontalPadding,
        24,
      ),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: ArrangeStyle.surface,
          borderRadius: BorderRadius.circular(compact ? 24 : 28),
          border: Border.all(color: ArrangeStyle.border),
          boxShadow: ArrangeStyle.panelShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              event.title.isEmpty ? '(无标题)' : event.title,
              style: TextStyle(
                color: ArrangeStyle.textPrimary,
                fontSize: compact ? 22 : 25,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            if (event.purpose.trim().isNotEmpty) ...[
              SizedBox(height: compact ? 14 : 16),
              _LabeledText(label: '目的', text: event.purpose),
            ],
            SizedBox(height: compact ? 18 : 22),
            const _SectionTitle('怎么做'),
            SizedBox(height: compact ? 10 : 12),
            if (event.steps.isEmpty)
              Text(
                '暂无步骤',
                style: TextStyle(
                  color: ArrangeStyle.textSecondary,
                  fontSize: compact ? 14 : 15,
                ),
              )
            else
              ...event.steps.map((step) => _StepRow(step: step)),
            const Divider(height: 28, color: ArrangeStyle.border),
            _DurationSummary(event: event),
            SizedBox(height: compact ? 18 : 22),
            _PomodoroButton(),
            SizedBox(height: compact ? 20 : 24),
            const _SectionTitle('做后复盘'),
            const SizedBox(height: 10),
            TextField(
              controller: reviewController,
              minLines: 4,
              maxLines: 7,
              cursorColor: ArrangeStyle.accent,
              style: TextStyle(
                color: ArrangeStyle.textPrimary,
                fontSize: compact ? 14 : 15,
                height: 1.45,
              ),
              decoration: InputDecoration(
                hintText: '完成后在这里写下复盘...',
                hintStyle: const TextStyle(color: ArrangeStyle.textSecondary),
                filled: true,
                fillColor: ArrangeStyle.accentSofter,
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: ArrangeStyle.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: ArrangeStyle.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: ArrangeStyle.textSecondary,
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: ArrangeStyle.textPrimary,
              fontSize: compact ? 14 : 15,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    return Text(
      '$text:',
      style: TextStyle(
        color: ArrangeStyle.textPrimary,
        fontSize: compact ? 15 : 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final StepItem step;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: const BoxDecoration(
              color: ArrangeStyle.accent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              '第${step.stepOrder}步: ${step.description}',
              style: TextStyle(
                color: ArrangeStyle.textPrimary,
                fontSize: compact ? 14 : 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _durationText(step.estimatedMin),
            style: TextStyle(
              color: ArrangeStyle.textSecondary,
              fontSize: compact ? 13 : 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationSummary extends StatelessWidget {
  const _DurationSummary({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final stepTotal = event.steps.fold<int>(
      0,
      (sum, step) => sum + step.estimatedMin,
    );
    final total = event.totalMinutes;
    final overridden = event.totalMinutesOverride != null && total != stepTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '预计总耗时:',
              style: TextStyle(
                color: ArrangeStyle.textPrimary,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _durationText(total),
              style: TextStyle(
                color: ArrangeStyle.accent,
                fontSize: compact ? 15 : 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (overridden) ...[
          const SizedBox(height: 6),
          Text(
            '步骤累计 ${_durationText(stepTotal)}，总耗时已手动调整',
            style: TextStyle(
              color: ArrangeStyle.textSecondary,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ],
    );
  }
}

String _durationText(int totalMinutes) {
  final minutes = totalMinutes < 0 ? 0 : totalMinutes;
  if (minutes < 60) return '${minutes}m';

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h${rest}m';
}

class _PomodoroButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('番茄钟功能即将上线，届时可从此处进入专注计时')),
          );
        },
        icon: const Icon(Icons.timer_outlined),
        label: const Text('进入番茄钟，开始专注之旅'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ArrangeStyle.accent,
          side: const BorderSide(color: ArrangeStyle.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 44,
              color: ArrangeStyle.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              '事件不存在或已被删除',
              style: TextStyle(
                color: ArrangeStyle.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onBack, child: const Text('返回')),
          ],
        ),
      ),
    );
  }
}
