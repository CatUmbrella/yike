import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/pomodoro_models.dart';
import 'package:frontend/repositories/pomodoro_repository.dart';
import 'package:frontend/screens/pomodoro/pomodoro_timer_controller.dart';
import 'package:frontend/shared/pomodoro_constants.dart';

void main() {
  test('timer sync catches up elapsed time from the wall clock', () async {
    final repository = _FakePomodoroRepository();
    final controller = PomodoroTimerController(repository: repository);
    final now = DateTime.now();
    controller.snapshot = PomodoroTaskSnapshot(
      event: Event(id: 1, title: 'timer sync'),
      session: PomodoroSession(
        id: 1,
        eventId: 1,
        startTime: now.subtract(const Duration(minutes: 1)),
        status: PomodoroTimerStatus.running,
        durationSec: PomodoroConstants.tomatoSeconds - 10,
        tomatoCount: 0,
        createdAt: now,
        updatedAt: now.subtract(const Duration(seconds: 15)),
      ),
      interruptions: const [],
      ideas: const [],
      stepRecords: const [],
    );

    controller.syncElapsedFromClock();
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.elapsedSeconds,
      greaterThanOrEqualTo(PomodoroConstants.tomatoSeconds + 5),
    );
    expect(controller.session?.tomatoCount, 1);
    expect(repository.savedSnapshots, isNotEmpty);

    controller.dispose();
  });
}

class _FakePomodoroRepository extends PomodoroRepository {
  final savedSnapshots = <PomodoroTaskSnapshot>[];

  @override
  Future<void> saveSnapshot(
    PomodoroTaskSnapshot snapshot, {
    bool includeRecords = false,
    bool saveEvent = false,
  }) async {
    savedSnapshots.add(snapshot);
  }
}
