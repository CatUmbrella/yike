import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await LocalDatabase.getEvents();
    for (final e in events) {
      if (e.id == widget.eventId) {
        if (!mounted) return;
        setState(() => _event = e);
        return;
      }
    }
  }

  Future<void> _deleteEvent() async {
    final event = _event;
    if (event == null || event.id == null) return;
    final eventId = event.id!;
    final eventTitle = event.title;

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
    await LocalDatabase.softDeleteEvent(eventId);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('事件详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final e = _event!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('事件详情'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '删除',
            onPressed: _deleteEvent,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(e.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 目的
            if (e.purpose.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('目的：',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 15)),
                  Expanded(
                      child: Text(e.purpose,
                          style: const TextStyle(fontSize: 15))),
                ],
              ),
            ],

            // 怎么做
            const SizedBox(height: 12),
            const Text('怎么做：',
                style: TextStyle(color: Colors.grey, fontSize: 15)),

            // 步骤
            for (var i = 0; i < e.steps.length; i++) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '第${e.steps[i].stepOrder}步：${e.steps[i].description}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Text('${e.steps[i].estimatedMin}min',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),
            Row(
              children: [
                const Text('预计总耗时：',
                    style: TextStyle(fontSize: 15)),
                Text('${e.totalMinutes}min',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),

            const SizedBox(height: 24),

            // 进入番茄钟按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('番茄钟功能即将上线，届时可从此处进入专注计时')),
                  );
                },
                icon: const Icon(Icons.timer),
                label: const Text('进入番茄钟，开始专注之旅'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 做后复盘
            const Text('做后复盘：',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '完成后在这里写下复盘...',
                border: const OutlineInputBorder(),
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
