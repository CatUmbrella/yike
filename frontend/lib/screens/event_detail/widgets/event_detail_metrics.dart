part of 'event_detail_content.dart';

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.event, required this.compact});

  final Event event;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final completed = event.status == 'completed';
    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            compact: compact,
            icon: completed ? Icons.check_circle_outline : Icons.schedule,
            label: completed ? '总用时' : '预计耗时',
            value: formatEventDuration(event.displayTotalMinutes),
            emphasizeValue: true,
          ),
        ),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: _MetricChip(
            compact: compact,
            icon: Icons.fact_check_outlined,
            label: '共',
            value: '${event.steps.length} 个步骤',
            emphasizeValue: true,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.compact,
    required this.icon,
    required this.label,
    required this.value,
    required this.emphasizeValue,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final String value;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: ArrangeStyle.accentSofter,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: ArrangeStyle.border),
        boxShadow: ArrangeStyle.itemShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 18 : 20, color: ArrangeStyle.accent),
          SizedBox(width: compact ? 6 : 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: emphasizeValue
                        ? ArrangeStyle.accent
                        : ArrangeStyle.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              color: ArrangeStyle.textPrimary,
              fontSize: compact ? 14 : 15,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
