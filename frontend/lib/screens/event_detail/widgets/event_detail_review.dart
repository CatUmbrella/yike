part of 'event_detail_content.dart';

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.compact,
    required this.expanded,
    required this.controller,
    required this.onToggle,
  });

  final bool compact;
  final bool expanded;
  final TextEditingController controller;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      compact: compact,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 20,
                compact ? 14 : 16,
                compact ? 14 : 16,
                compact ? 14 : 16,
              ),
              child: _SectionHeader(
                compact: compact,
                title: '做后复盘',
                subtitle: '（完成后可填写）',
                trailing: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: ArrangeStyle.textPrimary,
                  size: compact ? 22 : 24,
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ArrangeStyle.border)),
              ),
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 20,
                compact ? 14 : 16,
                compact ? 16 : 20,
                compact ? 16 : 20,
              ),
              child: TextField(
                controller: controller,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                minLines: 4,
                maxLines: 8,
                cursorColor: ArrangeStyle.accent,
                style: TextStyle(
                  color: ArrangeStyle.textPrimary,
                  fontSize: compact ? 14 : 15,
                  height: 1.5,
                ),
                decoration: const InputDecoration.collapsed(
                  hintText: '这次完成得怎么样？\n遇到哪些问题？\n下次可以如何改进？',
                  hintStyle: TextStyle(color: Color(0xFF9AA8BA)),
                ),
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
