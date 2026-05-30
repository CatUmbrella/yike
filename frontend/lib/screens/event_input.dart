import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api.dart';
import '../services/database.dart';

class EventInputScreen extends StatefulWidget {
  const EventInputScreen({super.key});

  @override
  State<EventInputScreen> createState() => _EventInputScreenState();
}

class _EventInputScreenState extends State<EventInputScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  bool _failed = false;
  List<Event> _parsed = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.trim().isNotEmpty) {
        Future.delayed(const Duration(seconds: 3), () {
          if (!_focusNode.hasFocus && mounted) _parse();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final results = await ApiService.parseEventText(text);
    setState(() {
      _loading = false;
      if (results.isEmpty) {
        _failed = true;
      } else {
        _parsed = results;
      }
    });
  }

  Future<void> _saveOne(Event e) async {
    await LocalDatabase.saveEvent(e);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存：${e.title}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加事件'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ═══ 区域 1：手动录入 ═══
              Text('手动录入',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: '点击输入或长按讲话，AI会自动区分事件',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _parse,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? '正在拆解计划中...' : 'AI 拆解'),
              ),

              if (_failed) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text('生成失败，请重试',
                        style: TextStyle(color: Colors.orange)),
                    const Spacer(),
                    TextButton(onPressed: _parse, child: const Text('重试')),
                  ],
                ),
              ],

              // ═══ 区域 2：事件预览 ═══
              if (_parsed.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('事件预览',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (var i = 0; i < _parsed.length; i++)
                  _PreviewCard(
                    event: _parsed[i],
                    onSave: () => _saveOne(_parsed[i]),
                  ),
              ],

              // ═══ 区域 3：语音输入（暂时占位） ═══
              const SizedBox(height: 24),
              Text('语音输入',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('语音输入功能即将上线')),
                  );
                },
                icon: const Icon(Icons.mic),
                label: const Text('长按说话'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                '注：生成失败时请点击重试按钮重新触发 AI 处理。\n新增 / 删除步骤时序号会自动重新排序。',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatefulWidget {
  final Event event;
  final VoidCallback onSave;

  const _PreviewCard({required this.event, required this.onSave});

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  late Event _e;
  bool _edited = false; // 用户修改过就不再显示灰色

  @override
  void initState() {
    super.initState();
    _e = widget.event;
  }

  void _addStep() {
    setState(() {
      _e.steps.add(StepItem(
        stepOrder: _e.steps.length + 1,
        description: '',
        estimatedMin: 0,
      ));
      _edited = true;
    });
  }

  void _removeStep(int index) {
    setState(() {
      _e.steps.removeAt(index);
      _reorder();
      _edited = true;
    });
  }

  void _reorder() {
    for (var i = 0; i < _e.steps.length; i++) {
      _e.steps[i].stepOrder = i + 1;
    }
  }

  Color _textColor(bool isTitle) {
    if (isTitle) return Colors.black;
    return _edited ? Colors.black : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题（黑色=确定）
            Row(
              children: [
                Expanded(
                  child: Text(_e.title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor(true))),
                ),
                Text('${_e.totalMinutes}min',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textColor(false))),
              ],
            ),
            if (_e.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_e.summary,
                    style: TextStyle(
                        color: _textColor(false), fontSize: 13)),
              ),
            const Divider(),

            // 步骤列表
            const Text('怎么做：',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            ...List.generate(_e.steps.length, (i) {
              final s = _e.steps[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Text('第${i + 1}步：',
                        style: TextStyle(
                            color: _textColor(false), fontSize: 14)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(text: s.description),
                        style:
                            TextStyle(color: _textColor(false), fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          s.description = v;
                          setState(() => _edited = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: TextField(
                        controller: TextEditingController(
                            text: '${s.estimatedMin}'),
                        keyboardType: TextInputType.number,
                        style:
                            TextStyle(color: _textColor(false), fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.zero,
                          suffixText: 'min',
                        ),
                        onChanged: (v) {
                          s.estimatedMin = int.tryParse(v) ?? 0;
                          setState(() => _edited = true);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.red),
                      onPressed: () => _removeStep(i),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),

            // 添加步骤
            TextButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加步骤'),
            ),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _e = widget.event;
                      _edited = false;
                    });
                  },
                  child: const Text('重置AI建议'),
                ),
                FilledButton(
                  onPressed: widget.onSave,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
