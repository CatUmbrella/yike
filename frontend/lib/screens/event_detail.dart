import 'dart:async';

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../repositories/event_repository.dart';
import 'arrange/arrange_style.dart';
import 'event_detail/widgets/event_detail_content.dart';

enum _DetailLoadState { loading, loaded, notFound }

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  final EventRepository eventRepository;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.eventRepository = const EventRepository(),
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _reviewController = TextEditingController();
  var _loadState = _DetailLoadState.loading;
  Event? _event;
  bool _closing = false;
  bool _eventChanged = false;

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
    final event = await widget.eventRepository.loadEventById(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = event;
      if (event != null) {
        _reviewController.text = event.review;
      }
      _eventChanged = false;
      _loadState = event == null
          ? _DetailLoadState.notFound
          : _DetailLoadState.loaded;
    });
  }

  Future<bool> _close({bool pop = true}) async {
    if (_closing) return false;
    _closing = true;
    if (mounted) FocusScope.of(context).unfocus();

    try {
      final changed = await _saveChangesIfNeeded();
      if (pop && mounted) Navigator.pop(context, changed);
      return changed;
    } catch (_) {
      if (pop && mounted) {
        _closing = false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('复盘保存失败，请稍后重试')));
      }
      return false;
    }
  }

  Future<bool> _saveChangesIfNeeded() async {
    final event = _event;
    if (event == null || event.id == null) return false;

    final review = _reviewController.text.trim();
    final reviewChanged = review != event.review;
    if (!reviewChanged && !_eventChanged) return false;

    event.review = review;
    if (_eventChanged) {
      await widget.eventRepository.saveEvent(event);
    } else {
      await widget.eventRepository.updateReview(event.id!, review);
    }
    return true;
  }

  void _markEventChanged() {
    _eventChanged = true;
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
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
    await widget.eventRepository.softDeleteEvent(event.id!);
    if (!mounted) return;
    _closing = true;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final allowInteractivePop =
        Theme.of(context).platform == TargetPlatform.iOS;

    return PopScope<void>(
      canPop: allowInteractivePop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(_close(pop: false));
          return;
        }
        unawaited(_close());
      },
      child: Scaffold(
        backgroundColor: ArrangeStyle.background,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_loadState) {
      case _DetailLoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _DetailLoadState.notFound:
        return EventDetailNotFoundView(onBack: _close);
      case _DetailLoadState.loaded:
        return EventDetailContent(
          event: _event!,
          keyboardVisible: MediaQuery.viewInsetsOf(context).bottom > 0,
          reviewController: _reviewController,
          onBack: _close,
          onDelete: _deleteEvent,
          onEventChanged: _markEventChanged,
        );
    }
  }

  String _dialogTitle(String title) {
    final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 24) return normalized;
    return '${normalized.substring(0, 24)}...';
  }
}
