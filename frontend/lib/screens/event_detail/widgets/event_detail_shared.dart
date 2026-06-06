part of 'event_detail_content.dart';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.compact,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final bool compact;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 7 : 8,
          height: compact ? 7 : 8,
          decoration: const BoxDecoration(
            color: ArrangeStyle.accent,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Text(
          title,
          style: TextStyle(
            color: ArrangeStyle.textPrimary,
            fontSize: compact ? 17 : 18,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(width: compact ? 6 : 8),
          Flexible(
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ArrangeStyle.textSecondary,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.compact, required this.child, this.padding});

  final bool compact;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: ArrangeStyle.surface,
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        border: Border.all(color: ArrangeStyle.border),
        boxShadow: ArrangeStyle.itemShadow,
      ),
      child: child,
    );
  }
}
