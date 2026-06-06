part of 'event_detail_content.dart';

class _PomodoroButton extends StatelessWidget {
  const _PomodoroButton({
    required this.event,
    required this.height,
    required this.compact,
  });

  final Event event;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final eventId = event.id;
        if (eventId == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请先保存事件后再开始番茄钟')));
          return;
        }

        final active = await PomodoroRepository().loadActiveSession();
        if (!context.mounted) return;
        if (active != null && active.event.id != eventId) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已有番茄钟正在进行，请先结束当前专注')));
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PomodoroTimerPage(
              eventId: eventId,
              initialEvent: active?.event ?? event,
              source: PomodoroStartSource.eventDetail,
            ),
          ),
        );
      },
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4C8DFF), Color(0xFF006BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330A84FF),
              blurRadius: 20,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 48 : 56,
              height: compact ? 48 : 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_rounded,
                color: ArrangeStyle.accent,
                size: compact ? 28 : 32,
              ),
            ),
            SizedBox(width: compact ? 16 : 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '进入番茄钟',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    '开始专注之旅',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xDFFFFFFF),
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
