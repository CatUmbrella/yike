part of 'event_detail_content.dart';

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.compact,
    required this.controller,
    required this.onChanged,
  });

  final bool compact;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            compact: compact,
            title: '目的',
            trailing: Icon(
              Icons.edit_rounded,
              color: ArrangeStyle.textSecondary,
              size: compact ? 18 : 20,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 2,
            maxLines: 4,
            cursorColor: ArrangeStyle.accent,
            style: TextStyle(
              color: ArrangeStyle.textPrimary,
              fontSize: compact ? 15 : 17,
              height: 1.4,
            ),
            decoration: const InputDecoration.collapsed(
              hintText: '补充这个事件的目的...',
              hintStyle: TextStyle(color: ArrangeStyle.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
