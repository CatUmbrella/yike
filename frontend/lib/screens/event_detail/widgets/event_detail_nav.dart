part of 'event_detail_content.dart';

class EventDetailNotFoundView extends StatelessWidget {
  const EventDetailNotFoundView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
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
      ),
    );
  }
}

class _DetailNavBar extends StatelessWidget {
  const _DetailNavBar({
    required this.compact,
    required this.onBack,
    required this.onDelete,
  });

  final bool compact;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          style: TextButton.styleFrom(
            foregroundColor: ArrangeStyle.accent,
            padding: EdgeInsets.zero,
            minimumSize: Size(compact ? 82 : 92, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: compact ? 25 : 28),
          label: Text(
            '安排',
            style: TextStyle(
              fontSize: compact ? 17 : 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: '更多',
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: ArrangeStyle.accent,
            size: 30,
          ),
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'delete', child: Text('删除事件')),
          ],
        ),
      ],
    );
  }
}
