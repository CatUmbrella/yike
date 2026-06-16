import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/repositories/event_repository.dart';
import 'package:frontend/services/database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('event repository replaces steps when updating an event', () async {
    const repository = EventRepository();
    final unique = DateTime.now().microsecondsSinceEpoch;
    final event = Event(
      title: 'transaction event $unique',
      summary: 'transaction',
      steps: [
        StepItem(stepOrder: 1, description: 'old step', estimatedMin: 10),
      ],
    );
    int? eventId;

    try {
      eventId = await repository.saveEvent(event);
      event.steps = [
        StepItem(stepOrder: 1, description: 'new step 1', estimatedMin: 15),
        StepItem(stepOrder: 2, description: 'new step 2', estimatedMin: 20),
      ];

      await repository.saveEvent(event);

      final loaded = await repository.loadEventById(eventId);
      expect(loaded, isNotNull);
      expect(loaded!.steps.map((step) => step.description), [
        'new step 1',
        'new step 2',
      ]);
      expect(loaded.totalMinutes, 35);
    } finally {
      if (eventId != null) {
        await LocalDatabase.deleteEventPermanently(eventId);
      }
    }
  });
}
