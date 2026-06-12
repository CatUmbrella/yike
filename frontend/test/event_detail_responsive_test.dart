import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/screens/event_detail/widgets/event_detail_content.dart';

void main() {
  testWidgets('event detail metric chips fit on compact width', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;

    final reviewController = TextEditingController();
    addTearDown(reviewController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDetailContent(
            event: Event(
              id: 1,
              title: '修复程序错误',
              purpose: '补充这个事件的目的',
              totalMinutesOverride: 30,
            ),
            reviewController: reviewController,
            onBack: () {},
            onDelete: () {},
            onEventChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
